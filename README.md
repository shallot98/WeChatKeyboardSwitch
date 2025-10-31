# WeChat Keyboard Switch

A jailbreak tweak that enables Chinese/English input method switching via keyboard swipe gestures when using WeChat keyboard globally across all apps.

## Features

- 🔄 **Quick Input Switching**: Swipe up/down on keyboard to switch between Chinese and English
- ⚙️ **Settings Toggle**: Enable/disable the tweak from iOS Settings app
- 🌍 **Global Support**: Works in all apps when WeChat keyboard is active
- 🎯 **WeChat Keyboard Only**: Specifically targets WeChat/Weixin input methods
- 🔋 **Lightweight**: Minimal performance impact
- 📱 **Modern iOS**: Full support for iOS 16, 17, and newer versions
- 🪝 **Rootless Ready**: Complete rootless jailbreak support

## Installation

### Prerequisites

- iOS 16.0 or later
- Rootless jailbreak (Dopamine, Palera1n, etc.)
- Theos build system (for building from source)
- WeChat keyboard/input method installed and enabled

### From Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/WeChatKeyboardSwitch.git
cd WeChatKeyboardSwitch
```

2. Make sure Theos is properly set up:
```bash
export THEOS=/path/to/theos
```

3. Build the tweak:
```bash
make package
```

4. Install the generated .deb file:
```bash
make install
# or manually install with your package manager
```

5. Respring your device

### From Package Manager

(If published to a repository)

1. Add the repository to your package manager
2. Search for "WeChat Keyboard Switch"
3. Install the package
4. Respring your device

## Usage

### Setup

1. Make sure WeChat keyboard is installed and added to your keyboard list:
   - Go to **Settings → General → Keyboard → Keyboards**
   - Add WeChat/Weixin keyboard if not already added

2. Enable the tweak:
   - Open **Settings** app
   - Scroll down to find **WeChat Keyboard Switch**
   - Toggle **Enable** switch to ON

3. Respring for changes to take effect (optional but recommended)

### Gestures

Once enabled, when WeChat keyboard is active in any app:

- **Swipe UP** on keyboard → Switch to **English** input mode
- **Swipe DOWN** on keyboard → Switch to **Chinese** input mode

The tweak automatically detects when WeChat keyboard is active and only responds to gestures in that context.

## Configuration

The tweak stores preferences in the rootless-compatible location:
```
/var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist
```

Preferences are loaded on tweak initialization and updated in real-time via Darwin notifications when changed in Settings.

## Compatibility

### iOS Versions
- ✅ iOS 16.0 - 16.7
- ✅ iOS 17.0+
- ✅ Future iOS versions (as long as keyboard APIs remain compatible)

### Jailbreak Types
- ✅ Rootless jailbreaks (Dopamine, Palera1n)
- ✅ Semi-untethered jailbreaks
- ✅ Checkra1n-based setups

### Device Support
- ✅ iPhone (all models running iOS 16+)
- ✅ iPad (all models running iOS 16+)

## Technical Details

### Architecture

The tweak hooks into iOS keyboard frameworks using Logos syntax:

- **UIKeyboardImpl**: Main keyboard implementation class
- **UIKeyboardInputModeController**: Manages input mode switching
- **UIKeyboardInputMode**: Represents individual input modes

### Key Components

1. **Gesture Recognition**: UISwipeGestureRecognizer instances added to keyboard view
2. **Input Mode Detection**: Identifies WeChat keyboard by bundle identifier and language
3. **Preference Management**: Darwin notifications for real-time settings updates
4. **Rootless Paths**: All file operations use `/var/jb` prefix

### Files

- `Tweak.xm` - Main tweak implementation with hooks
- `Makefile` - Build configuration for rootless
- `control` - Package metadata
- `WeChatKeyboardSwitch.plist` - MobileSubstrate filter (UIKit bundle)
- `wechatkeyboardswitchprefs/` - PreferenceBundle for Settings integration

## Troubleshooting

### Gestures Not Working

1. **Check if tweak is enabled**:
   - Go to Settings → WeChat Keyboard Switch
   - Ensure "Enable" toggle is ON

2. **Verify WeChat keyboard is active**:
   - The tweak only works when WeChat/Weixin keyboard is the current input method
   - Switch to WeChat keyboard before attempting gestures

3. **Respring the device**:
   ```bash
   killall SpringBoard
   ```

4. **Check tweak injection**:
   - Make sure the tweak is properly installed in `/var/jb/Library/MobileSubstrate/DynamicLibraries/`

### Settings Not Appearing

1. **Check PreferenceLoader**:
   - Ensure PreferenceLoader is installed
   - Respring after installing the tweak

2. **Verify preference bundle installation**:
   ```bash
   ls /var/jb/Library/PreferenceBundles/ | grep WeChatKeyboardSwitch
   ```

### Input Mode Not Switching

1. **Ensure multiple WeChat input modes are enabled**:
   - You need both Chinese and English WeChat keyboard variants added
   - Go to Settings → General → Keyboard → Keyboards

2. **Check logs for errors**:
   ```bash
   # Use your preferred logging tool
   syslog | grep WeChatKeyboardSwitch
   ```

## Building from Source

### Requirements

- macOS or Linux with Theos installed
- iOS SDK (comes with Xcode or Theos)
- ARM64 compiler toolchain

### Build Commands

```bash
# Clean build
make clean

