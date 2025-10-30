# Rootless Jailbreak Installation Guide

# 无根越狱安装指南

本文档专门针对无根越狱用户（palera1n rootless、Dopamine、XinaA15 等）。

This guide is specifically for rootless jailbreak users (palera1n rootless, Dopamine, XinaA15, etc.).

---

## 什么是无根越狱？ (What is Rootless Jailbreak?)

无根越狱是一种新型的越狱方式，它不修改系统根目录，而是将所有越狱文件安装在 `/var/jb/` 目录下。这种方式更安全，对系统的影响更小。

Rootless jailbreak is a new type of jailbreak that doesn't modify the system root directory. Instead, all jailbreak files are installed in `/var/jb/`. This approach is safer and has less impact on the system.

### 常见的无根越狱工具 (Common Rootless Jailbreak Tools)

- **palera1n** (rootless mode) - iOS 15.0 - 16.5
- **Dopamine** - iOS 15.0 - 16.6.1
- **XinaA15** - iOS 15.0 - 15.1.1

---

## 安装步骤 (Installation Steps)

### 方法一：从源码编译 (Method 1: Build from Source)

1. **确保 Theos 已配置** (Ensure Theos is configured)

```bash
# 检查 Theos 是否安装
echo $THEOS

# 如果未设置，请设置环境变量
export THEOS=/path/to/theos
```

2. **克隆并编译项目** (Clone and build the project)

```bash
git clone <repository-url>
cd WeChatIMEGestureSwitch
make package
```

3. **安装生成的 deb 包** (Install the generated deb package)

编译完成后，包将位于 `packages/` 目录下：

The compiled package will be in the `packages/` directory:

```bash
# 复制到设备
scp packages/com.yourcompany.wechatimegestureswitch_1.0.0_iphoneos-arm64.deb root@<device-ip>:/var/mobile/

# SSH 到设备并安装
ssh root@<device-ip>
cd /var/mobile
dpkg -i com.yourcompany.wechatimegestureswitch_1.0.0_iphoneos-arm64.deb

# 重启 SpringBoard
killall -9 SpringBoard
```

### 方法二：从包管理器安装 (Method 2: Install from Package Manager)

如果插件已添加到 Cydia/Sileo 源：

If the tweak is available in a Cydia/Sileo repository:

1. 打开 Sileo 或 Zebra (Open Sileo or Zebra)
2. 添加源（如果需要）(Add repository if needed)
3. 搜索 "WeChat IME Gesture Switch"
4. 点击安装 (Tap Install)
5. 重启 SpringBoard (Respring)

---

## 验证安装 (Verify Installation)

### 检查包是否已安装 (Check if package is installed)

```bash
dpkg -l | grep wechatimegestureswitch
```

应该看到类似输出：

You should see output similar to:

```
ii  com.yourcompany.wechatimegestureswitch  1.0.0  iphoneos-arm64
```

### 检查文件位置 (Check file location)

在无根越狱环境中，插件文件应该位于：

In rootless jailbreak, the tweak files should be located at:

```bash
ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/ | grep WeChat
```

应该看到：

You should see:

```
-rw-r--r-- 1 root wheel WeChatIMEGestureSwitch.dylib
-rw-r--r-- 1 root wheel WeChatIMEGestureSwitch.plist
```

### 查看日志 (Check logs)

```bash
# 实时查看日志
log stream --predicate 'process == "SpringBoard"' --level debug | grep WeChatIMEGestureSwitch

# 或者查看系统日志
tail -f /var/mobile/Library/Logs/CrashReporter/SpringBoard-*.ips | grep WeChatIMEGestureSwitch
```

成功加载时应该看到：

Upon successful loading, you should see:

```
[WeChatIMEGestureSwitch] ===== Tweak Loaded =====
[WeChatIMEGestureSwitch] iOS 16+ detected. Full compatibility enabled.
[WeChatIMEGestureSwitch] Gesture switch enabled: Swipe UP/DOWN on keyboard to switch input language
```

---

## 常见问题 (FAQ)

### Q: 如何确认我使用的是无根越狱？

**A:** 检查 `/var/jb/` 目录是否存在：

```bash
ls -la /var/jb/
```

如果存在并包含 `usr/`, `Library/` 等目录，说明你使用的是无根越狱。

