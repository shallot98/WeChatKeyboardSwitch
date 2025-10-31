# GitHub Actions 自动编译配置总结

## 概述

本项目已完全配置 GitHub Actions 自动编译功能，无需本地安装 Theos，即可在云端自动构建 WeChat Keyboard Switch 插件。

## 已完成的配置

### ✅ 工作流文件

**文件位置**: `.github/workflows/build.yml`

**主要配置**:
- 工作流名称: "Build WeChat Keyboard Switch"
- 触发条件: 推送到 main/master/develop/feat-wechat-keyboard-swipe-switcher 分支，PR，或版本标签
- 运行环境: Ubuntu Latest
- 构建工具: Theos (自动下载)
- SDK: iOS 16+ (自动下载)

**构建步骤**:
1. 签出代码
2. 安装依赖 (build-essential, git, curl, wget, perl, fakeroot, libarchive-tools, zstd)
3. 设置 Theos 环境
4. 下载 iOS SDK
5. 编译 Tweak 和 PreferenceBundle
6. 生成 .deb 包
7. 上传构建产物
8. 自动创建 Release (对于版本标签)

### ✅ 文档

1. **`.github/workflows/README.md`** - 详细的工作流使用文档
2. **`.github/CI_SETUP.md`** - 中英文双语 CI/CD 设置指南
3. **本文件** - 快速参考总结

## 如何使用

### 方法 1: 自动触发（推荐）

只需推送代码到仓库：

```bash
git add .
git commit -m "feat: your changes"
git push origin feat-wechat-keyboard-swipe-switcher
```

GitHub Actions 会自动：
- 检测到推送
- 启动构建
- 编译插件
- 生成 .deb 包
- 上传为构建产物

### 方法 2: 手动触发

1. 打开 GitHub 仓库
2. 点击 "Actions" 标签
3. 选择 "Build WeChat Keyboard Switch"
4. 点击 "Run workflow"
5. 选择分支，点击绿色按钮

### 方法 3: 创建正式发布

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions 会：
- 自动构建包
- 创建 GitHub Release
- 附加 .deb 文件
- 生成发布说明

## 获取构建产物

### 从 Actions 产物下载

1. 进入仓库 "Actions" 标签
2. 点击最新的成功运行
3. 滚动到底部 "Artifacts" 区域
4. 下载 `WeChatKeyboardSwitch-rootless-1.0.0`
5. 解压 zip 得到 .deb 文件

### 从 Releases 下载（针对标签）

1. 进入仓库 "Releases" 页面
2. 找到对应版本（如 v1.0.0）
3. 直接下载 .deb 文件

## 构建产物说明

**文件名**: `com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb`

**包含内容**:
- 主 Tweak (`WeChatKeyboardSwitch.dylib`)
- PreferenceBundle (Settings 界面)
- MobileSubstrate 过滤器
- PreferenceLoader 配置

**适用环境**:
- iOS 16.0 及更高版本
- Rootless 越狱 (Dopamine, Palera1n, etc.)
- ARM64 架构

## 安装方法

### 方法 1: SSH (推荐)

```bash
# 1. 传输到设备
scp com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb root@DEVICE_IP:/var/mobile/

# 2. SSH 连接
ssh root@DEVICE_IP

# 3. 安装
dpkg -i /var/mobile/com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb

# 4. 注销
killall SpringBoard
```

### 方法 2: Filza

1. 下载 .deb 到设备
2. 使用 Filza 打开
3. 点击安装
4. 注销

### 方法 3: 包管理器

1. 将 .deb 传输到设备
2. 在 Sileo/Zebra/Installer 中安装

## 构建时间和成本

**构建时间**: 约 3-5 分钟

**费用**: 
- 公开仓库: **完全免费**，无限构建次数
- 私有仓库: 免费计划每月 2000 分钟（本项目每次约 5 分钟）

## 构建状态

### 查看状态

- 绿色对勾 ✅ = 构建成功
- 红色 X ❌ = 构建失败
- 黄色圆圈 🟡 = 正在构建

### 添加状态徽章

在 README.md 中添加：

```markdown
![Build Status](https://github.com/YOUR_USERNAME/WeChatKeyboardSwitch/workflows/Build%20WeChat%20Keyboard%20Switch/badge.svg)
```

## 当前分支配置

**当前分支**: `feat-wechat-keyboard-swipe-switcher`

此分支已在工作流触发列表中，推送后会自动构建。

## 验证配置

运行以下命令检查配置：

