#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Conditional debug logging
#ifdef DEBUG
#define DLog(fmt, ...) NSLog(@"[WeChatKeyboardSwitch] " fmt, ##__VA_ARGS__)
#else
#define DLog(fmt, ...)
#endif

// Constants
#define PREF_PATH @"/var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist"
#define NOTIFICATION_NAME "com.yourrepo.wechatkeyboardswitch/prefsChanged"
#define DEBOUNCE_INTERVAL 0.25
#define WECHAT_BUNDLE_ID @"com.tencent.xin"

// Forward declarations
@interface UIKeyboardImpl : UIView
+ (instancetype)activeInstance;
- (void)setInputMode:(id)mode;
- (id)inputModeForCurrentLocale;
- (BOOL)isInHardwareKeyboardMode;
@end

@interface UIKeyboardInputModeController : NSObject
+ (instancetype)sharedInputModeController;
- (NSArray *)enabledInputModeIdentifiers;
- (void)setCurrentInputMode:(id)mode;
- (id)currentInputMode;
- (NSArray *)activeInputModes;
- (void)changeToInputMode:(id)mode;
@end

@interface UIKeyboardInputMode : NSObject
@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *primaryLanguage;
- (BOOL)isExtensionInputMode;
- (NSString *)displayName;
+ (UIKeyboardInputMode *)keyboardInputModeWithIdentifier:(NSString *)identifier;
@end

@interface UIRemoteKeyboardWindow : UIWindow
@end

@interface UIInputSetHostView : UIView
@end

@interface UIKBKeyplaneView : UIView
@end

#pragma mark - PrefsManager

@interface PrefsManager : NSObject
+ (BOOL)isEnabled;
+ (void)reload;
@end

static BOOL g_tweakEnabled = YES;

@implementation PrefsManager

+ (BOOL)isEnabled {
    return g_tweakEnabled;
}

+ (void)reload {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    if (prefs) {
        g_tweakEnabled = [prefs[@"enabled"] boolValue];
    } else {
        g_tweakEnabled = YES;
    }
    DLog(@"Preferences reloaded: enabled=%d", g_tweakEnabled);
}

@end

#pragma mark - KeyboardSurfaceFinder

@interface KeyboardSurfaceFinder : NSObject
+ (UIView *)findKeyboardSurface;
@end

@implementation KeyboardSurfaceFinder

+ (UIView *)findKeyboardSurface {
    UIView *keyboardSurface = nil;
    
    // Try to find UIRemoteKeyboardWindow
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([window isKindOfClass:NSClassFromString(@"UIRemoteKeyboardWindow")]) {
            // Try to find UIInputSetHostView or UIKBKeyplaneView
            keyboardSurface = [self findKeyboardViewInHierarchy:window];
            if (keyboardSurface) {
                DLog(@"Found keyboard surface: %@", NSStringFromClass([keyboardSurface class]));
                return keyboardSurface;
            }
        }
    }
    
    // Fallback: use UIKeyboardImpl
    UIKeyboardImpl *keyboard = [NSClassFromString(@"UIKeyboardImpl") activeInstance];
    if (keyboard) {
        DLog(@"Using UIKeyboardImpl as fallback surface");
        return keyboard;
    }
    
    DLog(@"No keyboard surface found");
    return nil;
}

+ (UIView *)findKeyboardViewInHierarchy:(UIView *)view {
    Class inputSetHostView = NSClassFromString(@"UIInputSetHostView");
    Class keyplaneView = NSClassFromString(@"UIKBKeyplaneView");
    
    if ((inputSetHostView && [view isKindOfClass:inputSetHostView]) ||
        (keyplaneView && [view isKindOfClass:keyplaneView])) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *found = [self findKeyboardViewInHierarchy:subview];
        if (found) {
            return found;
        }
    }
    
    return nil;
}

@end

#pragma mark - ModeSwitcher

@interface ModeSwitcher : NSObject
+ (BOOL)isWeChatKeyboardActive;
+ (void)switchToMode:(BOOL)toEnglish;
@end

@implementation ModeSwitcher