### Q: 插件安装后不生效？

**A:** 请按以下步骤排查：

1. 确认插件已正确安装：`dpkg -l | grep wechatimegestureswitch`
2. 确认文件在正确位置：`ls /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChat*`
3. 重启 SpringBoard：`killall -9 SpringBoard`
4. 检查日志输出确认插件已加载
5. 确保系统中启用了至少 2 个输入法

### Q: 和有根越狱的区别？

**A:** 从用户角度来说，使用体验完全相同。区别仅在于安装路径：

- 有根越狱：`/Library/MobileSubstrate/`
- 无根越狱：`/var/jb/Library/MobileSubstrate/`

Theos 构建系统会自动处理这些差异。

### Q: 可以在有根和无根越狱之间切换吗？

**A:** 同一个 `.deb` 包同时支持有根和无根越狱。插件会根据运行环境自动适配。

### Q: How do I know if I'm using rootless jailbreak?

**A:** Check if `/var/jb/` directory exists:

```bash
ls -la /var/jb/
```

If it exists and contains `usr/`, `Library/` directories, you're on rootless jailbreak.

### Q: Tweak not working after installation?

**A:** Troubleshooting steps:

1. Verify installation: `dpkg -l | grep wechatimegestureswitch`
2. Check file location: `ls /var/jb/Library/MobileSubstrate/DynamicLibraries/WeChat*`
3. Respring: `killall -9 SpringBoard`
4. Check logs to confirm tweak is loaded
5. Ensure at least 2 input languages are enabled in system settings

### Q: Difference from rooted jailbreak?

**A:** From a user perspective, the experience is identical. The only difference is the installation path:

- Rooted: `/Library/MobileSubstrate/`
- Rootless: `/var/jb/Library/MobileSubstrate/`

Theos build system handles these differences automatically.

---

## 技术细节 (Technical Details)

### Makefile 配置 (Makefile Configuration)

项目的 Makefile 中已经启用了 rootless 支持：

Rootless support is enabled in the project's Makefile:

```makefile
THEOS_PACKAGE_SCHEME = rootless
```

这一行告诉 Theos 构建系统生成兼容无根越狱的包。

This line tells the Theos build system to generate rootless-compatible packages.

### 依赖处理 (Dependency Handling)

`control` 文件中的依赖项使用了灵活的 OR 语法：

The dependencies in the `control` file use flexible OR syntax:

```
Depends: mobilesubstrate (>= 0.9.5000) | substitute (>= 2.0)
```

这确保了包可以与不同的 hook 框架一起工作。

This ensures the package works with different hooking frameworks.

### 自动路径处理 (Automatic Path Handling)

Theos 会根据 `THEOS_PACKAGE_SCHEME` 自动调整：

Theos automatically adjusts based on `THEOS_PACKAGE_SCHEME`:

- 安装路径 (Install paths)
- 依赖路径 (Dependency paths)  
- 库路径 (Library paths)

无需在代码中硬编码任何路径。

No need to hardcode any paths in the code.

---

## 卸载 (Uninstallation)

```bash
# SSH 到设备
ssh root@<device-ip>

# 卸载包
dpkg -r com.yourcompany.wechatimegestureswitch

# 或使用包管理器卸载
# Or uninstall via package manager

# 重启 SpringBoard
killall -9 SpringBoard
```

---

## 支持 (Support)

如果遇到问题，请：

If you encounter issues, please:

1. 检查日志输出 (Check log output)
2. 提交 Issue 到项目仓库 (Submit an issue to the repository)
3. 包含以下信息 (Include the following information):
   - iOS 版本 (iOS version)
   - 越狱工具和版本 (Jailbreak tool and version)
   - 设备型号 (Device model)
   - 完整的日志输出 (Complete log output)

---

## 相关资源 (Related Resources)

- [Theos Documentation](https://theos.dev)
- [palera1n](https://palera.in)
- [Dopamine Jailbreak](https://github.com/opa334/Dopamine)
- [r/jailbreak](https://reddit.com/r/jailbreak)

---

**注意**: 无根越狱是相对较新的技术，请确保使用最新版本的越狱工具和包管理器。

**Note**: Rootless jailbreak is a relatively new technology. Please ensure you're using the latest versions of jailbreak tools and package managers.