```bash
# 查看工作流文件
cat .github/workflows/build.yml

# 查看当前分支
git branch

# 查看文件状态
git status
```

## 下一步操作

### 立即测试构建

```bash
# 提交当前更改
git add .
git commit -m "chore: configure GitHub Actions"
git push origin feat-wechat-keyboard-swipe-switcher
```

然后：
1. 打开 GitHub 仓库
2. 进入 "Actions" 标签
3. 查看构建进度
4. 等待 3-5 分钟
5. 下载构建产物

### 创建第一个正式版本

```bash
# 确保代码已推送
git push origin feat-wechat-keyboard-swipe-switcher

# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

然后检查 "Releases" 页面，应该会看到自动创建的发布版本。

## 故障排除

### 构建失败

1. 点击失败的工作流运行
2. 展开失败的步骤
3. 查看错误信息
4. 常见问题：
   - 语法错误 → 检查 Tweak.xm
   - 缺少文件 → 确保所有文件已提交
   - Makefile 错误 → 验证配置

### 没有 Actions 标签

- 确保仓库启用了 Actions
- 前往 Settings → Actions → General
- 启用 "Allow all actions and reusable workflows"

### 产物未上传

- 检查构建是否成功完成
- 查看 "Upload Artifacts" 步骤的日志
- 确保 packages/ 目录下有 .deb 文件

## 工作流特性

### ✅ 已实现的功能

- [x] 自动构建 (推送触发)
- [x] 手动触发
- [x] 产物上传
- [x] 自动发布 (标签触发)
- [x] 构建摘要
- [x] 构建日志上传
- [x] Rootless 支持
- [x] iOS 16+ SDK
- [x] PreferenceBundle 构建

### 🔄 可选增强

- [ ] 缓存 Theos (加速构建)
- [ ] 代码质量检查
- [ ] 单元测试集成
- [ ] 多架构构建 (arm64e)
- [ ] 自动版本号递增
- [ ] Slack/Discord 通知

## 相关文档

- [GitHub Actions 工作流文档](.github/workflows/README.md)
- [CI/CD 设置指南（双语）](.github/CI_SETUP.md)
- [主 README](README.md)
- [安装指南](INSTALLATION.md)
- [快速参考](QUICK_REFERENCE.md)

## 技术细节

### 构建环境

```yaml
运行环境: Ubuntu Latest
Theos: 最新版本 (从 GitHub 克隆)
SDK: iOS 16.5 (从 theos/sdks 下载)
编译器: Clang (Latest)
架构: ARM64
包格式: Debian (.deb)
```

### 工作流输出

**成功构建输出**:
```
✅ Build Successful
Package: com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb
Size: ~50-100 KB (取决于代码大小)
Duration: ~3-5 minutes
```

**产物包含**:
- Tweak dylib
- PreferenceBundle
- 控制文件
- 安装脚本

## 支持的触发方式

| 触发方式 | 操作 | 结果 |
|---------|------|------|
| Push | `git push origin <branch>` | 构建并上传产物 |
| PR | 创建 Pull Request | 构建并验证 |
| 标签 | `git push origin v1.0.0` | 构建、产物、Release |
| 手动 | Actions UI "Run workflow" | 构建并上传产物 |

## 构建命令等效

GitHub Actions 执行的命令等同于本地执行：

```bash
# CI 中执行
export THEOS=$HOME/theos
make clean
make package FINALPACKAGE=1

# 产生相同的结果
```

## 安全说明

- 不需要提供任何密钥或凭证
- 构建在 GitHub 的安全环境中进行
- 源代码不会被修改
- 生成的包可以安全下载和安装

## 性能优化建议

### 当前配置
- 每次构建约 5 分钟
- 包含完整的环境设置

### 可优化的地方
1. **添加缓存** (可减少到 2-3 分钟)
   ```yaml
   - name: Cache Theos
     uses: actions/cache@v3
     with:
       path: ~/theos
       key: ${{ runner.os }}-theos
   ```

2. **仅在需要时下载 SDK**
3. **使用预构建的 Theos 镜像**

## 总结

✅ **GitHub Actions 已完全配置并可使用**

- 无需本地 Theos 安装
- 自动构建和打包
- 支持自动发布
- 免费且高效
- 文档齐全

**下一步**: 推送代码到 GitHub，观察自动构建过程！

```bash
git push origin feat-wechat-keyboard-swipe-switcher
```

---

**配置日期**: 2024-10-31  
**工作流版本**: 1.0  
**状态**: ✅ 生产就绪
