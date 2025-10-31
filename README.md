# WeChat IME Gesture Switch (微信输入法手势切换)

一个iOS越狱插件，为微信输入法添加手势切换功能，支持通过上下滑动快速切换中英文输入。

An iOS jailbreak tweak that adds gesture switching to WeChat input method, allowing quick language switching via swipe gestures.

## 功能特性 (Features)

- ✅ **手势识别**: 在键盘上上划/下划切换输入语言
- ✅ **全局生效**: 在任何应用的输入法中都可使用
- ✅ **iOS 16 兼容**: 专门优化支持 iOS 16+ 系统
- ✅ **无根越狱支持**: 完全兼容 rootless 越狱环境 (palera1n, Dopamine 等)
- ✅ **调试日志**: 输出详细的类遍历和手势事件日志
- ✅ **零配置**: 安装后自动生效，无需额外设置
- ✅ **CI/CD 自动构建**: GitHub Actions 自动编译并发布 rootless 版本

## 系统要求 (Requirements)

- iOS 16.0 或更高版本
- 已越狱设备 (支持有根和无根越狱)
- 安装 Cydia Substrate / Substitute (版本 2.0+)

## 安装方法 (Installation)

### GitHub Actions 自动构建 (Automated Build via GitHub Actions)

本项目支持通过 GitHub Actions 自动编译 rootless 版本！

This project supports automated builds via GitHub Actions for rootless jailbreak!

**下载预编译包 (Download Pre-built Package):**
1. 访问 [Actions](../../actions) 页面
2. 选择最新的成功构建
3. 在 Artifacts 中下载 `.deb` 文件
4. 传输到设备并安装

**For tag releases:**
1. 访问 [Releases](../../releases) 页面
2. 下载最新版本的 `.deb` 文件

详细文档: [CI/CD 工作流文档](.github/workflows/README.md)

### 从源码编译 (Build from Source)

