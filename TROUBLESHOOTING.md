# Troubleshooting Guide | 故障排除指南

## Common Issues | 常见问题

### 1. Tweak Not Working | 插件不生效

#### Symptom | 症状
Swipe gestures don't switch input methods in WeChat.

滑动手势无法切换输入法。

#### Solutions | 解决方案

**A. Check if tweak is installed | 检查插件是否已安装**
```bash
ssh root@<device-ip>
dpkg -l | grep wechatkeyboard
```

Expected output: `ii  com.tweak.wechatkeyboardswipe  1.0.0`

**B. Respring SpringBoard | 注销SpringBoard**
```bash
killall -9 SpringBoard
```

**C. Check MobileSubstrate | 检查MobileSubstrate**
```bash
dpkg -l | grep substrate
```
Make sure `mobilesubstrate` is installed.

**D. Verify WeChat bundle ID | 验证微信Bundle ID**
Open WeChat and check if bundle ID matches:
```bash
ps aux | grep WeChat
# Look for com.tencent.xin process
```

**E. Check tweak loading | 检查插件加载**
```bash
# View system logs
tail -f /var/log/syslog | grep WeChat
# or
/var/log/syslog | grep Keyboard
```

---

### 2. Input Method Not Switching | 输入法无法切换

#### Symptom | 症状
Gesture is recognized (haptic feedback works) but input method doesn't change.

手势被识别（有震动反馈）但输入法没有切换。

#### Solutions | 解决方案

**A. Check installed keyboards | 检查已安装的键盘**
1. Go to Settings > General > Keyboard > Keyboards
2. Make sure you have both:
   - English keyboard (e.g., English (US))
   - Chinese keyboard (e.g., Simplified Chinese - Pinyin)

设置 > 通用 > 键盘 > 键盘，确保已添加：
- 英文键盘（如：英语（美国））
- 中文键盘（如：简体中文 - 拼音）

**B. Test keyboard switching manually | 手动测试键盘切换**
Try switching keyboards using the globe icon on the keyboard to verify keyboards are working.

尝试使用键盘上的地球图标手动切换，验证键盘功能正常。

**C. Check language codes | 检查语言代码**
Different iOS versions or regions may use different language codes. The tweak looks for:
- English: `en`, `en-US`, `en_US`
- Chinese: `zh`, `zh-Hans`, `zh_CN`

If your keyboard uses a different code, you may need to modify Tweak.x.

---

### 3. Gesture Conflicts with Typing | 手势与打字冲突

#### Symptom | 症状
Swipe gestures interfere with normal typing.

滑动手势干扰正常打字。

#### Solutions | 解决方案

**A. Adjust swipe technique | 调整滑动技巧**
- Use a quicker, more deliberate swipe motion
- Swipe from the bottom or top edge of keyboard
- Avoid slow dragging motions

使用更快、更明确的滑动动作
从键盘的底部或顶部边缘滑动
避免缓慢的拖动

**B. Check gesture settings | 检查手势设置**
The tweak is configured with:
```objc
gesture.cancelsTouchesInView = NO;
gesture.delaysTouchesEnded = NO;
```

This should prevent interference, but if issues persist, the settings may need adjustment.

---

### 4. WeChat Crashes | 微信崩溃

#### Symptom | 症状
WeChat crashes when keyboard appears.

键盘出现时微信崩溃。

#### Solutions | 解决方案

**A. Check crash logs | 查看崩溃日志**
```bash
ssh root@<device-ip>
cd /var/mobile/Library/Logs/CrashReporter/
ls -lt | head
# Find recent WeChat crash log
cat <crash-log-file>
```

**B. Disable tweak temporarily | 临时禁用插件**
```bash
# Rename plist to disable
mv /Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwipe.plist \
   /Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwipe.plist.disabled
killall -9 WeChat
```

**C. Check iOS version compatibility | 检查iOS版本兼容性**
This tweak is designed for iOS 16. Other versions may have different API structures.

**D. Report issue | 报告问题**
If crashes persist, please report with:
- iOS version
- WeChat version
- Crash log
- Jailbreak type (rootless/rootful)

---

### 5. No Haptic Feedback | 没有触觉反馈

#### Symptom | 症状
Input method switches but no vibration felt.

输入法切换了但没有震动感觉。

