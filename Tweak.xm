/*
 * WeChatKeyboardSwitch - Rootless iOS Tweak
 * Target: WeChat (com.tencent.xin)
 * iOS 13.0 - 16.5
 */

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h>

#ifndef WKS_DEBUG
#define WKS_DEBUG 0
#endif

static BOOL kRuntimeDebugEnabled = NO;

#if WKS_DEBUG
#define WKSLog(fmt, ...) do { \
    if (kRuntimeDebugEnabled) { \
        NSLog(@"[WeChatKeyboardSwitch] " fmt, ##__VA_ARGS__); \
    } \
} while(0)
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
static const CGFloat kBottomExclusionHeight = 54.0;
static const SystemSoundID kWKSGestureSoundID = 1104;
static const CFTimeInterval kWKSSwitchDebounceInterval = 0.3;
static const NSUInteger kWKSSwitchMaxRetries = 2;
static const CFTimeInterval kWKSSwitchRetryDelay = 0.02;

static BOOL kPrefEnabled = YES;
static BOOL kPrefOnlyWeChat = YES;
static BOOL kPrefInvertDirection = NO;
static BOOL kPrefHapticFeedback = YES;
static UIImpactFeedbackStyle kPrefHapticStrength = UIImpactFeedbackStyleLight;
static BOOL kPrefSoundEnabled = NO;
static CGFloat kPrefSwipeThreshold = 42.0f;
static CFTimeInterval kPrefGestureDebounce = 0.35;
static BOOL kPrefDisableInSearchFields = YES;
static NSString *kPrefChineseMode = nil;
static NSString *kPrefEnglishMode = nil;
static NSSet<NSString *> *kPrefContextBlacklist = nil;
static NSSet<NSString *> *kPrefContextWhitelist = nil;
static NSSet<NSString *> *kPrefContextIdentifierBlacklist = nil;
static BOOL kPrefDebugLogging = NO;
static __weak UIResponder *WKSWeakFirstResponder = nil;

static CFTimeInterval gHardwareKeyboardLastCheckTime = 0;
static BOOL gHardwareKeyboardCachedResult = NO;
static BOOL gHardwareKeyboardObserversRegistered = NO;
static CFTimeInterval gLastSwitchTimestamp = 0;
static BOOL gSwitchOperationInFlight = NO;
static dispatch_source_t gSwitchWatchdogTimer = nil;


@interface UIKeyboardLayout : UIView
@end

@interface UIKeyboardDockView : UIView
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
@end

@interface UIInputSetHostView : UIView
@end

@interface UIKBKeyplaneView : UIView
@end

@interface UIRemoteKeyboardWindow : UIWindow
@end

@interface WKSKeyboardLifecycleManager : NSObject
+ (instancetype)sharedManager;
- (void)registerKeyboardView:(UIView *)keyboardView;
- (void)unregisterKeyboardView:(UIView *)keyboardView;
- (void)detachAllGestures;
- (void)revalidateAllKeyboards;
- (void)hardwareKeyboardAvailabilityDidChange;
@end

static BOOL WKSIsHardwareKeyboardConnected(void);
static BOOL WKSViewIsEligibleKeyboardView(UIView *keyboardView);
static void WKSAttachGesturesToKeyboardView(UIView *keyboardView);
static void WKSDetachGesturesFromKeyboardView(UIView *keyboardView);
static void WKSScanForKeyboardViews(UIView *rootView, NSUInteger depth);

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

@interface UIResponder (WKSPrivate)
- (id)_responderForEditing;
@end

static id WKSCallSelectorReturningId(id target, SEL selector) {
    if (!target || !selector || ![target respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(target, selector);
}

static BOOL WKSCallSelectorReturningBOOL(id target, SEL selector) {
    if (!target || !selector || ![target respondsToSelector:selector]) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))objc_msgSend)(target, selector);
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

__attribute__((unused))
static NSInteger WKSGetIntegerPreference(CFStringRef key, NSInteger defaultValue) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, (__bridge CFStringRef)kPreferencesDomain);
    NSInteger result = defaultValue;
    if (value) {
        if (CFGetTypeID(value) == CFNumberGetTypeID()) {
            CFNumberGetValue((CFNumberRef)value, kCFNumberNSIntegerType, &result);
        } else if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            result = CFBooleanGetValue((CFBooleanRef)value) ? 1 : 0;
        }
        CFRelease(value);
    }
    return result;
}

static CGFloat WKSGetFloatPreference(CFStringRef key, CGFloat defaultValue) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, (__bridge CFStringRef)kPreferencesDomain);
    CGFloat result = defaultValue;
    if (value) {
        if (CFGetTypeID(value) == CFNumberGetTypeID()) {
            double doubleValue = 0.0;
            CFNumberGetValue((CFNumberRef)value, kCFNumberDoubleType, &doubleValue);
            result = (CGFloat)doubleValue;
        }
        CFRelease(value);
    }
    return result;
}

static NSString *WKSGetStringPreference(CFStringRef key, NSString *defaultValue) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, (__bridge CFStringRef)kPreferencesDomain);
    NSString *result = defaultValue;
    if (value) {
        if (CFGetTypeID(value) == CFStringGetTypeID()) {
            result = (__bridge_transfer NSString *)value;
            return result;
        }
        CFRelease(value);
    }
    return result;
}

__attribute__((unused))
static NSArray *WKSGetArrayPreference(CFStringRef key) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, (__bridge CFStringRef)kPreferencesDomain);
    NSArray *result = nil;
    if (value) {
        if (CFGetTypeID(value) == CFArrayGetTypeID()) {
            result = (__bridge_transfer NSArray *)value;
            return result;
        }
        CFRelease(value);
    }
    return result;
}

