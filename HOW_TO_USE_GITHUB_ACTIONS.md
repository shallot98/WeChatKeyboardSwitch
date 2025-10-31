# 如何使用 GitHub Actions 自动编译

## 简介

本项目已配置完整的 GitHub Actions 自动编译功能。您无需在本地安装 Theos，只需推送代码到 GitHub，即可自动构建 .deb 安装包。

## 快速开始

### 第一步：推送代码

```bash
# 添加所有文件
git add .

# 提交更改
git commit -m "feat: configure GitHub Actions"

# 推送到 GitHub
git push origin feat-wechat-keyboard-swipe-switcher
```

### 第二步：查看构建

1. 打开 GitHub 仓库页面
2. 点击顶部的 **"Actions"** 标签
3. 查看正在运行或已完成的工作流

### 第三步：下载产物

构建成功后（约 3-5 分钟）：

1. 点击已完成的工作流运行
2. 滚动到页面底部 **"Artifacts"** 区域
3. 点击下载 `WeChatKeyboardSwitch-rootless-1.0.0`
4. 解压 ZIP 文件，得到 `.deb` 包

### 第四步：安装到设备

**方法 1 - SSH**:
```bash
scp *.deb root@设备IP:/var/mobile/
ssh root@设备IP
dpkg -i /var/mobile/*.deb
killall SpringBoard
```

**方法 2 - Filza**:
1. 传输 .deb 到设备
2. 用 Filza 打开并安装
3. 注销重启

## 自动构建触发条件

GitHub Actions 会在以下情况自动构建：

✅ **推送到以下分支**:
- `main`
- `master`
- `develop`
- `feat-wechat-keyboard-swipe-switcher` (当前分支)

✅ **创建 Pull Request** 到主分支

✅ **推送版本标签** (如 `v1.0.0`)

## 创建正式发布版本

如果您想创建一个正式的发布版本（带 Release 页面）：

```bash
# 1. 确保代码已提交并推送
git add .
git commit -m "chore: release v1.0.0"
git push origin feat-wechat-keyboard-swipe-switcher

# 2. 创建版本标签
git tag v1.0.0

# 3. 推送标签
git push origin v1.0.0
```

GitHub Actions 会：
- 自动构建包
- 创建 Release 页面
- 附加 .deb 文件
- 生成发布说明

然后您可以在仓库的 **"Releases"** 页面直接下载 .deb 文件。

## 手动触发构建

如果您想在不推送代码的情况下触发构建：

1. 进入 GitHub 仓库
2. 点击 **"Actions"** 标签
3. 选择 **"Build WeChat Keyboard Switch"** 工作流
4. 点击右侧的 **"Run workflow"** 按钮
5. 选择分支，点击绿色的 **"Run workflow"**

## 构建状态说明

| 图标 | 状态 | 说明 |
|-----|------|------|
| 🟡 黄色圆圈 | 进行中 | 正在构建，等待 3-5 分钟 |
| ✅ 绿色对勾 | 成功 | 构建完成，可以下载产物 |
| ❌ 红色叉号 | 失败 | 构建失败，点击查看日志 |

## 构建失败怎么办？

如果构建失败：

1. 点击失败的工作流运行
2. 展开红色的失败步骤
3. 查看错误信息
4. 修复代码中的问题
5. 重新推送

常见错误：
- **语法错误**: 检查 `Tweak.xm` 文件
- **缺少文件**: 确保所有文件都已 `git add`
- **Makefile 错误**: 检查 `Makefile` 配置

## 费用说明

✅ **完全免费**
- 公开仓库无限制使用
- 私有仓库每月 2000 分钟免费额度
- 本项目每次构建约 5 分钟

## 构建包说明

**构建产物**:
- 文件名: `com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb`
- 大小: 约 50-100 KB
- 架构: ARM64
- 兼容: iOS 16+ rootless 越狱

**包含内容**:
- 主插件 (Tweak)
- 设置界面 (PreferenceBundle)
- 配置文件

## 查看构建日志

如果您想查看详细的构建过程：

1. 进入 Actions 标签
2. 点击任意工作流运行
3. 展开各个步骤查看输出

主要步骤：
1. 签出代码
2. 安装依赖
3. 设置 Theos
4. 下载 iOS SDK
5. 编译 Tweak
6. 编译 PreferenceBundle
7. 打包 .deb
8. 上传产物

## 进阶使用

### 添加构建状态徽章

在 README.md 顶部已添加构建状态徽章：

```markdown
[![Build Status](https://github.com/用户名/仓库名/workflows/Build%20WeChat%20Keyboard%20Switch/badge.svg)](链接)
```

将 `用户名` 和 `仓库名` 替换为您的实际信息。

### 修改构建配置

如需修改构建配置，编辑 `.github/workflows/build.yml` 文件。

### 添加更多触发分支

在 `build.yml` 中添加：

```yaml
on:
  push:
    branches:
      - main
      - your-new-branch  # 添加新分支
```

## 常见问题

**Q: 为什么没有 Actions 标签？**
A: 确保仓库启用了 Actions。前往 Settings → Actions → General → 启用 Actions。

**Q: 产物在哪里？**
A: 点击工作流运行，滚动到页面底部的 "Artifacts" 区域。

**Q: 可以下载到手机上直接安装吗？**
A: 需要先下载到电脑，然后通过 SSH、Filza 或 AirDrop 传输到设备。

**Q: 构建需要多长时间？**
A: 通常 3-5 分钟，取决于 GitHub 服务器负载。

**Q: 可以取消正在运行的构建吗？**
A: 可以。在 Actions 页面点击工作流运行，然后点击 "Cancel workflow"。

## 相关文档

- 📖 [详细 CI/CD 文档](.github/workflows/README.md)
- 🌐 [中英文设置指南](.github/CI_SETUP.md)
- 📝 [GitHub Actions 总结](GITHUB_ACTIONS_SUMMARY.md)
- 📘 [主 README](README.md)

## 下一步

✅ **现在就试试！**

```bash
# 提交当前更改
git add .
git commit -m "docs: add GitHub Actions instructions"
git push origin feat-wechat-keyboard-swipe-switcher
```

然后打开 GitHub Actions 页面，观察您的第一次自动构建！

---

**提示**: 首次构建可能需要稍长时间（约 5 分钟），因为需要下载 Theos 和 SDK。后续构建会更快。

**技术支持**: 如有问题，请在仓库中创建 Issue。
