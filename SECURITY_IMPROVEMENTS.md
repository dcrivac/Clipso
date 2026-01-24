# Security Improvements - LicenseManager

## Overview

This document outlines the security and code quality improvements made to the LicenseManager system.

## Changes Made

### 1. ✅ Removed Hardcoded Credentials

**Problem**: Paddle credentials were hardcoded directly in `LicenseManager.swift`, making them visible in version control and difficult to change per environment.

**Solution**: Created `PaddleConfig.swift` to:
- Separate configuration from business logic
- Load credentials from `Info.plist` for secure configuration
- Provide environment-specific presets (Sandbox vs Production)
- Make it easy to switch between environments via build configurations

**Files Modified**:
- Created: `Managers/PaddleConfig.swift`
- Modified: `Managers/LicenseManager.swift` (removed hardcoded values)

### 2. ✅ Fixed Force Unwrap in saveToKeychain()

**Problem**: `saveToKeychain()` used force unwrap (`!`) when converting string to data:
```swift
let data = value.data(using: .utf8)!  // ❌ Could crash
```

**Solution**: Added proper error handling:
```swift
guard let data = value.data(using: .utf8) else {
    print("⚠️ Failed to convert string to data for keychain: \(key)")
    return
}
```

**Impact**: Prevents crashes if string encoding fails (extremely rare, but possible with invalid Unicode).

### 3. ✅ Implemented Device Binding with instanceID

**Problem**: `instanceID` variable was created but never used in `validateLicenseWithPaddle()`.

**Solution**: Implemented device binding:
- `instanceID` is now sent in the `X-Device-ID` HTTP header
- Server can track which devices have activated a license
- Enables enforcement of device activation limits (e.g., 3 devices per license)

**How it works**:
1. Each device generates a unique UUID on first launch
2. UUID is stored in UserDefaults for persistence
3. UUID is sent with every license validation request
4. Backend can track and limit activations per license

**Next Steps**:
- Set up backend to track device activations
- Implement device limit enforcement (e.g., max 3 devices)
- Add UI for managing activated devices

### 4. ✅ Added Timeout to URLSession Requests

**Problem**: Network requests had no timeout, potentially hanging indefinitely.

**Solution**: Added comprehensive timeout configuration:
```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30  // 30 second timeout per request
config.timeoutIntervalForResource = 60 // 60 second timeout for entire resource
let session = URLSession(configuration: config)

var request = URLRequest(url: url)
request.timeoutInterval = 30  // Also set on request level
```

**Impact**:
- Requests fail gracefully after 30 seconds instead of hanging
- Better user experience with predictable timeout behavior
- Prevents app from appearing frozen during network issues

---

## Configuration Guide

### Setting Up Paddle Credentials Securely

#### Option 1: Using Info.plist (Recommended)

1. Open `Info.plist` in Xcode
2. Add these keys:

```xml
<key>PADDLE_VENDOR_ID</key>
<string>test_859aa26dd9d5c623ccccf54e0c7</string>

<key>PADDLE_LIFETIME_PRICE_ID</key>
<string>pri_01kfr145r1eh8f7m8w0nfkvz74uf</string>

<key>PADDLE_ANNUAL_PRICE_ID</key>
<string>pri_01kfr12rgvdnhpr52zspmqvnk1</string>

<key>PADDLE_API_KEY</key>
<string>YOUR_API_KEY_HERE</string>

<key>PADDLE_USE_SANDBOX</key>
<true/>
```

3. **For production builds**, create a separate `Info.plist` configuration:
   - Use Xcode build configurations (Debug, Release)
   - In Release configuration, set `PADDLE_USE_SANDBOX` to `false`
   - Use production credentials

#### Option 2: Using Build Configurations

1. In Xcode, go to Project Settings → Build Settings
2. Create user-defined build settings:
   - `PADDLE_VENDOR_ID`
   - `PADDLE_LIFETIME_PRICE_ID`
   - `PADDLE_ANNUAL_PRICE_ID`
   - `PADDLE_API_KEY`
   - `PADDLE_USE_SANDBOX`

3. Reference them in Info.plist:
```xml
<key>PADDLE_VENDOR_ID</key>
<string>$(PADDLE_VENDOR_ID)</string>
```

#### Option 3: Environment Variables (CI/CD)

For automated builds:
1. Set environment variables in your CI/CD system
2. Reference them in build settings
3. Values will be injected at build time

### Switching Between Sandbox and Production