static NSString *WKSNormalizePreferenceString(NSString *string) {
    if (![string isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    return trimmed;
}

static NSString *WKSNormalizeClassName(NSString *className) {
    NSString *normalized = WKSNormalizePreferenceString(className);
    if (normalized.length == 0) {
        return nil;
    }
    return [normalized lowercaseString];
}

static NSSet<NSString *> *WKSNormalizedClassSetFromValue(id value) {
    if (!value) {
        return nil;
    }
    NSMutableSet<NSString *> *collected = [NSMutableSet set];
    void (^addString)(NSString *) = ^(NSString *candidate) {
        NSString *normalized = WKSNormalizeClassName(candidate);
        if (normalized.length > 0) {
            [collected addObject:normalized];
        }
    };
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]]) {
        for (id element in value) {
            if ([element isKindOfClass:[NSString class]]) {
                addString(element);
            }
        }
    } else if ([value isKindOfClass:[NSString class]]) {
        NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@",\n" ];
        NSArray<NSString *> *pieces = [value componentsSeparatedByCharactersInSet:delimiters];
        for (NSString *piece in pieces) {
            addString(piece);
        }
    }
    if (collected.count == 0) {
        return nil;
    }
    return [collected copy];
}

static NSSet<NSString *> *WKSDefaultSearchBlacklist(void) {
    static NSSet<NSString *> *defaultSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultSet = [NSSet setWithObjects:@"uisearchbartextfield", @"uisearchtextfield", nil];
    });
    return defaultSet;
}

static NSSet<NSString *> *WKSDefaultIdentifierBlacklist(void) {
    static NSSet<NSString *> *defaultSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultSet = [NSSet setWithObjects:
            @"search", @"login", @"password", @"passcode",
            @"verification", @"code", @"otp", @"pin",
            @"username", @"email", nil];
    });
    return defaultSet;
}

static BOOL WKSResponderIsBlacklistedByHeuristics(UIResponder *responder) {
    if (!responder) {
        return NO;
    }
    SEL secureTextEntrySel = @selector(isSecureTextEntry);
    if ([responder respondsToSelector:secureTextEntrySel]) {
        BOOL isSecure = WKSCallSelectorReturningBOOL(responder, secureTextEntrySel);
        if (isSecure) {
#if WKS_DEBUG
            WKSLog(@"Blacklisted: secure text entry");
#endif
            return YES;
        }
    }
    SEL textContentTypeSel = @selector(textContentType);
    if ([responder respondsToSelector:textContentTypeSel]) {
        id contentType = WKSCallSelectorReturningId(responder, textContentTypeSel);
        if ([contentType isKindOfClass:[NSString class]]) {
            NSString *lowerContentType = [(NSString *)contentType lowercaseString];
            for (NSString *blacklisted in WKSDefaultIdentifierBlacklist()) {
                if ([lowerContentType containsString:blacklisted]) {
#if WKS_DEBUG
                    WKSLog(@"Blacklisted: textContentType contains '%@'", blacklisted);
#endif
                    return YES;
                }
            }
        }
    }
    SEL accessibilityIdentifierSel = @selector(accessibilityIdentifier);
    if ([responder respondsToSelector:accessibilityIdentifierSel]) {
        id identifier = WKSCallSelectorReturningId(responder, accessibilityIdentifierSel);
        if ([identifier isKindOfClass:[NSString class]]) {
            NSString *lowerIdentifier = [(NSString *)identifier lowercaseString];
            for (NSString *blacklisted in WKSDefaultIdentifierBlacklist()) {
                if ([lowerIdentifier containsString:blacklisted]) {
#if WKS_DEBUG
                    WKSLog(@"Blacklisted: accessibilityIdentifier contains '%@'", blacklisted);
#endif
                    return YES;
                }
            }
            if (kPrefContextIdentifierBlacklist.count > 0) {
                for (NSString *custom in kPrefContextIdentifierBlacklist) {
                    if ([lowerIdentifier containsString:custom]) {
#if WKS_DEBUG
                        WKSLog(@"Blacklisted: accessibilityIdentifier contains custom '%@'", custom);
#endif
                        return YES;
                    }
                }
            }
        }
    }
    if (kPrefContextIdentifierBlacklist.count > 0) {
        SEL accessibilityLabelSel = @selector(accessibilityLabel);
        if ([responder respondsToSelector:accessibilityLabelSel]) {
            id label = WKSCallSelectorReturningId(responder, accessibilityLabelSel);
            if ([label isKindOfClass:[NSString class]]) {
                NSString *normalized = WKSNormalizeClassName(label);
                if (normalized.length > 0 && [kPrefContextIdentifierBlacklist containsObject:normalized]) {
#if WKS_DEBUG
                    WKSLog(@"Blacklisted: accessibilityLabel matches custom blacklist");
#endif
                    return YES;
                }
            }
        }
    }
    return NO;
}

static UIImpactFeedbackStyle WKSHapticStyleFromValue(id value, UIImpactFeedbackStyle fallback) {
    if (!value) {
        return fallback;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        NSInteger intValue = [(NSNumber *)value integerValue];
        switch (intValue) {
            case UIImpactFeedbackStyleLight: return UIImpactFeedbackStyleLight;
            case UIImpactFeedbackStyleMedium: return UIImpactFeedbackStyleMedium;
            case UIImpactFeedbackStyleHeavy: return UIImpactFeedbackStyleHeavy;
            case 3: return fallback;
            default: return fallback;
        }
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *stringValue = [(NSString *)value lowercaseString];
        if ([stringValue isEqualToString:@"light"]) return UIImpactFeedbackStyleLight;
        if ([stringValue isEqualToString:@"medium"]) return UIImpactFeedbackStyleMedium;
        if ([stringValue isEqualToString:@"heavy"]) return UIImpactFeedbackStyleHeavy;
    }
    return fallback;
}

