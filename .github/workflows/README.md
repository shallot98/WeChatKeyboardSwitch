# GitHub Actions Workflow Documentation

## Overview

This GitHub Actions workflow automatically builds the WeChatIMEGestureSwitch tweak for **rootless jailbreak** environments targeting **iOS 16+**.

## Workflow: `build.yml`

### Triggers

The workflow is triggered by:

- **Push** to `main`, `master`, or `develop` branches
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
6. **Build Rootless Package**: Compiles the tweak with `THEOS_PACKAGE_SCHEME=rootless`
7. **Upload Artifacts**: Uploads the generated `.deb` package as a workflow artifact
8. **Create Release** (for tags): Automatically creates a GitHub release with the package

### Rootless Support

The workflow is specifically configured for **rootless jailbreak** environments:

- `THEOS_PACKAGE_SCHEME=rootless` is set in the Makefile
- Package is built to install to `/var/jb/` directory structure
- Compatible with Dopamine, palera1n (rootless), XinaA15, and other rootless jailbreaks

### iOS 16 Compatibility

- Uses iOS 16.0+ SDK (`TARGET := iphone:clang:latest:16.0`)
- Builds for arm64 and arm64e architectures
- Minimum deployment target: iOS 16.0

### Artifacts

After a successful build, the following artifacts are available:

1. **DEB Package**: `WeChatIMEGestureSwitch-rootless-{version}.deb`
   - Located in workflow artifacts
   - Can be downloaded and installed on jailbroken devices
   - Compatible with Sileo, Zebra, and other package managers

2. **Build Logs** (optional):
   - Debug information
   - DEBIAN control files
   - Build logs for troubleshooting

### Usage

#### Automatic Build on Push

Simply push your changes to `main`, `master`, or `develop`:

```bash
git add .
git commit -m "Update tweak"
git push origin main
```

The workflow will automatically start building.

#### Manual Build

1. Go to the "Actions" tab in your GitHub repository
2. Select "Build Rootless iOS 16 Tweak" workflow
3. Click "Run workflow" button
4. Select the branch you want to build
5. Click "Run workflow"

#### Creating a Release

To create a release with automatic package attachment:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:
- Build the package
- Create a GitHub release
- Attach the `.deb` file to the release
- Generate release notes

### Downloading Build Artifacts

1. Navigate to the "Actions" tab
2. Click on the specific workflow run
3. Scroll down to "Artifacts" section
4. Download the `.deb` package
5. Install on your jailbroken device

### Installation on Device

After downloading the `.deb` file:

```bash
# Transfer to device
scp WeChatIMEGestureSwitch-*.deb root@<device-ip>:/var/mobile/

# SSH to device
ssh root@<device-ip>

# Install package
cd /var/mobile
dpkg -i WeChatIMEGestureSwitch-*.deb

# Respring
killall -9 SpringBoard
```

### Environment Variables

The workflow sets the following environment variables:

- `THEOS`: Path to Theos installation (`$HOME/theos`)
- `PATH`: Updated to include Theos binaries

### Build Configuration

From `Makefile`:

```makefile
TARGET := iphone:clang:latest:16.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless
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

### Troubleshooting

#### Build Fails

1. Check the workflow logs in the Actions tab
2. Verify the Makefile configuration
3. Ensure `control` file has correct dependencies
4. Check SDK compatibility

#### SDK Not Found

The workflow automatically downloads iOS SDK. If it fails:
- Check network connectivity
- Verify SDK repository availability
- Check theos/sdks repository status

#### Package Not Generated

Ensure:
- Makefile syntax is correct
- All source files are present
- No compilation errors in Tweak.x

### Customization

To customize the workflow:

1. Edit `.github/workflows/build.yml`
2. Modify build steps as needed
3. Update SDK version if required
4. Change artifact naming convention

### Related Documentation

- [Main README](../../README.md)
- [Rootless Guide](../../ROOTLESS.md)
- [Quick Start Guide](../../QUICK_START.md)
- [Theos Documentation](https://theos.dev)

### Support

For issues related to:
- **Workflow**: Open an issue in this repository
- **Build errors**: Check Makefile and source code
- **Installation**: See [ROOTLESS.md](../../ROOTLESS.md)

---

**Note**: This workflow is designed for rootless jailbreak environments. For traditional (rooted) jailbreak, modify `THEOS_PACKAGE_SCHEME` in the Makefile.