**During Development (Sandbox)**:
```xml
<key>PADDLE_USE_SANDBOX</key>
<true/>
```

**For Production (Live)**:
```xml
<key>PADDLE_USE_SANDBOX</key>
<false/>
```

Or let the app auto-detect:
- Debug builds → Sandbox (automatic)
- Release builds → Production (automatic)

---

## Security Best Practices

### ✅ DO:
- Store API keys in Info.plist, not in source code
- Use different credentials for Sandbox vs Production
- Add `*.plist` with sensitive data to `.gitignore` (if using separate config files)
- Rotate API keys if they're accidentally exposed
- Use build configurations to separate environments
- Validate all user input before sending to APIs

### ❌ DON'T:
- Hardcode credentials in Swift files
- Commit API keys to version control
- Use production credentials in development
- Use force unwraps (`!`) for operations that could fail
- Skip timeout configuration on network requests
- Share API keys between projects

---

## Device Binding Implementation

The `instanceID` is now used for device binding. To fully implement device limits:

### Backend Requirements

Your backend should:
1. Store activated devices per license key
2. Check device count on activation
3. Return error if limit exceeded (e.g., > 3 devices)
4. Provide API to deactivate devices

### Example Backend Logic

```
POST /api/licenses/activate
{
  "license_key": "txn_...",
  "device_id": "UUID",
  "device_name": "MacBook Pro"
}

Response:
{
  "success": true,
  "devices_used": 1,
  "devices_limit": 3
}

OR

{
  "success": false,
  "error": "DEVICE_LIMIT_EXCEEDED",
  "devices_used": 3,
  "devices_limit": 3,
  "message": "Maximum 3 devices allowed. Deactivate a device to continue."
}
```

### UI for Device Management

Add a settings view to show activated devices:
- List all activated devices
- Show activation date
- Allow user to deactivate devices remotely
- Show remaining device slots

---

## Testing

### Test Credentials Handling

```swift
// The old way (❌ Hardcoded)
private let vendorID = "test_859aa26dd9d5c623ccccf54e0c7"

// The new way (✅ Loaded from config)
private let paddleConfig = PaddleConfig.loadConfig()
```

### Test Timeout Behavior

```swift
// Simulate slow network
// Request should timeout after 30 seconds
// User should see error message, not frozen UI
```

### Test Device Binding

```swift
let instanceID = getDeviceInstanceID()
print("Device ID: \(instanceID)")
// Same ID should persist across app launches
```

### Test Keychain Robustness

```swift
// Test with normal strings
saveToKeychain(key: "test", value: "normal value")

// Test with empty strings
saveToKeychain(key: "test", value: "")

// Test with special characters
saveToKeychain(key: "test", value: "emoji 😀 unicode ñ")
```

---

## Migration Guide

If you have existing users with activated licenses, no migration needed:
- Keychain data structure unchanged
- License validation logic unchanged
- Only configuration loading changed

---

## Next Steps

### Immediate
- [ ] Add Paddle API key to Info.plist
- [ ] Test license activation in Sandbox
- [ ] Verify credentials load correctly

### Short-term
- [ ] Set up backend for device tracking
- [ ] Implement device limit enforcement
- [ ] Add device management UI
- [ ] Set up Paddle webhooks for real-time license updates

### Long-term
- [ ] Implement periodic re-validation (every 7 days)
- [ ] Add subscription renewal reminders
- [ ] Implement grace period for expired subscriptions
- [ ] Add offline license validation fallback

---

## Files Changed

### Created
- `Managers/PaddleConfig.swift` - Configuration management

### Modified
- `Managers/LicenseManager.swift`:
  - Line 30-35: Removed hardcoded credentials
  - Line 56-59: Updated init to load config
  - Line 125-142: Updated purchase methods to use config
  - Line 164-240: Updated validation to use config, timeout, and device binding
  - Line 242-262: Updated price ID matching to use config
  - Line 310-324: Fixed force unwrap in saveToKeychain

---

## Support

If you encounter issues after these changes:

1. **Credentials not loading**:
   - Check Info.plist has all required keys
   - Verify key names match exactly
   - Check for typos in credential values

2. **Timeout errors**:
   - Check network connectivity
   - Verify Paddle API is accessible
   - Try increasing timeout values if needed

3. **Device binding issues**:
   - Verify instanceID is being generated
   - Check it persists across launches
   - Ensure it's sent in HTTP header

---

**Summary**: These changes make the app more secure, robust, and production-ready while maintaining backward compatibility with existing licenses.
