# Quick Reference Guide

## Quick Start

### Installation
```bash
make package
make install
killall SpringBoard
```

### Enable in Settings
Settings → WeChat Keyboard Switch → Enable (ON)

### Usage
- **Swipe UP** on keyboard → English
- **Swipe DOWN** on keyboard → Chinese

---

## File Structure

```
├── Tweak.xm                               # Main tweak code
├── Makefile                               # Build config (rootless)
├── control                                # Package metadata
├── WeChatKeyboardSwitch.plist            # MobileSubstrate filter
├── wechatkeyboardswitchprefs/            # Settings bundle
│   ├── Makefile                          # Bundle build config
│   ├── entry.plist                       # PreferenceLoader entry
│   ├── Resources/Root.plist              # Settings UI
│   └── WeChatKeyboardSwitchPrefsRootListController.[h|m]
└── layout/Library/PreferenceLoader/      # Installation layout
```

---

## Build Commands

```bash
# Clean build
make clean

# Build package
make package

# Install to device
make install

# Build and install
make do

# Clean all
make clean all
```

---

## Key Components

### Tweak.xm

**Hooks:**
- `UIKeyboardImpl` - Main keyboard view
  - `setDelegate:` - Inject gesture recognizers
  - `handleUpSwipe:` - Switch to English
  - `handleDownSwipe:` - Switch to Chinese

**Functions:**
- `loadPreferences()` - Load settings from plist
- `preferencesChangedCallback()` - Handle settings changes
- `isWeChatKeyboard()` - Check if WeChat keyboard is active
- `switchToInputMode()` - Switch input language

**Classes Used:**
- `UIKeyboardImpl` - Keyboard implementation
- `UIKeyboardInputModeController` - Input mode management
- `UIKeyboardInputMode` - Input mode representation

### Makefile

**Key Settings:**
```makefile
TARGET := iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard
```

### control

**Package Info:**
```
Package: com.yourrepo.wechatkeyboardswitch
Name: WeChat Keyboard Switch
Version: 1.0.0
Depends: mobilesubstrate, preferenceloader, firmware (>= 16.0)
```

---

## Preference Management

### Storage Location (Rootless)
```
/var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist
```

### Preference Keys
- `enabled` (BOOL) - Enable/disable tweak (default: YES)

### Darwin Notification
```
com.yourrepo.wechatkeyboardswitch/prefsChanged
```

### Loading Preferences
```objc
NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
tweakEnabled = [prefs[@"enabled"] boolValue];
```

---

## iOS API Reference

### UIKeyboardImpl
```objc
@interface UIKeyboardImpl : UIView
+ (instancetype)activeInstance;
- (void)setInputMode:(id)mode;
@end
```

### UIKeyboardInputModeController
```objc
@interface UIKeyboardInputModeController : NSObject
+ (instancetype)sharedInputModeController;
- (id)currentInputMode;
- (NSArray *)activeInputModes;
- (void)changeToInputMode:(id)mode;
@end
```

### UIKeyboardInputMode
```objc
@interface UIKeyboardInputMode : NSObject
@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *primaryLanguage;
@end
```

---

## Debugging

### View Logs
```bash
# SSH into device
ssh root@YOUR_DEVICE_IP

# View system log
tail -f /var/log/syslog | grep WeChatKeyboardSwitch

# Or use log stream (iOS 10+)
log stream --predicate 'process == "SpringBoard"' --level debug
```

### Check Installation
```bash
# Verify tweak files
ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwitch.*

# Verify preference bundle
ls -la /var/jb/Library/PreferenceBundles/WeChatKeyboardSwitchPrefs.bundle/

# Check preferences
cat /var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist
```

### Common Issues

**Gestures not working?**
- Check if tweak is enabled in Settings
- Verify WeChat keyboard is active
- Respring device

**Settings not appearing?**
- Reinstall PreferenceLoader
- Check PreferenceLoader entry exists
- Respring device

**Build errors?**
- Verify Theos installation: `echo $THEOS`
- Update Theos: `cd $THEOS && git pull`
- Clean and rebuild: `make clean && make package`

---

## Code Snippets

### Adding a New Preference
```objc
// 1. Add to loadPreferences()
static BOOL newOption = YES;

static void loadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    if (prefs) {
        newOption = [prefs[@"newOption"] boolValue];
    }
}

// 2. Add to Root.plist
<dict>
    <key>cell</key>
    <string>PSSwitchCell</string>
    <key>key</key>
    <string>newOption</string>
    <key>label</key>
    <string>New Option</string>
    ...
</dict>
```

### Adding Debug Logging
```objc
NSLog(@"[WeChatKeyboardSwitch] Debug: %@", variable);
```

### Checking Current Input Mode
```objc
UIKeyboardInputModeController *controller = [objc_getClass("UIKeyboardInputModeController") sharedInputModeController];
UIKeyboardInputMode *currentMode = [controller currentInputMode];
NSLog(@"Current mode: %@ (%@)", currentMode.identifier, currentMode.primaryLanguage);
```

---

## Rootless Paths

### Standard → Rootless Mapping
```
/Library/                    → /var/jb/Library/
/usr/lib/                    → /var/jb/usr/lib/
/var/mobile/                 → /var/jb/var/mobile/
```

### Common Rootless Paths
```
Tweaks:          /var/jb/Library/MobileSubstrate/DynamicLibraries/
PreferenceBundles: /var/jb/Library/PreferenceBundles/
PreferenceLoader:  /var/jb/Library/PreferenceLoader/Preferences/
User Preferences:  /var/jb/var/mobile/Library/Preferences/
```

---

## Package Information

### Version Scheme
```
MAJOR.MINOR.PATCH
1.0.0 = Initial release
1.1.0 = New features
1.0.1 = Bug fixes
```

### Dependencies
- `mobilesubstrate` - Hook framework
- `preferenceloader` - Settings integration
- `firmware (>= 16.0)` - Minimum iOS version

---

## Testing Checklist

- [ ] Builds without errors
- [ ] Installs successfully
- [ ] Settings appear in Settings app
- [ ] Toggle switch works
- [ ] Swipe up switches to English
- [ ] Swipe down switches to Chinese
- [ ] Works in multiple apps
- [ ] No crashes or freezes
- [ ] Preferences persist after respring
- [ ] Real-time toggle enable/disable

---

## Resources

- [Theos Documentation](https://theos.dev)
- [Logos Syntax](https://theos.dev/docs/logos-syntax)
- [iOS Runtime Headers](https://github.com/nst/iOS-Runtime-Headers)
- [r/jailbreakdevelopers](https://www.reddit.com/r/jailbreakdevelopers/)

---

## License

MIT License - See LICENSE file for details

---

**Quick Tip:** Always test on a real device. Simulators don't support jailbreak tweaks!