static UIImpactFeedbackStyle WKSGetHapticStylePreference(void) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR("HapticStrength"), (__bridge CFStringRef)kPreferencesDomain);
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleLight;
    if (value) {
        style = WKSHapticStyleFromValue((__bridge id)value, UIImpactFeedbackStyleLight);
        CFRelease(value);
    }
    return style;
}

static void WKSReloadPreferences(void) {
    kPrefEnabled = WKSGetBoolPreference(CFSTR("Enabled"), YES);
    kPrefOnlyWeChat = WKSGetBoolPreference(CFSTR("OnlyWeChat"), YES);
    kPrefInvertDirection = WKSGetBoolPreference(CFSTR("InvertDirection"), NO);
    kPrefHapticFeedback = WKSGetBoolPreference(CFSTR("HapticFeedback"), YES);
    kPrefHapticStrength = WKSGetHapticStylePreference();
    kPrefSoundEnabled = WKSGetBoolPreference(CFSTR("SoundEnabled"), NO);
    
    CGFloat thresholdValue = WKSGetFloatPreference(CFSTR("SwipeThreshold"), 42.0);
    kPrefSwipeThreshold = (thresholdValue >= 12.0f && thresholdValue <= 200.0f) ? thresholdValue : 42.0f;
    
    CGFloat debounceValue = WKSGetFloatPreference(CFSTR("GestureDebounce"), 0.35);
    kPrefGestureDebounce = (debounceValue >= 0.1 && debounceValue <= 2.0) ? debounceValue : 0.35;
    
    kPrefDisableInSearchFields = WKSGetBoolPreference(CFSTR("DisableInSearchFields"), YES);
    kPrefChineseMode = WKSGetStringPreference(CFSTR("ChineseMode"), nil);
    kPrefEnglishMode = WKSGetStringPreference(CFSTR("EnglishMode"), nil);
    
    id contextBlacklistValue = (__bridge_transfer id)CFPreferencesCopyAppValue(CFSTR("ContextBlacklist"), (__bridge CFStringRef)kPreferencesDomain);
    kPrefContextBlacklist = WKSNormalizedClassSetFromValue(contextBlacklistValue);
    
    id contextWhitelistValue = (__bridge_transfer id)CFPreferencesCopyAppValue(CFSTR("ContextWhitelist"), (__bridge CFStringRef)kPreferencesDomain);
    kPrefContextWhitelist = WKSNormalizedClassSetFromValue(contextWhitelistValue);
    
    id identifierBlacklistValue = (__bridge_transfer id)CFPreferencesCopyAppValue(CFSTR("ContextIdentifierBlacklist"), (__bridge CFStringRef)kPreferencesDomain);
    kPrefContextIdentifierBlacklist = WKSNormalizedClassSetFromValue(identifierBlacklistValue);
    
    kPrefDebugLogging = WKSGetBoolPreference(CFSTR("DebugLogging"), NO);
    kRuntimeDebugEnabled = kPrefDebugLogging;
#if WKS_DEBUG
    WKSLog(@"Preferences reloaded");
#endif
}

