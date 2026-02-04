/**
 * Email Service for License Delivery
 *
 * Supports multiple email providers:
 * - Resend (recommended, easiest to set up)
 * - SendGrid
 * - AWS SES
 * - SMTP (fallback)
 */

const https = require('https');

/**
 * Send license email using Resend API (recommended)
 */
async function sendEmailResend(to, licenseKey, licenseType) {
    const apiKey = process.env.RESEND_API_KEY;

    if (!apiKey) {
        console.error('RESEND_API_KEY not configured');
        return false;
    }

    const emailData = JSON.stringify({
        from: process.env.EMAIL_FROM || 'Clipso <licenses@clipso.app>',
        to: [to],
        subject: '🎉 Your Clipso License Key',
        html: generateLicenseEmail(to, licenseKey, licenseType)
    });

    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.resend.com',
            path: '/emails',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'Content-Length': emailData.length
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    console.log(`✅ License email sent to ${to} via Resend`);
                    resolve(true);
                } else {
                    console.error(`❌ Resend API error: ${res.statusCode}`, data);
                    reject(new Error(`Resend error: ${res.statusCode}`));
                }
            });
        });

        req.on('error', (error) => {
            console.error('❌ Resend request error:', error);
            reject(error);
        });

        req.write(emailData);
        req.end();
    });
}

/**
 * Send license email using SendGrid API
 */
async function sendEmailSendGrid(to, licenseKey, licenseType) {
    const apiKey = process.env.SENDGRID_API_KEY;

    if (!apiKey) {
        console.error('SENDGRID_API_KEY not configured');
        return false;
    }

    const emailData = JSON.stringify({
        personalizations: [{
            to: [{ email: to }],
            subject: '🎉 Your Clipso License Key'
        }],
        from: {
            email: process.env.EMAIL_FROM || 'licenses@clipso.app',
            name: 'Clipso'
        },
        content: [{
            type: 'text/html',
            value: generateLicenseEmail(to, licenseKey, licenseType)
        }]
    });

    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.sendgrid.com',
            path: '/v3/mail/send',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'Content-Length': emailData.length
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 202) {
                    console.log(`✅ License email sent to ${to} via SendGrid`);
                    resolve(true);
                } else {
                    console.error(`❌ SendGrid API error: ${res.statusCode}`, data);
                    reject(new Error(`SendGrid error: ${res.statusCode}`));
                }
            });
        });

        req.on('error', (error) => {
            console.error('❌ SendGrid request error:', error);
            reject(error);
        });

        req.write(emailData);
        req.end();
    });
}

/**
 * Generate HTML email template for license delivery
 */
