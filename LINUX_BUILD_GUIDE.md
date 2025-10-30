# Linux编译打包指南 | Linux Build Guide

本指南详细说明如何在Linux系统上编译和打包WeChat Keyboard Swipe插件。

This guide explains how to compile and package the WeChat Keyboard Swipe tweak on Linux systems.

> **🇨🇳 中国大陆用户注意：** 如果访问GitHub较慢，请先查看镜像加速指南：
> - [CHINA_MIRROR_GUIDE.md](CHINA_MIRROR_GUIDE.md) - 中国镜像加速配置

---

## 系统要求 | System Requirements

- Ubuntu 20.04+ / Debian 11+ / 其他Linux发行版
- Git
- Make
- Clang/LLVM
- Perl
- 至少1GB可用磁盘空间

---

## 一、安装Theos | Step 1: Install Theos

### 1. 安装依赖包 | Install Dependencies

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y git curl build-essential clang-12 llvm-12 \
    libssl-dev libplist-utils libplist-dev fakeroot perl \
    python3 python3-pip zip unzip wget
```

#### Fedora/RHEL/CentOS:
```bash
sudo dnf install -y git curl clang llvm openssl-devel \
    libplist-devel perl python3 python3-pip zip unzip wget
```

#### Arch Linux:
```bash
sudo pacman -S git curl base-devel clang llvm openssl \
    libplist perl python python-pip zip unzip wget
```

### 2. 设置环境变量 | Set Environment Variables

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export THEOS=~/theos
export PATH=$THEOS/bin:$PATH
```

应用环境变量：
```bash
source ~/.bashrc
# 或者
source ~/.zshrc
```

### 3. 克隆Theos | Clone Theos

```bash
git clone --recursive https://github.com/theos/theos.git $THEOS
```

### 4. 安装iOS工具链 | Install iOS Toolchain

```bash
cd $THEOS
curl -LO https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma
TMP=$(mktemp -d)
tar -xvf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
mkdir -p $THEOS/toolchain/linux/iphone
mv $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma
```

### 5. 下载iOS SDK | Download iOS SDK

```bash
cd $THEOS
mkdir -p sdks

# 方法1：使用预编译的SDK（推荐）
cd sdks
wget https://github.com/theos/sdks/archive/master.zip
unzip master.zip
mv sdks-master/* .
rm -rf sdks-master master.zip

# 或方法2：从特定版本下载
# git clone https://github.com/theos/sdks.git sdks_temp
# mv sdks_temp/* .
# rm -rf sdks_temp
```

验证SDK安装：
```bash
ls $THEOS/sdks/
# 应该看到 iPhoneOS*.sdk 目录
```

---

## 二、编译项目 | Step 2: Build the Project

### 1. 进入项目目录 | Navigate to Project

```bash
cd /path/to/WeChat-Keyboard-Swipe
# 或者克隆项目
# git clone <repository-url>
# cd <project-directory>
```

### 2. 检查项目文件 | Verify Project Files

```bash
ls -l
# 应该看到:
# - Tweak.x
# - Makefile
# - control
# - WeChatKeyboardSwipe.plist
```

### 3. 清理之前的编译 | Clean Previous Build

```bash
make clean
```

### 4. 编译项目 | Build the Project

```bash
make package
```

或者使用编译脚本：
```bash
./build.sh
```

### 5. 查看编译输出 | Check Build Output

```bash
# 查看生成的.deb包
ls -lh packages/
```

应该看到类似：
```
com.tweak.wechatkeyboardswipe_1.0.0_iphoneos-arm64.deb
```

---

## 三、常见问题排查 | Step 3: Troubleshooting

### 问题1：找不到THEOS

**错误信息：**
```
/bin/sh: 1: /makefiles/common.mk: not found
```

**解决方案：**
```bash
# 检查THEOS变量
echo $THEOS

# 如果为空，设置它
export THEOS=~/theos
echo "export THEOS=~/theos" >> ~/.bashrc
source ~/.bashrc
```

### 问题2：找不到SDK

**错误信息：**
```
error: unable to locate SDK
```

**解决方案：**
```bash
# 检查SDK
ls $THEOS/sdks/

# 如果为空，下载SDK
cd $THEOS/sdks
git clone https://github.com/theos/sdks.git temp
mv temp/*.sdk .
rm -rf temp
```

