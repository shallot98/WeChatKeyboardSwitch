# Linux编译快速参考 | Linux Build Quick Reference

---

## 一次性设置 | One-Time Setup

```bash
# 1. 安装依赖
sudo apt update && sudo apt install -y git curl build-essential \
    clang-12 llvm-12 libssl-dev libplist-dev fakeroot perl python3

# 2. 安装Theos
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS
echo "export THEOS=~/theos" >> ~/.bashrc
echo 'export PATH=$THEOS/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 3. 下载SDK
cd $THEOS/sdks
wget https://github.com/theos/sdks/archive/master.zip
unzip master.zip && mv sdks-master/* . && rm -rf sdks-master master.zip

# 4. 安装iOS工具链
cd $THEOS
curl -LO https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma
TMP=$(mktemp -d) && tar -xf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
mkdir -p $THEOS/toolchain/linux/iphone
mv $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma
```

---

## 日常编译 | Daily Build

```bash
# 进入项目目录
cd /path/to/project

# 编译
make clean package

# 查看结果
ls -lh packages/*.deb
```

---

## 安装到设备 | Install to Device

### 方法1：自动安装
```bash
export THEOS_DEVICE_IP=192.168.1.100
make package install
```

### 方法2：手动安装
```bash
# 传输
scp packages/*.deb root@192.168.1.100:/var/root/

# 安装
ssh root@192.168.1.100
dpkg -i /var/root/*.deb
killall -9 WeChat
exit
```

### 方法3：使用脚本
```bash
./build.sh
# 然后手动传输到设备
```

---

## 常用命令 | Common Commands

```bash
# 清理编译
make clean

# 只编译不打包
make

# 编译并打包
make package

# 详细输出
make package VERBOSE=1

# 指定架构
make package ARCHS=arm64

# 查看包内容
dpkg-deb --contents packages/*.deb

# 查看包信息
dpkg-deb --info packages/*.deb
```

---

## 快速故障排查 | Quick Troubleshooting

### THEOS未设置
```bash
export THEOS=~/theos
echo "export THEOS=~/theos" >> ~/.bashrc
```

### 找不到SDK
```bash
ls $THEOS/sdks/
# 如果为空，重新下载（见上方设置步骤）
```

### 权限问题
```bash
chmod +x build.sh
chmod -R 755 .
```

### 编译错误
```bash
make clean
make package VERBOSE=1  # 查看详细错误
```

---

## 环境检查 | Environment Check

```bash
# 检查Theos
echo $THEOS
ls $THEOS/makefiles/

# 检查SDK
ls $THEOS/sdks/

# 检查工具链
ls $THEOS/toolchain/

# 检查项目文件
ls -l Tweak.x Makefile control *.plist
```

---

## 完整一键脚本 | All-in-One Script

将以下内容保存为 `quick-build.sh`:

```bash
#!/bin/bash
set -e

# 设置环境
export THEOS=${THEOS:-~/theos}
export PATH=$THEOS/bin:$PATH

# 编译
echo "→ Building..."
make clean package

# 显示结果
DEB=$(find packages -name "*.deb" -type f | head -n 1)
echo "✓ Built: $DEB"
ls -lh "$DEB"

# 如果提供了设备IP，自动安装
if [ -n "$1" ]; then
    echo "→ Installing to $1..."
    scp "$DEB" root@$1:/var/root/
    ssh root@$1 "dpkg -i /var/root/$(basename $DEB) && killall -9 WeChat || true"
    echo "✓ Installed!"
fi
```

使用方法：
```bash
chmod +x quick-build.sh

# 只编译
./quick-build.sh

# 编译并安装
./quick-build.sh 192.168.1.100
```

---

## Docker快速编译 | Docker Quick Build

```bash
# 一键Docker编译
docker run --rm -v $(pwd):/project \
    -e THEOS=/opt/theos \
    theos-builder make package

# 或创建别名
alias theos-build='docker run --rm -v $(pwd):/project -e THEOS=/opt/theos theos-builder make package'

# 使用
theos-build
```

---

## 详细文档 | Full Documentation

完整指南请参考：[LINUX_BUILD_GUIDE.md](LINUX_BUILD_GUIDE.md)

---

**保存此页面以便快速参考！| Save this page for quick reference!**
