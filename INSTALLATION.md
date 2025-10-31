# Installation Guide

## Prerequisites

Before installing WeChat Keyboard Switch, ensure you have:

1. **Jailbroken iOS Device**
   - iOS 16.0 or later
   - Rootless jailbreak (Dopamine, Palera1n, etc.)

2. **Required Dependencies**
   - MobileSubstrate (Cydia Substrate)
   - PreferenceLoader
   - WeChat/Weixin keyboard installed and enabled

3. **Build Tools (for building from source)**
   - Theos framework
   - iOS SDK
   - SSH access to your device

## Method 1: Install from Pre-built Package

If you have a pre-built .deb file:

### Using SSH

1. Copy the .deb file to your device:
```bash
scp com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb root@YOUR_DEVICE_IP:/var/root/
```

2. SSH into your device:
```bash
ssh root@YOUR_DEVICE_IP
```

3. Install the package:
```bash
dpkg -i /var/root/com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb
```

4. Respring:
```bash
killall SpringBoard
```

### Using Package Manager

If the package is in a repository:

1. Open your package manager (Sileo, Zebra, Installer, etc.)
2. Add the repository URL (if not already added)
3. Refresh sources
4. Search for "WeChat Keyboard Switch"
5. Tap Install
6. Respring when prompted

## Method 2: Build and Install from Source

### Step 1: Set Up Theos

If you haven't installed Theos yet:

```bash
# Install Theos dependencies (on macOS)
brew install ldid xz

# Clone Theos
git clone --recursive https://github.com/theos/theos.git ~/theos

# Set environment variable
echo "export THEOS=~/theos" >> ~/.zshrc
source ~/.zshrc
```

### Step 2: Clone the Repository

```bash
git clone https://github.com/yourusername/WeChatKeyboardSwitch.git
cd WeChatKeyboardSwitch
```

### Step 3: Configure Device Connection

Create a `.theos` directory with device configuration:

```bash
# Set up your device IP and port
echo "YOUR_DEVICE_IP" > .theos/device_ip
echo "22" > .theos/device_port
```

Or set environment variables:

```bash
export THEOS_DEVICE_IP=192.168.1.XXX
export THEOS_DEVICE_PORT=22
```

### Step 4: Build the Package

```bash
make clean
make package
```

This will create a .deb file in the `packages/` directory.

### Step 5: Install to Device

**Option A: Direct Install via SSH**

```bash
make install
```

This will automatically build, package, and install to your device via SSH.

**Option B: Manual Install**

1. Copy the .deb file to your device:
```bash
scp packages/com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb root@YOUR_DEVICE_IP:/var/root/
```

2. SSH into device and install:
```bash
ssh root@YOUR_DEVICE_IP
dpkg -i /var/root/com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb
killall SpringBoard
```

## Post-Installation Setup

### 1. Enable WeChat Keyboard

If you haven't already:

1. Open **Settings** → **General** → **Keyboard** → **Keyboards**
2. Tap **Add New Keyboard**
3. Find and add **WeChat** or **Weixin** keyboard
4. Make sure both Chinese and English variants are added (if available)

### 2. Configure the Tweak

1. Open **Settings** app
2. Scroll down to find **WeChat Keyboard Switch**
3. Toggle **Enable** to ON
4. Read the usage instructions in the Settings pane

### 3. Test the Functionality

1. Open any app with text input (Messages, Notes, Safari, etc.)
2. Tap on a text field to bring up the keyboard
3. Switch to WeChat keyboard
4. Try the gestures:
   - **Swipe UP** on the keyboard → Should switch to English
   - **Swipe DOWN** on the keyboard → Should switch to Chinese

## Verification

### Check Installation

Verify the tweak files are installed correctly:

```bash
ssh root@YOUR_DEVICE_IP

# Check tweak dylib
ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwitch.*

# Check preference bundle
ls -la /var/jb/Library/PreferenceBundles/WeChatKeyboardSwitchPrefs.bundle/

# Check preference loader entry
ls -la /var/jb/Library/PreferenceLoader/Preferences/WeChatKeyboardSwitchPrefs.plist

# Check preferences file (after changing settings)
ls -la /var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist
```

### Check Logs

Monitor system logs for any errors:

```bash
# On device via SSH
tail -f /var/log/syslog | grep -i wechat

# Or using other logging tools
log stream --predicate 'process == "SpringBoard"' | grep WeChatKeyboardSwitch
```

## Troubleshooting

### Tweak Not Loading

1. **Check MobileSubstrate is working:**
```bash
ls /var/jb/Library/MobileSubstrate/DynamicLibraries/
```

2. **Verify filter plist:**
```bash
cat /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwitch.plist
```

3. **Re-inject MobileSubstrate:**
```bash
# Method depends on your jailbreak
killall SpringBoard
```

### Settings Not Appearing

1. **Reinstall PreferenceLoader:**
   - Open your package manager
   - Reinstall PreferenceLoader
   - Respring

2. **Check preference loader entry:**
```bash
cat /var/jb/Library/PreferenceLoader/Preferences/WeChatKeyboardSwitchPrefs.plist
```

### Build Errors

1. **"THEOS not found":**
```bash
export THEOS=~/theos
# Or wherever you installed Theos
```

2. **"SDK not found":**
```bash
# Make sure you have iOS SDK
ls $THEOS/sdks/
# If empty, download iOS SDK and place in $THEOS/sdks/
```

3. **"Target not supported":**
   - Make sure you're using latest Theos
   - Update Theos: `cd $THEOS && git pull`

## Uninstallation

### Via Package Manager

1. Open your package manager
2. Find "WeChat Keyboard Switch"
3. Tap Remove/Uninstall
4. Respring when prompted

### Via Command Line

```bash
ssh root@YOUR_DEVICE_IP
dpkg -r com.yourrepo.wechatkeyboardswitch
killall SpringBoard
```

### Manual Cleanup (if needed)

```bash
ssh root@YOUR_DEVICE_IP

# Remove tweak files
rm /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwitch.*

# Remove preference bundle
rm -rf /var/jb/Library/PreferenceBundles/WeChatKeyboardSwitchPrefs.bundle/

# Remove preference loader entry
rm /var/jb/Library/PreferenceLoader/Preferences/WeChatKeyboardSwitchPrefs.plist

# Remove preferences
rm /var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist

# Respring
killall SpringBoard
```

## Update Instructions

### Via Package Manager

Updates will appear automatically in your package manager. Simply tap Update.

### Manual Update

1. Build the new version:
```bash
make clean
make package
```

2. Install over the old version:
```bash
make install
# or manually install the new .deb
```

3. Respring

## Support

If you encounter issues:

1. Check the main [README.md](README.md) troubleshooting section
2. Review system logs for error messages
3. Open an issue on GitHub with:
   - iOS version
   - Jailbreak type and version
   - Error logs
   - Steps to reproduce

## Notes

- **Rootless paths**: All paths use `/var/jb` prefix for rootless jailbreak compatibility
- **Respring**: Always respring after installation or changing settings
- **Backup**: It's recommended to create a device backup before installing tweaks
- **Safety**: This tweak only hooks keyboard-related classes and doesn't modify system files

---

For more information, see the main [README.md](README.md) file.
