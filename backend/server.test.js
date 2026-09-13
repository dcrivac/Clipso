/**
 * Tests for the Clipso license server.
 *
 * Unit tests (validation, helpers, auth) run with no database.
 * Integration tests run only when RUN_DB_TESTS=1 and a database is reachable
 * (CI sets this and provides a Postgres service; see .github/workflows/backend.yml).
 */

const crypto = require('crypto');
const request = require('supertest');

process.env.ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'test-admin-token';
process.env.PADDLE_WEBHOOK_SECRET = process.env.PADDLE_WEBHOOK_SECRET || 'test-webhook-secret';

const app = require('./server');
const pool = require('./db');

const runDbTests = process.env.RUN_DB_TESTS === '1';
const itDb = runDbTests ? it : it.skip;

afterAll(async () => {
    await pool.end().catch(() => {});
});

describe('Health', () => {
    it('GET /health returns ok without touching the database', async () => {
        const res = await request(app).get('/health').expect(200);
        expect(res.body).toHaveProperty('status', 'ok');
        expect(res.body).toHaveProperty('timestamp');
    });
});

describe('Input validation (no DB)', () => {
    const endpoints = ['/api/licenses/activate', '/api/licenses/validate', '/api/licenses/deactivate'];

    for (const path of endpoints) {
        it(`POST ${path} -> 400 when license_key missing`, async () => {
            const res = await request(app).post(path).send({ device_id: 'd1' }).expect(400);
            expect(res.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });

        it(`POST ${path} -> 400 when device_id missing`, async () => {
            const res = await request(app).post(path).send({ license_key: 'CLIPSO-AAAA-BBBB-CCCC-DDDD' }).expect(400);
            expect(res.body).toHaveProperty('error', 'MISSING_PARAMETERS');
        });
    }
});

describe('Admin endpoint auth (no DB)', () => {
    it('GET /api/licenses/:key -> 401 without a token', async () => {
        await request(app).get('/api/licenses/CLIPSO-AAAA-BBBB-CCCC-DDDD').expect(401);
    });

    it('GET /api/licenses/:key -> 401 with a wrong token', async () => {
        await request(app)
            .get('/api/licenses/CLIPSO-AAAA-BBBB-CCCC-DDDD')
            .set('Authorization', 'Bearer nope')
            .expect(401);
    });
});

describe('Paddle webhook signature (no DB)', () => {
    it('rejects a request with no signature header', async () => {
        await request(app).post('/webhook/paddle').send({ event_type: 'x' }).expect(401);
    });

    it('rejects a request with a bad signature', async () => {
        await request(app)
            .post('/webhook/paddle')
            .set('Paddle-Signature', `ts=${Math.floor(Date.now() / 1000)};h1=deadbeef`)
            .set('Content-Type', 'application/json')
            .send(JSON.stringify({ event_type: 'transaction.completed', event_id: 'evt_1' }))
            .expect(401);
    });

    it('accepts a correctly signed request (unhandled event type is fine)', async () => {
        if (!runDbTests) return; // handler touches the DB
        const ts = Math.floor(Date.now() / 1000);
        const body = JSON.stringify({ event_type: 'report.created', event_id: `evt_${Date.now()}` });
        const sig = crypto
            .createHmac('sha256', process.env.PADDLE_WEBHOOK_SECRET)
            .update(`${ts}:${body}`)
            .digest('hex');
        const res = await request(app)
            .post('/webhook/paddle')
            .set('Paddle-Signature', `ts=${ts};h1=${sig}`)
            .set('Content-Type', 'application/json')
            .send(body)
            .expect(200);
        expect(res.body).toHaveProperty('received', true);
    });
});

describe('Helpers (no DB)', () => {
    const generateLicenseKey = (transactionId) => {
        const hash = crypto.createHash('sha256').update(transactionId).digest('hex');
        return `CLIPSO-${hash.substring(0, 16).match(/.{1,4}/g).join('-').toUpperCase()}`;
    };

    it('license key is deterministic per transaction and well-formed', () => {
        const a = generateLicenseKey('txn_1');
        expect(a).toBe(generateLicenseKey('txn_1'));
        expect(a).not.toBe(generateLicenseKey('txn_2'));
        expect(a).toMatch(/^CLIPSO-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$/);
    });
});

describe('Integration: activation lifecycle (DB)', () => {
    const key = `CLIPSO-TEST-${Date.now().toString(16).toUpperCase()}`;
    const txn = `test_${Date.now()}`;

    beforeAll(async () => {
        if (!runDbTests) return;
        await pool.query(
            `INSERT INTO licenses (license_key, email, transaction_id, product_id, price_id, license_type, status, device_limit, purchased_at)
             VALUES ($1, $2, $3, 'prod_test', 'manual', 'lifetime', 'active', 2, NOW())`,
            [key, 'itest@example.com', txn]
        );
    });

    afterAll(async () => {
        if (!runDbTests) return;
        await pool.query('DELETE FROM licenses WHERE transaction_id = $1', [txn]);
        await pool.query('DELETE FROM validation_logs WHERE license_key = $1', [key]);
    });

    itDb('unknown key -> 404 INVALID_LICENSE', async () => {
        const res = await request(app)
            .post('/api/licenses/activate')
            .send({ license_key: 'CLIPSO-0000-0000-0000-0000', device_id: 'd1' })
            .expect(404);
        expect(res.body).toHaveProperty('error', 'INVALID_LICENSE');
    });

    itDb('activate -> validate -> deactivate happy path', async () => {
        const device_id = 'device-A';

        const act = await request(app)
            .post('/api/licenses/activate')
            .send({ license_key: key, device_id, device_name: 'Test Mac', os_version: 'macOS 26', app_version: '1.0.4' })
            .expect(200);
        expect(act.body).toMatchObject({ success: true, license_type: 'lifetime' });

        // Re-activating the same device is idempotent.
        await request(app).post('/api/licenses/activate').send({ license_key: key, device_id }).expect(200);

        const val = await request(app)
            .post('/api/licenses/validate')
            .send({ license_key: key, device_id })
            .expect(200);
        expect(val.body).toMatchObject({ valid: true, license_type: 'lifetime' });

        await request(app)
            .post('/api/licenses/deactivate')
            .send({ license_key: key, device_id })
            .expect(200);

        const val2 = await request(app)
            .post('/api/licenses/validate')
            .send({ license_key: key, device_id })
            .expect(200);
        expect(val2.body).toMatchObject({ valid: false });
    });

    itDb('enforces the device limit', async () => {
        await request(app).post('/api/licenses/activate').send({ license_key: key, device_id: 'lim-1' }).expect(200);
        await request(app).post('/api/licenses/activate').send({ license_key: key, device_id: 'lim-2' }).expect(200);

        const over = await request(app)
            .post('/api/licenses/activate')
            .send({ license_key: key, device_id: 'lim-3' })
            .expect(403);
        expect(over.body).toHaveProperty('error', 'DEVICE_LIMIT_EXCEEDED');
    });

    itDb('admin can read license info with the right token', async () => {
        const res = await request(app)
            .get(`/api/licenses/${key}`)
            .set('Authorization', `Bearer ${process.env.ADMIN_TOKEN}`)
            .expect(200);
        expect(res.body.license).toMatchObject({ license_key: key, email: 'itest@example.com' });
    });
});
