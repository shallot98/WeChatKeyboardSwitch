# Changelog | 更新日志

All notable changes to this project will be documented in this file.

本文件记录项目的所有重要变更。

## [1.0.0] - 2024

### Added | 新增功能
- 🎉 Initial release of WeChat Keyboard Swipe tweak
- ⬆️ Swipe up gesture to switch to English input method
- ⬇️ Swipe down gesture to switch to Chinese input method
- 📱 Haptic feedback on input method switch
- 🎯 WeChat-only activation (bundle ID filtering)
- 🔧 Non-intrusive gesture recognition (doesn't interfere with typing)
- 📦 iOS 16 support (arm64/arm64e)
- 🌐 Support for both rootless and rootful jailbreak environments

### 新增功能（中文）
- 🎉 微信键盘滑动切换输入法插件首次发布
- ⬆️ 向上滑动切换到英文输入法
- ⬇️ 向下滑动切换到中文输入法
- 📱 切换输入法时提供触觉反馈
- 🎯 仅在微信应用中激活（Bundle ID过滤）
- 🔧 无侵入式手势识别（不影响正常打字）
- 📦 支持iOS 16（arm64/arm64e架构）
- 🌐 支持rootless和rootful越狱环境

### Technical Details | 技术细节
- Hook `UIInputWindowController` for keyboard view access
- Use `UISwipeGestureRecognizer` with `cancelsTouchesInView = NO`
- Implement input method switching via `UIKeyboardImpl` and `UITextInputMode`
- Add 0.5s delayed initialization for stable gesture setup
- Enable ARC for automatic memory management

---

## Future Plans | 未来计划

### [1.1.0] - Planned
- [ ] Preference bundle for customization
- [ ] Support for more input methods (not just Chinese/English)
- [ ] Configurable gesture directions
- [ ] Visual feedback (toast notification)
- [ ] Support for other messaging apps

### [1.1.0] - 计划中
- [ ] 添加偏好设置界面
- [ ] 支持更多输入法（不仅限中英文）
- [ ] 可配置的手势方向
- [ ] 视觉反馈（toast通知）
- [ ] 支持其他即时通讯应用

---

## Version Format | 版本格式

This project follows [Semantic Versioning](https://semver.org/):
- MAJOR version: Incompatible API changes
- MINOR version: Add functionality (backwards compatible)
- PATCH version: Bug fixes (backwards compatible)

本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)规范：
- 主版本号：不兼容的API变更
- 次版本号：向下兼容的功能性新增
- 修订号：向下兼容的问题修正
