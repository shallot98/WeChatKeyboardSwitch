# Quick Start Guide

# 快速开始指南

---

## 🚀 5分钟上手 (5-Minute Setup)

### 第一步：确认你的越狱类型 (Step 1: Check Your Jailbreak Type)

#### 有根越狱？(Rooted?)
```bash
ls /Library/MobileSubstrate/
```
如果这个目录存在 → **有根越狱**

#### 无根越狱？(Rootless?)
```bash
ls /var/jb/Library/
```
如果这个目录存在 → **无根越狱**

---

### 第二步：安装插件 (Step 2: Install the Tweak)

#### 方法 A: 从包管理器安装 (Via Package Manager)
1. 打开 Sileo/Cydia/Zebra
2. 搜索 "WeChat IME Gesture Switch"
3. 点击安装
4. 重启 SpringBoard

#### 方法 B: 从 deb 文件安装 (Via .deb File)
```bash
# 下载或传输 .deb 文件到设备
dpkg -i com.yourcompany.wechatimegestureswitch_1.0.0_iphoneos-arm64.deb

# 重启 SpringBoard
killall -9 SpringBoard
```

---

### 第三步：验证安装 (Step 3: Verify Installation)

打开任意应用（如备忘录），调出键盘，查看日志：

Open any app (like Notes), bring up the keyboard, and check logs:

```bash
log stream --predicate 'process == "SpringBoard"' --level debug | grep WeChatIMEGestureSwitch
```

你应该看到：

You should see:

```
[WeChatIMEGestureSwitch] ===== Tweak Loaded =====
[WeChatIMEGestureSwitch] iOS 16+ detected. Full compatibility enabled.
```

✅ **成功！现在可以使用了** (Success! Ready to use)

---

### 第四步：使用插件 (Step 4: Use the Tweak)

1. 打开任意应用（微信、备忘录、Safari等）
2. 点击文本框调出键盘
3. **在键盘上向上滑动** 或 **向下滑动**
4. 输入法将自动切换！

**注意**: 确保系统中启用了至少 2 个输入法

**Note**: Ensure at least 2 input languages are enabled in system settings

---

## 🎯 核心功能 (Core Features)

| 功能 | 描述 |
|------|------|
| 👆 **上划切换** | 在键盘上向上滑动切换输入法 |
| 👇 **下划切换** | 在键盘上向下滑动切换输入法 |
| 🌐 **全局生效** | 在任何应用中都可使用 |
| ⚡ **零配置** | 安装即用，无需设置 |
| 🔄 **循环切换** | 在所有已启用的输入法间循环 |

---

## ⚙️ 系统要求 (System Requirements)

| 项目 | 要求 |
|------|------|
| iOS 版本 | 16.0 或更高 |
| 越狱类型 | 有根或无根越狱均可 |
| 架构 | arm64 / arm64e |
| 依赖 | mobilesubstrate 或 substitute |

---

## 🔧 常见问题 (Common Issues)

### ❌ 手势不响应

**解决方案:**
1. 确认至少启用了 2 个输入法
   - 设置 → 通用 → 键盘 → 键盘
2. 重启 SpringBoard
   ```bash
   killall -9 SpringBoard
   ```
3. 检查插件是否加载
   ```bash
   dpkg -l | grep wechatimegestureswitch
   ```

### ❌ 安装后无效果

**解决方案:**
1. 检查文件是否在正确位置
   
   **有根越狱:**
   ```bash
   ls /Library/MobileSubstrate/DynamicLibraries/WeChat*
   ```
   
   **无根越狱:**
   ```bash
   ls /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChat*
   ```

2. 重新安装
   ```bash
   dpkg -r com.yourcompany.wechatimegestureswitch
   dpkg -i com.yourcompany.wechatimegestureswitch_*.deb
   killall -9 SpringBoard
   ```

### ❌ 日志无输出

**解决方案:**
1. 确认 SpringBoard 已重启
2. 尝试使用 syslog 查看
   ```bash
   tail -f /var/log/syslog | grep WeChatIMEGestureSwitch
   ```
3. 检查插件是否被禁用
   - 某些越狱工具有插件管理功能

---

## 📱 支持的越狱工具 (Supported Jailbreaks)

### ✅ 有根越狱 (Rooted)
- checkra1n
- unc0ver
- Taurine
- Chimera

### ✅ 无根越狱 (Rootless)
- palera1n (rootless mode)
- Dopamine
- XinaA15
- Fugu15

---

## 🎓 使用技巧 (Usage Tips)

### 💡 最佳实践

