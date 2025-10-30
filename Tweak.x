#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define kWeChatInputMethodPrefix @"WeChat"
#define kKeyboardPrefix @"Keyboard"
#define kInputViewPrefix @"InputView"

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
    
    UITextInputMode *currentMode = [UITextInputMode currentInputMode];
    NSLog(@"[WeChatIMEGestureSwitch] Current input mode: %@", currentMode.primaryLanguage);
    
    NSArray *inputModes = [UITextInputMode activeInputModes];
    NSLog(@"[WeChatIMEGestureSwitch] Available input modes: %@", inputModes);
    
    if (inputModes.count < 2) {
        NSLog(@"[WeChatIMEGestureSwitch] Warning: Less than 2 input modes available. Cannot switch.");
        return;
    }
    
    NSInteger currentIndex = [inputModes indexOfObject:currentMode];
    NSInteger nextIndex = (currentIndex + 1) % inputModes.count;
    
    UITextInputMode *nextMode = inputModes[nextIndex];
    NSLog(@"[WeChatIMEGestureSwitch] Switching to: %@", nextMode.primaryLanguage);
    
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
