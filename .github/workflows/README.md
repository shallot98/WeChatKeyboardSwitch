# GitHub Actions CI/CD Documentation

## Overview

This GitHub Actions workflow provides automated building, testing, and release management for the WeChat Keyboard Switch tweak targeting **iOS 16.5+ rootless jailbreak** environments.

## Workflow File

**Location**: `.github/workflows/build.yml`  
**Name**: iOS 16.5 Rootless CI

## Triggers

The workflow automatically runs on:

### Push Events
- Branches: `main`, `master`, `develop`, `ci/**`, `feature/**`
- Tags: `v*` (e.g., `v1.0.0`, `v2.1.3`)

### Pull Requests
- Target branches: `main`, `master`, `develop`

### Manual Dispatch
- Available through GitHub Actions UI with no required inputs

## Jobs

### 1. Lint & Format

**Purpose**: Validate code quality and metadata before building

**Runs on**: `macos-latest`

**Checks performed**:
- Source file formatting (trailing whitespace, newlines, carriage returns)
- Property list (`.plist`) file validation
- Control file metadata validation

**Exit behavior**: Fails the workflow if any check fails

---

### 2. Build Package

**Purpose**: Compile the tweak and create a `.deb` package

**Runs on**: `macos-latest`

**Dependencies**: Requires `lint` job to pass

**Key features**:
- Uses Xcode's native toolchain
- Caches Theos, iOS SDK, and toolchain for faster builds
- Downloads iOS 16.5 SDK from theos/sdks repository
- Builds with `FINALPACKAGE=1` for deterministic output
- Verifies `.deb` package creation

**Build configuration**:
- **Target**: iOS 16.5+
- **Architecture**: arm64
- **Package scheme**: rootless
- **Compiler flags**: `-Werror` (fail on warnings)

**Artifacts**:
- Uploads `.deb` package as `wechatkeyboardswitch-rootless-deb`
- Available for 90 days by default

---

### 3. Publish Release

**Purpose**: Create GitHub releases with attached `.deb` files

**Runs on**: `ubuntu-latest`

**Trigger**: Only when a tag matching `v*` is pushed

**Dependencies**: Requires `build` job to pass

**Actions**:
- Downloads build artifact from the build job
- Generates release notes with installation instructions
- Creates GitHub release with `.deb` attachment
- Marks release as non-draft and non-prerelease

---

## Caching Strategy

The workflow uses GitHub Actions cache to speed up builds:

### Cached Items
1. **Theos** (`~/theos`)
   - Key: `${{ runner.os }}-theos-rootless-v1`
   - Includes core Theos build system

2. **Theos Toolchain** (`~/theos/toolchain`)
   - Automatically installed if not cached
   - Uses native toolchain from theos/toolchain repository

3. **iOS 16.5 SDK** (`~/theos/sdks`)
   - Contains iOS 16.5 SDK from theos/sdks
   - Verified before build

### Cache Benefits
- Reduces build time from ~5 minutes to ~2 minutes
- Consistent, reproducible builds
- Lower network usage

---

## Usage Examples

### Creating a Pull Request

When you open a PR to `main`, `master`, or `develop`:

1. Lint checks run automatically
2. Build job compiles the tweak
3. `.deb` artifact is uploaded
4. Review build logs and download artifact from Actions tab

### Releasing a Version

To create a release:

```bash
# Ensure code is ready
git add .
git commit -m "feat: add new feature"
git push origin main

# Create and push tag
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:
- Run lint and build jobs
- Create a GitHub Release at `https://github.com/OWNER/REPO/releases/tag/v1.0.0`
- Attach the `.deb` file to the release
- Generate release notes

### Manual Build

1. Navigate to Actions tab
2. Select "iOS 16.5 Rootless CI" workflow
3. Click "Run workflow"
4. Select branch
5. Click "Run workflow" button

---

## Build Requirements

### System Dependencies
- macOS runner (GitHub-hosted)
- Xcode (pre-installed on runner)
- Homebrew packages: `ldid`, `dpkg`, `gnu-sed`

### Theos Dependencies
- Theos build system
- Theos toolchain
- iOS 16.5 SDK

### Project Dependencies
- Valid `Makefile` with Theos configuration
- Valid `control` file with package metadata
- Source files: `Tweak.x`, layouts, plists

---

## Artifacts

### Build Artifacts

**Name**: `wechatkeyboardswitch-rootless-deb`

**Contents**: 
- `.deb` package file
- Format: `com.example.wechatkeyboardswitch_VERSION_iphoneos-arm64.deb`

**Retention**: 90 days (GitHub default)

**Download**:
1. Go to Actions tab
2. Select workflow run
3. Scroll to "Artifacts" section
4. Click artifact name to download

---

## Makefile Configuration

The workflow expects the following Makefile configuration:

