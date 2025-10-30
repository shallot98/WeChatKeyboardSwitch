# Quick Start Guide | 快速开始指南

## For Users | 用户使用指南

### Installation | 安装步骤

1. **Download the .deb package** | 下载.deb安装包
   ```
   从Release页面下载最新版本的.deb文件
   ```

2. **Install via SSH** | 通过SSH安装
   ```bash
   # Copy to device | 复制到设备
   scp com.tweak.wechatkeyboardswipe_*.deb root@YOUR_DEVICE_IP:/var/root/
   
   # SSH to device | SSH连接设备
   ssh root@YOUR_DEVICE_IP
   
   # Install | 安装
   dpkg -i /var/root/com.tweak.wechatkeyboardswipe_*.deb
   
   # Restart WeChat | 重启微信
   killall -9 WeChat
   ```

3. **Install via Filza** | 通过Filza安装
   - 将.deb文件传输到设备
   - 使用Filza打开文件
   - 点击安装

### Usage | 使用方法

1. Open WeChat | 打开微信
2. Start typing in any chat | 在任意聊天界面开始输入
3. When keyboard appears | 当键盘出现时:
   - **Swipe UP** ⬆️ = Switch to English | 向上滑 = 切换英文
   - **Swipe DOWN** ⬇️ = Switch to Chinese | 向下滑 = 切换中文
4. Feel the haptic feedback! | 感受触觉反馈！

### Requirements | 系统要求

- ✅ iOS 16.0 or later | iOS 16.0及以上
- ✅ Jailbroken device | 已越狱设备
- ✅ MobileSubstrate installed | 已安装MobileSubstrate
- ✅ Both Chinese and English keyboards installed | 已安装中英文键盘

---

## For Developers | 开发者编译指南

### Prerequisites | 前置要求

1. **Install Theos** | 安装Theos
   ```bash
   export THEOS=~/theos
   git clone --recursive https://github.com/theos/theos.git $THEOS
   ```

2. **Install iOS SDK** | 安装iOS SDK
   ```bash
   # Download iOS 16 SDK
   # Place in $THEOS/sdks/iPhoneOS16.0.sdk
   ```

3. **Set up SSH access to device** | 设置SSH访问
   ```bash
   ssh-keygen
   ssh-copy-id root@YOUR_DEVICE_IP
   ```

### Build & Install | 编译与安装

#### Method 1: Using build script | 使用编译脚本

```bash
./build.sh
```

#### Method 2: Using make commands | 使用make命令

```bash
# Clean build | 清理编译
make clean

# Build only | 仅编译
make

# Build package | 打包
make package

# Build and install to device | 编译并安装到设备
export THEOS_DEVICE_IP=YOUR_DEVICE_IP
make package install
```

### Project Structure | 项目结构

```
.
├── Tweak.x                      # Main tweak code | 主要Hook代码
├── Makefile                     # Build configuration | 编译配置
├── control                      # Package metadata | 包信息
├── WeChatKeyboardSwipe.plist   # Bundle filter | Bundle过滤器
├── build.sh                     # Build helper script | 编译辅助脚本
├── README.md                    # Main documentation | 主要文档
├── IMPLEMENTATION.md            # Technical details | 技术细节
├── CHANGELOG.md                 # Version history | 版本历史
├── LICENSE                      # MIT License | 开源协议
└── .gitignore                   # Git ignore rules | Git忽略规则
```

### Testing | 测试

1. **Install on device** | 安装到设备
   ```bash
   make package install THEOS_DEVICE_IP=YOUR_IP
   ```

2. **Check installation** | 检查安装
   ```bash
   ssh root@YOUR_DEVICE_IP
   dpkg -l | grep wechatkeyboard
   ```

3. **View logs** | 查看日志
   ```bash
   # On device | 在设备上
   tail -f /var/log/syslog | grep WeChat
   ```

4. **Test in WeChat** | 在微信中测试
   - Open WeChat | 打开微信
   - Type in chat | 在聊天中输入
   - Try swipe gestures | 尝试滑动手势

### Debugging | 调试

**Add debug logs** | 添加调试日志
```objc
NSLog(@"[WeChatKeyboardSwipe] Debug message: %@", info);
```

**Use Cycript** | 使用Cycript
```bash
cycript -p WeChat
cy# UIApp
cy# [UIKeyboardImpl sharedInstance]
```

### Common Issues | 常见问题

**Build fails** | 编译失败
```bash
# Check THEOS path | 检查THEOS路径
echo $THEOS

# Check SDK | 检查SDK
ls $THEOS/sdks/
```

**Install fails** | 安装失败
```bash
# Check SSH connection | 检查SSH连接
ssh root@YOUR_DEVICE_IP

# Check if device has enough space | 检查设备空间
df -h
```

**Tweak not working** | 插件不工作
```bash
# Respring | 注销
killall -9 SpringBoard

# Check if loaded | 检查是否加载
ps aux | grep WeChat
```

---

## Support | 技术支持

- 📖 Read the full [README.md](README.md)
- 🔧 Check [IMPLEMENTATION.md](IMPLEMENTATION.md) for technical details
- 📝 View [CHANGELOG.md](CHANGELOG.md) for version history
- 🐛 Report issues on GitHub Issues

---

**Happy Tweaking! | 祝使用愉快！** 🎉
