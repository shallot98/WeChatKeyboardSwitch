# GitHub Actions Workflow Documentation

## Overview

This GitHub Actions workflow automatically builds the **WeChat Keyboard Switch** tweak for **rootless jailbreak** environments targeting **iOS 16+**.

## Workflow: `build.yml`

### Triggers

The workflow is triggered by:

- **Push** to `main`, `master`, `develop`, or `feat-wechat-keyboard-swipe-switcher` branches
- **Pull requests** targeting `main`, `master`, or `develop` branches
- **Tags** starting with `v*` (e.g., `v1.0.0`)
- **Manual trigger** via GitHub Actions UI (workflow_dispatch)

### Build Process

The workflow performs the following steps:

1. **Checkout Repository**: Clones the repository with submodules
2. **Install Dependencies**: Installs required build tools (build-essential, git, curl, wget, perl, fakeroot, etc.)
3. **Setup Theos**: Clones the latest Theos build system from GitHub
4. **Download iOS SDK**: Downloads iOS 16 SDK from the theos/sdks repository
5. **Configure Theos**: Sets up environment variables for the build
6. **Build Rootless Package**: Compiles the tweak and preference bundle with `THEOS_PACKAGE_SCHEME=rootless`
7. **Upload Artifacts**: Uploads the generated `.deb` package as a workflow artifact
8. **Create Release** (for tags): Automatically creates a GitHub release with the package

### Rootless Support

The workflow is specifically configured for **rootless jailbreak** environments:

- `THEOS_PACKAGE_SCHEME=rootless` is set in the Makefile
- Package is built to install to `/var/jb/` directory structure
- Compatible with Dopamine, Palera1n (rootless), XinaA15, and other rootless jailbreaks

### iOS 16+ Compatibility

- Uses iOS 16.0+ SDK (`TARGET := iphone:clang:latest:16.0`)
- Builds for arm64 architecture
- Minimum deployment target: iOS 16.0
- Supports iOS 16, 17, and newer versions

### Project Structure

The build includes:

- **Main Tweak** (`Tweak.xm`): Keyboard gesture recognition and input mode switching
- **PreferenceBundle** (`wechatkeyboardswitchprefs/`): Settings integration
- **MobileSubstrate Filter**: UIKit injection configuration
- **PreferenceLoader Entry**: Settings app integration

### Artifacts

After a successful build, the following artifacts are available:

1. **DEB Package**: `WeChatKeyboardSwitch-rootless-{version}.deb`
   - Located in workflow artifacts
   - Can be downloaded and installed on jailbroken devices
   - Compatible with Sileo, Zebra, Installer, and other package managers
   - Includes both the tweak dylib and preference bundle

2. **Build Logs** (optional):
   - Debug information
   - DEBIAN control files
   - Build logs for troubleshooting

### Usage

#### Automatic Build on Push

Simply push your changes to any tracked branch:

```bash
git add .
git commit -m "feat: add new feature"
git push origin feat-wechat-keyboard-swipe-switcher
```

The workflow will automatically start building.

#### Manual Build

1. Go to the "Actions" tab in your GitHub repository
2. Select "Build WeChat Keyboard Switch" workflow
3. Click "Run workflow" button
4. Select the branch you want to build
5. Click "Run workflow"

#### Creating a Release

To create a release with automatic package attachment:

```bash
# Tag your version
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:
- Build the package
- Create a GitHub release
- Attach the `.deb` file to the release
- Generate release notes automatically

### Downloading Build Artifacts

1. Navigate to the "Actions" tab
2. Click on the specific workflow run
3. Scroll down to "Artifacts" section
4. Download the `WeChatKeyboardSwitch-rootless-{version}` artifact
5. Extract the `.deb` package from the zip file
6. Install on your jailbroken device

### Installation on Device

After downloading the `.deb` file:

#### Method 1: SSH Installation

```bash
# Transfer to device
scp com.yourrepo.wechatkeyboardswitch_*.deb root@<device-ip>:/var/mobile/

# SSH to device
ssh root@<device-ip>

# Install package
cd /var/mobile
dpkg -i com.yourrepo.wechatkeyboardswitch_*.deb

# Respring
killall SpringBoard
```

#### Method 2: Package Manager

1. Transfer the `.deb` file to your device
2. Open your package manager (Sileo, Zebra, Installer)
3. Navigate to the file location
4. Tap to install
5. Respring when prompted

#### Method 3: Filza

1. Transfer the `.deb` file to device using AirDrop or iTunes
2. Open Filza File Manager
3. Navigate to the file location
4. Tap the `.deb` file
5. Tap "Install"
6. Respring

### Environment Variables

The workflow sets the following environment variables:

- `THEOS`: Path to Theos installation (`$HOME/theos`)
- `PATH`: Updated to include Theos binaries

### Build Configuration

From `Makefile`:

```makefile
TARGET := iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