# Build for debugging
make DEBUG=1

# Build package
make package

# Install to device via SSH
make install THEOS_DEVICE_IP=your.device.ip THEOS_DEVICE_PORT=22

# Build and install in one command
make do
```

## Development

### Project Structure

```
WeChatKeyboardSwitch/
├── Tweak.xm                          # Main tweak code
├── Makefile                          # Build configuration
├── control                           # Package metadata
├── WeChatKeyboardSwitch.plist       # MobileSubstrate filter
├── wechatkeyboardswitchprefs/       # Settings bundle
│   ├── Makefile
│   ├── entry.plist
│   ├── WeChatKeyboardSwitchPrefsRootListController.h
│   ├── WeChatKeyboardSwitchPrefsRootListController.m
│   └── Resources/
│       └── Root.plist               # Settings UI definition
└── README.md
```

### Adding Features

To modify or extend the tweak:

1. Edit `Tweak.xm` for functionality changes
2. Update `Resources/Root.plist` for new settings
3. Rebuild and test on device

### Debugging

Enable debug logging by modifying the tweak code to include NSLog statements:

```objc
NSLog(@"[WeChatKeyboardSwitch] Debug message: %@", someVariable);
```

View logs in real-time:
```bash
ssh root@device.ip
tail -f /var/log/syslog | grep WeChatKeyboardSwitch
```

## Known Issues

- Some third-party keyboard managers may interfere with gesture recognition
- Very fast swipes might not register consistently - moderate swipe speed recommended
- First gesture after keyboard appears may have slight delay while gesture recognizers initialize

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on your device
5. Submit a pull request

## License

This project is provided as-is for educational and personal use. 

## Credits

- Developed for the jailbreak community
- Built with Theos framework
- Uses iOS private APIs for keyboard manipulation

## Disclaimer

This tweak modifies system behavior and requires a jailbroken device. Use at your own risk. The author is not responsible for any damage or data loss that may occur from using this tweak.

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Contact via email (if provided)
- Join discussion on relevant jailbreak forums/subreddits

## Changelog

### Version 1.0.0 (Initial Release)
- ✨ Initial implementation
- ✨ Swipe up/down gesture support
- ✨ Settings bundle with enable toggle
- ✨ iOS 16+ support
- ✨ Full rootless compatibility
- ✨ Real-time preference updates
- ✨ Global keyboard support

---

**Enjoy seamless Chinese/English switching with WeChat keyboard! 🎉**
