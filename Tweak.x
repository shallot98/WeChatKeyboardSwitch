#import <UIKit/UIKit.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UITextInput.h>
#import <objc/runtime.h>

@class UITextInputMode;
@interface UIResponder (TextInputModeCompat)
@property (nonatomic, readonly, strong) UITextInputMode *textInputMode;
@end

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#define kWeChatInputMethodPrefix @"WeChat"
#define kKeyboardPrefix @"Keyboard"
#define kInputViewPrefix @"InputView"

#if __has_feature(objc_arc)
static __weak id wkFirstResponder;
#else
static __unsafe_unretained id wkFirstResponder;
#endif

@interface UIResponder (WKFirstResponder)
+ (id)wk_currentFirstResponder;
- (void)wk_findFirstResponder:(id)sender;
@end

@implementation UIResponder (WKFirstResponder)

+ (id)wk_currentFirstResponder {
    wkFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(wk_findFirstResponder:) to:nil from:nil forEvent:nil];
    return wkFirstResponder;
}

- (void)wk_findFirstResponder:(id)sender {
    wkFirstResponder = self;
}

@end

static BOOL isIOS16OrLater() {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    return version.majorVersion >= 16;
}

static void traverseWeChatKeyboardClasses() {
    NSLog(@"[WeChatIMEGestureSwitch] Starting to traverse WeChat keyboard-related classes...");
    NSLog(@"[WeChatIMEGestureSwitch] iOS Version: %@", [[UIDevice currentDevice] systemVersion]);
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *wechatKeyboardClasses = [NSMutableArray array];
    
    for (int i = 0; i < numClasses; i++) {
        const char *className = class_getName(classes[i]);
        NSString *classNameStr = [NSString stringWithUTF8String:className];
        
        if ([classNameStr containsString:kWeChatInputMethodPrefix] ||
            [classNameStr containsString:kKeyboardPrefix] ||
            [classNameStr containsString:kInputViewPrefix] ||
            [classNameStr containsString:@"WXKeyboard"] ||
            [classNameStr containsString:@"MMKeyboard"] ||
            [classNameStr containsString:@"InputBar"] ||
            [classNameStr containsString:@"TextInput"]) {
            [wechatKeyboardClasses addObject:classNameStr];
        }
    }
    
    free(classes);
    
    NSLog(@"[WeChatIMEGestureSwitch] Found %lu keyboard-related classes:", (unsigned long)wechatKeyboardClasses.count);
    for (NSString *className in [wechatKeyboardClasses sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"[WeChatIMEGestureSwitch]   - %@", className);
    }
}

static void switchInputLanguage() {
    NSLog(@"[WeChatIMEGestureSwitch] Attempting to switch input language...");
    
    [UIResponder wk_currentFirstResponder];
    UIResponder<UITextInput> *firstResponder = (UIResponder<UITextInput> *)wkFirstResponder;
    UITextInputMode *currentMode = nil;
    
    if (firstResponder && [firstResponder respondsToSelector:@selector(textInputMode)]) {
        currentMode = [(id)firstResponder textInputMode];
        NSString *primaryLang = currentMode.primaryLanguage;
        if (primaryLang != nil) {
            NSLog(@"[WeChatIMEGestureSwitch] Current input mode: %@", primaryLang);
        } else {
            NSLog(@"[WeChatIMEGestureSwitch] Current input mode has nil primaryLanguage (possibly third-party keyboard)");
        }
    } else {
        NSLog(@"[WeChatIMEGestureSwitch] Warning: No active text input found.");
    }
    
    NSArray *inputModes = [UITextInputMode activeInputModes];
    NSLog(@"[WeChatIMEGestureSwitch] Available input modes: %@", inputModes);
    
    if (inputModes.count < 2) {
        NSLog(@"[WeChatIMEGestureSwitch] Warning: Less than 2 input modes available. Cannot switch.");
        return;
    }
    
    NSInteger currentIndex = NSNotFound;
    if (currentMode != nil) {
        currentIndex = [inputModes indexOfObject:currentMode];
    }
    
    NSInteger nextIndex;
    if (currentIndex != NSNotFound) {
        nextIndex = (currentIndex + 1) % inputModes.count;
    } else {
        nextIndex = 0;
        NSLog(@"[WeChatIMEGestureSwitch] Current mode not found in available modes, defaulting to first mode.");
    }
    
    UITextInputMode *nextMode = inputModes[nextIndex];
    NSString *nextPrimaryLang = nextMode.primaryLanguage;
    if (nextPrimaryLang != nil) {
        NSLog(@"[WeChatIMEGestureSwitch] Switching to: %@", nextPrimaryLang);
    } else {
        NSLog(@"[WeChatIMEGestureSwitch] Switching to mode with nil primaryLanguage");
    }
    
    [[UIApplication sharedApplication] sendAction:@selector(handleKeyUIEvent:) to:nil from:nil forEvent:nil];
}

@interface UIView (WeChatIMEGestureSwitch)
@property (nonatomic, assign) BOOL hasWeChatGestureRecognizers;
@end

%hook UIInputView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) {
        return;
    }
    
    if ([self respondsToSelector:@selector(hasWeChatGestureRecognizers)] && self.hasWeChatGestureRecognizers) {
        return;
    }
    
    NSString *className = NSStringFromClass([self class]);
    NSLog(@"[WeChatIMEGestureSwitch] UIInputView didMoveToWindow: %@", className);
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(wechat_handleSwipeUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(wechat_handleSwipeDown:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self addGestureRecognizer:swipeDown];
    
    self.hasWeChatGestureRecognizers = YES;
    
    NSLog(@"[WeChatIMEGestureSwitch] Added gesture recognizers to: %@", className);
}

%new
- (void)wechat_handleSwipeUp:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"[WeChatIMEGestureSwitch] Swipe UP detected on: %@", NSStringFromClass([self class]));
    switchInputLanguage();
}

%new
- (void)wechat_handleSwipeDown:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"[WeChatIMEGestureSwitch] Swipe DOWN detected on: %@", NSStringFromClass([self class]));
    switchInputLanguage();
}

%new
- (BOOL)hasWeChatGestureRecognizers {
    return [objc_getAssociatedObject(self, @selector(hasWeChatGestureRecognizers)) boolValue];
}

%new
- (void)setHasWeChatGestureRecognizers:(BOOL)hasGestures {
    objc_setAssociatedObject(self, @selector(hasWeChatGestureRecognizers), @(hasGestures), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%hook UIKeyboardImpl

+ (instancetype)sharedInstance {
    UIKeyboardImpl *instance = %orig;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[WeChatIMEGestureSwitch] UIKeyboardImpl sharedInstance created");
        traverseWeChatKeyboardClasses();
    });
    
    return instance;
}

%end

%ctor {
    NSLog(@"[WeChatIMEGestureSwitch] ===== Tweak Loaded =====");
    
    if (!isIOS16OrLater()) {
        NSLog(@"[WeChatIMEGestureSwitch] Warning: iOS version is below 16.0. Some features may not work correctly.");
    } else {
        NSLog(@"[WeChatIMEGestureSwitch] iOS 16+ detected. Full compatibility enabled.");
    }
    
    NSLog(@"[WeChatIMEGestureSwitch] Gesture switch enabled: Swipe UP/DOWN on keyboard to switch input language");
    NSLog(@"[WeChatIMEGestureSwitch] ========================");
}