TWEAK_NAME = WeChatKeyboardSwitch
WeChatKeyboardSwitch_FILES = Tweak.xm
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc
WeChatKeyboardSwitch_FRAMEWORKS = UIKit Foundation
WeChatKeyboardSwitch_PRIVATE_FRAMEWORKS = Preferences

SUBPROJECTS += wechatkeyboardswitchprefs
```

### Dependencies

The workflow installs:

- build-essential
- git
- curl
- wget
- perl
- fakeroot
- libarchive-tools
- zstd

### Package Dependencies

From `control` file:

- mobilesubstrate (Cydia Substrate)
- preferenceloader (Settings integration)
- firmware >= 16.0 (iOS 16+)

### Troubleshooting

#### Build Fails

1. Check the workflow logs in the Actions tab
2. Verify the Makefile configuration
3. Ensure `control` file has correct dependencies
4. Check SDK compatibility
5. Verify all source files are present

#### SDK Not Found

The workflow automatically downloads iOS SDK. If it fails:
- Check network connectivity
- Verify SDK repository availability
- Check theos/sdks repository status
- Try re-running the workflow

#### Package Not Generated

Ensure:
- Makefile syntax is correct
- All source files are present (`Tweak.xm`, preference bundle files)
- No compilation errors in code
- PreferenceBundle Makefile is correct

#### PreferenceBundle Build Fails

Check:
- `wechatkeyboardswitchprefs/Makefile` exists and is correct
- All `.m` and `.h` files are present
- `Resources/Root.plist` is valid XML
- `entry.plist` is properly formatted

### Build Summary Output

After each build, the workflow generates a summary showing:

- Package name and version
- Architecture (iphoneos-arm64)
- Target iOS version (16.0+)
- Package scheme (Rootless)
- Build status (✅ Success or ❌ Failed)
- Package file name and size

### Customization

To customize the workflow:

1. Edit `.github/workflows/build.yml`
2. Modify build steps as needed
3. Update SDK version if required
4. Change artifact naming convention
5. Add additional build steps (e.g., code signing)

Example customizations:

```yaml
# Add code quality checks
- name: Run Code Quality Checks
  run: |
    # Add your linting/static analysis here
    
# Add unit tests
- name: Run Tests
  run: |
    # Add your test commands here
```

### CI/CD Best Practices

1. **Version Tags**: Use semantic versioning for releases (v1.0.0, v1.1.0, etc.)
2. **Commit Messages**: Use conventional commits (feat:, fix:, docs:, etc.)
3. **Branch Strategy**: Develop on feature branches, merge to main for releases
4. **Testing**: Test the built package on actual devices before creating releases
5. **Documentation**: Update CHANGELOG.md with each release

### Workflow Status Badge

Add this badge to your README to show build status:

```markdown
![Build Status](https://github.com/yourusername/WeChatKeyboardSwitch/workflows/Build%20WeChat%20Keyboard%20Switch/badge.svg)
```

### Related Documentation

- [Main README](../../README.md) - User guide and features
- [INSTALLATION.md](../../INSTALLATION.md) - Installation instructions
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
- [CHANGELOG.md](../../CHANGELOG.md) - Version history
- [QUICK_REFERENCE.md](../../QUICK_REFERENCE.md) - Quick reference guide
- [Theos Documentation](https://theos.dev) - Theos build system

### Support

For issues related to:
- **Workflow**: Open an issue in this repository
- **Build errors**: Check Makefile and source code
- **Installation**: See [INSTALLATION.md](../../INSTALLATION.md)
- **Usage**: See [README.md](../../README.md)

### Advanced Usage

#### Building Locally vs CI

The workflow uses the same build commands you can use locally:

```bash
# Local build (with Theos installed)
make clean
make package FINALPACKAGE=1

# CI build (automatic)
git push origin main
```

#### Caching Theos

To speed up builds, you can add caching:

```yaml
- name: Cache Theos
  uses: actions/cache@v3
  with:
    path: ~/theos
    key: ${{ runner.os }}-theos-${{ hashFiles('**/Makefile') }}
```

#### Multi-Architecture Builds

To build for multiple architectures, update the Makefile:

```makefile
ARCHS = arm64 arm64e
```

#### Debug vs Release Builds

For debug builds:

```bash
make package DEBUG=1
```

For release builds (used in CI):

```bash
make package FINALPACKAGE=1
```

---

## Quick Reference

### Trigger Build
```bash
git push origin <branch-name>
```

### Create Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Download Artifact
1. Actions tab → Select run → Download artifact

### Install Package
```bash
dpkg -i *.deb && killall SpringBoard
```

---

**Note**: This workflow is designed for rootless jailbreak environments. For traditional (rooted) jailbreak, modify `THEOS_PACKAGE_SCHEME` in the Makefile.

**Platform**: Ubuntu latest (Linux)  
**Theos**: Latest from GitHub  
**SDK**: iOS 16+  
**Architecture**: ARM64  
**Package Format**: Debian (.deb)
