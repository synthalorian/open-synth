# Open Synth — Release Setup Guide

This document covers everything needed to build, sign, and release Open Synth
for Linux and Android.

---

## Table of Contents

1. [Flutter Version Pinning](#flutter-version-pinning)
2. [Android Release Signing](#android-release-signing)
3. [Triggering a Release](#triggering-a-release)
4. [Release Artifacts](#release-artifacts)
5. [Troubleshooting](#troubleshooting)

---

## Flutter Version Pinning

The project pins the Flutter SDK version via `.fvmrc` (for FVM users) and a
plain `flutter-version` file (for CI). Both files must be committed to the
repository so that CI and other developers use the exact same Flutter SDK.

**Current version:** `3.41.9`

To update the pinned version:

```bash
# Edit both files
$EDITOR .fvmrc
$EDITOR flutter-version

# Verify locally
flutter --version
```

The CI workflows read `.fvmrc` via `flutter-version-file`, so updating both
files is sufficient to pin the version across all environments.

---

## Android Release Signing

The Android release build is signed with a release keystore. If the keystore
is missing, the build falls back to the debug signing config (useful for CI
on forks and local development).

### Step 1: Generate a Release Keystore

Run this command once from the project root and store the resulting file securely:

```bash
cd android/app
keytool -genkey -v \
  -keystore release.keystore \
  -alias open_synth_release \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000
```

You will be prompted for:
- **Keystore password** — used to unlock the keystore file
- **Key password** — used to unlock the specific signing key (can be the same)
- **Key alias** — the name of the key inside the keystore (e.g. `open_synth_release`)

> **Keep `android/app/release.keystore` safe.** Back it up in a password manager
> or secure storage. If you lose it, you cannot update existing app installations
> on the Play Store.
> **Do not commit the keystore to Git.** It is already ignored via `.gitignore`.

### Step 2: Encode the Keystore for GitHub Actions

GitHub Actions secrets have a 64 KB limit and cannot store binary files directly.
Base64-encode the keystore (run from `android/app/` where the keystore lives):

```bash
cd android/app
base64 -i release.keystore
```

Copy the entire output string and paste it into the GitHub secret (see below).

### Step 3: Add Secrets to GitHub

Go to **Settings → Secrets and variables → Actions → New repository secret**
and create the following four secrets:

| Secret name | Value |
|---|---|
| `KEYSTORE_BASE64` | The base64-encoded keystore string from Step 2 |
| `KEYSTORE_PASSWORD` | The keystore password you set in Step 1 |
| `KEY_ALIAS` | The alias you chose in Step 1 (e.g. `open_synth_release`) |
| `KEY_PASSWORD` | The key password you set in Step 1 |

### Verification

After adding the secrets, trigger a release (see [Triggering a Release](#triggering-a-release))
and verify the APK is signed:

```bash
# Download the APK from the release page
jarsigner -verify -verbose -certs app-release.apk
```

You should see `jar verified.` and the certificate details.

---

## Triggering a Release

Releases are fully automated via GitHub Actions. Simply push a semver tag:

```bash
# Create an annotated tag
git tag -a v1.2.3 -m "Release v1.2.3"

# Push the tag
git push origin v1.2.3
```

The `release.yml` workflow will:

1. Build the Linux release bundle, `.deb`, and `.AppImage`
2. Build the signed Android APK
3. Create a **draft** GitHub Release with all four artifacts attached
4. Auto-generate release notes from the commit history

> **Why a draft?** The release is created as a draft so a human can review
> the release notes and artifacts before publishing it to users.

### Prerelease Tags

Tags containing `alpha` or `beta` are automatically marked as prereleases:

```bash
git tag -a v1.3.0-beta.1 -m "Beta 1"
git push origin v1.3.0-beta.1
```

---

## Release Artifacts

| Artifact | Platform | Description |
|---|---|---|
| `open-synth-linux-x64.tar.gz` | Linux | Portable tarball — extract and run `./open_synth` |
| `open-synth-linux-amd64.deb` | Linux | Debian/Ubuntu package — install with `sudo dpkg -i` |
| `open-synth-linux-x86_64.AppImage` | Linux | Universal AppImage — make executable and run |
| `app-release.apk` | Android | Signed APK for sideloading or Play Store upload |

---

## Troubleshooting

### Android build fails with "keystore file not found"

The `build-android` job creates `android/key.properties` and decodes the
keystore from the `KEYSTORE_BASE64` secret. If this secret is missing or
invalid, the build will fail.

**Fix:** Verify all four secrets are set correctly in the repository settings.

### `.deb` install fails with dependency errors

```bash
sudo dpkg -i open-synth-linux-amd64.deb
sudo apt-get install -f   # Fix missing dependencies
```

### AppImage won't run (FUSE error)

Some distributions restrict FUSE. Use `--appimage-extract-and-run`:

```bash
./open-synth-linux-x86_64.AppImage --appimage-extract-and-run
```

### CI uses the wrong Flutter version

Ensure both `.fvmrc` and `flutter-version` contain the desired version, and
that the workflow YAML references `.fvmrc` via `flutter-version-file`.

---

*Last updated: May 2026*
