/**
 * Shared PostgreSQL connection pool.
 *
 * Connection resolution order:
 *   1. DATABASE_URL  (Fly Postgres, Neon, Supabase, Heroku, ...)
 *   2. Discrete DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD  (local dev)
 *
 * TLS:
 *   - Enabled automatically when DATABASE_URL contains sslmode=require, or
 *     when PGSSL / DATABASE_SSL is truthy, or in production.
 *   - `DATABASE_SSL=disable` forces it off (Fly's internal *.flycast /
 *     .internal addresses speak plaintext on the private network).
 */

const { Pool } = require('pg');

function truthy(v) {
    return v !== undefined && ['1', 'true', 'yes', 'on', 'require'].includes(String(v).toLowerCase());
}

function buildConfig() {
    const url = process.env.DATABASE_URL;

    // Explicit opt-out (Fly private networking, local docker, ...)
    const sslDisabled = ['disable', 'false', '0', 'off', 'no'].includes(
        String(process.env.DATABASE_SSL || '').toLowerCase()
    );

    let ssl = false;
    if (!sslDisabled) {
        const wantsSsl =
            truthy(process.env.DATABASE_SSL) ||
            truthy(process.env.PGSSL) ||
            (url && /sslmode=require/i.test(url)) ||
            process.env.NODE_ENV === 'production';
        // Managed Postgres providers terminate TLS with certs that don't chain
        // to a public root the container trusts; verify-full would break them.
        if (wantsSsl) ssl = { rejectUnauthorized: false };
    }

    const common = {
        max: parseInt(process.env.DB_POOL_MAX || '10', 10),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
        ssl,
    };

    if (url) {
        return { connectionString: url, ...common };
    }

    return {
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432', 10),
        database: process.env.DB_NAME || 'clipso_licenses',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD,
        ...common,
    };
}

const pool = new Pool(buildConfig());

pool.on('error', (err) => {
    // Don't crash on transient idle-client errors; the pool recovers.
    console.error('Postgres pool error:', err.message);
});

module.exports = pool;
