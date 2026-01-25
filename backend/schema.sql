-- Clipso License Database Schema
-- PostgreSQL Database for license validation and device tracking

-- Licenses table
CREATE TABLE licenses (
    id SERIAL PRIMARY KEY,
    license_key VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    product_id VARCHAR(255) NOT NULL,
    price_id VARCHAR(255) NOT NULL,
    license_type VARCHAR(50) NOT NULL, -- 'lifetime', 'annual', 'monthly'
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'cancelled', 'expired', 'refunded'
    device_limit INTEGER NOT NULL DEFAULT 3,
    purchased_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP, -- NULL for lifetime licenses
    last_validated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Paddle transaction data
    paddle_customer_id VARCHAR(255),
    paddle_subscription_id VARCHAR(255), -- NULL for one-time purchases

    -- Metadata
    custom_data JSONB,

    INDEX idx_license_key (license_key),
    INDEX idx_email (email),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_status (status)
);

-- Activated devices table
CREATE TABLE devices (
    id SERIAL PRIMARY KEY,
    license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_name VARCHAR(255),
    device_model VARCHAR(255),
    os_version VARCHAR(255),
    app_version VARCHAR(255),
    activated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deactivated_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,

    -- IP tracking (optional)
    ip_address VARCHAR(45),

    UNIQUE(license_id, device_id),
    INDEX idx_license_id (license_id),
    INDEX idx_device_id (device_id),
    INDEX idx_is_active (is_active)
);

-- Webhook events log
CREATE TABLE webhook_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(255),
    customer_id VARCHAR(255),
    subscription_id VARCHAR(255),
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMP,
    error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_event_id (event_id),
    INDEX idx_event_type (event_type),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_processed (processed)
);

-- Validation requests log (for analytics)
CREATE TABLE validation_logs (
    id SERIAL PRIMARY KEY,
    license_key VARCHAR(255) NOT NULL,
    device_id VARCHAR(255),
    validation_result VARCHAR(50) NOT NULL, -- 'success', 'invalid_key', 'expired', 'device_limit_exceeded'
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_license_key (license_key),
    INDEX idx_created_at (created_at)
);

-- Helper functions

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for licenses table
CREATE TRIGGER update_licenses_updated_at
    BEFORE UPDATE ON licenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Views

-- Active licenses with device count
CREATE VIEW active_licenses_summary AS
SELECT
    l.id,
    l.license_key,
    l.email,
    l.license_type,
    l.status,
    l.device_limit,
    COUNT(d.id) FILTER (WHERE d.is_active = TRUE) as active_devices,
    l.purchased_at,
    l.expires_at,
    l.last_validated
FROM licenses l
LEFT JOIN devices d ON l.id = d.license_id
WHERE l.status = 'active'
GROUP BY l.id;

-- Devices summary
CREATE VIEW devices_summary AS
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

-- Sample queries for testing

-- Find license by key
-- SELECT * FROM licenses WHERE license_key = 'XXX';

-- Get all active devices for a license
-- SELECT * FROM devices WHERE license_id = 1 AND is_active = TRUE;

-- Check if device can activate
-- SELECT
--     l.device_limit,
--     COUNT(d.id) FILTER (WHERE d.is_active = TRUE) as active_devices
-- FROM licenses l
-- LEFT JOIN devices d ON l.id = d.license_id
-- WHERE l.license_key = 'XXX'
-- GROUP BY l.id;

-- Get recent validation logs
-- SELECT * FROM validation_logs ORDER BY created_at DESC LIMIT 100;
