/**
 * Clipso License Validation Server
 *
 * Handles:
 * - License activation and validation
 * - Device tracking and limits
 * - Paddle webhook events
 * - Periodic revalidation
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const { Pool } = require('pg');
const { sendLicenseEmail } = require('./email-service');

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'clipso_licenses',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Verify Paddle webhook signature
 */
function verifyPaddleSignature(req) {
    const signature = req.headers['paddle-signature'];
    if (!signature) {
        return false;
    }

    // Extract timestamp and signature
    const parts = signature.split(';');
    let ts, h1;

    parts.forEach(part => {
        const [key, value] = part.split('=');
        if (key === 'ts') ts = value;
        if (key === 'h1') h1 = value;
    });

    if (!ts || !h1) {
        return false;
    }

    // Reconstruct signed payload
    const signedPayload = `${ts}:${JSON.stringify(req.body)}`;

    // Calculate expected signature
    const expectedSignature = crypto
        .createHmac('sha256', process.env.PADDLE_WEBHOOK_SECRET)
        .update(signedPayload)
        .digest('hex');

    // Compare signatures
    return crypto.timingSafeEqual(
        Buffer.from(h1),
        Buffer.from(expectedSignature)
    );
}

/**
 * Generate license key from transaction
 */
function generateLicenseKey(transactionId) {
    // Format: CLIPSO-XXXX-XXXX-XXXX-XXXX
    const hash = crypto.createHash('sha256').update(transactionId).digest('hex');
    const parts = hash.substring(0, 16).match(/.{1,4}/g);
    return `CLIPSO-${parts.join('-').toUpperCase()}`;
}

/**
 * Check if license is valid and not expired
 */