```makefile
TARGET := iphone:clang:latest:16.5
ARCHS = arm64
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

TWEAK_NAME = WeChatKeyboardSwitch
WeChatKeyboardSwitch_FILES = Tweak.x
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc -Werror
WeChatKeyboardSwitch_FRAMEWORKS = UIKit Foundation
```

Key requirements:
- `THEOS_PACKAGE_SCHEME = rootless`
- `-Werror` flag to fail on warnings
- `TWEAK_NAME` must be defined

---

## Control File

Required fields in `control` file:
- `Package`: Bundle identifier
- `Name`: Display name
- `Version`: Semantic version
- `Architecture`: Target architecture
- `Description`: Package description

Example:
```
Package: com.example.wechatkeyboardswitch
Name: WeChat Keyboard Switch
Version: 1.0.0
Architecture: iphoneos-arm64
Description: Minimal rootless Theos tweak skeleton targeting iOS 16.5.
Maintainer: Example Maintainer <maintainer@example.com>
Author: Example Maintainer <maintainer@example.com>
Section: Tweaks
Depends: mobilesubstrate, firmware (>= 15.0)
Priority: optional
```

---

## Troubleshooting

### Build Fails

**Check**:
1. Review Actions logs for error messages
2. Verify Makefile syntax
3. Ensure all source files are committed
4. Check control file has required fields

**Common issues**:
- Missing `-Werror` warnings (now treated as errors)
- Missing iOS 16.5 SDK (workflow downloads automatically)
- Theos installation failure (check network connectivity)

### Lint Fails

**Check**:
1. Trailing whitespace in source files
2. Missing newlines at end of files
3. Invalid plist files
4. Missing control file fields

**Fix**:
```bash
# Remove trailing whitespace
git ls-files '*.x' '*.m' '*.h' | xargs sed -i '' 's/[[:space:]]*$//'

# Validate plist files
plutil -lint *.plist
```

### Cache Issues

If cache causes problems:
1. Update cache key version in workflow file
2. Or manually delete caches in GitHub Settings → Actions → Caches

### Release Not Created

**Check**:
1. Ensure tag matches `v*` pattern
2. Verify `GITHUB_TOKEN` has write permissions
3. Check if release already exists
4. Review release job logs

---

## Best Practices

### Version Tagging
- Use semantic versioning: `v1.0.0`, `v2.1.3`
- Update version in `control` file before tagging
- Create annotated tags with messages:
  ```bash
  git tag -a v1.0.0 -m "Release version 1.0.0"
  ```

### Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- Keep messages concise and descriptive

### Branch Strategy
- Develop features in `feature/*` branches
- Test in `develop` branch
- Merge to `main` for releases
- Tag from `main` branch

### Testing
- Always test `.deb` packages on real devices
- Verify rootless installation path (`/var/jb`)
- Test on iOS 16.5+ devices
- Check with different jailbreak tools (Dopamine, Palera1n)

---

## Security

### Secrets
- Workflow uses `GITHUB_TOKEN` (automatically provided)
- No additional secrets required
- Token has `contents: write` permission for releases

### Code Signing
- Uses `ldid` for fake code signing
- Sufficient for jailbroken devices
- No Apple Developer account required

---

## Performance

### Typical Build Times

| Job | Duration | Notes |
|-----|----------|-------|
| Lint | ~30 seconds | Fast validation checks |
| Build (first time) | ~4-5 minutes | Downloads Theos and SDK |
| Build (cached) | ~1-2 minutes | Uses cached dependencies |
| Release | ~30 seconds | Downloads artifact and creates release |

### Optimization Tips
- Keep cache keys stable for better hit rates
- Use shallow clones (`--depth=1`) for Git repositories
- Minimize unnecessary dependencies

---

## Platform Compatibility

### Runner
- **OS**: macOS (latest stable)
- **Xcode**: Pre-installed (multiple versions available)
- **Architecture**: x86_64 / arm64 (Apple Silicon)

### Target Device
- **iOS**: 16.5 or later
- **Jailbreak**: Rootless (Dopamine, Palera1n, etc.)
- **Architecture**: arm64

---

## Future Enhancements

Potential improvements:
- [ ] Add unit tests for Objective-C code
- [ ] Integrate clang-format for automatic formatting
- [ ] Add code signing with real certificates (optional)
- [ ] Support multiple SDK versions in matrix builds
- [ ] Add automatic changelog generation
- [ ] Integrate with external package repositories

---

## Support and Contribution

### Getting Help
- Review workflow logs in Actions tab
- Check this documentation
- Open issues for problems
- Consult Theos documentation: https://theos.dev

### Contributing
- Follow existing code style
- Ensure lint checks pass
- Test changes locally when possible
- Update documentation for workflow changes

---

## References

- [Theos Documentation](https://theos.dev)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [iOS Jailbreak Development](https://iphonedev.wiki)

---

**Last Updated**: November 2024  
**Workflow Version**: 1.0.0  
**Maintained by**: Repository maintainers
