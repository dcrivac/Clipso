# Clipso Release Process

This guide explains how to create a new release of Clipso using the automated release script.

## Quick Start

```bash
# Interactive mode (recommended for first-time users)
./release.sh

# Specify version directly
./release.sh --version 1.0.4

# Auto-confirm prompts
./release.sh --version 1.0.4 --yes
```

## What the Script Does

The `release.sh` script automates the entire release process:

1. ✅ **Validates** git repository status
2. 🔢 **Determines** version number (interactive or specified)
3. 📝 **Creates** release notes template
4. 🌐 **Updates** website download links
5. 💾 **Commits** changes to git
6. 🏷️ **Creates** git tag
7. 🚀 **Pushes** to GitHub (triggers automated build)

## Prerequisites

Before running a release:

- [ ] All code changes are committed
- [ ] Tests are passing
- [ ] Git working directory is clean
- [ ] You're on the `main` branch
- [ ] You have push access to the repository

## Usage Examples

### Interactive Mode

The easiest way to create a release:

```bash
./release.sh
```

You'll be prompted to:
1. Choose version bump type (major/minor/patch) or custom
2. Review changes
3. Edit release notes (optional)
4. Confirm release

### Direct Version

Specify the exact version:

```bash
./release.sh --version 1.0.4
```

### Auto-Confirm Mode

Skip all confirmation prompts (use in CI/CD):

```bash
./release.sh --version 1.0.4 --yes
```

## Version Bumping

The script supports semantic versioning:

- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, backwards compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes, backwards compatible

## What Happens After Running the Script

### 1. GitHub Actions Workflow Triggers

Once you push the tag, GitHub Actions automatically:

- ✅ Builds the Xcode project
- ✅ Creates DMG and ZIP files
- ✅ Generates SHA256 checksums
- ✅ Creates GitHub release
- ✅ Uploads release artifacts
- ✅ (Optional) Code signs and notarizes if secrets are configured

**Monitor progress:**
```
https://github.com/dcrivac/Clipso/actions
```

Build typically takes 5-10 minutes.

### 2. GitHub Release is Created

Once the workflow completes, a new release appears at:
```
https://github.com/dcrivac/Clipso/releases
```

The release includes:
- `Clipso-X.X.X.dmg` - Disk image installer
- `Clipso-X.X.X.zip` - Zipped app bundle
- `*.sha256` - Checksum files for verification
- Auto-generated release notes

### 3. Website Updates Automatically

GitHub Pages will automatically deploy the updated website with new download links within 1-2 minutes.

**Verify at:** `https://clipso.app` or your GitHub Pages URL

## Release Notes

The script creates a template at `RELEASE_vX.X.X.md`. Edit this file to document:

- **What's New**: New features
- **Improvements**: Enhancements to existing features
- **Bug Fixes**: Resolved issues
- **Breaking Changes**: Changes that require user action

Example:

```markdown
# Clipso v1.0.4

## What's New

- Added keyboard shortcut customization
- Improved semantic search accuracy by 15%

## Improvements

- Faster clipboard monitoring (50ms → 30ms)
- Reduced memory usage by 20%

## Bug Fixes

- Fixed crash when copying large images (#42)
- Resolved OCR failure on retina displays (#38)

## Breaking Changes

- None
```

## Manual Steps After Release

### 1. Verify the Release

```bash
# Check GitHub release page
open https://github.com/dcrivac/Clipso/releases

# Test download link
curl -I https://github.com/dcrivac/Clipso/releases/download/v1.0.4/Clipso-1.0.4.dmg

# Verify checksum
curl -sL https://github.com/dcrivac/Clipso/releases/download/v1.0.4/Clipso-1.0.4.dmg.sha256
```

### 2. Test the DMG

Download and test the release:

```bash
# Download
wget https://github.com/dcrivac/Clipso/releases/download/v1.0.4/Clipso-1.0.4.dmg

# Verify checksum
shasum -a 256 Clipso-1.0.4.dmg

# Mount and test
open Clipso-1.0.4.dmg
# Drag to Applications and launch
```

### 3. Announce the Release

- [ ] Update README.md badges if needed
- [ ] Post on social media (Twitter, Reddit, etc.)
- [ ] Notify users via email newsletter (if applicable)
- [ ] Update documentation if APIs changed