+ (BOOL)isWeChatKeyboardActive {
    Class controllerClass = NSClassFromString(@"UIKeyboardInputModeController");
    if (!controllerClass || ![controllerClass respondsToSelector:@selector(sharedInputModeController)]) {
        return NO;
    }
    
    UIKeyboardInputModeController *controller = [controllerClass sharedInputModeController];
    if (!controller || ![controller respondsToSelector:@selector(currentInputMode)]) {
        return NO;
    }
    
    UIKeyboardInputMode *currentMode = [controller currentInputMode];
    if (!currentMode) {
        return NO;
    }
    
    NSString *identifier = currentMode.identifier;
    if (!identifier) {
        return NO;
    }
    
    BOOL isWeChat = [identifier containsString:@"com.tencent.xin"] || 
                    [identifier containsString:@"com.tencent.wechat"] ||
                    [identifier containsString:@"WeChat"] ||
                    [identifier containsString:@"Weixin"];
    
    DLog(@"Current input mode: %@ (WeChat: %d)", identifier, isWeChat);
    return isWeChat;
}

+ (void)switchToMode:(BOOL)toEnglish {
    @try {
        Class controllerClass = NSClassFromString(@"UIKeyboardInputModeController");
        if (!controllerClass || ![controllerClass respondsToSelector:@selector(sharedInputModeController)]) {
            DLog(@"UIKeyboardInputModeController not available");
            return;
        }
        
        UIKeyboardInputModeController *controller = [controllerClass sharedInputModeController];
        if (!controller) {
            DLog(@"Failed to get input mode controller");
            return;
        }
        
        if (![controller respondsToSelector:@selector(currentInputMode)] ||
            ![controller respondsToSelector:@selector(activeInputModes)] ||
            ![controller respondsToSelector:@selector(changeToInputMode:)]) {
            DLog(@"Required selectors not available");
            return;
        }
        
        UIKeyboardInputMode *currentMode = [controller currentInputMode];
        if (!currentMode) {
            DLog(@"No current input mode");
            return;
        }
        
        if (![self isWeChatKeyboardActive]) {
            DLog(@"WeChat keyboard not active, ignoring switch");
            return;
        }
        
        NSArray *activeInputModes = [controller activeInputModes];
        if (!activeInputModes || activeInputModes.count == 0) {
            DLog(@"No active input modes");
            return;
        }
        
        UIKeyboardInputMode *targetMode = [self findTargetMode:activeInputModes toEnglish:toEnglish];
        
        if (!targetMode) {
            DLog(@"No suitable %@ mode found", toEnglish ? @"English" : @"Chinese");
            return;
        }
        
        if ([targetMode.identifier isEqualToString:currentMode.identifier]) {
            DLog(@"Already in target mode: %@", targetMode.identifier);
            return;
        }
        
        DLog(@"Switching from %@ to %@", currentMode.identifier, targetMode.identifier);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller changeToInputMode:targetMode];
            
            // Also set on UIKeyboardImpl for redundancy
            Class keyboardImplClass = NSClassFromString(@"UIKeyboardImpl");
            if (keyboardImplClass && [keyboardImplClass respondsToSelector:@selector(activeInstance)]) {
                UIKeyboardImpl *keyboard = [keyboardImplClass activeInstance];
                if (keyboard && [keyboard respondsToSelector:@selector(setInputMode:)]) {
                    [keyboard setInputMode:targetMode];
                }
            }
            
            // Verify switch after a short delay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self verifySwitch:targetMode controller:controller];
            });
        });
        
    } @catch (NSException *exception) {
        DLog(@"Error switching input mode: %@", exception);
    }
}

+ (UIKeyboardInputMode *)findTargetMode:(NSArray *)activeInputModes toEnglish:(BOOL)toEnglish {
    UIKeyboardInputMode *weChatChineseMode = nil;
    UIKeyboardInputMode *weChatEnglishMode = nil;
    UIKeyboardInputMode *systemChineseMode = nil;
    UIKeyboardInputMode *systemEnglishMode = nil;
    
    for (UIKeyboardInputMode *mode in activeInputModes) {
        NSString *identifier = mode.identifier;
        NSString *primaryLanguage = mode.primaryLanguage;
        
        BOOL isWeChat = [identifier containsString:@"com.tencent.xin"] ||
                       [identifier containsString:@"com.tencent.wechat"] ||
                       [identifier containsString:@"WeChat"] ||
                       [identifier containsString:@"Weixin"];
        
        BOOL isChinese = [primaryLanguage hasPrefix:@"zh"] ||
                        [identifier containsString:@"zh-Hans"] ||
                        [identifier containsString:@"zh-Hant"] ||
                        [identifier containsString:@"Chinese"] ||
                        [identifier containsString:@"Pinyin"] ||
                        [identifier containsString:@"拼音"];
        
        BOOL isEnglish = [primaryLanguage hasPrefix:@"en"] ||
                        [identifier containsString:@"en_US"] ||
                        [identifier containsString:@"en-US"] ||
                        [identifier containsString:@"English"];
        
        if (isWeChat) {
            if (isChinese && !weChatChineseMode) {
                weChatChineseMode = mode;
            } else if (isEnglish && !weChatEnglishMode) {
                weChatEnglishMode = mode;
            }
        } else {
            if (isChinese && !systemChineseMode) {
                systemChineseMode = mode;
            } else if (isEnglish && !systemEnglishMode) {
                systemEnglishMode = mode;
            }
        }
    }
    
    // Prefer WeChat modes, fallback to system modes
    if (toEnglish) {
        return weChatEnglishMode ?: systemEnglishMode;
    } else {
        return weChatChineseMode ?: systemChineseMode;
    }
}

