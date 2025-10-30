# Project Index | 项目索引

Welcome to the WeChat Keyboard Swipe project! This index will help you navigate the project files.

欢迎来到微信键盘滑动切换输入法项目！此索引将帮助您浏览项目文件。

---

## 🚀 Getting Started | 快速开始

**New User?** Start here:
1. [README.md](README.md) - Project overview and features
2. [QUICKSTART.md](QUICKSTART.md) - Installation and usage guide

**新用户？** 从这里开始：
1. [README.md](README.md) - 项目概述和功能
2. [QUICKSTART.md](QUICKSTART.md) - 安装和使用指南

---

## 📚 Documentation | 文档

### For Users | 用户文档
| File | Description | 描述 |
|------|-------------|------|
| [README.md](README.md) | Main documentation | 主要文档 |
| [QUICKSTART.md](QUICKSTART.md) | Quick start guide | 快速入门指南 |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Problem solving | 故障排除 |
| [CHANGELOG.md](CHANGELOG.md) | Version history | 版本历史 |

### For Developers | 开发者文档
| File | Description | 描述 |
|------|-------------|------|
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | Technical details | 技术实现细节 |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Project overview | 项目总结 |
| [.github-description.md](.github-description.md) | GitHub description | GitHub描述 |

---

## 💻 Source Code | 源代码

### Core Files | 核心文件
| File | Lines | Purpose | 用途 |
|------|-------|---------|------|
| [Tweak.x](Tweak.x) | 125 | Main hook implementation | 主要Hook实现 |
| [Makefile](Makefile) | 15 | Build configuration | 构建配置 |
| [control](control) | 9 | Package metadata | 包元数据 |
| [WeChatKeyboardSwipe.plist](WeChatKeyboardSwipe.plist) | 1 | Bundle filter | Bundle过滤器 |

### Build Tools | 构建工具
| File | Purpose | 用途 |
|------|---------|------|
| [build.sh](build.sh) | Build automation script | 构建自动化脚本 |
| [.gitignore](.gitignore) | Git ignore rules | Git忽略规则 |

---

## 📖 Documentation Structure | 文档结构

```
Documentation Hierarchy | 文档层次结构
│
├── README.md ...................... Main entry point | 主入口
│   ├── Features ................... What it does | 功能介绍
│   ├── Installation ............... How to install | 安装方法
│   ├── Usage ...................... How to use | 使用方法
│   └── Compilation ................ How to build | 编译方法
│
├── QUICKSTART.md .................. Quick guide | 快速指南
│   ├── For Users .................. End-user guide | 用户指南
│   └── For Developers ............. Dev setup | 开发设置
│
├── IMPLEMENTATION.md .............. Technical deep dive | 技术深入
│   ├── Architecture ............... System design | 系统设计
│   ├── Hook Strategy .............. Hook方案
│   ├── API Usage .................. API使用
│   └── Best Practices ............. 最佳实践
│
├── TROUBLESHOOTING.md ............. Problem solving | 问题解决
│   ├── Common Issues .............. 常见问题
│   ├── Diagnostics ................ 诊断方法
│   └── Solutions .................. 解决方案
│
├── PROJECT_SUMMARY.md ............. Project overview | 项目概览
│   ├── Status ..................... 完成状态
│   ├── Architecture ............... 架构设计
│   └── Statistics ................. 统计信息
│
└── CHANGELOG.md ................... Version history | 版本历史
    └── Release notes .............. 发布说明
```

---

## 🎯 Quick Navigation | 快速导航

### I want to... | 我想要...

#### ...install the tweak | 安装插件
→ Go to [QUICKSTART.md](QUICKSTART.md) → Installation Section

#### ...use the tweak | 使用插件
→ Go to [README.md](README.md) → Usage Section

#### ...understand how it works | 了解工作原理
→ Go to [IMPLEMENTATION.md](IMPLEMENTATION.md)

