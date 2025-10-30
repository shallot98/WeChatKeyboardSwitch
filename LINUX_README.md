# Linux用户必读 | Linux Users Must Read

如果您使用Linux系统进行编译，本文档将指引您完成整个流程。

---

## 📚 文档导航 | Documentation Guide

### 1️⃣ 首次设置（必读）

**如果您在中国大陆：**
1. 先阅读 [CHINA_MIRROR_GUIDE.md](CHINA_MIRROR_GUIDE.md)
   - 配置GitHub镜像加速
   - 配置APT软件源镜像
   - 大幅提升下载速度

**所有用户：**
2. 阅读 [LINUX_BUILD_GUIDE.md](LINUX_BUILD_GUIDE.md)
   - 完整的环境安装指南
   - 详细的编译步骤
   - 故障排除方案

### 2️⃣ 快速参考（日常使用）

3. 使用 [LINUX_QUICK_REF.md](LINUX_QUICK_REF.md)
   - 快速命令参考
   - 常用操作速查
   - 一键编译脚本

### 3️⃣ 环境检查（推荐）

4. 运行 `./check-env.sh`
   - 自动检查编译环境
   - 发现配置问题
   - 给出修复建议

---

## 🚀 快速开始 | Quick Start

### 第一步：环境检查

```bash
# 运行环境检查脚本
./check-env.sh
```

如果所有检查都通过，继续下一步。如果有错误，按照提示修复。

### 第二步：编译

```bash
# 方法1：使用make
make clean package

# 方法2：使用脚本
./build.sh

# 查看编译结果
ls -lh packages/*.deb
```

### 第三步：安装到设备

```bash
# 设置设备IP
export THEOS_DEVICE_IP=192.168.1.100

# 自动安装
make package install

# 或手动传输
scp packages/*.deb root@192.168.1.100:/var/root/
ssh root@192.168.1.100 "dpkg -i /var/root/*.deb && killall -9 WeChat"
```

---

## 📋 完整流程示例 | Complete Workflow Example

### 场景1：首次在Linux上编译（中国用户）

```bash
# 1. 配置镜像（一次性）
# 参考 CHINA_MIRROR_GUIDE.md 配置Git和APT镜像

# 2. 安装Theos（一次性）
export THEOS=~/theos
git clone --recursive https://ghproxy.com/https://github.com/theos/theos.git $THEOS
# 详细步骤见 LINUX_BUILD_GUIDE.md

# 3. 下载项目
cd ~
git clone <repository-url>
cd <project-directory>

# 4. 检查环境
./check-env.sh

# 5. 编译
make clean package

# 6. 安装
export THEOS_DEVICE_IP=192.168.1.100
make package install
```

### 场景2：首次在Linux上编译（国际用户）

```bash
# 1. 安装Theos（一次性）
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS
# 详细步骤见 LINUX_BUILD_GUIDE.md

# 2. 下载项目
cd ~
git clone <repository-url>
cd <project-directory>

# 3. 检查环境
./check-env.sh

# 4. 编译
make clean package

# 5. 安装
export THEOS_DEVICE_IP=192.168.1.100
make package install
```

### 场景3：日常开发（已配置环境）

```bash
# 1. 修改代码
vim Tweak.x

# 2. 编译测试
make clean package

# 3. 安装到设备
export THEOS_DEVICE_IP=192.168.1.100
make package install

# 4. 在微信中测试
# 打开微信，测试手势功能
```

---

## 🔧 常用工具脚本 | Useful Scripts

### 1. 环境检查脚本

```bash
./check-env.sh
```

检查内容：
- THEOS环境变量
- Theos安装状态
- iOS SDK
- 工具链
- 必要工具（make, clang, git等）
- 项目文件完整性

### 2. 编译脚本

```bash
./build.sh
```

功能：
- 清理旧编译
- 执行编译
- 显示结果
- 提供安装指引

### 3. 快速编译安装脚本（自己创建）

创建 `quick-build.sh`:
```bash
#!/bin/bash
set -e
export THEOS=${THEOS:-~/theos}
export PATH=$THEOS/bin:$PATH

make clean package

DEB=$(find packages -name "*.deb" | head -n 1)
if [ -n "$1" ]; then
    scp "$DEB" root@$1:/var/root/
    ssh root@$1 "dpkg -i /var/root/$(basename $DEB) && killall -9 WeChat"
    echo "✓ Installed to $1"
else
    echo "✓ Built: $DEB"
    echo "Usage: $0 <device-ip> to auto-install"
fi
```

使用：
```bash
chmod +x quick-build.sh
./quick-build.sh 192.168.1.100
```

---

## 📖 文档速查表 | Documentation Cheatsheet

| 文档 | 用途 | 何时阅读 |
|------|------|---------|
| [LINUX_README.md](LINUX_README.md) | 总览导航 | 首次使用 |
| [LINUX_BUILD_GUIDE.md](LINUX_BUILD_GUIDE.md) | 完整安装指南 | 首次设置环境 |
| [LINUX_QUICK_REF.md](LINUX_QUICK_REF.md) | 快速命令参考 | 日常开发 |
| [CHINA_MIRROR_GUIDE.md](CHINA_MIRROR_GUIDE.md) | 镜像加速配置 | 中国用户首次设置 |
| check-env.sh | 环境检查工具 | 编译前检查 |
| build.sh | 编译辅助脚本 | 每次编译 |

