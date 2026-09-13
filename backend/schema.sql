-- Clipso License Database Schema
-- PostgreSQL schema for license validation and device tracking.
--
-- Safe to run repeatedly: every object uses IF NOT EXISTS / OR REPLACE.
-- Applied automatically by `npm run migrate` (see db/migrate.js).

-- ---------------------------------------------------------------------------
-- Licenses
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS licenses (
    id SERIAL PRIMARY KEY,
    license_key VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    product_id VARCHAR(255) NOT NULL,
    price_id VARCHAR(255) NOT NULL,
    license_type VARCHAR(50) NOT NULL,                 -- 'lifetime', 'annual', 'monthly'
    status VARCHAR(50) NOT NULL DEFAULT 'active',      -- 'active', 'cancelled', 'expired', 'refunded', 'past_due'
    device_limit INTEGER NOT NULL DEFAULT 3,
    purchased_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,                            -- NULL for lifetime licenses
    last_validated TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Paddle transaction data
    paddle_customer_id VARCHAR(255),
    paddle_subscription_id VARCHAR(255),              -- NULL for one-time purchases

    -- Metadata
    custom_data JSONB
);

CREATE INDEX IF NOT EXISTS idx_licenses_license_key    ON licenses (license_key);
CREATE INDEX IF NOT EXISTS idx_licenses_email          ON licenses (email);
CREATE INDEX IF NOT EXISTS idx_licenses_transaction_id ON licenses (transaction_id);
CREATE INDEX IF NOT EXISTS idx_licenses_status         ON licenses (status);
CREATE INDEX IF NOT EXISTS idx_licenses_paddle_sub     ON licenses (paddle_subscription_id);

-- ---------------------------------------------------------------------------
-- Activated devices
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_name VARCHAR(255),
    device_model VARCHAR(255),
    os_version VARCHAR(255),
    app_version VARCHAR(255),
    activated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deactivated_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    ip_address VARCHAR(45),

    UNIQUE (license_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_devices_license_id ON devices (license_id);
CREATE INDEX IF NOT EXISTS idx_devices_device_id  ON devices (device_id);
CREATE INDEX IF NOT EXISTS idx_devices_is_active  ON devices (is_active);

-- ---------------------------------------------------------------------------
-- Paddle webhook event log (idempotency + audit)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhook_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(255),
    customer_id VARCHAR(255),
    subscription_id VARCHAR(255),
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_event_id       ON webhook_events (event_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_type     ON webhook_events (event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_events_transaction_id ON webhook_events (transaction_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed      ON webhook_events (processed);

-- ---------------------------------------------------------------------------
-- Validation request log (analytics / abuse detection)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS validation_logs (
    id SERIAL PRIMARY KEY,
    license_key VARCHAR(255) NOT NULL,
    device_id VARCHAR(255),
    validation_result VARCHAR(50) NOT NULL,           -- 'success', 'invalid_key', 'expired', 'device_limit_exceeded', ...
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_validation_logs_license_key ON validation_logs (license_key);
CREATE INDEX IF NOT EXISTS idx_validation_logs_created_at  ON validation_logs (created_at);

-- ---------------------------------------------------------------------------
-- updated_at trigger for licenses
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_licenses_updated_at ON licenses;
CREATE TRIGGER update_licenses_updated_at
    BEFORE UPDATE ON licenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- Reporting views
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW active_licenses_summary AS
SELECT
    l.id,
    l.license_key,
    l.email,
    l.license_type,
    l.status,
    l.device_limit,
    COUNT(d.id) FILTER (WHERE d.is_active = TRUE) AS active_devices,
    l.purchased_at,
    l.expires_at,
    l.last_validated
FROM licenses l
LEFT JOIN devices d ON l.id = d.license_id
WHERE l.status = 'active'
GROUP BY l.id;

CREATE OR REPLACE VIEW devices_summary AS
SELECT
    d.id,
    d.device_id,
    d.device_name,
    l.license_key,
    l.email,
    l.license_type,
    d.activated_at,
    d.last_seen,
    d.is_active
FROM devices d
JOIN licenses l ON d.license_id = l.id
WHERE d.is_active = TRUE;
