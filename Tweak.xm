#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define PREF_PATH @"/var/jb/var/mobile/Library/Preferences/com.yourrepo.wechatkeyboardswitch.plist"
#define NOTIFICATION_NAME "com.yourrepo.wechatkeyboardswitch/prefsChanged"

static BOOL tweakEnabled = YES;
static UISwipeGestureRecognizer *upSwipeGesture = nil;
static UISwipeGestureRecognizer *downSwipeGesture = nil;

@interface UIKeyboardImpl : UIView
+ (instancetype)activeInstance;
- (void)setInputMode:(id)mode;
- (id)inputModeForCurrentLocale;
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

static void loadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    if (prefs) {
        tweakEnabled = [prefs[@"enabled"] boolValue];
    } else {
        tweakEnabled = YES;
    }
}

static void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPreferences();
    
    UIKeyboardImpl *keyboard = [objc_getClass("UIKeyboardImpl") activeInstance];
    if (keyboard) {
        if (tweakEnabled) {
            if (!upSwipeGesture) {
                upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:(id)keyboard action:@selector(handleUpSwipe:)];
                upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
                [keyboard addGestureRecognizer:upSwipeGesture];
            }
            
            if (!downSwipeGesture) {
                downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:(id)keyboard action:@selector(handleDownSwipe:)];
                downSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
                [keyboard addGestureRecognizer:downSwipeGesture];
            }
        } else {
            if (upSwipeGesture) {
                [keyboard removeGestureRecognizer:upSwipeGesture];
                upSwipeGesture = nil;
            }
            
            if (downSwipeGesture) {
                [keyboard removeGestureRecognizer:downSwipeGesture];
                downSwipeGesture = nil;
            }
        }
    }
}

static BOOL isWeChatKeyboard(UIKeyboardInputMode *mode) {
    if (!mode) return NO;
    
    NSString *identifier = mode.identifier;
    if (!identifier) return NO;
    
    return [identifier containsString:@"com.tencent.xin"] || 
           [identifier containsString:@"com.tencent.wechat"] ||
           [identifier containsString:@"WeChat"] ||
           [identifier containsString:@"Weixin"];
}

static void switchToInputMode(BOOL toEnglish) {
    @try {
        UIKeyboardInputModeController *controller = [objc_getClass("UIKeyboardInputModeController") sharedInputModeController];
        if (!controller) return;
        
        UIKeyboardInputMode *currentMode = [controller currentInputMode];
        if (!currentMode) return;
        
        if (!isWeChatKeyboard(currentMode)) {
            return;
        }
        
        NSArray *activeInputModes = [controller activeInputModes];
        if (!activeInputModes || activeInputModes.count == 0) return;
        
        UIKeyboardInputMode *targetMode = nil;
        
        for (UIKeyboardInputMode *mode in activeInputModes) {
            if (!isWeChatKeyboard(mode)) continue;
            
            NSString *primaryLanguage = mode.primaryLanguage;
            NSString *identifier = mode.identifier;
            
            if (toEnglish) {
                if ([primaryLanguage containsString:@"en"] || 
                    [identifier containsString:@"en"] ||
                    [identifier containsString:@"English"]) {
                    targetMode = mode;
                    break;
                }
            } else {
                if ([primaryLanguage containsString:@"zh"] || 
                    [identifier containsString:@"zh"] ||
                    [identifier containsString:@"Chinese"] ||
                    [identifier containsString:@"Pinyin"] ||
                    [identifier containsString:@"拼音"]) {
                    targetMode = mode;
                    break;
                }
            }
        }
        
        if (targetMode && targetMode != currentMode) {
            [controller changeToInputMode:targetMode];
            
            UIKeyboardImpl *keyboard = [objc_getClass("UIKeyboardImpl") activeInstance];
            if (keyboard) {
                [keyboard setInputMode:targetMode];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"[WeChatKeyboardSwitch] Error switching input mode: %@", exception);
    }
}

%hook UIKeyboardImpl

%new
- (void)handleUpSwipe:(UISwipeGestureRecognizer *)gesture {
    if (!tweakEnabled) return;
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        switchToInputMode(YES);
    }
}

%new
- (void)handleDownSwipe:(UISwipeGestureRecognizer *)gesture {
    if (!tweakEnabled) return;
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        switchToInputMode(NO);
    }
}

- (void)setDelegate:(id)delegate {
    %orig;
    
    if (!tweakEnabled) return;
    
    if (!upSwipeGesture) {
        upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpSwipe:)];
        upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:upSwipeGesture];
    }
    
    if (!downSwipeGesture) {
        downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDownSwipe:)];
        downSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:downSwipeGesture];
    }
}

%end

%ctor {
    loadPreferences();
    
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        preferencesChangedCallback,
        CFSTR(NOTIFICATION_NAME),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}