---

## 🎯 推荐学习路径 | Recommended Learning Path

### 新手路径（3-4小时）

1. **阅读基础文档**（30分钟）
   - README.md - 了解项目
   - LINUX_README.md（本文档）- 了解Linux编译流程

2. **配置环境**（1-2小时）
   - 如果在中国：先配置 CHINA_MIRROR_GUIDE.md
   - 按照 LINUX_BUILD_GUIDE.md 安装Theos

3. **第一次编译**（30分钟）
   - 运行 check-env.sh 检查环境
   - 执行 make clean package
   - 查看生成的.deb文件

4. **安装测试**（1小时）
   - 传输.deb到设备
   - 安装并测试功能
   - 如遇问题，查看 TROUBLESHOOTING.md

### 进阶路径（1-2小时）

1. **深入理解**
   - IMPLEMENTATION.md - 技术实现细节
   - Tweak.x - 源代码分析

2. **优化流程**
   - 创建自己的编译脚本
   - 配置CI/CD自动编译
   - Docker容器化编译

3. **扩展功能**
   - 修改代码添加新功能
   - 调试和测试
   - 提交Pull Request

---

## ❓ 常见问题 | FAQ

### Q1: 我应该先看哪个文档？

**A:** 
- 中国用户：CHINA_MIRROR_GUIDE.md → LINUX_BUILD_GUIDE.md
- 其他用户：LINUX_BUILD_GUIDE.md
- 已配置环境：LINUX_QUICK_REF.md

### Q2: check-env.sh报错怎么办？

**A:** 
1. 仔细阅读错误信息
2. 按照提示安装缺失的软件
3. 参考 LINUX_BUILD_GUIDE.md 的故障排查章节

### Q3: 编译很慢/下载失败怎么办？

**A:** 
- 中国用户：配置 CHINA_MIRROR_GUIDE.md 中的镜像
- 其他用户：检查网络连接，可能需要VPN

### Q4: 找不到THEOS怎么办？

**A:** 
```bash
export THEOS=~/theos
echo "export THEOS=~/theos" >> ~/.bashrc
source ~/.bashrc
```

### Q5: 编译成功但安装失败？

**A:** 
1. 检查设备SSH连接：`ssh root@<device-ip>`
2. 检查设备空间：`df -h`
3. 查看 TROUBLESHOOTING.md 安装部分

---

## 🔗 相关资源 | Related Resources

### 项目文档
- [README.md](README.md) - 主文档
- [QUICKSTART.md](QUICKSTART.md) - 快速开始
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - 技术细节
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排除

### 外部资源
- [Theos官方文档](https://github.com/theos/theos/wiki)
- [iOS越狱开发入门](https://iphonedev.wiki/)
- [Logos语法文档](https://github.com/theos/logos/wiki)

---

## 💡 提示与技巧 | Tips & Tricks

### 1. 加速编译

```bash
# 使用多核编译
make package -j$(nproc)

# 只编译不打包（更快）
make
```

### 2. 查看详细错误

```bash
make package VERBOSE=1
```

### 3. 清理彻底

```bash
make clean
rm -rf .theos packages obj
```

### 4. 设置别名

在 `~/.bashrc` 添加：
```bash
alias mkpkg='make clean package'
alias mkinstall='make package install'
alias mkclean='make clean && rm -rf .theos packages obj'
```

### 5. 快速测试

```bash
# 编译 → 安装 → 测试 一条龙
make clean package install && echo "请在设备上测试微信"
```

---

## 📞 获取帮助 | Get Help

遇到问题？按以下顺序寻求帮助：

1. **查看文档**
   - 本文档及相关Linux文档
   - TROUBLESHOOTING.md

2. **运行检查脚本**
   ```bash
   ./check-env.sh
   ```

3. **查看详细错误**
   ```bash
   make package VERBOSE=1
   ```

4. **提交Issue**
   - 提供详细的错误信息
   - 说明您的系统环境
   - 附上check-env.sh输出

---

## ✅ 检查清单 | Checklist

编译前确认：

- [ ] 已阅读 LINUX_BUILD_GUIDE.md
- [ ] 已配置镜像（中国用户）
- [ ] 已安装Theos
- [ ] 已下载iOS SDK
- [ ] 运行 check-env.sh 全部通过
- [ ] 项目文件完整

首次编译：

- [ ] make clean 清理
- [ ] make package 编译
- [ ] 检查 packages/ 目录
- [ ] 验证 .deb 文件

安装测试：

- [ ] SSH连接正常
- [ ] 传输文件成功
- [ ] dpkg安装无错误
- [ ] 微信重启正常
- [ ] 手势功能正常

---

**祝编译顺利！| Happy Building!** 🎉

如有任何问题，请查看相关文档或提交Issue。
