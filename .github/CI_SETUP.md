# CI/CD 设置指南 / CI/CD Setup Guide

[English](#english) | [中文](#中文)

---

## English

### Overview

This document explains how to set up and use GitHub Actions for automatic building of the WeChat Keyboard Switch tweak.

### Prerequisites

- GitHub repository with the tweak code
- GitHub account with Actions enabled (free for public repositories)
- No local setup required - builds happen in the cloud

### Initial Setup

The GitHub Actions workflow is already configured in `.github/workflows/build.yml`. No additional setup is required.

### How It Works

#### Automatic Builds

The workflow automatically triggers when you:

1. **Push to tracked branches**: `main`, `master`, `develop`, `feat-wechat-keyboard-swipe-switcher`
2. **Create pull requests** to `main`, `master`, or `develop`
3. **Create version tags** (e.g., `v1.0.0`)

#### Manual Builds

You can also trigger builds manually:

1. Go to your repository on GitHub
2. Click the "Actions" tab
3. Select "Build WeChat Keyboard Switch" workflow
4. Click "Run workflow"
5. Choose the branch and click "Run workflow" button

### Getting Your Built Package

#### From Workflow Artifacts

1. Navigate to the "Actions" tab in your repository
2. Click on the completed workflow run
3. Scroll down to the "Artifacts" section
4. Download `WeChatKeyboardSwitch-rootless-{version}`
5. Extract the `.deb` file from the downloaded zip

#### From Releases (for tagged versions)

1. Go to the "Releases" section of your repository
2. Find your version (e.g., `v1.0.0`)
3. Download the `.deb` file directly

### Installing the Built Package

#### Method 1: SSH Transfer

```bash
# Download the .deb from GitHub
# Then transfer to your device
scp com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb root@YOUR_DEVICE_IP:/var/mobile/

# SSH into your device
ssh root@YOUR_DEVICE_IP

# Install
dpkg -i /var/mobile/com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb

# Respring
killall SpringBoard
```

#### Method 2: Filza

1. Download the `.deb` from GitHub to your computer
2. Transfer to your device via AirDrop, iTunes, or cloud storage
3. Open Filza on your device
4. Navigate to the file location
5. Tap the `.deb` file → Install
6. Respring

### Creating Releases

To create an official release with automatic package attachment:

```bash
# Make sure your code is ready
git add .
git commit -m "chore: prepare v1.0.0 release"
git push origin main

# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:
- Build the package automatically
- Create a GitHub Release
- Attach the `.deb` file to the release
- Generate release notes

### Workflow Status

#### Viewing Build Status

1. Go to the "Actions" tab
2. See the list of workflow runs
3. Click on any run to see detailed logs
4. Green checkmark ✅ = Success
5. Red X ❌ = Failed

#### Adding Status Badge

Add this to your README.md to show build status:

```markdown
![Build Status](https://github.com/YOUR_USERNAME/WeChatKeyboardSwitch/workflows/Build%20WeChat%20Keyboard%20Switch/badge.svg)
```

Replace `YOUR_USERNAME` with your GitHub username.

### Troubleshooting

#### Build Failed

1. Click on the failed workflow run
2. Review the error logs
3. Common issues:
   - Syntax errors in code
   - Missing files
   - Makefile configuration errors
4. Fix the issue and push again

#### No Artifacts Available

- Check if the build completed successfully
- Verify the workflow reached the "Upload Artifacts" step
- Check workflow logs for errors

#### Package Doesn't Install

- Verify you downloaded the correct `.deb` file
- Check if your device is running iOS 16+
- Ensure you have a rootless jailbreak
- Try installing dependencies manually:
  ```bash
  apt-get install mobilesubstrate preferenceloader
  ```

### Build Time

Typical build time: **3-5 minutes**

Includes:
- Setting up Ubuntu environment
- Installing dependencies
- Cloning Theos
- Downloading iOS SDK
- Building tweak and preference bundle
- Creating .deb package

### Cost

GitHub Actions is **free** for:
- Public repositories (unlimited minutes)
- Private repositories (2,000 minutes/month on free plan)

This project uses ~5 minutes per build.

### Best Practices

1. **Test locally first** before pushing (if you have Theos installed)
2. **Use meaningful commit messages** for easier tracking
3. **Tag releases** with semantic versioning (v1.0.0, v1.1.0, etc.)
4. **Review build logs** even when builds succeed
5. **Test built packages** on real devices before distributing

### Advanced Configuration

#### Changing Build Triggers

Edit `.github/workflows/build.yml`:

```yaml
on:
  push:
    branches:
      - main
      - your-branch-name  # Add your branch
```

#### Adding Build Steps

Add custom steps in the workflow:

```yaml
- name: Custom Step
  run: |
    echo "Your custom commands here"
```

#### Caching for Faster Builds

Add caching to speed up repeated builds:

```yaml
- name: Cache Theos
  uses: actions/cache@v3
  with:
    path: ~/theos
    key: ${{ runner.os }}-theos
```

---

## 中文

### 概述

本文档说明如何设置和使用 GitHub Actions 自动构建 WeChat Keyboard Switch 插件。

### 前置条件

- 包含插件代码的 GitHub 仓库
- 启用了 Actions 的 GitHub 账户（公开仓库免费）
- 无需本地设置 - 构建在云端进行

### 初始设置

GitHub Actions 工作流已在 `.github/workflows/build.yml` 中配置完成。无需额外设置。

### 工作原理

#### 自动构建

工作流在以下情况下自动触发：

1. **推送到跟踪的分支**：`main`、`master`、`develop`、`feat-wechat-keyboard-swipe-switcher`
2. **创建拉取请求**到 `main`、`master` 或 `develop`
3. **创建版本标签**（例如 `v1.0.0`）

#### 手动构建

您也可以手动触发构建：

1. 在 GitHub 上打开您的仓库
2. 点击 "Actions" 标签
3. 选择 "Build WeChat Keyboard Switch" 工作流
4. 点击 "Run workflow"
5. 选择分支并点击 "Run workflow" 按钮

### 获取构建的包

#### 从工作流产物

1. 导航到仓库的 "Actions" 标签
2. 点击已完成的工作流运行
3. 向下滚动到 "Artifacts" 部分
4. 下载 `WeChatKeyboardSwitch-rootless-{version}`
5. 从下载的 zip 中提取 `.deb` 文件

#### 从发布版本（针对标记的版本）

1. 转到仓库的 "Releases" 部分
2. 找到您的版本（例如 `v1.0.0`）
3. 直接下载 `.deb` 文件

### 安装构建的包

#### 方法 1：SSH 传输

```bash
# 从 GitHub 下载 .deb
# 然后传输到您的设备
scp com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb root@您的设备IP:/var/mobile/

# SSH 连接到您的设备
ssh root@您的设备IP

# 安装
dpkg -i /var/mobile/com.yourrepo.wechatkeyboardswitch_1.0.0_iphoneos-arm64.deb

# 注销重启
killall SpringBoard
```

#### 方法 2：Filza

1. 从 GitHub 下载 `.deb` 到您的电脑
2. 通过 AirDrop、iTunes 或云存储传输到您的设备
3. 在设备上打开 Filza
4. 导航到文件位置
5. 点击 `.deb` 文件 → 安装
6. 注销重启

### 创建发布

要创建自动附加包的正式发布版本：

```bash
# 确保您的代码已准备好
git add .
git commit -m "chore: prepare v1.0.0 release"
git push origin main

# 创建并推送版本标签
git tag v1.0.0
git push origin v1.0.0
```

工作流将：
- 自动构建包
- 创建 GitHub Release
- 将 `.deb` 文件附加到发布
- 生成发布说明

### 工作流状态

#### 查看构建状态

1. 转到 "Actions" 标签
2. 查看工作流运行列表
3. 点击任何运行以查看详细日志
4. 绿色对勾 ✅ = 成功
5. 红色 X ❌ = 失败

#### 添加状态徽章

将此添加到您的 README.md 以显示构建状态：

```markdown
![Build Status](https://github.com/您的用户名/WeChatKeyboardSwitch/workflows/Build%20WeChat%20Keyboard%20Switch/badge.svg)
```

将 `您的用户名` 替换为您的 GitHub 用户名。

### 故障排除

#### 构建失败

1. 点击失败的工作流运行
2. 查看错误日志
3. 常见问题：
   - 代码中的语法错误
   - 缺少文件
   - Makefile 配置错误
4. 修复问题并再次推送

#### 没有可用的产物

- 检查构建是否成功完成
- 验证工作流是否到达 "Upload Artifacts" 步骤
- 检查工作流日志中的错误

#### 包无法安装

- 验证您下载了正确的 `.deb` 文件
- 检查您的设备是否运行 iOS 16+
- 确保您有 rootless 越狱
- 尝试手动安装依赖项：
  ```bash
  apt-get install mobilesubstrate preferenceloader
  ```

### 构建时间

典型构建时间：**3-5 分钟**

包括：
- 设置 Ubuntu 环境
- 安装依赖项
- 克隆 Theos
- 下载 iOS SDK
- 构建插件和偏好设置包
- 创建 .deb 包

### 费用

GitHub Actions 对以下情况**免费**：
- 公开仓库（无限分钟数）
- 私有仓库（免费计划每月 2,000 分钟）

此项目每次构建使用约 5 分钟。

### 最佳实践

1. **推送前先在本地测试**（如果您安装了 Theos）
2. **使用有意义的提交消息**以便更容易跟踪
3. **使用语义化版本标记发布**（v1.0.0、v1.1.0 等）
4. **即使构建成功也要查看构建日志**
5. **在分发前在真实设备上测试构建的包**

### 高级配置

#### 更改构建触发器

编辑 `.github/workflows/build.yml`：

```yaml
on:
  push:
    branches:
      - main
      - your-branch-name  # 添加您的分支
```

#### 添加构建步骤

在工作流中添加自定义步骤：

```yaml
- name: Custom Step
  run: |
    echo "在这里添加您的自定义命令"
```

#### 缓存以加快构建速度

添加缓存以加快重复构建：

```yaml
- name: Cache Theos
  uses: actions/cache@v3
  with:
    path: ~/theos
    key: ${{ runner.os }}-theos
```

---

## 快速参考 / Quick Reference

### 触发构建 / Trigger Build
```bash
git push origin <branch-name>
```

### 创建发布 / Create Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

### 下载产物 / Download Artifact
Actions 标签 → 选择运行 → 下载产物 / Actions tab → Select run → Download artifact

### 安装包 / Install Package
```bash
dpkg -i *.deb && killall SpringBoard
```

---

**支持 / Support**: 在仓库中打开 issue / Open an issue in the repository
