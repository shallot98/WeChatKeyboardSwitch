# Changelog

All notable changes to WeChatKeyboardSwitch will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-11-01

### Added
- Initial release of WeChatKeyboardSwitch
- Keyboard swipe gesture support for switching between input modes in WeChat
- Support for iOS 13.0 - 16.5 (rootless)
- Swipe left/right on keyboard to switch between Chinese (Simplified) Pinyin and English keyboards
- Configurable settings via Preferences bundle:
  - Toggle to enable/disable the tweak
  - Option to restrict functionality to WeChat only or system-wide
  - Invert swipe direction setting
  - Haptic feedback toggle
- Automatic input mode detection and switching
- Debounced gesture recognition to prevent accidental switches
- Bottom keyboard area exclusion to avoid conflicts with space bar
- Thread-safe implementation with main-thread enforcement for UI operations
- Comprehensive CI/CD pipeline with GitHub Actions
- Automated .deb package building for rootless jailbreak environments

### Technical Details
- Target: WeChat (com.tencent.xin)
- Architecture: arm64, arm64e
- Packaging: Rootless Theos (iOS 16.5 SDK)
- Build system: Theos with ARC enabled
- Dependencies: mobilesubstrate, preferenceloader, firmware >= 13.0

[0.1.0]: https://github.com/shallot98/WeChatKeyboardSwitch/releases/tag/v0.1.0