static void WKSPreferencesDidChangeNotification(CFNotificationCenterRef center,
                                                void *observer,
                                                CFStringRef name,
                                                const void *object,
                                                CFDictionaryRef userInfo) {
    WKSReloadPreferences();
    [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
}

static BOOL WKSIsRunningInWeChat(void) {
    static BOOL isWeChat = NO;
    static dispatch_once_t onceToken;
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

static BOOL WKSStringContainsTokenSet(NSString *string, NSSet<NSString *> *tokens) {
    if (string.length == 0 || tokens.count == 0) {
        return NO;
    }
    NSString *normalized = [[string lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (normalized.length == 0) {
        return NO;
    }
    for (NSString *token in tokens) {
        if (token.length > 0 && [normalized containsString:token]) {
            return YES;
        }
    }
    return NO;
}

static BOOL WKSResponderIsSearchField(UIResponder *responder) {
    if (!responder) {
        return NO;
    }
    NSString *className = NSStringFromClass([responder class]);
    NSString *lowerClassName = WKSNormalizeClassName(className);
    if (lowerClassName.length > 0) {
        NSSet<NSString *> *blacklist = kPrefDisableInSearchFields ? WKSDefaultSearchBlacklist() : nil;
        if (blacklist.count > 0 && [blacklist containsObject:lowerClassName]) {
            return YES;
        }
    }
    return NO;
}

static BOOL WKSShouldActivateForResponder(UIResponder *responder) {
    if (!kPrefEnabled) {
        return NO;
    }
    if (kPrefOnlyWeChat && !WKSIsRunningInWeChat()) {
        return NO;
    }
    if (!responder) {
        return NO;
    }
    if (WKSResponderIsBlacklistedByHeuristics(responder)) {
        return NO;
    }
    if (kPrefContextBlacklist.count > 0) {
        if (WKSResponderMatchesIdentifierSet(responder, kPrefContextBlacklist)) {
#if WKS_DEBUG
            WKSLog(@"Responder blacklisted by context");
#endif
            return NO;
        }
    }
    if (WKSResponderIsSearchField(responder)) {
#if WKS_DEBUG
        WKSLog(@"Responder is search field");
#endif
        return NO;
    }
    if (kPrefContextWhitelist.count > 0) {
        if (!WKSResponderMatchesIdentifierSet(responder, kPrefContextWhitelist)) {
#if WKS_DEBUG
            WKSLog(@"Responder not in whitelist");
#endif
            return NO;
        }
    }
    return YES;
}

static UIResponder *WKSCurrentFirstResponder(void) {
    return WKSWeakFirstResponder;
}

static void WKSClearSwitchWatchdog(void) {
    @synchronized (@"WKSSwitchWatchdog") {
        if (gSwitchWatchdogTimer) {
            dispatch_source_cancel(gSwitchWatchdogTimer);
            gSwitchWatchdogTimer = nil;
        }
        gSwitchOperationInFlight = NO;
    }
}

static void WKSStartSwitchWatchdog(void) {
    WKSClearSwitchWatchdog();
    @synchronized (@"WKSSwitchWatchdog") {
        gSwitchOperationInFlight = YES;
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (timer) {
            gSwitchWatchdogTimer = timer;
            dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), DISPATCH_TIME_FOREVER, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_source_set_event_handler(timer, ^{
#if WKS_DEBUG
                WKSLog(@"Switch watchdog timeout - clearing inflight flag");
#endif
                WKSClearSwitchWatchdog();
            });
            dispatch_resume(timer);
        }
    }
}

static void WKSRegisterHardwareKeyboardObservers(void) {
    if (gHardwareKeyboardObserversRegistered) {
        return;
    }
    gHardwareKeyboardObserversRegistered = YES;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSArray<NSString *> *notificationNames = @[
        @"UIKeyboardDidShowNotification",
        @"UIKeyboardWillHideNotification",
        @"UIKeyboardDidHideNotification",
        @"UITextInputCurrentInputModeDidChangeNotification",
        @"UIKeyboardWillShowNotification"
    ];
    for (NSString *name in notificationNames) {
        [nc addObserverForName:name
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification * _Nonnull note) {
            gHardwareKeyboardLastCheckTime = 0;
            if (!WKSIsHardwareKeyboardConnected()) {
                [[WKSKeyboardLifecycleManager sharedManager] hardwareKeyboardAvailabilityDidChange];
            }
        }];
    }
    
#if WKS_DEBUG
    WKSLog(@"Registered hardware keyboard observers");
#endif
}

static BOOL WKSIsHardwareKeyboardConnected(void) {
    CFTimeInterval now = CFAbsoluteTimeGetCurrent();
    if ((now - gHardwareKeyboardLastCheckTime) < 0.5) {
        return gHardwareKeyboardCachedResult;
    }
    gHardwareKeyboardLastCheckTime = now;
    gHardwareKeyboardCachedResult = WKSPerformOnMainThreadReturningBOOL(^BOOL{
        @try {
            UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
            if (!impl) {
                impl = [UIKeyboardImpl sharedInstance];
            }
            if (!impl) {
                return NO;
            }
            NSArray<NSString *> *selectors = @[ @"isHardwareKeyboardAttached",
                                                @"hardwareKeyboardAttached",
                                                @"_isHardwareKeyboardAttached",
                                                @"isInHardwareKeyboardMode",
                                                @"inHardwareKeyboardMode",
                                                @"_hardwareKeyboardAvailable",
                                                @"hardwareKeyboardAvailable" ];
            for (NSString *selName in selectors) {
                SEL selector = NSSelectorFromString(selName);
                if (selector && [impl respondsToSelector:selector]) {
                    BOOL result = WKSCallSelectorReturningBOOL(impl, selector);
                    if (result) {
                        return YES;
                    }
                }
            }
            id inputDelegate = [impl valueForKey:@"inputDelegate"];
            if (inputDelegate) {
                for (NSString *selName in selectors) {
                    SEL selector = NSSelectorFromString(selName);
                    if (selector && [inputDelegate respondsToSelector:selector]) {
                        BOOL result = WKSCallSelectorReturningBOOL(inputDelegate, selector);
                        if (result) {
                            return YES;
                        }
                    }
                }
            }
            return NO;
        } @catch (__unused NSException *exception) {
            return NO;
        }
    });
    return gHardwareKeyboardCachedResult;
}

static void WKSTriggerHapticFeedback(void) {
    if (!kPrefHapticFeedback) {
        return;
    }
    @try {
        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:kPrefHapticStrength];
        [feedbackGenerator prepare];
        [feedbackGenerator impactOccurred];
    } @catch (__unused NSException *exception) {
    }
}

static void WKSTriggerSoundFeedback(void) {
    if (!kPrefSoundEnabled) {
        return;
    }
    AudioServicesPlaySystemSound(kWKSGestureSoundID);
}

static void WKSTriggerFeedback(void) {
    WKSTriggerHapticFeedback();
    WKSTriggerSoundFeedback();
}

static CFTimeInterval WKSGestureDebounceInterval(void) {
    return MAX(0.1, kPrefGestureDebounce);
}

static CGFloat WKSGestureRequiredDistance(void) {
    return MAX(12.0f, kPrefSwipeThreshold);
}

@interface WKSKeyboardSwitcher : NSObject
+ (instancetype)sharedInstance;
- (id)inputModeController;
- (NSArray *)availableInputModes;
- (id)currentInputMode;
- (BOOL)switchToInputModeIdentifier:(NSString *)identifier;
- (BOOL)verifyInputModeIdentifier:(NSString *)identifier;
- (BOOL)cycleToNextInputMode;
- (BOOL)toggleBetweenChineseAndEnglish;
- (NSString *)preferredChineseInputModeIdentifier;
- (NSString *)preferredEnglishInputModeIdentifier;
@end

@implementation WKSKeyboardSwitcher

+ (instancetype)sharedInstance {
    static WKSKeyboardSwitcher *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)inputModeController {
    @try {
        Class controllerClass = NSClassFromString(@"UIKeyboardInputModeController");
        if (!controllerClass) {
            return nil;
        }
        SEL sharedInstanceSel = @selector(sharedInputModeController);
        if (![controllerClass respondsToSelector:sharedInstanceSel]) {
            sharedInstanceSel = @selector(sharedInstance);
        }
        if (![controllerClass respondsToSelector:sharedInstanceSel]) {
            return nil;
        }
        return ((id (*)(id, SEL))objc_msgSend)(controllerClass, sharedInstanceSel);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

- (NSArray *)availableInputModes {
    id controller = [self inputModeController];
    if (!controller) {
        return @[];
    }
    SEL activeModesS = @selector(activeInputModes);
    id modes = WKSCallSelectorReturningId(controller, activeModesS);
    if ([modes isKindOfClass:[NSArray class]]) {
        return modes;
    }
    return @[];
}

- (id)currentInputMode {
    return WKSPerformOnMainThreadReturningId(^id{
        @try {
            id controller = [self inputModeController];
            if (controller) {
                SEL currentModeSel = @selector(currentInputMode);
                id mode = WKSCallSelectorReturningId(controller, currentModeSel);
                if (mode) {
                    return mode;
                }
            }
            UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
            if (!impl) {
                impl = [UIKeyboardImpl sharedInstance];
            }
            if (impl) {
                SEL inputModeSel = @selector(inputMode);
                id mode = WKSCallSelectorReturningId(impl, inputModeSel);
                if (mode) {
                    return mode;
                }
            }
            return nil;
        } @catch (__unused NSException *exception) {
            return nil;
        }
    });
}

- (NSString *)preferredChineseInputModeIdentifier {
    if (kPrefChineseMode.length > 0) {
        NSString *configuredMode = kPrefChineseMode;
        NSArray *modes = [self availableInputModes];
        for (id mode in modes) {
            NSString *modeId = WKSIdentifierFromMode(mode);
            if ([modeId isEqualToString:configuredMode]) {
                return configuredMode;
            }
        }
    }
    NSArray *modes = [self availableInputModes];
    for (id mode in modes) {
        NSString *identifier = WKSIdentifierFromMode(mode);
        if (WKSIdentifierMatchesChinesePinyin(identifier)) {
            return identifier;
        }
    }
    for (id mode in modes) {
        NSString *identifier = WKSIdentifierFromMode(mode);
        NSString *language = WKSPrimaryLanguageFromMode(mode);
        if (WKSIdentifierMatchesChineseSimplified(identifier, language)) {
            return identifier;
        }
    }
    return nil;
}

- (NSString *)preferredEnglishInputModeIdentifier {
    if (kPrefEnglishMode.length > 0) {
        NSString *configuredMode = kPrefEnglishMode;
        NSArray *modes = [self availableInputModes];
        for (id mode in modes) {
            NSString *modeId = WKSIdentifierFromMode(mode);
            if ([modeId isEqualToString:configuredMode]) {
                return configuredMode;
            }
        }
    }
    NSArray *modes = [self availableInputModes];
    for (id mode in modes) {
        NSString *identifier = WKSIdentifierFromMode(mode);
        NSString *language = WKSPrimaryLanguageFromMode(mode);
        if (WKSIdentifierMatchesEnglish(identifier, language)) {
            return identifier;
        }
    }
    return nil;
}

- (BOOL)verifyInputModeIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return NO;
    }
    id currentMode = [self currentInputMode];
    NSString *currentIdentifier = WKSIdentifierFromMode(currentMode);
    if ([currentIdentifier isEqualToString:identifier]) {
        return YES;
    }
    return NO;
}

- (BOOL)switchToInputModeIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return NO;
    }
    WKSStartSwitchWatchdog();
    CFTimeInterval operationStartTime = CFAbsoluteTimeGetCurrent();
    return WKSPerformOnMainThreadReturningBOOL(^BOOL{
        @try {
            if ([self verifyInputModeIdentifier:identifier]) {
#if WKS_DEBUG
                WKSLog(@"Already at target input mode: %@", identifier);
#endif
                WKSClearSwitchWatchdog();
                return YES;
            }
            
            id controller = [self inputModeController];
            UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
            if (!impl) {
                impl = [UIKeyboardImpl sharedInstance];
            }
            
            if (controller) {
                SEL modeWithIdSel = @selector(keyboardInputModeWithIdentifier:);
                id targetMode = WKSCallSelectorReturningIdWithObject(controller, modeWithIdSel, identifier);
                if (targetMode) {
                    SEL setModeSel = @selector(setCurrentInputMode:);
                    WKSCallSelectorWithObject(controller, setModeSel, targetMode);
                    
                    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWKSSwitchRetryDelay]];
                    if ([self verifyInputModeIdentifier:identifier]) {
#if WKS_DEBUG
                        WKSLog(@"Switch success via controller to: %@", identifier);
#endif
                        gLastSwitchTimestamp = operationStartTime;
                        WKSClearSwitchWatchdog();
                        return YES;
                    }
                }
            }
            
            for (NSUInteger attempt = 0; attempt < kWKSSwitchMaxRetries; attempt++) {
                if ((CFAbsoluteTimeGetCurrent() - operationStartTime) > 2.0) {
#if WKS_DEBUG
                    WKSLog(@"Switch timeout after %.2f seconds", CFAbsoluteTimeGetCurrent() - operationStartTime);
#endif
                    WKSClearSwitchWatchdog();
                    return NO;
                }
                if (attempt > 0) {
                    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWKSSwitchRetryDelay]];
                }
            }
            
            BOOL didCycle = [self _cycleToNextInputModeLockedWithImpl:impl controller:controller];
            if (didCycle) {
                [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWKSSwitchRetryDelay]];
                if ([self verifyInputModeIdentifier:identifier]) {
#if WKS_DEBUG
                    WKSLog(@"Switch verified after cycling to: %@", identifier);
#endif
                    return YES;
                }
            }
            