### 问题3：找不到工具链

**错误信息：**
```
error: unable to find toolchain
```

**解决方案：**
```bash
# 检查工具链
ls $THEOS/toolchain/

# 重新安装工具链（见步骤1.4）
```

### 问题4：权限错误

**错误信息：**
```
Permission denied
```

**解决方案：**
```bash
# 给build.sh执行权限
chmod +x build.sh

# 检查文件权限
ls -la
```

### 问题5：缺少依赖

**错误信息：**
```
error: ld: library not found
```

**解决方案：**
```bash
# Ubuntu/Debian
sudo apt install -y libplist-dev libssl-dev

# Fedora
sudo dnf install -y libplist-devel openssl-devel
```

---

## 四、高级编译选项 | Step 4: Advanced Build Options

### 只编译不打包 | Compile Only (No Package)

```bash
make
```

### 清理并重新编译 | Clean and Rebuild

```bash
make clean all
```

### 调试模式编译 | Debug Build

在Makefile中添加：
```makefile
WeChatKeyboardSwipe_CFLAGS = -fobjc-arc -DDEBUG=1
```

然后：
```bash
make clean package
```

### 指定架构 | Specify Architecture

```bash
# 只编译arm64
make package ARCHS=arm64

# 只编译arm64e
make package ARCHS=arm64e

# 编译两者（默认）
make package ARCHS="arm64 arm64e"
```

### 查看详细编译信息 | Verbose Output

```bash
make package VERBOSE=1
```

---

## 五、打包验证 | Step 5: Package Verification

### 检查.deb包内容 | Inspect .deb Contents

```bash
# 查看包信息
dpkg-deb --info packages/com.tweak.wechatkeyboardswipe_*.deb

# 查看包内文件
dpkg-deb --contents packages/com.tweak.wechatkeyboardswipe_*.deb

# 解包查看
dpkg-deb -x packages/com.tweak.wechatkeyboardswipe_*.deb /tmp/extract
tree /tmp/extract
```

预期的文件结构：
```
/tmp/extract/
└── Library/
    └── MobileSubstrate/
        └── DynamicLibraries/
            ├── WeChatKeyboardSwipe.dylib
            └── WeChatKeyboardSwipe.plist
```

### 验证动态库 | Verify Dynamic Library

```bash
# 安装file命令（如果没有）
sudo apt install file

# 检查dylib文件类型
file /tmp/extract/Library/MobileSubstrate/DynamicLibraries/WeChatKeyboardSwipe.dylib
```

应该显示：
```
Mach-O 64-bit dynamically linked shared library arm64
```

---

## 六、传输到iOS设备 | Step 6: Transfer to iOS Device

### 方法1：通过SCP传输

```bash
# 设置设备IP
DEVICE_IP="192.168.1.100"  # 替换为你的设备IP

# 传输.deb包
scp packages/com.tweak.wechatkeyboardswipe_*.deb root@$DEVICE_IP:/var/root/

# SSH到设备并安装
ssh root@$DEVICE_IP "dpkg -i /var/root/com.tweak.wechatkeyboardswipe_*.deb && killall -9 WeChat"
```

### 方法2：使用make install

```bash
# 设置设备IP
export THEOS_DEVICE_IP=192.168.1.100
export THEOS_DEVICE_PORT=22

# 编译并自动安装
make package install
```

### 方法3：通过HTTP服务器

```bash
# 在项目目录启动简单HTTP服务器
cd packages
python3 -m http.server 8000

# 在iOS设备上用Safari访问
# http://你的Linux机器IP:8000/
# 下载.deb文件并用Filza安装
```

---

## 七、自动化脚本 | Step 7: Automation Scripts

### 创建完整编译安装脚本

创建 `build-and-install.sh`:

```bash
#!/bin/bash

# WeChat Keyboard Swipe - Build and Install Script
# Linux版本自动化编译安装脚本

set -e

echo "==========================================="
echo "WeChat Keyboard Swipe - Build & Install"
echo "==========================================="
echo ""

# 检查THEOS
if [ -z "$THEOS" ]; then
    echo "❌ Error: THEOS not set"
    echo "Setting THEOS to ~/theos"
    export THEOS=~/theos
fi

# 检查设备IP
if [ -z "$1" ]; then
    echo "Usage: $0 <device-ip>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

DEVICE_IP=$1

echo "✓ THEOS: $THEOS"
echo "✓ Device IP: $DEVICE_IP"
echo ""

# 清理
echo "→ Cleaning..."
make clean

# 编译
echo "→ Building..."
make package

# 查找.deb文件
DEB_FILE=$(find packages -name "*.deb" -type f | head -n 1)

if [ -z "$DEB_FILE" ]; then
    echo "❌ Error: .deb file not found"
    exit 1
fi

echo "✓ Built: $DEB_FILE"
echo ""

# 传输
echo "→ Transferring to device..."
scp "$DEB_FILE" root@$DEVICE_IP:/var/root/

# 安装
echo "→ Installing on device..."
ssh root@$DEVICE_IP "dpkg -i /var/root/$(basename $DEB_FILE) && killall -9 WeChat || true"

echo ""
echo "==========================================="
echo "✓ Installation complete!"
echo "==========================================="
```

使用脚本：
```bash
chmod +x build-and-install.sh
./build-and-install.sh 192.168.1.100
```

---

## 八、Docker环境（可选）| Step 8: Docker Environment (Optional)

### 创建Dockerfile

创建 `Dockerfile`:

```dockerfile
FROM ubuntu:22.04

# 安装依赖
RUN apt-get update && apt-get install -y \
    git curl build-essential clang-12 llvm-12 \
    libssl-dev libplist-utils libplist-dev \
    fakeroot perl python3 python3-pip \
    zip unzip wget openssh-client && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /build

# 安装Theos
ENV THEOS=/opt/theos
RUN git clone --recursive https://github.com/theos/theos.git $THEOS

# 下载SDK
RUN cd $THEOS/sdks && \
    wget https://github.com/theos/sdks/archive/master.zip && \
    unzip master.zip && \
    mv sdks-master/* . && \
    rm -rf sdks-master master.zip

# 设置环境变量
ENV PATH=$THEOS/bin:$PATH

WORKDIR /project
```

### 使用Docker编译

```bash
# 构建Docker镜像
docker build -t theos-builder .

# 使用Docker编译项目
docker run --rm -v $(pwd):/project theos-builder make package

# 编译结果在 packages/ 目录
```

---

## 九、CI/CD集成 | Step 9: CI/CD Integration

### GitHub Actions示例

创建 `.github/workflows/build.yml`:

```yaml
name: Build WeChat Keyboard Swipe

on:
  push:
    branches: [ main, feat-* ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y git curl build-essential clang-12 \
          libssl-dev libplist-dev fakeroot perl python3
    
    - name: Setup Theos
      run: |
        export THEOS=~/theos
        git clone --recursive https://github.com/theos/theos.git $THEOS
        cd $THEOS/sdks
        wget https://github.com/theos/sdks/archive/master.zip
        unzip master.zip
        mv sdks-master/* .
        rm -rf sdks-master master.zip
    
    - name: Build Package
      run: |
        export THEOS=~/theos
        export PATH=$THEOS/bin:$PATH
        make package
    
    - name: Upload Artifact
      uses: actions/upload-artifact@v3
      with:
        name: wechatkeyboardswipe-deb
        path: packages/*.deb
```

---

## 十、总结 | Summary

### 快速命令参考 | Quick Command Reference

```bash
# 完整编译流程
export THEOS=~/theos
cd /path/to/project
make clean
make package

# 传输安装
scp packages/*.deb root@<ip>:/var/root/
ssh root@<ip> "dpkg -i /var/root/*.deb && killall -9 WeChat"

# 或一键安装
export THEOS_DEVICE_IP=<ip>
make package install
```

### 检查清单 | Checklist

编译前确认：
- [ ] THEOS环境变量已设置
- [ ] SDK已下载到 $THEOS/sdks/
- [ ] 工具链已安装
- [ ] 所有依赖包已安装
- [ ] 项目文件完整（Tweak.x, Makefile, control, .plist）

编译后验证：
- [ ] packages/目录有.deb文件
- [ ] .deb文件大小合理（通常10-50KB）
- [ ] 使用dpkg-deb检查包内容
- [ ] 包含.dylib和.plist文件

---

## 相关文档 | Related Documentation

- [QUICKSTART.md](QUICKSTART.md) - 快速开始指南
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - 技术实现细节
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排除

---

**编译成功！| Build Success!** 🎉

如有问题，请参考 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 或提交Issue。
