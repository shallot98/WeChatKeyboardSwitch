# WeChat Keyboard Swipe - 微信键盘滑动切换输入法

一个iOS 16越狱插件，在微信应用中通过键盘上的滑动手势快速切换中英文输入法。

## 功能特性

- ⬆️ **向上滑动**：快速切换到英文输入法
- ⬇️ **向下滑动**：快速切换到中文输入法
- 🎯 **精准识别**：仅在微信应用中生效
- 📱 **触觉反馈**：切换时提供轻微震动反馈
- 🔧 **不影响原功能**：完全不干扰键盘原有的打字和触摸操作

## 系统要求

- iOS 16.0 或更高版本
- 已越狱设备（支持rootless和rootful）
- arm64/arm64e架构

## 安装方法

### 方法一：通过软件源安装（推荐）

1. 将编译好的.deb包添加到你的越狱软件源
2. 在包管理器（Sileo/Zebra/Cydia）中搜索"WeChat Keyboard Swipe"
3. 点击安装
4. 注销重启SpringBoard

### 方法二：手动安装

```bash
# 将.deb包传输到设备
scp com.tweak.wechatkeyboardswipe_1.0.0_iphoneos-arm64.deb root@<设备IP>:/var/root/

# SSH连接到设备
ssh root@<设备IP>

# 安装插件
dpkg -i /var/root/com.tweak.wechatkeyboardswipe_1.0.0_iphoneos-arm64.deb

# 重启微信
killall -9 WeChat
```

## 使用说明

1. 安装插件后，打开微信应用
2. 在任意聊天界面调出键盘
3. 在键盘区域进行滑动手势：
   - **向上滑动**：切换到英文输入法
   - **向下滑动**：切换到中文输入法
4. 感受到轻微震动表示切换成功

## 编译说明

### 环境准备

1. 安装Theos开发环境：

```bash
# macOS/Linux
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS
```

2. 确保已安装iOS 16 SDK：

```bash
# 下载并放置SDK到 $THEOS/sdks/
# 例如：iPhoneOS16.0.sdk
```

### 编译步骤

```bash
# 克隆项目
git clone <repository-url>
cd <project-directory>

# 编译
make clean
make package

# 编译后会在packages目录生成.deb安装包
```

### 安装到设备测试

```bash
# 设置设备IP
export THEOS_DEVICE_IP=<你的设备IP>
export THEOS_DEVICE_PORT=22

# 编译并安装
make package install

# 微信会自动重启
```

## 技术实现

### 核心技术

- **Theos框架**：iOS越狱插件开发框架
- **Logos语法**：用于Hook Objective-C方法
- **UISwipeGestureRecognizer**：实现滑动手势识别
- **UITextInputMode**：系统输入法切换API
- **UIImpactFeedbackGenerator**：触觉反馈

### Hook策略

- Hook `UIInputWindowController` 类
- 在 `viewDidLoad` 中注入手势识别器
- 通过 `UIKeyboardImpl` 实现输入法切换
- 使用 `cancelsTouchesInView = NO` 确保不影响原有触摸事件

### 项目结构

```
.
├── Makefile                      # 编译配置文件
├── Tweak.x                       # 主要Hook和逻辑代码
├── control                       # 插件元数据信息
├── WeChatKeyboardSwipe.plist    # 过滤器配置（限定微信）
└── README.md                     # 说明文档
```

## 兼容性

- ✅ iOS 16.0+
- ✅ arm64/arm64e
- ✅ rootless越狱（如palera1n）
- ✅ rootful越狱
- ✅ 微信最新版本

## 故障排除

### 插件不生效

1. 确认设备已正确越狱
2. 检查是否安装了substrate/substitute
3. 尝试注销重启SpringBoard：`killall -9 SpringBoard`
4. 检查插件是否启用（通过Choicy等插件管理器）

### 切换没有反应

1. 确认设备中已安装中文和英文输入法
2. 进入 设置 > 通用 > 键盘 > 键盘，添加所需输入法
3. 检查微信是否为最新版本

### 手势冲突

- 插件已设置 `cancelsTouchesInView = NO`，不应影响正常打字
- 如遇冲突，可尝试调整滑动速度

## 卸载

```bash
# 通过包管理器卸载
# 或手动卸载：
dpkg -r com.tweak.wechatkeyboardswipe
killall -9 WeChat
```

## 开源协议

MIT License

## 更新日志

### v1.0.0 (2024)
- 🎉 首次发布
- ✨ 支持上下滑动切换中英文输入法
- ✨ 添加触觉反馈
- ✨ 完全兼容iOS 16

## 贡献

欢迎提交Issue和Pull Request！

## 免责声明

本插件仅供学习交流使用，请勿用于商业用途。使用本插件造成的任何问题，开发者不承担责任。

## 联系方式

- Issues: 通过GitHub Issues反馈问题
- 讨论: 欢迎在越狱社区讨论

---

**享受更便捷的输入法切换体验！** 🚀