1. **启用常用输入法**
   - 中文简体拼音
   - English
   - 其他你常用的语言

2. **滑动位置**
   - 在键盘的**中间区域**滑动效果最好
   - 避免在键盘边缘或按键上滑动

3. **滑动速度**
   - 快速滑动即可
   - 不需要长按或慢速滑动

4. **多次切换**
   - 如果有 3+ 个输入法，继续滑动可循环切换
   - 每次滑动切换到下一个输入法

### 📊 输入法切换顺序示例

假设启用了 3 个输入法：

Assuming 3 input languages are enabled:

```
中文 (Chinese) → English → 日本語 (Japanese) → 中文 (循环)
    ↓ 滑动         ↓ 滑动        ↓ 滑动         ↺
```

---

## 🔍 调试模式 (Debug Mode)

### 查看实时日志 (View Real-time Logs)

```bash
# 方法 1: log stream
log stream --predicate 'process == "SpringBoard"' --level debug | grep WeChatIMEGestureSwitch

# 方法 2: syslog
tail -f /var/log/syslog | grep WeChatIMEGestureSwitch

# 方法 3: Console.app (macOS)
# 连接设备到 Mac，打开 Console.app
# 搜索 "WeChatIMEGestureSwitch"
```

### 日志内容说明 (Log Explanation)

```
[WeChatIMEGestureSwitch] ===== Tweak Loaded =====
# → 插件已加载

[WeChatIMEGestureSwitch] iOS 16+ detected. Full compatibility enabled.
# → 系统版本检查通过

[WeChatIMEGestureSwitch] UIInputView didMoveToWindow: UISystemKeyboardDockController
# → 键盘显示，手势识别器即将添加

[WeChatIMEGestureSwitch] Added gesture recognizers to: UISystemKeyboardDockController
# → 手势识别器添加成功

[WeChatIMEGestureSwitch] Swipe UP detected on: UIInputView
# → 检测到上划手势

[WeChatIMEGestureSwitch] Current input mode: en-US
# → 当前输入法：英文

[WeChatIMEGestureSwitch] Switching to: zh-Hans
# → 正在切换到：中文简体
```

---

## 🆘 获取帮助 (Get Help)

### 问题报告 (Report Issues)

提交 Issue 时请包含：

When submitting an issue, please include:

1. **设备信息** (Device Info)
   - 设备型号: iPhone XX
   - iOS 版本: 16.x
   - 越狱工具: palera1n / Dopamine / etc.

2. **问题描述** (Problem Description)
   - 详细描述问题
   - 预期行为 vs 实际行为

3. **日志输出** (Log Output)
   - 完整的相关日志
   - 错误信息（如果有）

4. **重现步骤** (Reproduction Steps)
   - 如何重现问题
   - 是否可稳定重现

### 社区支持 (Community Support)

- GitHub Issues: <repository-url>/issues
- r/jailbreak: 搜索或发帖
- Discord: 相关越狱社区

---

## 📚 更多文档 (More Documentation)

| 文档 | 描述 |
|------|------|
| **README.md** | 完整的项目说明和使用指南 |
| **ROOTLESS.md** | 无根越狱专用安装指南 |
| **ROOTLESS_SUMMARY.md** | 无根越狱支持技术细节 |
| **CHANGELOG.md** | 版本历史和更新日志 |
| **LICENSE** | MIT 开源许可证 |

---

## ⚡ 快速命令参考 (Quick Command Reference)

```bash
# 安装
dpkg -i <package.deb>

# 卸载
dpkg -r com.yourcompany.wechatimegestureswitch

# 重启 SpringBoard
killall -9 SpringBoard

# 查看已安装的插件
dpkg -l | grep wechatimegestureswitch

# 查看文件位置（有根）
ls -la /Library/MobileSubstrate/DynamicLibraries/WeChat*

# 查看文件位置（无根）
ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChat*

# 查看日志
log stream --predicate 'process == "SpringBoard"' | grep WeChatIMEGestureSwitch

# 检查依赖
dpkg -l | grep -E "mobilesubstrate|substitute"
```

---

## 🎉 完成！(Done!)

现在你已经完成了 WeChat IME Gesture Switch 的安装和配置！

You've now completed the installation and setup of WeChat IME Gesture Switch!

**享受流畅的输入法切换体验吧！**

**Enjoy the smooth input method switching experience!**

---

## 📞 联系方式 (Contact)

- **Issues**: <repository-url>/issues
- **Email**: your.email@example.com
- **Reddit**: r/jailbreak

---

**版本**: 1.0.0  
**更新**: 2024-01-01  
**许可**: MIT License