#if WKS_DEBUG
            WKSLog(@"Switch failed after %lu attempts to: %@", (unsigned long)(kWKSSwitchMaxRetries + 1), identifier);
#endif
            return NO;
        } @catch (NSException *exception) {
#if WKS_DEBUG
            WKSLog(@"Exception during switch: %@", exception);
#endif
            return NO;
        }
    });
}

- (BOOL)_cycleToNextInputModeLockedWithImpl:(UIKeyboardImpl *)impl controller:(id)controller {
    if (!impl) {
        impl = [UIKeyboardImpl activeInstance];
        if (!impl) {
            impl = [UIKeyboardImpl sharedInstance];
        }
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

    if (!controller) {
        controller = [self inputModeController];
    }
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
}

- (BOOL)cycleToNextInputMode {
    return WKSPerformOnMainThreadReturningBOOL(^BOOL{
        UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
        if (!impl) {
            impl = [UIKeyboardImpl sharedInstance];
        }
        id controller = [self inputModeController];
        return [self _cycleToNextInputModeLockedWithImpl:impl controller:controller];
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

    if (candidateIdentifiers.count == 0) {
#if WKS_DEBUG
        WKSLog(@"No candidate input modes found for toggle");
#endif
        return [self cycleToNextInputMode];
    }

    for (NSString *candidateId in candidateIdentifiers) {
        if (![candidateId isEqualToString:currentIdentifier]) {
            if ([self switchToInputModeIdentifier:candidateId]) {
#if WKS_DEBUG
                WKSLog(@"Toggled to: %@", candidateId);
#endif
                return YES;
            }
        }
    }

#if WKS_DEBUG
    WKSLog(@"Toggle failed, falling back to cycle");
#endif
    return [self cycleToNextInputMode];
}

@end

@interface WKSGestureHandler : NSObject <UIGestureRecognizerDelegate>
{
    __weak UIView *_keyboardView;
    UISwipeGestureRecognizer *_swipeUpGesture;
    UISwipeGestureRecognizer *_swipeDownGesture;
    CGPoint _initialTouchPoint;
    BOOL _hasInitialTouchPoint;
    CFTimeInterval _lastTrigger;
}
- (instancetype)initWithKeyboardView:(UIView *)keyboardView;
- (void)detachGestures;
- (void)handleSwipe:(UISwipeGestureRecognizer *)gestureRecognizer;
@end

@implementation WKSGestureHandler

- (instancetype)initWithKeyboardView:(UIView *)keyboardView {
    if (self = [super init]) {
        _keyboardView = keyboardView;
        _hasInitialTouchPoint = NO;
        _lastTrigger = 0;
        
        UISwipeGestureRecognizerDirection upDirection = kPrefInvertDirection ? UISwipeGestureRecognizerDirectionDown : UISwipeGestureRecognizerDirectionUp;
        UISwipeGestureRecognizerDirection downDirection = kPrefInvertDirection ? UISwipeGestureRecognizerDirectionUp : UISwipeGestureRecognizerDirectionDown;
        
        _swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        _swipeUpGesture.direction = upDirection;
        _swipeUpGesture.delegate = self;
        [keyboardView addGestureRecognizer:_swipeUpGesture];
        
        _swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        _swipeDownGesture.direction = downDirection;
        _swipeDownGesture.delegate = self;
        [keyboardView addGestureRecognizer:_swipeDownGesture];
    }
    return self;
}

- (void)dealloc {
    [self detachGestures];
}

- (void)detachGestures {
    if (_swipeUpGesture && _keyboardView) {
        [_keyboardView removeGestureRecognizer:_swipeUpGesture];
    }
    if (_swipeDownGesture && _keyboardView) {
        [_keyboardView removeGestureRecognizer:_swipeDownGesture];
    }
    _swipeUpGesture = nil;
    _swipeDownGesture = nil;
    _keyboardView = nil;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    UIResponder *responder = WKSCurrentFirstResponder();
    if (!WKSShouldActivateForResponder(responder)) {
#if WKS_DEBUG
        WKSLog(@"Swipe ignored: responder not eligible");
#endif
        return;
    }

    if (WKSIsHardwareKeyboardConnected()) {
#if WKS_DEBUG
        WKSLog(@"Swipe ignored: hardware keyboard connected");
#endif
        return;
    }

    CFTimeInterval now = CFAbsoluteTimeGetCurrent();
    CFTimeInterval debounceInterval = WKSGestureDebounceInterval();
    if (_lastTrigger > 0 && (now - _lastTrigger) < debounceInterval) {
#if WKS_DEBUG
        WKSLog(@"Gesture ignored due to debounce (%.2f s)", now - _lastTrigger);
#endif
        return;
    }

    if (gSwitchOperationInFlight) {
#if WKS_DEBUG
        WKSLog(@"Gesture ignored: switch operation already in flight");
#endif
        return;
    }

    if (gLastSwitchTimestamp > 0 && (now - gLastSwitchTimestamp) < kWKSSwitchDebounceInterval) {
#if WKS_DEBUG
        WKSLog(@"Switch ignored: global debounce (%.2f s)", now - gLastSwitchTimestamp);
#endif
        return;
    }

    if (_hasInitialTouchPoint && !CGPointEqualToPoint(_initialTouchPoint, CGPointZero)) {
        CGPoint currentPoint = [gestureRecognizer locationInView:_keyboardView];
        CGFloat deltaX = currentPoint.x - _initialTouchPoint.x;
        CGFloat deltaY = currentPoint.y - _initialTouchPoint.y;
        CGFloat distance = fabs(deltaY);
        CGFloat requiredDistance = WKSGestureRequiredDistance();
        
        if (distance < requiredDistance || fabs(deltaX) > distance * 0.8) {
#if WKS_DEBUG
            WKSLog(@"Gesture ignored: insufficient distance or too horizontal (%.1f px, required %.1f px)", distance, requiredDistance);
#endif
            _hasInitialTouchPoint = NO;
            return;
        }
    }

    _lastTrigger = now;
    _hasInitialTouchPoint = NO;

#if WKS_DEBUG
    WKSLog(@"Swipe detected, triggering toggle");
#endif
    
    WKSTriggerFeedback();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WKSKeyboardSwitcher sharedInstance] toggleBetweenChineseAndEnglish];
    });
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIResponder *responder = WKSCurrentFirstResponder();
    if (!WKSShouldActivateForResponder(responder)) {
        return NO;
    }
    if (!_keyboardView) {
        return NO;
    }
    CGRect bounds = _keyboardView.bounds;
    if (CGRectIsEmpty(bounds) || CGRectGetHeight(bounds) < 50.0f) {
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
        CGPoint location = [gestureRecognizer locationInView:_keyboardView];
        if (location.y > CGRectGetHeight(bounds) - kBottomExclusionHeight) {
            return NO;
        }
        if (location.y < 10.0f || location.x < 5.0f || location.x > CGRectGetWidth(bounds) - 5.0f) {
            return NO;
        }
    }
    if (!_hasInitialTouchPoint) {
        _initialTouchPoint = [gestureRecognizer locationInView:_keyboardView];
        _hasInitialTouchPoint = YES;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIResponder *responder = WKSCurrentFirstResponder();
    if (!WKSShouldActivateForResponder(responder)) {
        return NO;
    }
    if (!_keyboardView) {
        return NO;
    }
    UIView *view = touch.view;
    Class dockViewClass = NSClassFromString(@"UIKeyboardDockView");
    NSUInteger depth = 0;
    while (view && view != _keyboardView && depth < 10) {
        NSString *className = NSStringFromClass([view class]);
        NSString *lowerClassName = [className lowercaseString];
        if ([lowerClassName containsString:@"dock"] ||
            [lowerClassName containsString:@"dictation"] ||
            [lowerClassName containsString:@"globe"] ||
            (dockViewClass && [view isKindOfClass:dockViewClass])) {
            return NO;
        }
        view = view.superview;
        depth++;
    }
    CGPoint location = [touch locationInView:_keyboardView];
    CGRect bounds = _keyboardView.bounds;
    if (location.y > CGRectGetHeight(bounds) - kBottomExclusionHeight) {
        return NO;
    }
    if (location.y < 5.0f || location.x < 3.0f || location.x > CGRectGetWidth(bounds) - 3.0f) {
        return NO;
    }
    _initialTouchPoint = location;
    _hasInitialTouchPoint = YES;
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

@end

static const void *kWKSHandlerAssociationKey = &kWKSHandlerAssociationKey;

static BOOL WKSViewIsEligibleKeyboardView(UIView *keyboardView) {
    if (!keyboardView) {
        return NO;
    }
    if (CGRectGetHeight(keyboardView.bounds) < 40.0f || CGRectGetWidth(keyboardView.bounds) < 80.0f) {
        return NO;
    }
    UIWindow *window = keyboardView.window;
    if (!window || window.hidden) {
        return NO;
    }
    NSString *windowClassName = NSStringFromClass([window class]);
    NSString *lowerWindowName = [windowClassName lowercaseString];
    if ([lowerWindowName rangeOfString:@"keyboard"].location == NSNotFound &&
        [lowerWindowName rangeOfString:@"texteffects"].location == NSNotFound) {
        return NO;
    }
    NSString *className = NSStringFromClass([keyboardView class]);
    NSString *lowerClassName = [className lowercaseString];
    if ([lowerClassName containsString:@"keyboard"] ||
        [lowerClassName containsString:@"keyplane"] ||
        [lowerClassName containsString:@"inputsethost"]) {
        return YES;
    }
    UIView *current = keyboardView.superview;
    NSUInteger depth = 0;
    while (current && depth < 10) {
        NSString *currentClassName = NSStringFromClass([current class]);
        NSString *lowerName = [currentClassName lowercaseString];
        if ([lowerName containsString:@"keyboard"] ||
            [lowerName containsString:@"keyplane"] ||
            [lowerName containsString:@"inputsethost"]) {
            return YES;
        }
        current = current.superview;
        depth++;
    }
    return NO;
}

static void WKSAttachGesturesToKeyboardView(UIView *keyboardView) {
    if (!keyboardView) {
        return;
    }
    @synchronized (keyboardView) {
        WKSGestureHandler *existingHandler = objc_getAssociatedObject(keyboardView, kWKSHandlerAssociationKey);
        if (existingHandler) {
#if WKS_DEBUG
            WKSLog(@"Gesture handler already attached to view: %@", NSStringFromClass([keyboardView class]));
#endif
            return;
        }
        WKSGestureHandler *handler = [[WKSGestureHandler alloc] initWithKeyboardView:keyboardView];
        objc_setAssociatedObject(keyboardView, kWKSHandlerAssociationKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#if WKS_DEBUG
        WKSLog(@"Attached gesture handler to view: %@", NSStringFromClass([keyboardView class]));
#endif
    }
}

static void WKSDetachGesturesFromKeyboardView(UIView *keyboardView) {
    if (!keyboardView) {
        return;
    }
    @synchronized (keyboardView) {
        WKSGestureHandler *handler = objc_getAssociatedObject(keyboardView, kWKSHandlerAssociationKey);
        if (handler) {
            [handler detachGestures];
            objc_setAssociatedObject(keyboardView, kWKSHandlerAssociationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#if WKS_DEBUG
            WKSLog(@"Detached gesture handler from view: %@", NSStringFromClass([keyboardView class]));
#endif
        }
    }
}

static void WKSScanForKeyboardViews(UIView *rootView, NSUInteger depth) {
    if (!rootView || depth > 15) {
        return;
    }
    if (WKSViewIsEligibleKeyboardView(rootView)) {
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:rootView];
    }
    for (UIView *subview in rootView.subviews) {
        WKSScanForKeyboardViews(subview, depth + 1);
    }
}

@implementation WKSKeyboardLifecycleManager
{
    NSMapTable<UIView *, NSNumber *> *_registeredKeyboardViews;
    NSLock *_lock;
}

+ (instancetype)sharedManager {
    static WKSKeyboardLifecycleManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _registeredKeyboardViews = [NSMapTable weakToStrongObjectsMapTable];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)registerKeyboardView:(UIView *)keyboardView {
    if (!keyboardView || !WKSViewIsEligibleKeyboardView(keyboardView)) {
        return;
    }
    [_lock lock];
    NSNumber *existingState = [_registeredKeyboardViews objectForKey:keyboardView];
    if (existingState && [existingState boolValue]) {
        [_lock unlock];
        return;
    }
    [_registeredKeyboardViews setObject:@YES forKey:keyboardView];
    [_lock unlock];
    WKSPerformOnMainThread(^{
        if (WKSShouldActivateForResponder(WKSCurrentFirstResponder()) && !WKSIsHardwareKeyboardConnected()) {
            WKSAttachGesturesToKeyboardView(keyboardView);
        }
    });
}

- (void)unregisterKeyboardView:(UIView *)keyboardView {
    if (!keyboardView) {
        return;
    }
    [_lock lock];
    [_registeredKeyboardViews removeObjectForKey:keyboardView];
    [_lock unlock];
    WKSPerformOnMainThread(^{
        WKSDetachGesturesFromKeyboardView(keyboardView);
    });
}

- (void)detachAllGestures {
    [_lock lock];
    NSArray<UIView *> *views = [[_registeredKeyboardViews keyEnumerator] allObjects];
    [_lock unlock];
    WKSPerformOnMainThread(^{
        for (UIView *view in views) {
            WKSDetachGesturesFromKeyboardView(view);
        }
    });
}

- (void)revalidateAllKeyboards {
    [_lock lock];
    NSArray<UIView *> *views = [[_registeredKeyboardViews keyEnumerator] allObjects];
    [_lock unlock];
    WKSPerformOnMainThread(^{
        for (UIView *view in views) {
            BOOL shouldAttach = WKSShouldActivateForResponder(WKSCurrentFirstResponder()) && !WKSIsHardwareKeyboardConnected();
            WKSGestureHandler *handler = objc_getAssociatedObject(view, kWKSHandlerAssociationKey);
            if (shouldAttach && !handler) {
                WKSAttachGesturesToKeyboardView(view);
            } else if (!shouldAttach && handler) {
                WKSDetachGesturesFromKeyboardView(view);
            }
        }
    });
}

- (void)hardwareKeyboardAvailabilityDidChange {
    [self revalidateAllKeyboards];
}

@end

%hook UIKeyboardLayoutStar

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
    } else {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;
    if (!newWindow) {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

%end

%hook UIInputSetHostView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
    } else {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;
    if (!newWindow) {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

%end

%hook UIKeyboardLayout

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
    } else {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;
    if (!newWindow) {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

%end

%hook UIKBKeyplaneView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
    } else {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;
    if (!newWindow) {
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

%end

%hook UIRemoteKeyboardWindow

- (void)setRootViewController:(UIViewController *)rootViewController {
    %orig;
    if (rootViewController && rootViewController.view) {
        dispatch_async(dispatch_get_main_queue(), ^{
            WKSScanForKeyboardViews(rootViewController.view, 0);
        });
    }
}

%end

%hook UIWindow

- (void)becomeKeyWindow {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    NSString *lowerClassName = [className lowercaseString];
    if ([lowerClassName containsString:@"keyboard"] || [lowerClassName containsString:@"texteffects"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            WKSScanForKeyboardViews(self, 0);
        });
    }
}

%end

%hook UIResponder

- (BOOL)becomeFirstResponder {
    BOOL result = %orig;
    if (result) {
        WKSWeakFirstResponder = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
        });
    }
    return result;
}

- (BOOL)resignFirstResponder {
    BOOL result = %orig;
    if (result && WKSWeakFirstResponder == self) {
        WKSWeakFirstResponder = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
        });
    }
    return result;
}

%end

%ctor {
    @autoreleasepool {
        WKSReloadPreferences();
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        WKSPreferencesDidChangeNotification,
                                        (__bridge CFStringRef)kPrefsChangedNotification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);
        WKSRegisterHardwareKeyboardObservers();
#if WKS_DEBUG
        WKSLog(@"WeChatKeyboardSwitch initialized");
#endif
    }
}
