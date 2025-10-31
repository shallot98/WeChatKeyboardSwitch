# Changelog

All notable changes to WeChat Keyboard Switch will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-31

### Added
- Initial release of WeChat Keyboard Switch
- Swipe gesture support for keyboard input method switching
  - Swipe UP: Switch to English input mode
  - Swipe DOWN: Switch to Chinese input mode
- Settings bundle integration with iOS Settings app
  - Enable/disable toggle switch
  - Usage instructions in settings
  - About information
- Real-time preference updates via Darwin notifications
- Global keyboard support across all apps
- WeChat/Weixin keyboard detection
- iOS 16+ support with modern APIs
- Full rootless jailbreak compatibility
  - Rootless file paths (`/var/jb`)
  - Rootless package scheme in Makefile
- Comprehensive error handling
- UIKit keyboard framework hooks:
  - UIKeyboardImpl
  - UIKeyboardInputModeController
  - UIKeyboardInputMode
- PreferenceBundle with clean iOS-styled UI
- Automatic gesture recognizer management
- Smooth input mode switching logic

### Technical Details
- Built with Theos framework
- Written in Objective-C with Logos syntax
- Hooks UIKit private keyboard APIs
- Uses UISwipeGestureRecognizer for gesture detection
- Preference storage in rootless-compatible location
- Darwin notification system for settings synchronization
- ARC (Automatic Reference Counting) enabled
- Targets ARM64 architecture (iphoneos-arm64)

### Documentation
- Comprehensive README with usage instructions
- Detailed INSTALLATION guide
- Troubleshooting section
- Developer documentation
- MIT License

### Dependencies
- mobilesubstrate (Cydia Substrate)
- preferenceloader
- firmware >= 16.0

### Compatibility
- iOS 16.0 through iOS 17.x
- Rootless jailbreaks (Dopamine, Palera1n, etc.)
- iPhone and iPad devices

## [Unreleased]

### Planned Features
- Customizable gesture directions
- Support for additional keyboard vendors
- Haptic feedback option
- Sound feedback option
- Keyboard shortcut customization
- Multiple language cycling
- Gesture sensitivity adjustment
- Blacklist/whitelist for specific apps
- Statistics tracking (switch count, usage patterns)

### Under Consideration
- Non-rootless jailbreak support (if requested)
- iOS 15 backport compatibility
- Landscape keyboard optimization
- Third-party keyboard manager compatibility improvements
- Custom input mode ordering

---

## Version History

- **1.0.0** (2024-10-31) - Initial Release

## Notes

### Versioning Scheme

- **Major version** (X.0.0): Breaking changes, major feature overhauls
- **Minor version** (1.X.0): New features, significant improvements, non-breaking changes
- **Patch version** (1.0.X): Bug fixes, minor improvements, documentation updates

### Reporting Issues

If you encounter bugs or have feature requests, please:
1. Check existing issues on GitHub
2. Create a new issue with detailed information
3. Include iOS version, jailbreak type, and steps to reproduce

### Contributing

Contributions are welcome! Please refer to the main README for contribution guidelines.
