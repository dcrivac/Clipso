#!/usr/bin/env node
/**
 * Clipso License Generator
 *
 * Admin tool to manually generate lifetime licenses
 * Usage: node generate-license.js <email>
 */

require('dotenv').config();
const crypto = require('crypto');
const { Pool } = require('pg');
const readline = require('readline');

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'clipso_licenses',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
});

/**
 * Generate a unique license key
 */
function generateLicenseKey(seed) {
    const hash = crypto.createHash('sha256').update(seed).digest('hex');
    const parts = hash.substring(0, 16).match(/.{1,4}/g);
    return `CLIPSO-${parts.join('-').toUpperCase()}`;
}

/**
 * Generate a unique transaction ID for manual licenses
 */
function generateTransactionId() {
    const timestamp = Date.now();
    const random = crypto.randomBytes(8).toString('hex');
    return `manual_${timestamp}_${random}`;
}

/**
 * Create a lifetime license
 */
async function createLifetimeLicense(email, licenseType = 'lifetime', deviceLimit = 3) {
    const client = await pool.connect();

    try {
        // Generate unique identifiers
        const transactionId = generateTransactionId();
        const licenseKey = generateLicenseKey(transactionId);

        // Check if email already has a license
        const existingLicense = await client.query(
            'SELECT license_key, license_type, status FROM licenses WHERE email = $1',
            [email]
        );

        if (existingLicense.rows.length > 0) {
            const existing = existingLicense.rows[0];
            console.log('\n⚠️  Warning: This email already has a license:');
            console.log(`   License Key: ${existing.license_key}`);
            console.log(`   Type: ${existing.license_type}`);
            console.log(`   Status: ${existing.status}\n`);

            // Ask for confirmation
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });

            const answer = await new Promise(resolve => {
                rl.question('Do you want to create another license for this email? (yes/no): ', resolve);
            });
            rl.close();

            if (answer.toLowerCase() !== 'yes' && answer.toLowerCase() !== 'y') {
                console.log('\n❌ License generation cancelled.\n');
                return null;
            }
        }

        // Insert license into database
        const result = await client.query(
            `INSERT INTO licenses
            (license_key, email, transaction_id, product_id, price_id, license_type, status, device_limit, purchased_at, expires_at, custom_data)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING *`,
            [
                licenseKey,
                email,
                transactionId,
                'prod_clipso_lifetime',
                'manual',
                licenseType,
                'active',
                deviceLimit,
                new Date(),
                null, // NULL for lifetime licenses
                JSON.stringify({ source: 'manual', generated_by: 'admin' })
            ]
        );

        const license = result.rows[0];

        console.log('\n✅ Lifetime license created successfully!\n');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`📧 Email:        ${license.email}`);
        console.log(`🔑 License Key:  ${license.license_key}`);
        console.log(`🎫 Type:         ${license.license_type}`);
        console.log(`✓  Status:       ${license.status}`);
        console.log(`📱 Device Limit: ${license.device_limit} devices`);
        console.log(`📅 Created:      ${license.purchased_at}`);
        console.log(`⏰ Expires:      Never (Lifetime)`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        console.log('📋 Send this information to your friend:\n');
        console.log('   Subject: Your Clipso Lifetime License');
        console.log('   ─────────────────────────────────────────────────');
        console.log(`   Email: ${license.email}`);
        console.log(`   License Key: ${license.license_key}`);
        console.log('   ─────────────────────────────────────────────────');
        console.log('   To activate:');
        console.log('   1. Open Clipso app');
        console.log('   2. Go to Settings → License');
        console.log('   3. Enter the email and license key above');
        console.log('   4. Click "Activate License"\n');

        return license;

    } catch (error) {
        console.error('\n❌ Error creating license:', error.message);
        throw error;
    } finally {
        client.release();
    }
}

/**
 * Main function
 */
async function main() {
    const args = process.argv.slice(2);

    console.log('\n🎫 Clipso Lifetime License Generator\n');

    // Get email from command line or prompt
    let email = args[0];

    if (!email) {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });

        email = await new Promise(resolve => {
            rl.question('Enter email address for the license: ', resolve);
        });
        rl.close();
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
        console.error('\n❌ Invalid email address provided.\n');
        process.exit(1);
    }

    try {
        // Check database connection
        await pool.query('SELECT 1');

        // Create the license
        await createLifetimeLicense(email.trim());

    } catch (error) {
        if (error.code === 'ECONNREFUSED') {
            console.error('\n❌ Error: Cannot connect to database.');
            console.error('   Make sure PostgreSQL is running and the connection details in .env are correct.\n');
        } else {
            console.error('\n❌ Error:', error.message, '\n');
        }
        process.exit(1);
    } finally {
        await pool.end();
    }
}

// Run the script
if (require.main === module) {
    main().catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
}

module.exports = { generateLicenseKey, generateTransactionId, createLifetimeLicense };
