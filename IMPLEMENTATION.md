# 技术实现文档 | Technical Implementation Guide

## 项目概述 | Project Overview

这是一个基于Theos框架开发的iOS 16越狱插件，通过Hook微信键盘视图并添加手势识别，实现快速切换中英文输入法的功能。

This is an iOS 16 jailbreak tweak developed with Theos framework, implementing quick Chinese-English input method switching by hooking WeChat's keyboard view and adding gesture recognizers.

## 核心技术点 | Core Technical Points

### 1. Logos语法 | Logos Syntax

Logos是Theos提供的预处理器，扩展了Objective-C语法，简化Hook操作：

```objc
%hook ClassName        // Hook指定类
%new                   // 添加新方法
%orig                  // 调用原始实现
%ctor                  // 构造函数
%end                   // 结束Hook
```

### 2. 目标类选择 | Target Class Selection

**UIInputWindowController**
- iOS系统键盘窗口控制器
- 管理键盘视图的生命周期
- 在`viewDidLoad`时注入手势识别器
- 优点：稳定，适用于所有app包括微信

### 3. 手势识别实现 | Gesture Recognition Implementation

```objc
UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] 
                                      initWithTarget:self 
                                      action:@selector(handleSwipe:)];
gesture.direction = UISwipeGestureRecognizerDirectionUp; // 或 Down
gesture.numberOfTouchesRequired = 1;
gesture.cancelsTouchesInView = NO;      // 关键：不取消原有触摸事件
gesture.delaysTouchesEnded = NO;        // 关键：不延迟触摸结束事件
```

**关键参数说明：**
- `cancelsTouchesInView = NO`: 确保手势不会阻止键盘按键的正常点击
- `delaysTouchesEnded = NO`: 确保手势不会延迟键盘响应
- 单指滑动：避免与多指手势冲突

### 4. 输入法切换逻辑 | Input Method Switching Logic

```objc
// 获取所有可用输入法
NSArray *inputModes = [UITextInputMode activeInputModes];

// 遍历查找目标语言
for (UITextInputMode *mode in inputModes) {
    NSString *language = mode.primaryLanguage;
    if ([language hasPrefix:@"en"]) {
        // 通过UIKeyboardImpl切换
        [[UIKeyboardImpl sharedInstance] performSelector:@selector(setInputMode:) 
                                               withObject:mode];
        return;
    }
}
```

**语言代码识别：**
- 英文：`en`, `en-US`, `en_US`
- 中文：`zh`, `zh-Hans`, `zh_CN`, `zh-Hant`, `zh_TW`

### 5. 触觉反馈 | Haptic Feedback

```objc
UIImpactFeedbackGenerator *generator = 
    [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
[generator prepare];
[generator impactOccurred];
```

提供轻微震动反馈，提升用户体验。

### 6. Bundle过滤 | Bundle Filtering

通过两层过滤确保插件只在微信中生效：

**第一层：plist过滤**
```plist
{ Filter = { Bundles = ( "com.tencent.xin" ); }; }
```
- 系统级过滤，插件只在微信进程中加载
- 减少对其他app的性能影响

**第二层：代码过滤**
```objc
NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
if (![bundleID isEqualToString:@"com.tencent.xin"]) {
    return;
}
```
- 双重保险，防止意外情况

### 7. 延迟初始化 | Delayed Initialization

```objc
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), 
               dispatch_get_main_queue(), ^{
    [self setupSwipeGestures];
});
```

延迟0.5秒初始化手势，确保键盘视图完全加载。

## 编译配置 | Build Configuration

### Makefile解析

```makefile
TARGET := iphone:clang:16.0:16.0
# 格式：平台:编译器:SDK版本:最低支持版本

ARCHS = arm64 arm64e
# 支持arm64和arm64e架构（A12+设备需要arm64e）

WeChatKeyboardSwipe_CFLAGS = -fobjc-arc
# 启用ARC自动引用计数

WeChatKeyboardSwipe_FRAMEWORKS = UIKit CoreGraphics
# 链接必要的框架
```

### control文件说明

```
Package: com.tweak.wechatkeyboardswipe
# 唯一包标识符，反向域名格式

Architecture: iphoneos-arm64
# 支持的架构

Depends: mobilesubstrate, firmware (>= 16.0)
# 依赖：MobileSubstrate（Hook框架）和iOS 16+
```

## 兼容性考虑 | Compatibility Considerations

### iOS 16适配
- 使用iOS 16 SDK编译
- 测试rootless越狱（如palera1n）
- 测试rootful越狱（传统越狱）

### 多版本微信兼容
- Hook系统类而非微信私有类
- 避免依赖微信特定实现
- 理论支持所有微信版本

### 性能优化
- 静态变量缓存手势识别器
- 使用performSelector避免直接调用私有API
- Bundle过滤减少不必要的代码执行

## 调试方法 | Debugging Methods

### 1. 日志输出

在代码中添加NSLog：
```objc
NSLog(@"[WeChatKeyboardSwipe] Gesture recognized: %@", gesture);
```

查看日志：
```bash
ssh root@<device-ip>
tail -f /var/log/syslog | grep WeChatKeyboardSwipe
```

### 2. Cycript调试

```bash
cycript -p WeChat
# 在运行时注入代码进行调试
```

### 3. LLDB远程调试

配置debugserver进行断点调试。

## 潜在问题与解决方案 | Potential Issues & Solutions

### 问题1：手势冲突
**现象**：滑动手势干扰打字
**解决**：
- 设置`cancelsTouchesInView = NO`
- 设置`delaysTouchesEnded = NO`

### 问题2：切换无效
**现象**：滑动后输入法没有变化
**原因**：
- 设备未安装目标语言输入法
- iOS版本API变化
**解决**：
- 提示用户安装输入法
- 检查`activeInputModes`返回值

### 问题3：内存泄漏
**现象**：长时间使用后微信变慢
**解决**：
- 使用static变量而非每次创建
- 移除旧手势再添加新手势
- 启用ARC自动管理内存

## 安全性 | Security

- 不收集用户数据
- 不修改微信核心功能
- 仅在本地进行输入法切换
- 开源代码可审计

## 扩展功能建议 | Extension Suggestions

1. **可配置性**
   - 添加偏好设置Bundle
   - 自定义手势方向
   - 选择特定输入法

2. **更多手势**
   - 左右滑动切换其他输入法
   - 双指手势切换语音输入

3. **视觉反馈**
   - 显示当前输入法名称
   - Toast提示切换成功

4. **更多应用支持**
   - 扩展到QQ、钉钉等其他应用

## 参考资料 | References

- [Theos官方文档](https://github.com/theos/theos)
- [Logos语法指南](https://github.com/theos/logos)
- [iOS Private Headers](https://github.com/nst/iOS-Runtime-Headers)
- UIKit Framework Documentation

## 版本历史 | Version History

### v1.0.0
- 初始版本
- 支持上下滑动切换中英文
- 添加触觉反馈
- iOS 16兼容

---

**开发者备注**：本项目展示了iOS越狱开发的标准实践，适合作为Theos入门学习案例。