1. 确保已安装 [Theos](https://theos.dev/)
2. 克隆仓库并编译:

```bash
git clone <repository-url>
cd <repository-name>
make package
```

3. 安装生成的 `.deb` 文件:

```bash
dpkg -i packages/com.yourcompany.wechatimegestureswitch_1.0.0_iphoneos-arm64.deb
```

4. 重启 SpringBoard:

```bash
killall -9 SpringBoard
```

### 从 Cydia/Sileo 安装 (Install from Package Manager)

1. 添加源 (Add Repository)
2. 搜索 "WeChat IME Gesture Switch"
3. 点击安装 (Install)
4. 重启设备 (Respring)

### 无根越狱说明 (Rootless Jailbreak Notes)

本插件完全支持无根越狱环境！编译时 Theos 会自动处理文件路径：

- **有根越狱**: 安装到 `/Library/MobileSubstrate/DynamicLibraries/`
- **无根越狱**: 安装到 `/var/jb/Library/MobileSubstrate/DynamicLibraries/`

无需任何额外配置，`THEOS_PACKAGE_SCHEME = rootless` 已在 Makefile 中启用。

This tweak fully supports rootless jailbreak! Theos automatically handles file paths:

- **Rooted**: Installs to `/Library/MobileSubstrate/DynamicLibraries/`
- **Rootless**: Installs to `/var/jb/Library/MobileSubstrate/DynamicLibraries/`

No additional configuration needed - `THEOS_PACKAGE_SCHEME = rootless` is enabled in the Makefile.

## 使用方法 (Usage)

1. 打开任意应用并调出键盘
2. 在键盘区域向上或向下滑动
3. 输入法将自动切换到下一个语言
4. 继续滑动可以在所有已启用的输入法之间循环切换

### 注意事项 (Notes)

- 确保在系统设置中启用了至少两个输入法
- 建议启用"中文简体拼音"和"English"以获得最佳体验
- 手势需要在键盘视图上进行，不要在文本框上滑动

## 调试 (Debugging)

插件会输出详细的日志信息，可以通过以下方式查看:

```bash
# 实时查看日志
sudo log stream --predicate 'process == "SpringBoard"' --level debug | grep WeChatIMEGestureSwitch

# 或使用传统方式
tail -f /var/log/syslog | grep WeChatIMEGestureSwitch
```

### 日志输出内容 (Log Output)

- iOS 版本检查
- 遍历的键盘相关类列表
- 手势识别器添加事件
- 手势触发事件
- 当前和切换后的输入法信息

## 技术实现 (Technical Details)

### 核心技术

- **Runtime API**: 动态遍历查找键盘相关类
- **Method Swizzling**: Hook UIInputView 和 UIKeyboardImpl
- **Gesture Recognizers**: UISwipeGestureRecognizer 实现手势检测
- **Associated Objects**: 避免重复添加手势识别器

### Hook 的类

- `UIInputView`: 主要的键盘视图类，添加手势识别器
- `UIKeyboardImpl`: 键盘实现类，用于触发类遍历

### 手势处理流程

1. 键盘视图显示时 (`didMoveToWindow`)
2. 检查是否已添加手势识别器
3. 添加上划和下划手势识别器
4. 手势触发时调用 `switchInputLanguage()`
5. 通过 `UITextInputMode` API 切换到下一个输入法

## 开发配置 (Development)

### 项目结构

```
.
├── Makefile                          # Theos 编译配置
├── control                           # 包信息
├── WeChatIMEGestureSwitch.plist     # 注入配置
├── Tweak.x                           # 主要实现代码
└── README.md                         # 本文件
```

### 编译命令

```bash
make clean          # 清理编译文件
make               # 编译 tweak
make package       # 打包为 .deb
make install       # 安装到设备 (需要配置 THEOS_DEVICE_IP)
```

### 环境变量

在编译前可以设置以下环境变量:

```bash
export THEOS=/path/to/theos
export THEOS_DEVICE_IP=192.168.1.xxx
export THEOS_DEVICE_PORT=22
```

## 故障排除 (Troubleshooting)

### 手势不响应

1. 检查是否正确安装并重启了 SpringBoard
2. 确认系统中启用了多个输入法
3. 查看日志确认手势识别器是否成功添加

### 切换不生效

1. 检查日志中的当前输入法信息
2. 确认有多个可用的输入法模式
3. 尝试手动切换输入法后再使用手势

### 日志无输出

1. 确认插件已正确安装: `dpkg -l | grep wechatimegestureswitch`
2. 检查是否注入到 SpringBoard: `ps aux | grep SpringBoard`
3. 重新安装并重启设备

## 兼容性 (Compatibility)

### 已测试系统版本

- iOS 16.0 - 16.5

### 越狱环境

- ✅ **有根越狱 (Rooted)**: checkra1n, unc0ver, Taurine 等
- ✅ **无根越狱 (Rootless)**: palera1n (rootless), Dopamine, XinaA15 等

### 已测试设备

- iPhone 12 Pro 及以上
- 支持 arm64 和 arm64e 架构

### 已知问题

- 在某些第三方输入法中可能不工作
- 极少数情况下可能与其他键盘 tweak 冲突

## 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证 (License)

本项目采用 MIT 许可证。详见 LICENSE 文件。

## 致谢 (Acknowledgments)

- [Theos](https://theos.dev/) - iOS 越狱开发框架
- [Cydia Substrate](http://www.cydiasubstrate.com/) - 动态 Hook 框架
- iOS 越狱社区的所有贡献者

## 联系方式 (Contact)

如有问题或建议，请通过以下方式联系:

- 提交 Issue
- 发送邮件至: your.email@example.com

## 更新日志 (Changelog)

### v1.0.0 (2024-01-01)

- 🎉 首次发布
- ✨ 支持上下滑动手势切换输入法
- ✨ iOS 16+ 系统兼容
- ✨ 全局键盘生效
- 🐛 完整的调试日志输出
- 📝 详细的类遍历功能

---

**免责声明**: 本项目仅供学习和研究使用，请在越狱设备上谨慎使用第三方插件。作者不对使用本插件造成的任何问题负责。
