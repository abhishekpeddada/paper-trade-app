# GitHub Release Guide

## Creating a Release with Android APK

### Option 1: Using GitHub Web Interface (Recommended)

1. **Commit and Push Your Code**
   ```bash
   git add -A
   git commit -m "chore: prepare v1.0.0 release"
   git push origin main
   ```

2. **Create a Tag**
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

3. **Create Release on GitHub**
   - Go to: https://github.com/abhishekpeddada/paper-trade-app/releases/new
   - Tag: `v1.0.0`
   - Release title: `Paper Trade App v1.0.0`
   - Description: Copy from `RELEASE_NOTES.md`
   - Upload APK: `build/app/outputs/flutter-apk/app-release.apk`
   - Check "Set as the latest release"
   - Click "Publish release"

### Option 2: Using GitHub CLI (gh)

```bash
# Install gh if not already installed
# sudo apt install gh

# Authenticate
gh auth login

# Create release with APK
gh release create v1.0.0 \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "Paper Trade App v1.0.0" \
  --notes-file RELEASE_NOTES.md
```

### Your APK Location
```
build/app/outputs/flutter-apk/app-release.apk (53MB)
```

### Pre-Release Checklist

- [x] APK built successfully
- [x] Sensitive files gitignored
- [x] Example config files created
- [x] README.md and SETUP.md created
- [ ] All changes committed
- [ ] Tag created and pushed
- [ ] Release created on GitHub
