/*
 * WeChatKeyboardSwitch - Rootless iOS Tweak
 * Target: WeChat (com.tencent.xin)
 * iOS 13.0 - 16.5
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
#import <objc/message.h>
#import <objc/runtime.h>

#ifndef WKS_DEBUG
#define WKS_DEBUG 0
#endif

#if WKS_DEBUG
#define WKSLog(fmt, ...) NSLog(@"[WeChatKeyboardSwitch] " fmt, ##__VA_ARGS__)
#else
#define WKSLog(fmt, ...) ((void)0)
#endif

static BOOL WKSIsMainThread(void) {
    return [NSThread isMainThread];
}

static void WKSPerformOnMainThread(void (^block)(void)) {
    if (!block) {
        return;
    }
    if (WKSIsMainThread()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

static BOOL WKSPerformOnMainThreadReturningBOOL(BOOL (^block)(void)) {
    if (!block) {
        return NO;
    }
    if (WKSIsMainThread()) {
        return block();
    }
    __block BOOL result = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        result = block();
    });
    return result;
}

static id WKSPerformOnMainThreadReturningId(id (^block)(void)) {
    if (!block) {
        return nil;
    }
    if (WKSIsMainThread()) {
        return block();
    }
    __block id result = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        result = block();
    });
    return result;
}

static NSString * const kWeChatBundleIdentifier = @"com.tencent.xin";
static NSString * const kPreferencesDomain = @"com.wechat.keyboardswitch";
static NSString * const kPrefsChangedNotification = @"com.wechat.keyboardswitch.prefschanged";
static const CFTimeInterval kGestureDebounceInterval = 0.35;
static const CGFloat kBottomExclusionHeight = 54.0;

static BOOL kPrefEnabled = YES;
static BOOL kPrefOnlyWeChat = YES;
static BOOL kPrefInvertDirection = NO;
static BOOL kPrefHapticFeedback = YES;

@interface UIKeyboardLayout : UIView
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
@end

@interface UIKeyboardDockView : UIView
@end

@interface UIKeyboardImpl : UIView
+ (instancetype)activeInstance;
+ (instancetype)sharedInstance;
- (id)inputMode;
@end

@interface UIKeyboardInputModeController : NSObject
+ (instancetype)sharedInstance;
- (NSArray *)activeInputModes;
- (id)currentInputMode;
- (void)setCurrentInputMode:(id)mode;
- (id)keyboardInputModeWithIdentifier:(NSString *)identifier;
@end

@interface UIKeyboardInputMode : NSObject
- (NSString *)identifier;
- (NSString *)primaryLanguage;
@end

@interface UITextInputMode (Private)
- (NSString *)identifier;
@end

static id WKSCallSelectorReturningId(id target, SEL selector) {
    if (!target || !selector || ![target respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(target, selector);
}

static void WKSCallSelector(id target, SEL selector) {
    if (!target || !selector || ![target respondsToSelector:selector]) {
        return;
    }
    ((void (*)(id, SEL))objc_msgSend)(target, selector);
}

static void WKSCallSelectorWithObject(id target, SEL selector, id object) {
    if (!target || !selector || ![target respondsToSelector:selector]) {
        return;
    }
    ((void (*)(id, SEL, id))objc_msgSend)(target, selector, object);
}

static id WKSCallSelectorReturningIdWithObject(id target, SEL selector, id object) {
    if (!target || !selector || ![target respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL, id))objc_msgSend)(target, selector, object);
}

static NSString *WKSIdentifierFromMode(id mode) {
    if (!mode) {
        return nil;
    }
    SEL identifierSel = @selector(identifier);
    id value = WKSCallSelectorReturningId(mode, identifierSel);
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    @try {
        value = [mode valueForKey:@"identifier"];
        if ([value isKindOfClass:[NSString class]]) {
            return value;
        }
    } @catch (__unused NSException *exception) {
    }
    return nil;
}

static NSString *WKSPrimaryLanguageFromMode(id mode) {
    if (!mode) {
        return nil;
    }
    SEL languageSel = @selector(primaryLanguage);
    id value = WKSCallSelectorReturningId(mode, languageSel);
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    @try {
        value = [mode valueForKey:@"primaryLanguage"];
        if ([value isKindOfClass:[NSString class]]) {
            return value;
        }
    } @catch (__unused NSException *exception) {
    }
    return nil;
}

static BOOL WKSIdentifierMatchesChinesePinyin(NSString *identifier) {
    if (identifier.length == 0) {
        return NO;
    }
    if ([identifier caseInsensitiveCompare:@"zh-Hans-Pinyin"] == NSOrderedSame) {
        return YES;
    }
    NSRange range = [identifier rangeOfString:@"zh-Hans" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound && [identifier rangeOfString:@"pinyin" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return YES;
    }
    return NO;
}

static BOOL WKSIdentifierMatchesChineseSimplified(NSString *identifier, NSString *primaryLanguage) {
    if (identifier.length > 0) {
        if ([identifier rangeOfString:@"zh-Hans" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
        if ([identifier rangeOfString:@"zh_CN" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    if (primaryLanguage.length > 0 && [primaryLanguage hasPrefix:@"zh-Hans"]) {
        return YES;
    }
    return NO;
}

static BOOL WKSIdentifierMatchesEnglish(NSString *identifier, NSString *primaryLanguage) {
    if (identifier.length > 0) {
        if ([identifier hasPrefix:@"en_"] || [identifier hasPrefix:@"en-"]) {
            return YES;
        }
        if ([identifier caseInsensitiveCompare:@"en_US"] == NSOrderedSame || [identifier caseInsensitiveCompare:@"en_GB"] == NSOrderedSame) {
            return YES;
        }
    }
    if (primaryLanguage.length > 0 && [primaryLanguage hasPrefix:@"en"]) {
        return YES;
    }
    return NO;
}

static BOOL WKSGetBoolPreference(CFStringRef key, BOOL defaultValue) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, (__bridge CFStringRef)kPreferencesDomain);
    BOOL result = defaultValue;
    if (value) {
        if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            result = CFBooleanGetValue((CFBooleanRef)value);
        } else if (CFGetTypeID(value) == CFNumberGetTypeID()) {
            int number = 0;
            CFNumberGetValue((CFNumberRef)value, kCFNumberIntType, &number);
            result = (number != 0);
        }
        CFRelease(value);
    }
    return result;
}

static void WKSLoadPreferences(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPreferencesDomain);
    kPrefEnabled = WKSGetBoolPreference(CFSTR("Enabled"), YES);
    kPrefOnlyWeChat = WKSGetBoolPreference(CFSTR("OnlyWeChat"), YES);
    kPrefInvertDirection = WKSGetBoolPreference(CFSTR("InvertDirection"), NO);
    kPrefHapticFeedback = WKSGetBoolPreference(CFSTR("HapticFeedback"), YES);
#if WKS_DEBUG
    WKSLog(@"Preferences loaded - Enabled: %d, OnlyWeChat: %d, InvertDirection: %d, HapticFeedback: %d",
           kPrefEnabled, kPrefOnlyWeChat, kPrefInvertDirection, kPrefHapticFeedback);
#endif
}

static void WKSPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
#if WKS_DEBUG
    WKSLog(@"Received preferences change notification");
#endif
    WKSLoadPreferences();
}

static void WKSRegisterForPreferenceChanges(void) {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    WKSPreferencesChanged,
                                    (__bridge CFStringRef)kPrefsChangedNotification,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

static BOOL WKSIsWeChatProcess(void) {
    static dispatch_once_t onceToken;
    static BOOL isWeChat = NO;
    dispatch_once(&onceToken, ^{
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        isWeChat = [bundleIdentifier isEqualToString:kWeChatBundleIdentifier];
#if WKS_DEBUG
        if (!isWeChat) {
            WKSLog(@"Running in bundle: %@", bundleIdentifier);
        }
#endif
    });
    return isWeChat;
}

static BOOL WKSShouldActivate(void) {
    if (!kPrefEnabled) {
        return NO;
    }
    if (kPrefOnlyWeChat) {
        return WKSIsWeChatProcess();
    }
    return YES;
}

static BOOL WKSShouldProvideHapticFeedback(void) {
    return kPrefHapticFeedback;
}

static void WKSTriggerHapticFeedback(void) {
    if (!WKSShouldProvideHapticFeedback()) {
        return;
    }
    Class generatorClass = NSClassFromString(@"UIImpactFeedbackGenerator");
    if (!generatorClass) {
        return;
    }
    static id generator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        generator = [[generatorClass alloc] initWithStyle:UIImpactFeedbackStyleLight];
    });
    if ([generator respondsToSelector:@selector(impactOccurred)]) {
        [generator impactOccurred];
        if ([generator respondsToSelector:@selector(prepare)]) {
            [generator prepare];
        }
    }
}

@interface WKSKeyboardInputHelper : NSObject
+ (instancetype)sharedHelper;
- (BOOL)toggleBetweenChineseAndEnglish;
- (BOOL)switchToChineseInputMode;
- (BOOL)switchToEnglishInputMode;
@end

@implementation WKSKeyboardInputHelper

+ (instancetype)sharedHelper {
    static dispatch_once_t onceToken;
    static WKSKeyboardInputHelper *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)inputModeController {
    return WKSPerformOnMainThreadReturningId(^id{
        Class controllerClass = NSClassFromString(@"UIKeyboardInputModeController");
        if (!controllerClass) {
            return nil;
        }
        SEL selectors[] = { @selector(sharedInstance), NSSelectorFromString(@"sharedInputModeController") };
        for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
            SEL sel = selectors[i];
            if ([controllerClass respondsToSelector:sel]) {
                id controller = WKSCallSelectorReturningId(controllerClass, sel);
                if (controller) {
                    return controller;
                }
            }
        }
        return nil;
    });
}

- (NSArray *)activeInputModes {
    NSArray *modes = WKSPerformOnMainThreadReturningId(^id{
        id controller = [self inputModeController];
        SEL activeSel = @selector(activeInputModes);
        id activeModes = nil;
        if (controller && [controller respondsToSelector:activeSel]) {
            activeModes = WKSCallSelectorReturningId(controller, activeSel);
        }
        if (!activeModes && [UITextInputMode respondsToSelector:@selector(activeInputModes)]) {
            activeModes = [UITextInputMode activeInputModes];
        }
        if (![activeModes isKindOfClass:[NSArray class]]) {
            return @[];
        }
        return activeModes;
    });
    if (![modes isKindOfClass:[NSArray class]]) {
        return @[];
    }
    return modes;
}

- (id)currentInputMode {
    return WKSPerformOnMainThreadReturningId(^id{
        id controller = [self inputModeController];
        SEL currentSel = @selector(currentInputMode);
        if (controller && [controller respondsToSelector:currentSel]) {
            id mode = WKSCallSelectorReturningId(controller, currentSel);
            if (mode) {
                return mode;
            }
        }
        UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
        if (!impl) {
            impl = [UIKeyboardImpl sharedInstance];
        }
        if (impl && [impl respondsToSelector:@selector(inputMode)]) {
            id mode = WKSCallSelectorReturningId(impl, @selector(inputMode));
            if (mode) {
                return mode;
            }
        }
        NSArray *activeModes = [self activeInputModes];
        return activeModes.count > 0 ? activeModes.firstObject : nil;
    });
}

- (NSString *)findIdentifierMatchingPredicate:(BOOL (^)(NSString *identifier, NSString *language))predicate {
    if (!predicate) {
        return nil;
    }
    for (id mode in [self activeInputModes]) {
        NSString *identifier = WKSIdentifierFromMode(mode);
        NSString *language = WKSPrimaryLanguageFromMode(mode);
        if (predicate(identifier, language)) {
            return identifier;
        }
    }
    return nil;
}

- (id)canonicalInputModeForIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    return WKSPerformOnMainThreadReturningId(^id{
        id controller = [self inputModeController];
        SEL lookupSel = @selector(keyboardInputModeWithIdentifier:);
        if (controller && [controller respondsToSelector:lookupSel]) {
            id mode = WKSCallSelectorReturningIdWithObject(controller, lookupSel, identifier);
            if (mode) {
                return mode;
            }
        }
        for (id mode in [self activeInputModes]) {
            NSString *candidate = WKSIdentifierFromMode(mode);
            if (candidate.length > 0 && [candidate isEqualToString:identifier]) {
                return mode;
            }
        }
        return nil;
    });
}

- (NSString *)preferredChineseInputModeIdentifier {
    NSString *identifier = [self findIdentifierMatchingPredicate:^BOOL(NSString *identifier, NSString *language) {
        return WKSIdentifierMatchesChinesePinyin(identifier);
    }];
    if (identifier.length > 0) {
        return identifier;
    }
    return [self findIdentifierMatchingPredicate:^BOOL(NSString *identifier, NSString *language) {
        return WKSIdentifierMatchesChineseSimplified(identifier, language);
    }];
}

- (id)preferredChineseInputMode {
    NSString *identifier = [self preferredChineseInputModeIdentifier];
    if (identifier.length == 0) {
        return nil;
    }
    return [self canonicalInputModeForIdentifier:identifier];
}

- (NSString *)preferredEnglishInputModeIdentifier {
    return [self findIdentifierMatchingPredicate:^BOOL(NSString *identifier, NSString *language) {
        return WKSIdentifierMatchesEnglish(identifier, language);
    }];
}

- (id)preferredEnglishInputMode {
    NSString *identifier = [self preferredEnglishInputModeIdentifier];
    if (identifier.length == 0) {
        return nil;
    }
    return [self canonicalInputModeForIdentifier:identifier];
}

- (BOOL)switchToInputModeIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return NO;
    }
    id currentMode = [self currentInputMode];
    NSString *currentIdentifier = WKSIdentifierFromMode(currentMode);
    if (currentIdentifier.length > 0 && [currentIdentifier isEqualToString:identifier]) {
        return YES;
    }
    id targetMode = [self canonicalInputModeForIdentifier:identifier];
    if (!targetMode) {
        return NO;
    }
    return [self switchToInputModeObject:targetMode];
}

- (BOOL)switchToInputModeObject:(id)mode {
    if (!mode) {
        return NO;
    }
    return WKSPerformOnMainThreadReturningBOOL(^BOOL{
        id controller = [self inputModeController];
        UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
        if (!impl) {
            impl = [UIKeyboardImpl sharedInstance];
        }

        BOOL didInvoke = NO;

        SEL setCurrentSel = @selector(setCurrentInputMode:);
        if (controller && [controller respondsToSelector:setCurrentSel]) {
            WKSCallSelectorWithObject(controller, setCurrentSel, mode);
            didInvoke = YES;
        }

        SEL setInputModeSel = @selector(setInputMode:);
        if (impl && [impl respondsToSelector:setInputModeSel]) {
            WKSCallSelectorWithObject(impl, setInputModeSel, mode);
            didInvoke = YES;
        }

        if (didInvoke && impl) {
            SEL refreshSelectors[] = {
                NSSelectorFromString(@"updateLayout"),
                NSSelectorFromString(@"forceLayout"),
                @selector(setNeedsLayout),
                @selector(layoutIfNeeded)
            };
            for (NSUInteger i = 0; i < sizeof(refreshSelectors) / sizeof(refreshSelectors[0]); i++) {
                SEL selector = refreshSelectors[i];
                if (selector && [impl respondsToSelector:selector]) {
                    WKSCallSelector(impl, selector);
                }
            }
        }

#if WKS_DEBUG
        if (didInvoke) {
            NSString *targetIdentifier = WKSIdentifierFromMode(mode);
            WKSLog(@"Requested switch to input mode: %@", targetIdentifier);
        }
#endif

        return didInvoke;
    });
}

- (BOOL)cycleToNextInputMode {
    return WKSPerformOnMainThreadReturningBOOL(^BOOL{
        UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
        if (!impl) {
            impl = [UIKeyboardImpl sharedInstance];
        }
        NSArray<NSString *> *implSelectors = @[ @"setInputModeToNextInPreferredList",
                                                @"setInputModeToNextInPreferenceList",
                                                @"advanceToNextInputMode",
                                                @"switchToNextInputMode" ];
        for (NSString *selName in implSelectors) {
            SEL selector = NSSelectorFromString(selName);
            if (selector && impl && [impl respondsToSelector:selector]) {
                WKSCallSelector(impl, selector);
#if WKS_DEBUG
                WKSLog(@"Cycled input mode using selector: %@", selName);
#endif
                return YES;
            }
        }

        id controller = [self inputModeController];
        NSArray<NSString *> *controllerSelectors = @[ @"advanceToNextInputMode",
                                                      @"cycleToNextInputModePreference",
                                                      @"switchToNextInputMode" ];
        for (NSString *selName in controllerSelectors) {
            SEL selector = NSSelectorFromString(selName);
            if (selector && controller && [controller respondsToSelector:selector]) {
                WKSCallSelector(controller, selector);
#if WKS_DEBUG
                WKSLog(@"Cycled input mode via controller selector: %@", selName);
#endif
                return YES;
            }
        }
        return NO;
    });
}

- (BOOL)toggleBetweenChineseAndEnglish {
    id currentMode = [self currentInputMode];
    NSString *currentIdentifier = WKSIdentifierFromMode(currentMode);
    NSString *currentLanguage = WKSPrimaryLanguageFromMode(currentMode);

    BOOL currentIsChinese = WKSIdentifierMatchesChinesePinyin(currentIdentifier) ||
                             WKSIdentifierMatchesChineseSimplified(currentIdentifier, currentLanguage);
    BOOL currentIsEnglish = WKSIdentifierMatchesEnglish(currentIdentifier, currentLanguage);

    NSString *chineseIdentifier = [self preferredChineseInputModeIdentifier];
    NSString *englishIdentifier = [self preferredEnglishInputModeIdentifier];

    NSMutableOrderedSet<NSString *> *candidateIdentifiers = [NSMutableOrderedSet orderedSet];

    if (currentIsChinese) {
        if (englishIdentifier.length > 0) {
            [candidateIdentifiers addObject:englishIdentifier];
        }
        if (chineseIdentifier.length > 0) {
            [candidateIdentifiers addObject:chineseIdentifier];
        }
    } else if (currentIsEnglish) {
        if (chineseIdentifier.length > 0) {
            [candidateIdentifiers addObject:chineseIdentifier];
        }
        if (englishIdentifier.length > 0) {
            [candidateIdentifiers addObject:englishIdentifier];
        }
    } else {
        if (englishIdentifier.length > 0) {
            [candidateIdentifiers addObject:englishIdentifier];
        }
        if (chineseIdentifier.length > 0) {
            [candidateIdentifiers addObject:chineseIdentifier];
        }
    }

    if (englishIdentifier.length > 0) {
        [candidateIdentifiers addObject:englishIdentifier];
    }
    if (chineseIdentifier.length > 0) {
        [candidateIdentifiers addObject:chineseIdentifier];
    }

    for (NSString *identifier in candidateIdentifiers) {
        if (identifier.length == 0) {
            continue;
        }
        if (currentIdentifier.length > 0 && [identifier isEqualToString:currentIdentifier]) {
            continue;
        }
        if ([self switchToInputModeIdentifier:identifier]) {
            return YES;
        }
    }

    if ([self cycleToNextInputMode]) {
        return YES;
    }

#if WKS_DEBUG
    WKSLog(@"Unable to toggle input mode - no action performed");
#endif
    return NO;
}

- (BOOL)switchToChineseInputMode {
    NSString *identifier = [self preferredChineseInputModeIdentifier];
    if ([self switchToInputModeIdentifier:identifier]) {
        return YES;
    }
    id fallbackMode = [self preferredChineseInputMode];
    if (fallbackMode) {
        return [self switchToInputModeObject:fallbackMode];
    }
    return NO;
}

- (BOOL)switchToEnglishInputMode {
    NSString *identifier = [self preferredEnglishInputModeIdentifier];
    if ([self switchToInputModeIdentifier:identifier]) {
        return YES;
    }
    id fallbackMode = [self preferredEnglishInputMode];
    if (fallbackMode) {
        return [self switchToInputModeObject:fallbackMode];
    }
    return NO;
}

@end

@interface WKSKeyboardGestureHandler : NSObject <UIGestureRecognizerDelegate>
- (instancetype)initWithKeyboardView:(UIView *)keyboardView;
- (void)install;
- (void)detach;
@end

@implementation WKSKeyboardGestureHandler {
    __weak UIView *_keyboardView;
    UISwipeGestureRecognizer *_swipeUp;
    UISwipeGestureRecognizer *_swipeDown;
    CFTimeInterval _lastTrigger;
}

- (instancetype)initWithKeyboardView:(UIView *)keyboardView {
    self = [super init];
    if (self) {
        _keyboardView = keyboardView;
        _lastTrigger = 0;
    }
    return self;
}

- (void)install {
    UIView *view = _keyboardView;
    if (!view) {
        return;
    }

    if (!_swipeUp) {
        _swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        _swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        _swipeUp.delegate = self;
        _swipeUp.numberOfTouchesRequired = 1;
        _swipeUp.cancelsTouchesInView = NO;
        _swipeUp.delaysTouchesBegan = NO;
        _swipeUp.delaysTouchesEnded = NO;
        if ([_swipeUp respondsToSelector:@selector(requiresExclusiveTouchType)]) {
            _swipeUp.requiresExclusiveTouchType = NO;
        }
        [view addGestureRecognizer:_swipeUp];
    }

    if (!_swipeDown) {
        _swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget=self action:@selector(handleSwipe:)];
        _swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
        _swipeDown.delegate = self;
        _swipeDown.numberOfTouchesRequired = 1;
        _swipeDown.cancelsTouchesInView = NO;
        _swipeDown.delaysTouchesBegan = NO;
        _swipeDown.delaysTouchesEnded = NO;
        if ([_swipeDown respondsToSelector:@selector(requiresExclusiveTouchType)]) {
            _swipeDown.requiresExclusiveTouchType = NO;
        }
        [view addGestureRecognizer:_swipeDown];
    }

#if WKS_DEBUG
    WKSLog(@"Attached swipe gestures to keyboard view: %@", view);
#endif
}

- (void)detach {
    if (_swipeUp && _keyboardView) {
        [_keyboardView removeGestureRecognizer:_swipeUp];
    }
    if (_swipeDown && _keyboardView) {
        [_keyboardView removeGestureRecognizer:_swipeDown];
    }
    _swipeUp = nil;
    _swipeDown = nil;
    _keyboardView = nil;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) {
        return;
    }
    if (!WKSShouldActivate()) {
        return;
    }

    CFTimeInterval now = CACurrentMediaTime();
    if (_lastTrigger > 0 && (now - _lastTrigger) < kGestureDebounceInterval) {
#if WKS_DEBUG
        WKSLog(@"Gesture ignored due to debounce (%.2f s)", now - _lastTrigger);
#endif
        return;
    }
    _lastTrigger = now;

    BOOL isUpGesture = (gesture == _swipeUp) || ((gesture.direction & UISwipeGestureRecognizerDirectionUp) != 0);
    BOOL targetChinese = isUpGesture ? !kPrefInvertDirection : kPrefInvertDirection;

    WKSPerformOnMainThread(^{
        WKSKeyboardInputHelper *helper = [WKSKeyboardInputHelper sharedHelper];
        BOOL didSwitch = NO;
        if (targetChinese) {
            didSwitch = [helper switchToChineseInputMode];
        } else {
            didSwitch = [helper switchToEnglishInputMode];
        }

        if (!didSwitch) {
            didSwitch = [helper toggleBetweenChineseAndEnglish];
        }

        if (didSwitch) {
            WKSTriggerHapticFeedback();
        }
    });
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (!WKSShouldActivate()) {
        return NO;
    }
    if (!_keyboardView) {
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
        CGPoint location = [gestureRecognizer locationInView:_keyboardView];
        if (location.y > CGRectGetHeight(_keyboardView.bounds) - kBottomExclusionHeight) {
            // Avoid conflicting with globe/dictation area
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (!WKSShouldActivate()) {
        return NO;
    }
    if (!_keyboardView) {
        return NO;
    }
    UIView *view = touch.view;
    while (view && view != _keyboardView) {
        NSString *className = NSStringFromClass([view class]);
        if ([className containsString:@"Dock"] || [view isKindOfClass:[UIKeyboardDockView class]]) {
            return NO;
        }
        view = view.superview;
    }
    CGPoint location = [touch locationInView:_keyboardView];
    if (location.y > CGRectGetHeight(_keyboardView.bounds) - kBottomExclusionHeight) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

@end

static const void *kWKSHandlerAssociationKey = &kWKSHandlerAssociationKey;

static void WKSAttachGesturesToKeyboardView(UIView *keyboardView) {
    if (!keyboardView) {
        return;
    }
    WKSKeyboardGestureHandler *handler = objc_getAssociatedObject(keyboardView, kWKSHandlerAssociationKey);
    if (!handler) {
        handler = [[WKSKeyboardGestureHandler alloc] initWithKeyboardView:keyboardView];
        objc_setAssociatedObject(keyboardView, kWKSHandlerAssociationKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [handler install];
    }
}

static void WKSDetachGesturesFromKeyboardView(UIView *keyboardView) {
    if (!keyboardView) {
        return;
    }
    WKSKeyboardGestureHandler *handler = objc_getAssociatedObject(keyboardView, kWKSHandlerAssociationKey);
    if (handler) {
        [handler detach];
        objc_setAssociatedObject(keyboardView, kWKSHandlerAssociationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%hook UIKeyboardLayout

- (void)didMoveToWindow {
    %orig;
    BOOL shouldActivate = WKSShouldActivate();
    if (self.window && shouldActivate) {
        WKSAttachGesturesToKeyboardView(self);
    } else {
        WKSDetachGesturesFromKeyboardView(self);
    }
}

%end

%hook UIKeyboardLayoutStar

- (void)didMoveToWindow {
    %orig;
    BOOL shouldActivate = WKSShouldActivate();
    if (self.window && shouldActivate) {
        WKSAttachGesturesToKeyboardView(self);
    } else {
        WKSDetachGesturesFromKeyboardView(self);
    }
}

%end

%ctor {
    @autoreleasepool {
        WKSLoadPreferences();
        WKSRegisterForPreferenceChanges();
        %init;
#if WKS_DEBUG
        WKSLog(@"WeChatKeyboardSwitch loaded - Enabled: %d, OnlyWeChat: %d", kPrefEnabled, kPrefOnlyWeChat);
#endif
    }
}
