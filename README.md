# WeChat Keyboard Switch

A minimal Theos-based iOS tweak skeleton for rootless jailbreak targeting iOS 16.5.

## Overview

This is a basic rootless tweak skeleton configured for iOS 16.5+ development.

## Requirements

- iOS 16.5 or later
- Rootless jailbreak (Dopamine, Palera1n, etc.)
- Theos build system

## Building

```bash
export THEOS=/path/to/theos
make package
```

This will generate a `.deb` package that installs to rootless paths (`/var/jb`).

## Installation

```bash
make install THEOS_DEVICE_IP=<device-ip> THEOS_DEVICE_PORT=22
```

Or manually install the generated `.deb` file using your preferred package manager.

## Configuration

- **Bundle ID**: `com.example.wechatkeyboardswitch`
- **Version**: 1.0.0
- **Target**: iOS 16.5+
- **Architecture**: arm64
- **Jailbreak Type**: Rootless

## Dependencies

- `mobilesubstrate`
- `firmware (>= 15.0)`

## License

MIT License - see LICENSE file for details.

## Structure

```
.
├── Tweak.x                      # Main tweak implementation
├── Makefile                     # Build configuration
├── control                      # Package metadata
├── WeChatKeyboardSwitch.plist  # MobileSubstrate filter
├── layout/                      # Rootless install layout
└── LICENSE                      # MIT License
```

## Notes

This is a skeleton project intended as a starting point for tweak development. The tweak currently logs a message on SpringBoard launch to verify proper injection.