+ (void)verifySwitch:(UIKeyboardInputMode *)targetMode controller:(UIKeyboardInputModeController *)controller {
    if (![controller respondsToSelector:@selector(currentInputMode)]) {
        return;
    }
    
    UIKeyboardInputMode *currentMode = [controller currentInputMode];
    if (currentMode && ![currentMode.identifier isEqualToString:targetMode.identifier]) {
        DLog(@"Switch verification failed, retrying...");
        if ([controller respondsToSelector:@selector(changeToInputMode:)]) {
            [controller changeToInputMode:targetMode];
        }
    } else {
        DLog(@"Switch verified successfully");
    }
}

@end

#pragma mark - GestureManager

@interface GestureManager : NSObject
@property (nonatomic, weak) UIView *keyboardSurface;
@property (nonatomic, strong) UISwipeGestureRecognizer *upSwipeGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *downSwipeGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) NSDate *lastGestureTime;

- (void)attachGesturesToSurface:(UIView *)surface;
- (void)removeGestures;
- (void)handleUpSwipe:(UISwipeGestureRecognizer *)gesture;
- (void)handleDownSwipe:(UISwipeGestureRecognizer *)gesture;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
@end

static GestureManager *g_gestureManager = nil;

@implementation GestureManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _lastGestureTime = [NSDate distantPast];
    }
    return self;
}

- (void)attachGesturesToSurface:(UIView *)surface {
    if (!surface) {
        DLog(@"No surface provided for gesture attachment");
        return;
    }
    
    [self removeGestures];
    
    self.keyboardSurface = surface;
    
    // Up swipe gesture
    self.upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpSwipe:)];
    self.upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    self.upSwipeGesture.delaysTouchesBegan = NO;
    self.upSwipeGesture.delaysTouchesEnded = NO;
    self.upSwipeGesture.cancelsTouchesInView = NO;
    [surface addGestureRecognizer:self.upSwipeGesture];
    
    // Down swipe gesture
    self.downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDownSwipe:)];
    self.downSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    self.downSwipeGesture.delaysTouchesBegan = NO;
    self.downSwipeGesture.delaysTouchesEnded = NO;
    self.downSwipeGesture.cancelsTouchesInView = NO;
    [surface addGestureRecognizer:self.downSwipeGesture];
    
    // Pan gesture as fallback
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGesture.delaysTouchesBegan = NO;
    self.panGesture.delaysTouchesEnded = NO;
    self.panGesture.cancelsTouchesInView = NO;
    [surface addGestureRecognizer:self.panGesture];
    
    DLog(@"Gestures attached to surface: %@", NSStringFromClass([surface class]));
}

- (void)removeGestures {
    if (self.keyboardSurface) {
        if (self.upSwipeGesture) {
            [self.keyboardSurface removeGestureRecognizer:self.upSwipeGesture];
            self.upSwipeGesture = nil;
        }
        if (self.downSwipeGesture) {
            [self.keyboardSurface removeGestureRecognizer:self.downSwipeGesture];
            self.downSwipeGesture = nil;
        }
        if (self.panGesture) {
            [self.keyboardSurface removeGestureRecognizer:self.panGesture];
            self.panGesture = nil;
        }
        DLog(@"Gestures removed from surface");
    }
    self.keyboardSurface = nil;
}

