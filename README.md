# WeChatKeyboardSwitch

A rootless Theos tweak that enhances keyboard input switching in WeChat through intuitive swipe gestures. Compatible with iOS 13.0 - 16.5.

## Features

- 🎯 **Gesture-based keyboard switching**: Swipe left or right on the keyboard to switch between Chinese (Simplified) Pinyin and English input modes
- ⚙️ **Configurable settings**: Customize behavior through the Settings app
  - Enable/disable the tweak
  - Restrict to WeChat only or enable system-wide
  - Invert swipe direction
  - Toggle haptic feedback
- 🔒 **Safe and efficient**: Debounced gesture recognition with smart exclusion zones
- 🏗️ **Rootless compatible**: Built specifically for modern rootless jailbreaks

## Installation

### From Release (Recommended)

1. Download the latest `.deb` package from the [Releases](https://github.com/shallot98/WeChatKeyboardSwitch/releases) page
2. Transfer the `.deb` file to your jailbroken iOS device via SSH, Filza, or your preferred method
3. Install using your package manager (Sileo, Zebra) or via command line:
   ```bash
   dpkg -i com.wechat.keyboardswitch_0.1.0_iphoneos-arm64.deb
   ```
4. Respring your device
5. Configure the tweak in **Settings → WeChatKeyboardSwitch**

### Building from Source

#### Requirements

- [Theos](https://theos.dev/) environment configured with the latest iOS 16.5 SDK
- Rootless packaging support (`THEOS_PACKAGE_SCHEME = rootless`)

#### Build Steps

```bash
# Clone the repository
git clone https://github.com/shallot98/WeChatKeyboardSwitch.git
cd WeChatKeyboardSwitch

# Build the package
make package

# Install to device (set THEOS_DEVICE_IP first)
make install
```

The generated rootless `.deb` will be placed inside the `packages/` directory.

## Usage

1. Open WeChat and start typing in any text field
2. When the keyboard is visible, swipe left or right on the keyboard area to switch input modes
3. The keyboard will automatically switch between Chinese Pinyin and English
4. Haptic feedback confirms the switch (if enabled in settings)

**Note**: Avoid swiping on the bottom area of the keyboard (space bar region) to prevent accidental switches.

## Continuous Integration

This project includes automated GitHub Actions CI that builds the tweak on every push and pull request to the `main`/`master` branches. The workflow:

- Runs on a macOS runner with Theos configured for iOS 16.5 SDK
- Uses rootless packaging (`THEOS_PACKAGE_SCHEME=rootless`) with the target `iphone:clang:latest:16.5`
- Caches Theos toolchain and SDK to speed up subsequent builds
- Produces a release `.deb` package and uploads it as a workflow artifact

See `.github/workflows/build.yml` for the full workflow definition.

> **Note**
> This project now includes a Preferences bundle (`com.wechat.keyboardswitch`) that can be configured in Settings.
