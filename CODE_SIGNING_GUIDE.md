# Code Signing & Notarization Guide

This guide explains how to set up proper code signing and notarization for Clipso so users don't get the "damaged app" error.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Obtaining Certificates](#obtaining-certificates)
3. [Setting Up GitHub Secrets](#setting-up-github-secrets)
4. [Local Development Signing](#local-development-signing)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

To sign and notarize Clipso, you need:

- **Apple Developer Account** ($99/year)
  - Free accounts cannot create Distribution certificates needed for signing
  - Sign up at: https://developer.apple.com/programs/

- **Xcode** (latest stable version)
  - Download from App Store or developer.apple.com

## Obtaining Certificates

### Step 1: Create Developer ID Application Certificate

1. Go to https://developer.apple.com/account/resources/certificates
2. Click the **+** button to create a new certificate
3. Select **Developer ID Application**
4. Follow the instructions to create a Certificate Signing Request (CSR) using Keychain Access
5. Upload the CSR and download the certificate
6. Double-click the downloaded `.cer` file to install it in your Keychain

### Step 2: Export Certificate for CI/CD

You need to export your certificate and private key to use in GitHub Actions:

1. Open **Keychain Access**
2. Find your "Developer ID Application" certificate
3. Expand it to show the private key
4. Select **both** the certificate and private key
5. Right-click → **Export 2 items...**
6. Choose `.p12` format
7. Set a strong password (you'll need this later)
8. Save as `Certificates.p12`

### Step 3: Base64 Encode Certificate

GitHub Actions needs the certificate as a base64-encoded string:

```bash
# Encode the certificate
base64 -i Certificates.p12 | pbcopy

# This copies the encoded string to your clipboard
```

### Step 4: Get Your Team ID

```bash
# Method 1: From certificate
security find-identity -v -p codesigning

# Look for your Developer ID Application certificate
# The Team ID is the 10-character string in parentheses

# Method 2: From Apple Developer portal
# Visit https://developer.apple.com/account
# Your Team ID is shown in the top right
```

### Step 5: Create App-Specific Password for Notarization

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. In the **Security** section, click **Generate Password** under App-Specific Passwords
4. Label it "Clipso Notarization"
5. Save the generated password (you'll need this for GitHub Secrets)

## Setting Up GitHub Secrets

Add these secrets to your GitHub repository:

1. Go to your repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add each of these:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `APPLE_CERTIFICATE_BASE64` | The base64 string from Step 3 | Your exported `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password you set when exporting | Password for the `.p12` file |
| `APPLE_TEAM_ID` | Your 10-character Team ID | Found in Step 4 |
| `APPLE_ID_EMAIL` | Your Apple ID email | The email for your Apple Developer account |
| `APPLE_ID_PASSWORD` | App-specific password from Step 5 | For notarization |
| `APPLE_SIGNING_IDENTITY` | Usually `"Developer ID Application"` | The certificate name (optional, has default) |

### Finding Your Code Signing Identity

To find the exact identity name for `APPLE_SIGNING_IDENTITY`:

```bash
security find-identity -v -p codesigning
```

Look for something like:
```
1) ABC123... "Developer ID Application: Your Name (TEAMID123)"
```

The part in quotes is your identity. You can use just `"Developer ID Application"` or the full string.

## How It Works

Once you've set up the secrets, the release workflow will automatically:

1. **Detect** if signing secrets are available
2. **Import** your certificate into the GitHub Actions runner
3. **Sign** the app with your Developer ID
4. **Create** a DMG and ZIP
5. **Notarize** with Apple (sends to Apple for scanning)
6. **Staple** the notarization ticket (embeds approval in the app)
7. **Release** the signed, notarized DMG and ZIP

Users will be able to double-click and open the app without any warnings!

## Local Development Signing

For local development, you can sign manually:

### Option 1: Sign Manually

```bash
# Build the app
xcodebuild -project Clipso.xcodeproj \
  -scheme Clipso \
  -configuration Release \
  -derivedDataPath ./DerivedData

# Find the built app
APP_PATH=$(find ./DerivedData -name "Clipso.app" | head -n 1)

# Sign it
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application" \
  "$APP_PATH"

# Verify signature
codesign --verify --verbose "$APP_PATH"
spctl -a -vv "$APP_PATH"
```

### Option 2: Create Signed DMG Locally

```bash
# After building and signing the app:

# Create DMG
mkdir dmg-staging
cp -R build/Clipso.app dmg-staging/
ln -s /Applications dmg-staging/Applications

hdiutil create -volname "Clipso" \
  -srcfolder dmg-staging \
  -ov -format UDZO \
  Clipso-signed.dmg

# Sign the DMG
codesign --sign "Developer ID Application" Clipso-signed.dmg

# Notarize (requires Apple ID)
xcrun notarytool submit Clipso-signed.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAMID123" \
  --password "app-specific-password" \
  --wait

# Staple the ticket
xcrun stapler staple Clipso-signed.dmg

# Verify
spctl -a -vv Clipso-signed.dmg
```

## Unsigned Builds (Current Behavior)

If no signing secrets are present, the workflow will:
- Build **without** code signing (current behavior)
- Add warning to release notes about Gatekeeper
- Link to `INSTALLATION_TROUBLESHOOTING.md` for user workarounds

## Troubleshooting

### "No identity found" Error

**Problem**: Certificate not properly imported

**Solution**:
```bash
# Verify certificate is in Keychain
security find-identity -v -p codesigning

# If not there, reimport:
security import Certificates.p12 -P "your-password"
```

### "Code signing failed" Error

**Problem**: Wrong identity name

**Solution**: Use the exact identity from:
```bash
security find-identity -v -p codesigning
```

### Notarization Fails

**Problem**: App-specific password incorrect or expired

**Solution**:
1. Generate a new app-specific password at appleid.apple.com
2. Update `APPLE_ID_PASSWORD` secret in GitHub

### "Invalid Developer" Error

**Problem**: Certificate expired or revoked

**Solution**:
1. Check certificate expiration in Keychain Access
2. Renew certificate at developer.apple.com
3. Re-export and update `APPLE_CERTIFICATE_BASE64`

### Notarization Takes Forever

**Problem**: Apple's servers are slow (normal)

**Solution**: Notarization usually takes 2-10 minutes. The workflow waits automatically.

### Users Still Get "Damaged" Error

**Problem**: DMG not properly stapled

**Solution**: Ensure the stapling step completed successfully in the workflow logs.

## Verification

After a signed release:

1. **Download the DMG** from GitHub releases
2. **Verify it opens** without warnings
3. **Check signature**:
   ```bash
   codesign --verify --verbose Clipso.app
   spctl -a -vv Clipso.app
   ```
4. **Check notarization**:
   ```bash
   xcrun stapler validate Clipso.app
   ```

All should show "accepted" or "approved" status.

## Cost Summary

- **Apple Developer Account**: $99/year (required)
- **Notarization**: Free (included with Developer Account)
- **GitHub Actions**: Free for public repositories
- **Total**: $99/year

## Resources

- [Apple Code Signing Guide](https://developer.apple.com/documentation/xcode/notarizing-macos-software-before-distribution)
- [Notarization Workflow](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
- [GitHub Actions - Xcode](https://docs.github.com/en/actions/use-cases-and-examples/building-and-testing/building-and-testing-swift)

## Next Steps

1. ✅ Sign up for Apple Developer Program
2. ✅ Create Developer ID Application certificate
3. ✅ Export certificate and encode as base64
4. ✅ Get Team ID and create app-specific password
5. ✅ Add all secrets to GitHub repository
6. ✅ Push a new tag to trigger a signed release
7. ✅ Verify the release works without warnings

---

**Questions?** Open an issue at https://github.com/dcrivac/Clipso/issues
