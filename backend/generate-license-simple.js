#!/usr/bin/env node
/**
 * Simple License Generator (No Database Required)
 *
 * Generates a license key and SQL statement without requiring database connection.
 * Usage: node generate-license-simple.js <email>
 */

const crypto = require('crypto');

function generateLicenseKey(seed) {
    const hash = crypto.createHash('sha256').update(seed).digest('hex');
    const parts = hash.substring(0, 16).match(/.{1,4}/g);
    return `CLIPSO-${parts.join('-').toUpperCase()}`;
}

function generateTransactionId() {
    const timestamp = Date.now();
    const random = crypto.randomBytes(8).toString('hex');
    return `manual_${timestamp}_${random}`;
}

function main() {
    const args = process.argv.slice(2);
    const email = args[0];

    if (!email) {
        console.error('\n❌ Usage: node generate-license-simple.js <email>\n');
        process.exit(1);
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        console.error('\n❌ Invalid email address provided.\n');
        process.exit(1);
    }

    // Generate unique identifiers
    const transactionId = generateTransactionId();
    const licenseKey = generateLicenseKey(transactionId);
    const now = new Date().toISOString();

    console.log('\n🎫 Clipso Lifetime License Generated\n');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📧 Email:        ${email}`);
    console.log(`🔑 License Key:  ${licenseKey}`);
    console.log(`🎫 Type:         lifetime`);
    console.log(`✓  Status:       active`);
    console.log(`📱 Device Limit: 3 devices`);
    console.log(`📅 Created:      ${now}`);
    console.log(`⏰ Expires:      Never (Lifetime)`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('📋 Send this information to your friend:\n');
    console.log('   Subject: Your Clipso Lifetime License');
    console.log('   ─────────────────────────────────────────────────');
    console.log(`   Email: ${email}`);
    console.log(`   License Key: ${licenseKey}`);
    console.log('   ─────────────────────────────────────────────────');
    console.log('   To activate:');
    console.log('   1. Open Clipso app');
    console.log('   2. Go to Settings → License');
    console.log('   3. Enter the email and license key above');
    console.log('   4. Click "Activate License"\n');

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('💾 Database SQL (Run this in your PostgreSQL database):\n');
    console.log('```sql');
    console.log(`INSERT INTO licenses (`);
    console.log(`    license_key,`);
    console.log(`    email,`);
    console.log(`    transaction_id,`);
    console.log(`    product_id,`);
    console.log(`    price_id,`);
    console.log(`    license_type,`);
    console.log(`    status,`);
    console.log(`    device_limit,`);
    console.log(`    purchased_at,`);
    console.log(`    expires_at,`);
    console.log(`    custom_data`);
    console.log(`) VALUES (`);
    console.log(`    '${licenseKey}',`);
    console.log(`    '${email}',`);
    console.log(`    '${transactionId}',`);
    console.log(`    'prod_clipso_lifetime',`);
    console.log(`    'manual',`);
    console.log(`    'lifetime',`);
    console.log(`    'active',`);
    console.log(`    3,`);
    console.log(`    '${now}',`);
    console.log(`    NULL,`);
    console.log(`    '{"source": "manual", "generated_by": "admin"}'::jsonb`);
    console.log(`);`);
    console.log('```\n');

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log('✅ Done! Copy the SQL above and run it in your database.\n');
}

if (require.main === module) {
    main();
}

module.exports = { generateLicenseKey, generateTransactionId };
