# GitHub Actions Release Workflow

This repository is configured to automatically build Clipso.dmg when you create a release tag - **no Mac required!**

## How to Trigger a Build

### Option 1: Create a Tag (Recommended)

From any device (including iPhone), create and push a version tag:

```bash
# Create a new release tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push the tag to GitHub
git push origin v1.0.0
```

This will:
1. Automatically trigger the GitHub Actions workflow
2. Build the app on GitHub's Mac runner
3. Create a .dmg and .zip file
4. Create a GitHub Release with the files attached
5. Generate checksums for verification

### Option 2: Manual Trigger from GitHub Web

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Click **Build and Release Clipso** workflow
4. Click **Run workflow** button (top right)
5. Enter version number (e.g., `1.0.0`)
6. Click **Run workflow**

This will build the app but **NOT** create a GitHub Release (artifacts only).

### Option 3: From iPhone Using Working Copy or GitHub Mobile

**Using Working Copy app:**
1. Open your repository
2. Tap the repository name
3. Tap **Tags**
4. Tap **+** to create new tag
5. Enter `v1.0.0` (or your version)
6. Add message: "Release version 1.0.0"
7. Tap **Create**
8. Tap **Push** to push the tag

**Using GitHub Mobile app:**
1. Open repository
2. Tap **Create release**
3. Enter tag: `v1.0.0`
4. Enter title and description
5. Tap **Publish release**
6. The workflow will trigger automatically

## What Gets Built

When the workflow runs, it creates:

- **Clipso-X.X.X.dmg** - macOS disk image for distribution
- **Clipso-X.X.X.zip** - Zipped app bundle (alternative format)
- **Clipso-X.X.X.dmg.sha256** - Checksum for DMG
- **Clipso-X.X.X.zip.sha256** - Checksum for ZIP

## Workflow Features

✅ **No Mac Required** - Builds on GitHub's macOS runners
✅ **Automatic Versioning** - Extracts version from tag
✅ **Both DMG and ZIP** - Two distribution formats
✅ **Checksums** - SHA-256 verification files
✅ **Auto-Release** - Creates GitHub release with notes
✅ **Manual Trigger** - Run from Actions tab when needed

## Version Numbering

Use semantic versioning: `vMAJOR.MINOR.PATCH`

- **v1.0.0** - First stable release
- **v1.1.0** - New features (backwards compatible)
- **v1.0.1** - Bug fixes
- **v2.0.0** - Breaking changes

## Viewing Build Progress

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Click on the running workflow
4. Watch real-time build logs

Build typically takes **5-10 minutes**.

## Downloading the Release

After the workflow completes:

1. Go to **Releases** page (or click release link in Actions)
2. Download `Clipso-X.X.X.dmg`
3. Optionally verify checksum:
   ```bash
   shasum -a 256 -c Clipso-X.X.X.dmg.sha256
   ```

## Troubleshooting

### Build Failed

Check the Actions logs for errors:
- Red X icon = failed
- Click workflow run to see logs
- Common issues: code signing, missing files, syntax errors

### Tag Already Exists

If you need to rebuild a version:
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Create new tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### No Release Created

If using manual trigger (workflow_dispatch), the release is not created automatically. You can:
- Download artifacts from the Actions run
- Use tag method instead for auto-release

## Code Signing

Currently, the workflow builds **unsigned** apps (no code signing). For production:

1. Add Apple Developer certificates to GitHub Secrets
2. Update workflow with signing configuration
3. Enable notarization for Gatekeeper compatibility

See [Apple's documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution) for details.

## Next Steps

- **First release**: Create tag `v1.0.0` to build your first release
- **Update app**: Make changes, commit, create new version tag
- **Pre-releases**: Use tags like `v1.0.0-beta.1` for testing

## Example: Creating Your First Release

```bash
# On your current branch (or main)
git checkout claude/swift-code-rebrand-OXgkW

# Make sure everything is committed
git status

# Create and push release tag
git tag -a v1.0.0 -m "First official release of Clipso"
git push origin v1.0.0

# Watch build at: https://github.com/dcrivac/Clipso/actions
```

That's it! GitHub Actions will build and release your app automatically.
