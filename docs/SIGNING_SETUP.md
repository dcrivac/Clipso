# Code signing & notarization setup

Status: **not yet active.** Releases are currently unsigned — users must run
`xattr -cr /Applications/Clipso.app` on first launch. This document is the
checklist to turn on signing once an Apple Developer account exists.

The release workflow (`.github/workflows/release.yml`) already branches on
whether the secrets below are present: with them it produces a signed +
notarized DMG/ZIP, without them it produces today's unsigned build. No workflow
changes are needed to activate — just add the secrets.

---

## 1. Enrol in the Apple Developer Program

<https://developer.apple.com/programs/> — $99/year. An individual account is
fine. After enrolment note your **Team ID** (10 characters, e.g. `DKN2U77MAZ` —
already referenced in `Clipso.xcodeproj`).

## 2. Create a "Developer ID Application" certificate

On a Mac signed in to the account:

1. Xcode → Settings → Accounts → your Apple ID → **Manage Certificates**
2. **+** → **Developer ID Application** → Done
   (this is the cert for distributing *outside* the App Store)
3. Confirm it is present and valid:
   ```bash
   security find-identity -v -p codesigning
   # -> "Developer ID Application: Your Name (TEAMID)"
   ```

## 3. Export the certificate as a .p12

Keychain Access → **My Certificates** → select *Developer ID Application:* …
(expand it, make sure the private key is included) → right-click → **Export** →
save as `clipso-signing.p12` → set a strong export password.

Then base64-encode it for GitHub:

```bash
base64 -i clipso-signing.p12 | pbcopy   # now in your clipboard
```

## 4. Create an app-specific password for notarization

<https://account.apple.com> → Sign-In and Security → **App-Specific Passwords**
→ generate one, label it "clipso notarytool". Format: `abcd-efgh-ijkl-mnop`.

## 5. Add the GitHub repository secrets

`gh secret set <NAME>` (run from the repo), or Settings → Secrets and variables
→ Actions:

| Secret | Value |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | the base64 blob from step 3 |
| `APPLE_CERTIFICATE_PASSWORD` | the .p12 export password from step 3 |
| `APPLE_SIGNING_IDENTITY` | `Developer ID Application: Your Name (TEAMID)` (optional — defaults to `Developer ID Application`) |
| `APPLE_TEAM_ID` | your 10-char Team ID |
| `APPLE_ID_EMAIL` | the Apple ID email |
| `APPLE_ID_PASSWORD` | the app-specific password from step 4 |

The workflow treats signing as "on" only when `APPLE_CERTIFICATE_BASE64`,
`APPLE_ID_EMAIL`, `APPLE_ID_PASSWORD` and `APPLE_TEAM_ID` are all set.

```bash
gh secret set APPLE_CERTIFICATE_BASE64   # paste, then Ctrl-D
gh secret set APPLE_CERTIFICATE_PASSWORD
gh secret set APPLE_SIGNING_IDENTITY
gh secret set APPLE_TEAM_ID
gh secret set APPLE_ID_EMAIL
gh secret set APPLE_ID_PASSWORD
```

## 6. Cut a release

```bash
git tag v1.0.4 && git push origin v1.0.4
```

Watch the run: `gh run watch`. The "Check for signing secrets" step will report
`✅ Signing + notarization secrets present`. On success the GitHub release gets a
signed, stapled `Clipso-1.0.4.dmg`.

## 7. Verify the published artifact

```bash
# download Clipso-1.0.4.dmg from the release, then:
codesign --verify --strict --verbose=2 /Volumes/Clipso/Clipso.app
spctl -a -vvv --type exec /Volumes/Clipso/Clipso.app     # -> "accepted, source=Notarized Developer ID"
xcrun stapler validate Clipso-1.0.4.dmg
```

## 8. After it works

- Delete the `xattr -cr` workaround section from `INSTALLATION_TROUBLESHOOTING.md`
  and the release-notes template's unsigned branch in `release.yml`.
- Certificates expire after 5 years; the app-specific password does not expire
  but is revoked if the Apple ID password changes.

---

### Notes

- `.github/workflows/main.yml` was removed — it was a second, older release
  pipeline with a conflicting secret scheme (`MACOS_CERTIFICATE`,
  `CODESIGN_IDENTITY`, …) and no notarization, and it created a duplicate GitHub
  release on every tag. `release.yml` is now the single release workflow.
- Local signed builds: `./scripts/build-release.sh` (see `CODE_SIGNING_GUIDE.md`).