#### Solutions | 解决方案

**A. Check haptic settings | 检查触觉反馈设置**
Settings > Sounds & Haptics > System Haptics (should be ON)

设置 > 声音与触感 > 系统触觉反馈（应开启）

**B. This is not critical | 这不是关键功能**
Haptic feedback is a nice-to-have feature. The main functionality (input switching) should still work without it.

---

### 6. Build/Compilation Errors | 编译错误

#### Symptom | 症状
`make package` fails with errors.

编译失败并显示错误。

#### Solutions | 解决方案

**A. Check THEOS installation | 检查THEOS安装**
```bash
echo $THEOS
ls $THEOS
```

**B. Check SDK | 检查SDK**
```bash
ls $THEOS/sdks/
# Should show iPhoneOS16.0.sdk or similar
```

**C. Clean and rebuild | 清理并重新编译**
```bash
make clean
make package
```

**D. Check Xcode Command Line Tools | 检查Xcode命令行工具**
```bash
xcode-select --install
```

**E. Common errors | 常见错误**

Error: `ld: framework not found UIKit`
```bash
# Make sure SDK is properly installed
# Check THEOS_DEVICE_IP is set if installing
```

Error: `logos.pl not found`
```bash
# Reinstall Theos
cd $THEOS
git pull
git submodule update --init --recursive
```

---

### 7. Installation Fails | 安装失败

#### Symptom | 症状
`dpkg -i` returns errors.

dpkg安装返回错误。

#### Solutions | 解决方案

**A. Check dependencies | 检查依赖**
```bash
dpkg -l | grep substrate
# Should show mobilesubstrate installed
```

**B. Fix broken packages | 修复损坏的包**
```bash
dpkg --configure -a
apt-get install -f
```

**C. Check disk space | 检查磁盘空间**
```bash
df -h
# Make sure / has free space
```

**D. Manual installation | 手动安装**
```bash
# Extract and copy manually
dpkg-deb -x package.deb /tmp/extract
cp /tmp/extract/Library/MobileSubstrate/DynamicLibraries/* \
   /Library/MobileSubstrate/DynamicLibraries/
killall -9 SpringBoard
```

---

## Diagnostic Commands | 诊断命令

### Check if tweak is loaded | 检查插件是否加载
```bash
ls -la /Library/MobileSubstrate/DynamicLibraries/ | grep WeChat
```

### View tweak files | 查看插件文件
```bash
cat /Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwipe.plist
```

### Check WeChat process | 检查微信进程
```bash
ps aux | grep WeChat
```

### Monitor system logs | 监控系统日志
```bash
tail -f /var/log/syslog
```

### Check substrate status | 检查substrate状态
```bash
ls -la /Library/MobileSubstrate/DynamicLibraries/*.dylib
```

---

## Uninstall | 卸载

If you need to completely remove the tweak:

```bash
# Via package manager | 通过包管理器
dpkg -r com.tweak.wechatkeyboardswipe

# Or manually | 或手动删除
rm /Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwipe.dylib
rm /Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwipe.plist
killall -9 SpringBoard
```

---

## Getting Help | 获取帮助

If you still have issues after trying these solutions:

1. **Check documentation**
   - [README.md](README.md)
   - [IMPLEMENTATION.md](IMPLEMENTATION.md)
   - [QUICKSTART.md](QUICKSTART.md)

2. **Gather information**
   - iOS version: Settings > General > About > Software Version
   - WeChat version: WeChat > Me > Settings > About
   - Jailbreak type: rootless/rootful
   - Error messages or crash logs

3. **Report issue**
   - Open a GitHub Issue
   - Include all diagnostic information
   - Describe steps to reproduce

4. **Community support**
   - r/jailbreak on Reddit
   - iOS jailbreak forums
   - Theos Discord

---

## Known Limitations | 已知限制

1. **Only works in WeChat** - By design, for safety and performance
2. **Requires both keyboards installed** - Must have Chinese and English keyboards
3. **iOS 16+ only** - Older iOS versions not tested
4. **First-generation keyboard switching** - May not work with all third-party keyboards
5. **No visual indicator** - Only haptic feedback (may add in future version)

---

**Still need help? | 仍需帮助？**

Feel free to open an issue on GitHub with detailed information about your problem.

欢迎在GitHub上提交详细问题报告。