async function checkLicenseStatus(license) {
    if (license.status !== 'active') {
        return { valid: false, reason: 'license_inactive' };
    }

    // Check expiration for subscription licenses
    if (license.expires_at) {
        const now = new Date();
        const expiresAt = new Date(license.expires_at);
        if (now > expiresAt) {
            return { valid: false, reason: 'license_expired' };
        }
    }

    return { valid: true };
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * Health check
 */
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

/**
 * Activate license on a device
 * POST /api/licenses/activate
 */
app.post('/api/licenses/activate', async (req, res) => {
    const { license_key, device_id, device_name, device_model, os_version, app_version } = req.body;

    if (!license_key || !device_id) {
        return res.status(400).json({
            success: false,
            error: 'MISSING_PARAMETERS',
            message: 'license_key and device_id are required'
        });
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Get license
        const licenseResult = await client.query(
            'SELECT * FROM licenses WHERE license_key = $1',
            [license_key]
        );

        if (licenseResult.rows.length === 0) {
            await client.query('ROLLBACK');

            // Log failed validation
            await logValidation(license_key, device_id, 'invalid_key', req.ip);

            return res.status(404).json({
                success: false,
                error: 'INVALID_LICENSE',
                message: 'License key not found'
            });
        }

        const license = licenseResult.rows[0];

        // Check license status
        const statusCheck = await checkLicenseStatus(license);
        if (!statusCheck.valid) {
            await client.query('ROLLBACK');
            await logValidation(license_key, device_id, statusCheck.reason, req.ip);

            return res.status(403).json({
                success: false,
                error: statusCheck.reason.toUpperCase(),
                message: `License is ${statusCheck.reason.replace('_', ' ')}`
            });
        }

        // Check if device is already activated
        const deviceResult = await client.query(
            'SELECT * FROM devices WHERE license_id = $1 AND device_id = $2',
            [license.id, device_id]
        );

        if (deviceResult.rows.length > 0) {
            const device = deviceResult.rows[0];

            if (device.is_active) {
                // Update last_seen
                await client.query(
                    'UPDATE devices SET last_seen = CURRENT_TIMESTAMP WHERE id = $1',
                    [device.id]
                );

                await client.query('COMMIT');

                return res.json({
                    success: true,
                    message: 'Device already activated',
                    license_type: license.license_type,
                    expires_at: license.expires_at,
                    device_id: device.device_id
                });
            } else {
                // Reactivate device
                await client.query(
                    'UPDATE devices SET is_active = TRUE, last_seen = CURRENT_TIMESTAMP, deactivated_at = NULL WHERE id = $1',
                    [device.id]
                );

                await client.query('COMMIT');

                return res.json({
                    success: true,
                    message: 'Device reactivated',
                    license_type: license.license_type,
                    expires_at: license.expires_at,
                    device_id: device.device_id
                });
            }
        }

        // Check device limit
        const activeDevicesResult = await client.query(
            'SELECT COUNT(*) as count FROM devices WHERE license_id = $1 AND is_active = TRUE',
            [license.id]
        );

        const activeDeviceCount = parseInt(activeDevicesResult.rows[0].count);

        if (activeDeviceCount >= license.device_limit) {
            await client.query('ROLLBACK');
            await logValidation(license_key, device_id, 'device_limit_exceeded', req.ip);

            return res.status(403).json({
                success: false,
                error: 'DEVICE_LIMIT_EXCEEDED',
                message: `Maximum ${license.device_limit} devices allowed. Deactivate a device to continue.`,
                devices_used: activeDeviceCount,
                devices_limit: license.device_limit
            });
        }

        // Activate new device
        await client.query(
            `INSERT INTO devices
            (license_id, device_id, device_name, device_model, os_version, app_version, ip_address)
            VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [license.id, device_id, device_name, device_model, os_version, app_version, req.ip]
        );

        // Update license last_validated
        await client.query(
            'UPDATE licenses SET last_validated = CURRENT_TIMESTAMP WHERE id = $1',
            [license.id]
        );

        await client.query('COMMIT');
        await logValidation(license_key, device_id, 'success', req.ip);

        res.json({
            success: true,
            message: 'Device activated successfully',
            license_type: license.license_type,
            expires_at: license.expires_at,
            devices_used: activeDeviceCount + 1,
            devices_limit: license.device_limit
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Activation error:', error);
        res.status(500).json({
            success: false,
            error: 'SERVER_ERROR',
            message: 'Failed to activate license'
        });
    } finally {
        client.release();
    }
});

/**
 * Validate license (for periodic revalidation)
 * POST /api/licenses/validate
 */
app.post('/api/licenses/validate', async (req, res) => {
    const { license_key, device_id } = req.body;

    if (!license_key || !device_id) {
        return res.status(400).json({
            success: false,
            error: 'MISSING_PARAMETERS',
            message: 'license_key and device_id are required'
        });
    }

    try {
        // Get license
        const licenseResult = await pool.query(
            'SELECT * FROM licenses WHERE license_key = $1',
            [license_key]
        );

        if (licenseResult.rows.length === 0) {
            await logValidation(license_key, device_id, 'invalid_key', req.ip);
            return res.status(404).json({
                success: false,
                error: 'INVALID_LICENSE',
                message: 'License key not found',
                valid: false
            });
        }

        const license = licenseResult.rows[0];

        // Check license status
        const statusCheck = await checkLicenseStatus(license);
        if (!statusCheck.valid) {
            await logValidation(license_key, device_id, statusCheck.reason, req.ip);
            return res.json({
                success: false,
                error: statusCheck.reason.toUpperCase(),
                message: `License is ${statusCheck.reason.replace('_', ' ')}`,
                valid: false
            });
        }

        // Check if device is activated
        const deviceResult = await pool.query(
            'SELECT * FROM devices WHERE license_id = $1 AND device_id = $2 AND is_active = TRUE',
            [license.id, device_id]
        );

        if (deviceResult.rows.length === 0) {
            await logValidation(license_key, device_id, 'device_not_activated', req.ip);
            return res.json({
                success: false,
                error: 'DEVICE_NOT_ACTIVATED',
                message: 'This device is not activated for this license',
                valid: false
            });
        }

        // Update last_seen and last_validated
        await pool.query(
            'UPDATE devices SET last_seen = CURRENT_TIMESTAMP WHERE id = $1',
            [deviceResult.rows[0].id]
        );

        await pool.query(
            'UPDATE licenses SET last_validated = CURRENT_TIMESTAMP WHERE id = $1',
            [license.id]
        );

        await logValidation(license_key, device_id, 'success', req.ip);

        res.json({
            success: true,
            valid: true,
            license_type: license.license_type,
            expires_at: license.expires_at,
            email: license.email
        });

    } catch (error) {
        console.error('Validation error:', error);
        res.status(500).json({
            success: false,
            error: 'SERVER_ERROR',
            message: 'Failed to validate license',
            valid: false
        });
    }
});

/**
 * Deactivate device
 * POST /api/licenses/deactivate
 */
app.post('/api/licenses/deactivate', async (req, res) => {
    const { license_key, device_id } = req.body;

    if (!license_key || !device_id) {
        return res.status(400).json({
            success: false,
            error: 'MISSING_PARAMETERS',
            message: 'license_key and device_id are required'
        });
    }

    try {
        // Get license
        const licenseResult = await pool.query(
            'SELECT * FROM licenses WHERE license_key = $1',
            [license_key]
        );

        if (licenseResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'INVALID_LICENSE',
                message: 'License key not found'
            });
        }

        const license = licenseResult.rows[0];

        // Deactivate device
        const result = await pool.query(
            `UPDATE devices
            SET is_active = FALSE, deactivated_at = CURRENT_TIMESTAMP
            WHERE license_id = $1 AND device_id = $2 AND is_active = TRUE
            RETURNING *`,
            [license.id, device_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'DEVICE_NOT_FOUND',
                message: 'Device not found or already deactivated'
            });
        }

        res.json({
            success: true,
            message: 'Device deactivated successfully'
        });

    } catch (error) {
        console.error('Deactivation error:', error);
        res.status(500).json({
            success: false,
            error: 'SERVER_ERROR',
            message: 'Failed to deactivate device'
        });
    }
});

/**
 * Get license info (including activated devices)
 * GET /api/licenses/:license_key
 */
app.get('/api/licenses/:license_key', async (req, res) => {
    const { license_key } = req.params;

    try {
        // Get license with devices
        const result = await pool.query(
            `SELECT
                l.*,
                json_agg(
                    json_build_object(
                        'device_id', d.device_id,
                        'device_name', d.device_name,
                        'device_model', d.device_model,
                        'activated_at', d.activated_at,
                        'last_seen', d.last_seen,
                        'is_active', d.is_active
                    )
                ) FILTER (WHERE d.id IS NOT NULL) as devices
            FROM licenses l
            LEFT JOIN devices d ON l.id = d.license_id AND d.is_active = TRUE
            WHERE l.license_key = $1
            GROUP BY l.id`,
            [license_key]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'INVALID_LICENSE',
                message: 'License key not found'
            });
        }

        const license = result.rows[0];
        const statusCheck = await checkLicenseStatus(license);

        res.json({
            success: true,
            license: {
                license_key: license.license_key,
                email: license.email,
                license_type: license.license_type,
                status: license.status,
                valid: statusCheck.valid,
                purchased_at: license.purchased_at,
                expires_at: license.expires_at,
                device_limit: license.device_limit,
                devices: license.devices || [],
                devices_used: license.devices ? license.devices.length : 0
            }
        });

    } catch (error) {
        console.error('License info error:', error);
        res.status(500).json({
            success: false,
            error: 'SERVER_ERROR',
            message: 'Failed to retrieve license info'
        });
    }
});

/**
 * Retrieve license by email (resend license key)
 * POST /api/licenses/retrieve
 */
app.post('/api/licenses/retrieve', async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({
            success: false,
            error: 'MISSING_PARAMETER',
            message: 'email is required'
        });
    }

    try {
        // Get active licenses for this email
        const result = await pool.query(
            `SELECT license_key, license_type, status, expires_at
             FROM licenses
             WHERE email = $1 AND status = 'active'
             ORDER BY purchased_at DESC`,
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'NO_LICENSE_FOUND',
                message: 'No active licenses found for this email address'
            });
        }

        // Get the most recent license
        const license = result.rows[0];

        // Resend license email
        const emailSent = await sendLicenseEmail(email, license.license_key, license.license_type);

        if (emailSent) {
            res.json({
                success: true,
                message: 'License key has been sent to your email address',
                licenses_found: result.rows.length
            });
        } else {
            // Email service not configured, return license in response
            res.json({
                success: true,
                message: 'License retrieved successfully',
                license_key: license.license_key,
                license_type: license.license_type,
                expires_at: license.expires_at,
                licenses_found: result.rows.length
            });
        }

    } catch (error) {
        console.error('License retrieval error:', error);
        res.status(500).json({
            success: false,
            error: 'SERVER_ERROR',
            message: 'Failed to retrieve license'
        });
    }
});

/**
 * Paddle webhook handler
 * POST /webhook/paddle
 */
app.post('/webhook/paddle', async (req, res) => {
    // Verify webhook signature
    if (!verifyPaddleSignature(req)) {
        console.error('Invalid webhook signature');
        return res.status(401).json({ error: 'Invalid signature' });
    }

    const event = req.body;
    const eventType = event.event_type;
    const eventId = event.event_id;

    console.log(`Received Paddle webhook: ${eventType} (${eventId})`);

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Check if event already processed
        const existingEvent = await client.query(
            'SELECT id FROM webhook_events WHERE event_id = $1',
            [eventId]
        );

        if (existingEvent.rows.length > 0) {
            console.log(`Event ${eventId} already processed, skipping`);
            await client.query('ROLLBACK');
            return res.json({ received: true, message: 'Event already processed' });
        }

        // Log webhook event
        await client.query(
            `INSERT INTO webhook_events (event_id, event_type, transaction_id, customer_id, subscription_id, payload)
            VALUES ($1, $2, $3, $4, $5, $6)`,
            [
                eventId,
                eventType,
                event.data?.id,
                event.data?.customer_id,
                event.data?.subscription_id,
                JSON.stringify(event)
            ]
        );

        // Process event based on type
        switch (eventType) {
            case 'transaction.completed':
                await handleTransactionCompleted(client, event);
                break;

            case 'transaction.updated':
                await handleTransactionUpdated(client, event);
                break;

            case 'subscription.activated':
                await handleSubscriptionActivated(client, event);
                break;

            case 'subscription.cancelled':
                await handleSubscriptionCancelled(client, event);
                break;

            case 'subscription.past_due':
                await handleSubscriptionPastDue(client, event);
                break;

            default:
                console.log(`Unhandled event type: ${eventType}`);
        }

        // Mark event as processed
        await client.query(
            'UPDATE webhook_events SET processed = TRUE, processed_at = CURRENT_TIMESTAMP WHERE event_id = $1',
            [eventId]
        );

        await client.query('COMMIT');

        res.json({ received: true });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Webhook processing error:', error);

        // Log error in webhook_events
        await pool.query(
            'UPDATE webhook_events SET error = $1 WHERE event_id = $2',
            [error.message, eventId]
        );

        res.status(500).json({ error: 'Webhook processing failed' });
    } finally {
        client.release();
    }
});

// ============================================================================
// WEBHOOK EVENT HANDLERS
// ============================================================================

async function handleTransactionCompleted(client, event) {
    const data = event.data;
    const transactionId = data.id;
    const customerId = data.customer_id;
    const customerEmail = data.customer?.email;

    // Extract product and price info
    const items = data.items || [];
    if (items.length === 0) {
        console.error('No items in transaction');
        return;
    }

    const firstItem = items[0];
    const productId = firstItem.price?.product_id;
    const priceId = firstItem.price?.id;
    const billingCycle = firstItem.price?.billing_cycle;

    // Determine license type
    let licenseType = 'lifetime';
    let expiresAt = null;

    if (billingCycle) {
        if (billingCycle.frequency === 1 && billingCycle.interval === 'year') {
            licenseType = 'annual';
            expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year from now
        } else if (billingCycle.frequency === 1 && billingCycle.interval === 'month') {
            licenseType = 'monthly';
            expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days from now
        }
    }

    // Generate license key
    const licenseKey = generateLicenseKey(transactionId);

    // Create license
    await client.query(
        `INSERT INTO licenses
        (license_key, email, transaction_id, product_id, price_id, license_type, status, purchased_at, expires_at, paddle_customer_id, paddle_subscription_id, custom_data)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ON CONFLICT (transaction_id) DO UPDATE
        SET status = 'active', updated_at = CURRENT_TIMESTAMP`,
        [
            licenseKey,
            customerEmail,
            transactionId,
            productId,
            priceId,
            licenseType,
            'active',
            data.created_at,
            expiresAt,
            customerId,
            data.subscription_id,
            JSON.stringify(data.custom_data || {})
        ]
    );

    console.log(`License created: ${licenseKey} for ${customerEmail} (type: ${licenseType})`);

    // Send license email to customer
    try {
        await sendLicenseEmail(customerEmail, licenseKey, licenseType);
    } catch (error) {
        console.error(`Failed to send license email to ${customerEmail}:`, error);
        // License is still created in database, email failure doesn't stop the process
    }
}

async function handleTransactionUpdated(client, event) {
    const data = event.data;
    const transactionId = data.id;

    // Update license status based on transaction status
    await client.query(
        'UPDATE licenses SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE transaction_id = $2',
        [data.status === 'completed' ? 'active' : data.status, transactionId]
    );
}

async function handleSubscriptionActivated(client, event) {
    const data = event.data;
    const subscriptionId = data.id;

    // Update license status
    await client.query(
        'UPDATE licenses SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE paddle_subscription_id = $2',
        ['active', subscriptionId]
    );
}

async function handleSubscriptionCancelled(client, event) {
    const data = event.data;
    const subscriptionId = data.id;

    // Update license status
    await client.query(
        'UPDATE licenses SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE paddle_subscription_id = $2',
        ['cancelled', subscriptionId]
    );
}

async function handleSubscriptionPastDue(client, event) {
    const data = event.data;
    const subscriptionId = data.id;

    // Update license status
    await client.query(
        'UPDATE licenses SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE paddle_subscription_id = $2',
        ['past_due', subscriptionId]
    );
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

async function logValidation(licenseKey, deviceId, result, ipAddress) {
    try {
        await pool.query(
            'INSERT INTO validation_logs (license_key, device_id, validation_result, ip_address) VALUES ($1, $2, $3, $4)',
            [licenseKey, deviceId, result, ipAddress]
        );
    } catch (error) {
        console.error('Failed to log validation:', error);
    }
}

// ============================================================================
// ERROR HANDLING
// ============================================================================

app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        error: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred'
    });
});

// ============================================================================
// START SERVER
// ============================================================================

app.listen(PORT, () => {
    console.log(`🚀 Clipso License Server running on port ${PORT}`);
    console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🗄️  Database: ${process.env.DB_NAME || 'clipso_licenses'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing server...');
    pool.end();
    process.exit(0);
});

module.exports = app; // For testing
