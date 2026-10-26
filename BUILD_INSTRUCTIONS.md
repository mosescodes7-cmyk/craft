# 🚀 Build Instructions

## Building APK with GitHub Actions (Recommended)

### Automatic Build on Push
1. Push your code to GitHub
2. GitHub Actions will automatically build the APK
3. Download the APK from the "Actions" tab → Click on workflow run → "Artifacts"

### Manual Build
1. Go to your GitHub repository
2. Click on "Actions" tab
3. Select "Build Android APK" workflow
4. Click "Run workflow" button
5. Wait for the build to complete (~5-10 minutes)
6. Download the APK from the artifacts section

### Creating a Release
1. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. GitHub Actions will automatically create a release with APK files attached
3. Users can download the APK directly from the Releases page

## APK Files Generated

The workflow creates 4 APK files:

1. **app-armeabi-v7a-release.apk** - For older 32-bit ARM devices (~15MB smaller)
2. **app-arm64-v8a-release.apk** - For modern 64-bit ARM devices (most common)
3. **app-x86_64-release.apk** - For x86 devices (rare, mostly emulators)
4. **app-release.apk** - Universal APK (works on all devices, largest size)

**Recommended**: Share `app-arm64-v8a-release.apk` for most users.

## Local Build (if Android SDK is set up)

```bash
# Split APKs (smaller size)
flutter build apk --split-per-abi --release

# Universal APK
flutter build apk --release
```

## App Information

- **App Name**: Craft Orders
- **Package**: com.example.craft_tracker
- **Developer**: NANDUTTU ROBINAH
- **Institution**: MUTEESA I ROYAL UNIVERSITY
- **Version**: 1.0.0+1

## Features

✅ Offline local storage (SharedPreferences)
✅ Splash screen with custom logo
✅ Custom launcher icons
✅ Dark theme with lime accent
✅ Device preview for testing
✅ Track craft orders, deposits, and balances

---

**Need help?** Check the Actions tab on GitHub for build logs.