#### ...solve a problem | 解决问题
→ Go to [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

#### ...build from source | 从源码编译
→ Go to [QUICKSTART.md](QUICKSTART.md) → Build & Install Section

#### ...contribute to the project | 为项目贡献
→ Go to [README.md](README.md) → Contributing Section

#### ...check what's new | 查看更新
→ Go to [CHANGELOG.md](CHANGELOG.md)

#### ...see project statistics | 查看项目统计
→ Go to [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

## 🔍 Code Reference | 代码参考

### Key Functions | 关键函数

| Function | Location | Purpose |
|----------|----------|---------|
| `setupSwipeGestures` | Tweak.x:29 | Initialize gesture recognizers |
| `handleUpSwipe` | Tweak.x:63 | Handle up swipe → English |
| `handleDownSwipe` | Tweak.x:71 | Handle down swipe → Chinese |
| `switchToEnglishInput` | Tweak.x:79 | Switch to English keyboard |
| `switchToChineseInput` | Tweak.x:92 | Switch to Chinese keyboard |
| `triggerHapticFeedback` | Tweak.x:105 | Provide haptic feedback |

### Hook Points | Hook点

| Hook | Location | Purpose |
|------|----------|---------|
| `UIInputWindowController` | Tweak.x:18 | Main keyboard controller |
| `viewDidLoad` | Tweak.x:20 | Initialization point |
| `UIKeyboardImpl` | Tweak.x:115 | Keyboard implementation |

---

## 📦 File Categories | 文件分类

### 📝 Documentation (8 files) | 文档
- README.md
- QUICKSTART.md
- IMPLEMENTATION.md
- TROUBLESHOOTING.md
- PROJECT_SUMMARY.md
- CHANGELOG.md
- INDEX.md (this file)
- .github-description.md

### 💻 Source Code (4 files) | 源代码
- Tweak.x
- Makefile
- control
- WeChatKeyboardSwipe.plist

### 🛠️ Build Tools (2 files) | 构建工具
- build.sh
- .gitignore

### 📄 Legal (1 file) | 法律文件
- LICENSE

**Total:** 15 files

---

## 📊 Documentation Statistics | 文档统计

| Category | Files | Approx. Lines |
|----------|-------|---------------|
| User Documentation | 4 | ~800 |
| Developer Documentation | 3 | ~500 |
| Source Code | 4 | ~150 |
| Build Tools | 2 | ~100 |
| Total | 15+ | ~1,550 |

---

## 🌐 Language Support | 语言支持

All major documentation includes:
- 🇺🇸 English
- 🇨🇳 简体中文 (Simplified Chinese)

主要文档均包含：
- 英文说明
- 中文说明

---

## 🔖 Tags & Keywords | 标签与关键词

**Technical:** iOS, Jailbreak, Theos, Logos, Objective-C, UIKit, Gesture  
**Functional:** Input Method, Keyboard, WeChat, Swipe, IME  
**Platform:** iOS 16, arm64, arm64e, rootless, rootful  

---

## 📞 Support Resources | 支持资源

1. **Documentation** - Read the docs first
2. **Troubleshooting** - Check common issues
3. **GitHub Issues** - Report bugs or request features
4. **Community** - Join jailbreak forums

---

## ⭐ Recommended Reading Order | 推荐阅读顺序

### For End Users | 终端用户
1. README.md (Overview)
2. QUICKSTART.md (Installation)
3. TROUBLESHOOTING.md (If issues)
4. CHANGELOG.md (What's new)

### For Developers | 开发者
1. README.md (Overview)
2. IMPLEMENTATION.md (Technical details)
3. PROJECT_SUMMARY.md (Architecture)
4. Tweak.x (Source code)
5. QUICKSTART.md (Build instructions)

### For Contributors | 贡献者
1. PROJECT_SUMMARY.md (Project status)
2. IMPLEMENTATION.md (Code structure)
3. Tweak.x (Current implementation)
4. README.md (Contribution guidelines)

---

## 🎓 Learning Path | 学习路径

**Beginner → Advanced**

1. **Install & Use** (User level)
   - README.md → QUICKSTART.md

2. **Understand How** (Learner level)
   - IMPLEMENTATION.md → Tweak.x

3. **Build & Modify** (Developer level)
   - QUICKSTART.md (Build section) → Makefile → control

4. **Contribute** (Contributor level)
   - PROJECT_SUMMARY.md → All docs → Source code

---

## 🚀 Quick Links | 快速链接

| I need to... | Go to |
|--------------|-------|
| Install | [QUICKSTART.md](QUICKSTART.md) |
| Use | [README.md](README.md) |
| Fix issues | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Understand | [IMPLEMENTATION.md](IMPLEMENTATION.md) |
| Build | [QUICKSTART.md](QUICKSTART.md) |
| Contribute | [README.md](README.md) |

---

## 📝 Notes | 注意事项

- All file paths are relative to project root
- Documentation uses Markdown format
- Source code uses Objective-C with Logos syntax
- Build requires Theos framework
- Compatible with iOS 16+ only

---

**Last Updated:** 2024  
**Document Version:** 1.0.0

---

*Happy coding! | 编码愉快！* 🎉