### 4. Monitor for Issues

Watch for:
- GitHub Issues from users
- Download statistics
- Crash reports (if analytics enabled)

## Troubleshooting

### "Git working directory is not clean"

Commit or stash your changes:

```bash
git status
git add .
git commit -m "Your changes"
```

Or skip the check (not recommended):

```bash
./release.sh --skip-checks
```

### "No download links were updated"

The script couldn't find links to update. Check:

- Does `website/index.html` exist?
- Does it contain download links with the current version?

Manual fix:

```bash
# Check current links
grep "releases/download" website/index.html

# Update manually if needed
sed -i '' 's|v1.0.2|v1.0.4|g' website/index.html
```

### GitHub Actions Workflow Fails

Common causes:

1. **Build error**: Check Xcode project builds locally
   ```bash
   xcodebuild -project Clipso.xcodeproj -scheme Clipso -configuration Release
   ```

2. **Signing error**: Ensure signing secrets are configured (or will create unsigned build)

3. **Workflow syntax**: Validate `.github/workflows/release.yml`

View logs:
```
https://github.com/dcrivac/Clipso/actions
```

### Website Not Updating

GitHub Pages deployment is delayed:

1. Check Pages status: `Settings → Pages`
2. Wait 2-5 minutes for deployment
3. Force refresh browser: `Cmd+Shift+R`
4. Check deployment: `https://github.com/dcrivac/Clipso/deployments`

## Advanced: Hotfix Releases

For urgent bug fixes:

```bash
# Create hotfix branch
git checkout -b hotfix/1.0.5

# Make fixes
git add .
git commit -m "Fix critical bug"

# Merge to main
git checkout main
git merge hotfix/1.0.5

# Run release
./release.sh --version 1.0.5 --yes

# Delete hotfix branch
git branch -d hotfix/1.0.5
```

## Advanced: Pre-releases

For beta/alpha versions:

```bash
# Create pre-release tag manually
git tag -a v1.1.0-beta.1 -m "Beta release"
git push origin v1.1.0-beta.1

# Mark as pre-release on GitHub
# (Edit the release and check "This is a pre-release")
```

## Script Options

```
Usage: ./release.sh [OPTIONS]

Options:
    -v, --version VERSION    Specify version number (e.g., 1.0.4)
    -y, --yes               Auto-confirm all prompts
    --skip-checks           Skip git status checks (not recommended)
    -h, --help              Show this help message
```

## Files Modified by Script

- `website/index.html` - Download links updated
- `RELEASE_vX.X.X.md` - Release notes created
- Git commits and tags created

## Rollback a Release

If something goes wrong:

```bash
# Delete local tag
git tag -d v1.0.4

# Delete remote tag
git push origin :refs/tags/v1.0.4

# Delete GitHub release
# Go to: https://github.com/dcrivac/Clipso/releases
# Click "Delete" on the release

# Revert website changes
git revert HEAD
git push origin main
```

## Code Signing (Optional)

For signed and notarized releases, configure these GitHub Secrets:

- `APPLE_CERTIFICATE_BASE64` - Your Developer ID certificate
- `APPLE_CERTIFICATE_PASSWORD` - Certificate password
- `APPLE_SIGNING_IDENTITY` - Signing identity name
- `APPLE_TEAM_ID` - Your Apple Team ID
- `APPLE_ID_EMAIL` - Apple ID email
- `APPLE_ID_PASSWORD` - App-specific password

See [CODE_SIGNING_GUIDE.md](CODE_SIGNING_GUIDE.md) for details.

## Getting Help

- Script help: `./release.sh --help`
- GitHub Actions logs: `https://github.com/dcrivac/Clipso/actions`
- Open an issue: `https://github.com/dcrivac/Clipso/issues`

## Checklist: Release Day

Use this checklist for each release:

- [ ] All changes committed and pushed
- [ ] Tests passing locally
- [ ] Version number decided
- [ ] Run `./release.sh`
- [ ] Edit release notes
- [ ] Wait for GitHub Actions to complete
- [ ] Verify release on GitHub
- [ ] Test DMG download and installation
- [ ] Verify website updates
- [ ] Announce release
- [ ] Monitor for issues

---

**Remember:** Releases are permanent once published. Always verify before running the script, and test the release artifacts before announcing publicly.
