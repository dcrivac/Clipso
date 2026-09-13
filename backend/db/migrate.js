#!/usr/bin/env node
/**
 * Apply schema.sql to the configured database.
 *
 * Idempotent: schema.sql uses IF NOT EXISTS / OR REPLACE throughout, so this
 * can run on every deploy. Wired as the Fly `release_command` (see fly.toml)
 * and available as `npm run migrate`.
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('../db');

async function main() {
    const schemaPath = path.join(__dirname, '..', 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');

    console.log(`Applying ${schemaPath} ...`);
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        await client.query(sql);
        await client.query('COMMIT');
        console.log('Migration applied successfully.');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Migration failed:', err.message);
        process.exitCode = 1;
    } finally {
        client.release();
        await pool.end();
    }
}

main();
