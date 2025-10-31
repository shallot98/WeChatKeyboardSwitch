# GitHub Actions Workflow Documentation

## Overview

This GitHub Actions workflow automatically builds the **WeChat Keyboard Switch** tweak for **rootless jailbreak** environments targeting **iOS 16+** using **macOS runners** with native Xcode toolchain.

## Workflow: `build.yml`

### Triggers

The workflow is triggered by:

- **Manual trigger** via GitHub Actions UI (workflow_dispatch) with customizable parameters
- **Tags** starting with `v*` (e.g., `v1.0.0`) - automatically creates releases

### Workflow Inputs (Manual Trigger)

When manually triggering the workflow, you can customize:

1. **package_scheme**: Choose between `rootless` (default) or `rootful` package schemes
2. **theos_target**: Specify custom Theos TARGET (e.g., `iphone:clang:latest:16.0`, `iphone:clang:16.5:16.0`)
3. **make_target**: Choose build target - `package` (default), `all`, or `debug`

### Build Process

The workflow performs the following steps:

1. **Checkout Repository**: Clones the repository with submodules
2. **Install Dependencies**: Installs required build tools via Homebrew (ldid, make, dpkg, gnu-sed)
3. **Install Theos**: Clones the latest Theos build system from GitHub
4. **Ensure SDK Availability**: Uses Xcode's native iOS SDK or falls back to theos/sdks
5. **Build Tweak**: Compiles the tweak and preference bundle with configurable scheme
6. **Upload Artifacts**: Uploads the generated `.deb` package as a workflow artifact
7. **Create Release** (for tags): Automatically publishes a GitHub release with the package

### macOS Runner Benefits

The workflow uses **macOS-13** runners which provide:

- ✅ Native Xcode toolchain and iOS SDK included
- ✅ No need to manually install iOS toolchain
- ✅ No libplist dependency issues
- ✅ Better compatibility with iOS development tools
- ✅ Proven reliability (used by KeySwipe11 and other projects)

### Rootless Support

The workflow supports both **rootless** and **rootful** jailbreak environments:

- Default: `THEOS_PACKAGE_SCHEME=rootless` (builds for `/var/jb/` structure)
- Optional: `THEOS_PACKAGE_SCHEME=rootful` (builds for traditional rooted jailbreak)
- Compatible with Dopamine, Palera1n (rootless), XinaA15, and other rootless jailbreaks

### iOS 16+ Compatibility

- Uses iOS SDK from Xcode (16.0+ compatible)
- Builds for arm64 and arm64e architectures (configured in Makefile)
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

1. **DEB Package**: `wechatkeyboardswitch-rootless-deb`
   - Located in workflow artifacts
   - Can be downloaded and installed on jailbroken devices
   - Compatible with Sileo, Zebra, Installer, and other package managers
   - Includes both the tweak dylib and preference bundle

### Usage

#### Manual Build

1. Go to the "Actions" tab in your GitHub repository
2. Select "Build WeChatKeyboardSwitch" workflow
3. Click "Run workflow" button
4. Configure build options:
   - **Branch**: Select the branch to build from
   - **Package scheme**: Choose `rootless` or `rootful`
   - **Theos TARGET**: (Optional) Specify custom target like `iphone:clang:latest:16.0`
   - **Make target**: Choose `package`, `all`, or `debug`
5. Click "Run workflow"

#### Creating a Release

To create a release with automatic package attachment:

```bash
# Tag your version
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:
- Build the package with rootless scheme
- Create a GitHub release
- Attach the `.deb` file to the release

### Downloading Build Artifacts

1. Navigate to the "Actions" tab
2. Click on the specific workflow run
3. Scroll down to "Artifacts" section
4. Download the `wechatkeyboardswitch-rootless-deb` artifact
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
- `THEOS_PLATFORM_SDK_ROOT`: Path to Xcode developer tools
- `DEVELOPER_DIR`: Path to Xcode developer directory

### Build Configuration

From `Makefile`:

```makefile
TARGET := iphone:clang:16.5:16.0
ARCHS = arm64 arm64e
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

The workflow installs via Homebrew:

- ldid (code signing)
- make (build system)
- dpkg (package creation)
- gnu-sed (text processing)

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

The workflow uses Xcode's native iOS SDK. If it fails:
- Xcode tools should be pre-installed on macOS runners
- Fallback to theos/sdks repository if needed
- Check workflow logs for SDK-related errors

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

### Customization

To customize the workflow:

1. Edit `.github/workflows/build.yml`
2. Modify build steps as needed
3. Update Theos TARGET via workflow inputs
4. Change package scheme via workflow inputs
5. Add additional build steps if required

Example: Building for different iOS versions:

```bash
# Via workflow_dispatch input
Theos TARGET: iphone:clang:17.0:16.0  # iOS 17 SDK, minimum iOS 16
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
![Build Status](https://github.com/yourusername/WeChatKeyboardSwitch/workflows/Build%20WeChatKeyboardSwitch/badge.svg)
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

The workflow uses the same build commands you can use locally (on macOS):

```bash
# Local build (with Theos installed on macOS)
export THEOS=~/theos
make clean
make package

# CI build (automatic)
git tag v1.0.0
git push origin v1.0.0
```

#### Building Different Schemes

```bash
# Rootless (default)
make package THEOS_PACKAGE_SCHEME=rootless

# Rootful
make package THEOS_PACKAGE_SCHEME=rootful
```

#### Multi-Architecture Builds

The Makefile is configured for multiple architectures:

```makefile
ARCHS = arm64 arm64e
```

This builds for both standard ARM64 and ARM64e (pointer authentication) devices.

#### Debug vs Release Builds

For debug builds (via workflow input):
- Select `make_target: debug`

For release builds (default):
- Select `make_target: package`

---

## Quick Reference

### Trigger Manual Build
1. Actions tab → "Build WeChatKeyboardSwitch" → "Run workflow"
2. Configure options → "Run workflow"

### Create Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Download Artifact
1. Actions tab → Select run → Download `wechatkeyboardswitch-rootless-deb`

### Install Package
```bash
dpkg -i *.deb && killall SpringBoard
```

---

**Note**: This workflow supports both rootless and rootful jailbreak environments via the `package_scheme` input parameter.

**Platform**: macOS-13 (with Xcode)  
**Theos**: Latest from GitHub  
**SDK**: Xcode iOS SDK (16.0+)  
**Architecture**: ARM64 + ARM64e  
**Package Format**: Debian (.deb)
