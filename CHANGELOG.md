# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-01-01

### Added
- 🎉 Initial release
- ✨ Gesture recognition for keyboard input switching
  - Swipe up/down on keyboard to switch input languages
  - Uses `UISwipeGestureRecognizer` for gesture detection
- ✨ iOS 16+ compatibility
  - System version check with `isIOS16OrLater()`
  - Optimized for iOS 16.0 - 16.5
- ✨ Global keyboard injection
  - Hooks `UIInputView` for universal keyboard support
  - Works in all apps, not just WeChat
  - Injected into SpringBoard for system-wide effect
- ✨ WeChat keyboard class traversal
  - Runtime API to enumerate keyboard-related classes
  - Comprehensive logging for debugging
  - Searches for WeChat, Keyboard, InputView, and related patterns
- ✨ Rootless jailbreak support
  - Full compatibility with rootless environments (palera1n, Dopamine, XinaA15)
  - `THEOS_PACKAGE_SCHEME = rootless` enabled in Makefile
  - Automatic path handling by Theos build system
  - Flexible dependencies: mobilesubstrate OR substitute
- 📝 Comprehensive documentation
  - Detailed README in Chinese and English
  - Installation instructions for both rooted and rootless jailbreaks
  - Debugging guide with log monitoring commands
  - Troubleshooting section
- 🐛 Debug logging system
  - Console output for all major events
  - Tweak load confirmation
  - iOS version detection
  - Class traversal results
  - Gesture events and input mode switching

### Technical Details
- Hooks `UIInputView` lifecycle method `didMoveToWindow`
- Adds gesture recognizers dynamically to keyboard views
- Uses Associated Objects to track gesture recognizer state
- Prevents duplicate gesture recognizer additions
- Cycles through available input modes using `UITextInputMode` API
- Constructor logs initialization and system compatibility

### Supported Environments
- **iOS Versions**: 16.0 - 16.5
- **Architectures**: arm64, arm64e
- **Jailbreaks**:
  - ✅ Rooted: checkra1n, unc0ver, Taurine
  - ✅ Rootless: palera1n (rootless), Dopamine, XinaA15
- **Substrates**: Cydia Substrate 0.9.5000+, Substitute 2.0+

### Known Issues
- May not work with some third-party input methods
- Rare conflicts with other keyboard tweaks possible
- Requires at least 2 input languages enabled in system settings

### Dependencies
- mobilesubstrate (>= 0.9.5000) | substitute (>= 2.0)
- firmware (>= 16.0)

---

## Release Notes

This is the initial release of WeChat IME Gesture Switch, providing a convenient gesture-based input method switching experience for iOS 16+ devices. The tweak has been designed with both traditional rooted and modern rootless jailbreak environments in mind, ensuring maximum compatibility across different setups.

### Highlights

🚀 **Universal Compatibility**: Works on both rooted and rootless jailbreaks without requiring separate builds or configurations.

⚡ **Zero Configuration**: Installs and works immediately after respring - no settings to configure.

🔍 **Developer-Friendly**: Extensive logging makes it easy to debug and understand tweak behavior.

🌐 **Global Effect**: Works system-wide in any app that uses the standard iOS keyboard.

### Future Plans

- Support for customizable gesture directions
- Preference bundle for user configuration
- Support for iOS 17+
- More input method switching modes (e.g., cycle in reverse, specific language selection)
- Performance optimizations
- Additional gesture types (long press, multi-finger swipes)
