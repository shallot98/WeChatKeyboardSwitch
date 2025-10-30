# 中国镜像加速指南 | China Mirror Guide

如果您在中国大陆，访问GitHub和下载依赖可能较慢。本指南提供镜像加速方案。

---

## 一、Git镜像配置 | Git Mirror Setup

### 方法1：使用Gitee镜像（推荐）

```bash
# 设置Git代理使用Gitee
git config --global url."https://gitee.com/".insteadOf "https://github.com/"

# 或使用特定镜像
git config --global url."https://hub.fastgit.xyz/".insteadOf "https://github.com/"
```

### 方法2：使用GitHub代理镜像

```bash
# ghproxy
git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"

# 或 GitHub镜像站
git config --global url."https://mirror.ghproxy.com/https://github.com/".insteadOf "https://github.com/"
```

### 恢复默认设置

```bash
git config --global --unset url."https://gitee.com/".insteadOf
git config --global --unset url."https://ghproxy.com/https://github.com/".insteadOf
```

---

## 二、Theos安装（国内镜像）| Theos Installation (China Mirror)

### 使用镜像安装Theos

```bash
# 设置环境变量
export THEOS=~/theos

# 方法1：使用GitHub代理
git clone --recursive https://ghproxy.com/https://github.com/theos/theos.git $THEOS

# 方法2：使用Gitee镜像（如果有）
# 注意：Theos可能没有官方Gitee镜像，建议使用代理

# 方法3：手动下载压缩包
wget https://ghproxy.com/https://github.com/theos/theos/archive/refs/heads/master.zip
unzip master.zip
mv theos-master $THEOS

# 更新子模块（使用代理）
cd $THEOS
git submodule update --init --recursive
```

---

## 三、SDK下载加速 | SDK Download Acceleration

### 使用代理下载SDK

```bash
cd $THEOS/sdks

# 方法1：使用ghproxy
wget https://ghproxy.com/https://github.com/theos/sdks/archive/refs/heads/master.zip
unzip master.zip
mv sdks-master/* .
rm -rf sdks-master master.zip

# 方法2：使用CDN加速
wget https://mirror.ghproxy.com/https://github.com/theos/sdks/archive/master.zip
# 后续步骤同上
```

### 使用国内网盘分享（备选）

如果上述方法都很慢，可以：

1. 到网盘搜索 "iOS SDK" 或 "iPhoneOS SDK"
2. 下载后解压到 `$THEOS/sdks/`
3. 确保目录名格式为 `iPhoneOS16.0.sdk`

---

## 四、工具链下载加速 | Toolchain Download

### Linux工具链镜像下载

```bash
cd $THEOS

# 原始链接（可能很慢）
# curl -LO https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma

# 使用代理下载
curl -LO https://ghproxy.com/https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma

# 或使用wget
wget https://ghproxy.com/https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma

# 解压
TMP=$(mktemp -d)
tar -xf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
mkdir -p $THEOS/toolchain/linux/iphone
mv $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma
```

---

## 五、APT镜像配置（Ubuntu/Debian）| APT Mirror

### 使用清华源

```bash
# 备份原配置
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Ubuntu 22.04 (jammy)
sudo tee /etc/apt/sources.list << 'EOF'
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF

# 更新
sudo apt update
```

### 使用阿里云源

```bash
# Ubuntu 22.04 (jammy)
sudo tee /etc/apt/sources.list << 'EOF'
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

sudo apt update
```

---

## 六、完整安装脚本（国内优化）| Complete Installation (China Optimized)

创建 `install-theos-china.sh`:

```bash
#!/bin/bash
set -e

echo "==========================================="
echo "Theos安装脚本 - 中国镜像优化版"
echo "==========================================="
echo ""

# 配置Git镜像
echo "→ 配置Git代理..."
git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"

# 设置THEOS
export THEOS=~/theos
echo "export THEOS=~/theos" >> ~/.bashrc
echo "export PATH=\$THEOS/bin:\$PATH" >> ~/.bashrc

# 安装依赖（使用国内源）
echo "→ 安装依赖包..."
sudo apt update
sudo apt install -y git curl build-essential clang-12 llvm-12 \
    libssl-dev libplist-dev libplist-utils fakeroot perl python3 \
    python3-pip zip unzip wget

# 克隆Theos（使用代理）
echo "→ 克隆Theos..."
git clone --recursive https://ghproxy.com/https://github.com/theos/theos.git $THEOS

# 下载SDK（使用代理）
echo "→ 下载iOS SDK..."
cd $THEOS/sdks
wget https://ghproxy.com/https://github.com/theos/sdks/archive/refs/heads/master.zip
unzip master.zip
mv sdks-master/* .
rm -rf sdks-master master.zip

# 下载工具链（使用代理）
echo "→ 下载工具链..."
cd $THEOS
wget https://ghproxy.com/https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma
TMP=$(mktemp -d)
tar -xf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
mkdir -p $THEOS/toolchain/linux/iphone
mv $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma

echo ""
echo "==========================================="
echo "✓ 安装完成！"
echo ""
echo "请运行以下命令使环境变量生效："
echo "  source ~/.bashrc"
echo ""
echo "然后可以开始编译项目："
echo "  cd /path/to/project"
echo "  make package"
echo "==========================================="
```

使用脚本：
```bash
chmod +x install-theos-china.sh
./install-theos-china.sh
source ~/.bashrc
```

---

## 七、常用镜像站点 | Common Mirror Sites

### GitHub代理服务

1. **ghproxy.com**
   ```
   https://ghproxy.com/https://github.com/...
   ```

2. **mirror.ghproxy.com**
   ```
   https://mirror.ghproxy.com/https://github.com/...
   ```

3. **fastgit.org**
   ```
   https://hub.fastgit.xyz/...
   ```

### APT软件源

1. **清华大学开源镜像站**
   - https://mirrors.tuna.tsinghua.edu.cn/

2. **阿里云开源镜像站**
   - https://mirrors.aliyun.com/

3. **中科大开源镜像站**
   - https://mirrors.ustc.edu.cn/

4. **华为云开源镜像站**
   - https://mirrors.huaweicloud.com/

---

## 八、网络测试 | Network Test

### 测试GitHub连接速度

```bash
# 测试直连
time git clone https://github.com/theos/theos.git test-direct
rm -rf test-direct

# 测试代理
time git clone https://ghproxy.com/https://github.com/theos/theos.git test-proxy
rm -rf test-proxy

# 比较速度选择最快的方式
```

### 测试下载速度

```bash
# 测试文件下载
wget --spider https://github.com/theos/sdks/archive/master.zip
wget --spider https://ghproxy.com/https://github.com/theos/sdks/archive/master.zip
```

---

## 九、常见问题 | FAQ

### 1. 代理后仍然很慢怎么办？

尝试不同的镜像站：
```bash
# 尝试不同代理
git config --global url."https://hub.fastgit.xyz/".insteadOf "https://github.com/"
# 或
git config --global url."https://gitclone.com/github.com/".insteadOf "https://github.com/"
```

### 2. 如何查看当前Git配置？

```bash
git config --global --list | grep url
```

### 3. 镜像站不可用怎么办？

镜像站可能会失效，建议：
- 尝试多个镜像站
- 使用VPN/代理
- 到网盘搜索离线包

### 4. 恢复Git原始设置

```bash
# 查看所有url替换
git config --global --get-regexp url

# 删除所有url替换
git config --global --unset-all url."https://ghproxy.com/https://github.com/".insteadOf
```

---

## 十、推荐配置 | Recommended Configuration

### 最优配置（2024年）

```bash
# 1. Git代理
git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"

# 2. 使用清华源
# 编辑 /etc/apt/sources.list 使用清华源

# 3. Python pip镜像
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 4. 设置Git加速
git config --global core.compression 0
git config --global http.postBuffer 1048576000
```

---

## 相关资源 | Related Resources

- [清华大学开源镜像站使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/)
- [阿里云镜像站](https://developer.aliyun.com/mirror/)
- [GitHub加速方法汇总](https://gitee.com/help/articles/4284)

---

**配置成功后，编译速度会大幅提升！| After configuration, build speed will improve significantly!** 🚀