- (BOOL)shouldProcessGesture {
    if (![PrefsManager isEnabled]) {
        DLog(@"Tweak disabled, ignoring gesture");
        return NO;
    }
    
    // Check for hardware keyboard
    Class keyboardImplClass = NSClassFromString(@"UIKeyboardImpl");
    if (keyboardImplClass && [keyboardImplClass respondsToSelector:@selector(activeInstance)]) {
        UIKeyboardImpl *keyboard = [keyboardImplClass activeInstance];
        if (keyboard && [keyboard respondsToSelector:@selector(isInHardwareKeyboardMode)]) {
            if ([keyboard isInHardwareKeyboardMode]) {
                DLog(@"Hardware keyboard active, ignoring gesture");
                return NO;
            }
        }
    }
    
    // Debounce
    NSTimeInterval timeSinceLastGesture = [[NSDate date] timeIntervalSinceDate:self.lastGestureTime];
    if (timeSinceLastGesture < DEBOUNCE_INTERVAL) {
        DLog(@"Gesture debounced (%.2fs since last)", timeSinceLastGesture);
        return NO;
    }
    
    if (![ModeSwitcher isWeChatKeyboardActive]) {
        DLog(@"WeChat keyboard not active");
        return NO;
    }
    
    return YES;
}

- (void)handleUpSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (![self shouldProcessGesture]) {
        return;
    }
    
    self.lastGestureTime = [NSDate date];
    DLog(@"Up swipe detected -> switching to English");
    [ModeSwitcher switchToMode:YES];
}

- (void)handleDownSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (![self shouldProcessGesture]) {
        return;
    }
    
    self.lastGestureTime = [NSDate date];
    DLog(@"Down swipe detected -> switching to Chinese");
    [ModeSwitcher switchToMode:NO];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    CGPoint velocity = [gesture velocityInView:gesture.view];
    CGPoint translation = [gesture translationInView:gesture.view];
    
    // Require significant vertical movement
    if (fabs(translation.y) < 50) {
        return;
    }
    
    // Require more vertical than horizontal movement
    if (fabs(translation.x) > fabs(translation.y)) {
        return;
    }
    
    // Require sufficient velocity
    if (fabs(velocity.y) < 200) {
        return;
    }
    
    if (![self shouldProcessGesture]) {
        return;
    }
    
    self.lastGestureTime = [NSDate date];
    
    if (velocity.y < 0) {
        // Swiped up
        DLog(@"Pan gesture detected (up) -> switching to English");
        [ModeSwitcher switchToMode:YES];
    } else {
        // Swiped down
        DLog(@"Pan gesture detected (down) -> switching to Chinese");
        [ModeSwitcher switchToMode:NO];
    }
}

- (void)dealloc {
    [self removeGestures];
}

@end

#pragma mark - Hooks

%hook UIKeyboardImpl

- (void)setDelegate:(id)delegate {
    %orig;
    
    if (![PrefsManager isEnabled]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_gestureManager) {
            g_gestureManager = [[GestureManager alloc] init];
        }
        
        UIView *surface = [KeyboardSurfaceFinder findKeyboardSurface];
        if (surface) {
            [g_gestureManager attachGesturesToSurface:surface];
        }
    });
}

%end

%hook UIRemoteKeyboardWindow

- (void)didMoveToWindow {
    %orig;
    
    if (![PrefsManager isEnabled]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!g_gestureManager) {
            g_gestureManager = [[GestureManager alloc] init];
        }
        
        UIView *surface = [KeyboardSurfaceFinder findKeyboardSurface];
        if (surface) {
            [g_gestureManager attachGesturesToSurface:surface];
        }
    });
}

%end

#pragma mark - Preferences Callback

static void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    DLog(@"Preferences changed notification received");
    [PrefsManager reload];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([PrefsManager isEnabled]) {
            if (!g_gestureManager) {
                g_gestureManager = [[GestureManager alloc] init];
            }
            
            UIView *surface = [KeyboardSurfaceFinder findKeyboardSurface];
            if (surface) {
                [g_gestureManager attachGesturesToSurface:surface];
            }
        } else {
            if (g_gestureManager) {
                [g_gestureManager removeGestures];
            }
        }
    });
}

#pragma mark - Constructor

%ctor {
    DLog(@"WeChatKeyboardSwitch initializing...");
    
    [PrefsManager reload];
    
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        preferencesChangedCallback,
        CFSTR(NOTIFICATION_NAME),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
    
    DLog(@"WeChatKeyboardSwitch initialized (enabled: %d)", [PrefsManager isEnabled]);
}
