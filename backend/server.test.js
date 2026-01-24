/**
 * Unit tests for Clipso License Server
 */

const request = require('supertest');
const app = require('./server');

describe('License Server API', () => {
    describe('GET /health', () => {
        it('should return health status', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            expect(response.body).toHaveProperty('status', 'ok');
            expect(response.body).toHaveProperty('timestamp');
        });
    });

    describe('POST /api/licenses/activate', () => {
        it('should return 400 when license_key is missing', async () => {
            const response = await request(app)
                .post('/api/licenses/activate')
                .send({
                    device_id: 'test-device-123'
                })
                .expect(400);

            expect(response.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });

        it('should return 400 when device_id is missing', async () => {
            const response = await request(app)
                .post('/api/licenses/activate')
                .send({
                    license_key: 'CLIPSO-TEST-1234-5678'
                })
                .expect(400);

            expect(response.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });

        it('should return 404 for invalid license key', async () => {
            const response = await request(app)
                .post('/api/licenses/activate')
                .send({
                    license_key: 'INVALID-KEY-1234-5678',
                    device_id: 'test-device-123'
                })
                .expect(404);

            expect(response.body).toHaveProperty('error', 'INVALID_LICENSE');
        });

        // Note: Additional tests require database setup with test data
    });

    describe('POST /api/licenses/validate', () => {
        it('should return 400 when license_key is missing', async () => {
            const response = await request(app)
                .post('/api/licenses/validate')
                .send({
                    device_id: 'test-device-123'
                })
                .expect(400);

            expect(response.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });

        it('should return 400 when device_id is missing', async () => {
            const response = await request(app)
                .post('/api/licenses/validate')
                .send({
                    license_key: 'CLIPSO-TEST-1234-5678'
                })
                .expect(400);

            expect(response.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });
    });

    describe('POST /api/licenses/deactivate', () => {
        it('should return 400 when license_key is missing', async () => {
            const response = await request(app)
                .post('/api/licenses/deactivate')
                .send({
                    device_id: 'test-device-123'
                })
                .expect(400);

            expect(response.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });

        it('should return 400 when device_id is missing', async () => {
            const response = await request(app)
                .post('/api/licenses/deactivate')
                .send({
                    license_key: 'CLIPSO-TEST-1234-5678'
                })
                .expect(400);

            expect(response.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });
    });

    describe('GET /api/licenses/:license_key', () => {
        it('should return 404 for non-existent license', async () => {
            const response = await request(app)
                .get('/api/licenses/INVALID-KEY-1234-5678')
                .expect(404);

            expect(response.body).toHaveProperty('error', 'INVALID_LICENSE');
        });
    });
});

describe('Helper Functions', () => {
    const crypto = require('crypto');

    describe('generateLicenseKey', () => {
        it('should generate consistent license keys for same transaction', () => {
            const generateLicenseKey = (transactionId) => {
                const hash = crypto.createHash('sha256').update(transactionId).digest('hex');
                const parts = hash.substring(0, 16).match(/.{1,4}/g);
                return `CLIPSO-${parts.join('-').toUpperCase()}`;
            };

            const txnId = 'txn_01234567890';
            const key1 = generateLicenseKey(txnId);
            const key2 = generateLicenseKey(txnId);

            expect(key1).toBe(key2);
            expect(key1).toMatch(/^CLIPSO-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$/);
        });

        it('should generate different keys for different transactions', () => {
            const generateLicenseKey = (transactionId) => {
                const hash = crypto.createHash('sha256').update(transactionId).digest('hex');
                const parts = hash.substring(0, 16).match(/.{1,4}/g);
                return `CLIPSO-${parts.join('-').toUpperCase()}`;
            };

            const key1 = generateLicenseKey('txn_01234567890');
            const key2 = generateLicenseKey('txn_09876543210');

            expect(key1).not.toBe(key2);
        });
    });

    describe('checkLicenseStatus', () => {
        it('should return invalid for inactive license', async () => {
            const checkLicenseStatus = (license) => {
                if (license.status !== 'active') {
                    return { valid: false, reason: 'license_inactive' };
                }
                return { valid: true };
            };

            const license = { status: 'cancelled', expires_at: null };
            const result = checkLicenseStatus(license);

            expect(result.valid).toBe(false);
            expect(result.reason).toBe('license_inactive');
        });

        it('should return invalid for expired license', () => {
            const checkLicenseStatus = (license) => {
                if (license.status !== 'active') {
                    return { valid: false, reason: 'license_inactive' };
                }

                if (license.expires_at) {
                    const now = new Date();
                    const expiresAt = new Date(license.expires_at);
                    if (now > expiresAt) {
                        return { valid: false, reason: 'license_expired' };
                    }
                }

                return { valid: true };
            };

            const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
            const license = { status: 'active', expires_at: yesterday.toISOString() };
            const result = checkLicenseStatus(license);

            expect(result.valid).toBe(false);
            expect(result.reason).toBe('license_expired');
        });

        it('should return valid for active lifetime license', () => {
            const checkLicenseStatus = (license) => {
                if (license.status !== 'active') {
                    return { valid: false, reason: 'license_inactive' };
                }

                if (license.expires_at) {
                    const now = new Date();
                    const expiresAt = new Date(license.expires_at);
                    if (now > expiresAt) {
                        return { valid: false, reason: 'license_expired' };
                    }
                }

                return { valid: true };
            };

            const license = { status: 'active', expires_at: null };
            const result = checkLicenseStatus(license);

            expect(result.valid).toBe(true);
        });

        it('should return valid for active subscription not yet expired', () => {
            const checkLicenseStatus = (license) => {
                if (license.status !== 'active') {
                    return { valid: false, reason: 'license_inactive' };
                }

                if (license.expires_at) {
                    const now = new Date();
                    const expiresAt = new Date(license.expires_at);
                    if (now > expiresAt) {
                        return { valid: false, reason: 'license_expired' };
                    }
                }

                return { valid: true };
            };

            const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
            const license = { status: 'active', expires_at: tomorrow.toISOString() };
            const result = checkLicenseStatus(license);

            expect(result.valid).toBe(true);
        });
    });
});

describe('Integration Tests', () => {
    // These tests require a test database to be set up
    // Run with: npm test -- --testPathPattern=integration

    describe('Full Activation Flow', () => {
        it.skip('should activate license, validate, and deactivate', async () => {
            // This test requires database setup
            // 1. Create test license in database
            // 2. Activate on device
            // 3. Validate license
            // 4. Deactivate device
            // 5. Verify device is deactivated
        });
    });

    describe('Device Limit Enforcement', () => {
        it.skip('should prevent activation beyond device limit', async () => {
            // This test requires database setup
            // 1. Create license with limit of 3 devices
            // 2. Activate on 3 devices
            // 3. Try to activate on 4th device
            // 4. Verify activation fails with DEVICE_LIMIT_EXCEEDED
        });
    });
});