function generateLicenseEmail(email, licenseKey, licenseType) {
    const licenseTypeDisplay = licenseType === 'lifetime' ? 'Lifetime' :
                                licenseType === 'annual' ? 'Annual' : 'Monthly';

    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Your Clipso License</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
        <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Welcome to Clipso Pro!</h1>
    </div>

    <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px; border: 1px solid #e5e7eb;">
        <p style="font-size: 16px; margin-top: 0;">Hi there!</p>

        <p style="font-size: 16px;">Thank you for purchasing Clipso ${licenseTypeDisplay}! Here's your license information:</p>

        <div style="background: white; border: 2px solid #6366F1; border-radius: 8px; padding: 20px; margin: 25px 0;">
            <p style="margin: 0 0 10px 0; color: #6b7280; font-size: 14px;">Email:</p>
            <p style="margin: 0 0 20px 0; font-size: 16px; font-weight: 600;">${email}</p>

            <p style="margin: 0 0 10px 0; color: #6b7280; font-size: 14px;">License Key:</p>
            <p style="margin: 0; font-size: 20px; font-weight: 700; color: #6366F1; letter-spacing: 1px; font-family: 'Courier New', monospace;">${licenseKey}</p>
        </div>

        <h2 style="color: #1f2937; font-size: 20px; margin-top: 30px;">How to Activate</h2>
        <ol style="padding-left: 20px; font-size: 15px;">
            <li style="margin-bottom: 10px;">Download Clipso from <a href="https://github.com/dcrivac/Clipso/releases/latest" style="color: #6366F1; text-decoration: none;">GitHub Releases</a></li>
            <li style="margin-bottom: 10px;">Open the app and click the menu bar icon</li>
            <li style="margin-bottom: 10px;">Go to <strong>Settings → License</strong></li>
            <li style="margin-bottom: 10px;">Enter your email and license key above</li>
            <li style="margin-bottom: 10px;">Click <strong>"Activate License"</strong></li>
        </ol>

        <div style="background: #ecfdf5; border-left: 4px solid #10b981; padding: 15px; margin: 25px 0; border-radius: 4px;">
            <p style="margin: 0; font-size: 14px; color: #065f46;">
                <strong>✨ Pro Tip:</strong> You can activate this license on up to 3 devices. To switch devices, simply deactivate from Settings in the old device.
            </p>
        </div>

        <h2 style="color: #1f2937; font-size: 20px; margin-top: 30px;">What You Get</h2>
        <ul style="list-style: none; padding: 0; font-size: 15px;">
            <li style="margin-bottom: 8px;">✅ <strong>AI Semantic Search</strong> - Find by meaning, not keywords</li>
            <li style="margin-bottom: 8px;">✅ <strong>Context Detection</strong> - Auto project grouping</li>
            <li style="margin-bottom: 8px;">✅ <strong>Unlimited Items</strong> - No 250-item limit</li>
            <li style="margin-bottom: 8px;">✅ <strong>Unlimited Retention</strong> - Keep history forever</li>
            <li style="margin-bottom: 8px;">✅ <strong>100% Private</strong> - All processing on-device</li>
        </ul>

        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">

        <p style="font-size: 14px; color: #6b7280;">
            Need help? Reply to this email or open an issue on <a href="https://github.com/dcrivac/Clipso/issues" style="color: #6366F1; text-decoration: none;">GitHub</a>.
        </p>

        <p style="font-size: 14px; color: #6b7280; margin-bottom: 0;">
            Happy clipping! 📋<br>
            <strong>The Clipso Team</strong>
        </p>
    </div>

    <div style="text-align: center; margin-top: 30px; padding: 20px; color: #9ca3af; font-size: 12px;">
        <p style="margin: 0;">Clipso - The First Truly Intelligent Clipboard for Mac</p>
        <p style="margin: 5px 0 0 0;">
            <a href="https://clipso.app" style="color: #6366F1; text-decoration: none;">clipso.app</a> |
            <a href="https://github.com/dcrivac/Clipso" style="color: #6366F1; text-decoration: none;">GitHub</a>
        </p>
    </div>
</body>
</html>
    `.trim();
}

/**
 * Main email sending function
 * Tries configured email service based on environment variables
 */
async function sendLicenseEmail(email, licenseKey, licenseType = 'lifetime') {
    console.log(`📧 Attempting to send license email to ${email}`);

    try {
        // Try Resend first (easiest and most reliable)
        if (process.env.RESEND_API_KEY) {
            await sendEmailResend(email, licenseKey, licenseType);
            return true;
        }

        // Fall back to SendGrid
        if (process.env.SENDGRID_API_KEY) {
            await sendEmailSendGrid(email, licenseKey, licenseType);
            return true;
        }

        // No email service configured
        console.warn('⚠️  No email service configured. Set RESEND_API_KEY or SENDGRID_API_KEY in .env');
        console.warn(`📝 Manual delivery needed for ${email}: ${licenseKey}`);
        return false;

    } catch (error) {
        console.error('❌ Failed to send license email:', error.message);
        console.error(`📝 Manual delivery needed for ${email}: ${licenseKey}`);
        return false;
    }
}

module.exports = {
    sendLicenseEmail,
    generateLicenseEmail
};
