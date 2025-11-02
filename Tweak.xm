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
        NSInteger integerValue = [value integerValue];
        switch (integerValue) {
            case 0: return UIImpactFeedbackStyleLight;
            case 1: return UIImpactFeedbackStyleMedium;
            case 2: return UIImpactFeedbackStyleHeavy;
            case 3:
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
                return UIImpactFeedbackStyleSoft;
#else
                return UIImpactFeedbackStyleLight;
#endif
            case 4:
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
                return UIImpactFeedbackStyleRigid;
#else
                return UIImpactFeedbackStyleHeavy;
#endif
            default:
                break;
        }
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *normalized = [[value lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([normalized isEqualToString:@"light"]) {
            return UIImpactFeedbackStyleLight;
        }
        if ([normalized isEqualToString:@"medium"]) {
            return UIImpactFeedbackStyleMedium;
        }
        if ([normalized isEqualToString:@"heavy"]) {
            return UIImpactFeedbackStyleHeavy;
        }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
        if ([normalized isEqualToString:@"soft"]) {
            return UIImpactFeedbackStyleSoft;
        }
        if ([normalized isEqualToString:@"rigid"]) {
            return UIImpactFeedbackStyleRigid;
        }
#endif
    }
    return fallback;
}

static NSString *WKSNormalizeInputModeIdentifier(NSString *identifier) {
    NSString *normalized = WKSNormalizePreferenceString(identifier);
    return normalized ?: nil;
}

static void WKSLoadPreferences(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPreferencesDomain);
    kPrefEnabled = WKSGetBoolPreference(CFSTR("Enabled"), YES);
    kPrefOnlyWeChat = WKSGetBoolPreference(CFSTR("OnlyWeChat"), YES);
    kPrefInvertDirection = WKSGetBoolPreference(CFSTR("InvertDirection"), NO);
    kPrefHapticFeedback = WKSGetBoolPreference(CFSTR("HapticFeedback"), YES);
    kPrefSoundEnabled = WKSGetBoolPreference(CFSTR("SoundEnabled"), NO);
    kPrefDisableInSearchFields = WKSGetBoolPreference(CFSTR("DisableInSearchFields"), YES);
    kPrefDebugLogging = WKSGetBoolPreference(CFSTR("DebugLogging"), NO);

    CFPropertyListRef hapticRaw = CFPreferencesCopyAppValue(CFSTR("HapticStrength"), (__bridge CFStringRef)kPreferencesDomain);
    if (hapticRaw) {
        kPrefHapticStrength = WKSHapticStyleFromValue((__bridge id)hapticRaw, UIImpactFeedbackStyleLight);
        CFRelease(hapticRaw);
    } else {
        kPrefHapticStrength = UIImpactFeedbackStyleLight;
    }

    CGFloat thresholdValue = WKSGetFloatPreference(CFSTR("SwipeThreshold"), 42.0);
    kPrefSwipeThreshold = MAX(15.0, MIN(120.0, thresholdValue));

    CGFloat debounceValue = WKSGetFloatPreference(CFSTR("GestureDebounce"), 0.35);
    kPrefGestureDebounce = MAX(0.12, MIN(1.5, debounceValue));

    NSString *rawChinese = WKSGetStringPreference(CFSTR("ChineseMode"), nil);
    NSString *rawEnglish = WKSGetStringPreference(CFSTR("EnglishMode"), nil);
    kPrefChineseMode = WKSNormalizeInputModeIdentifier(rawChinese);
    kPrefEnglishMode = WKSNormalizeInputModeIdentifier(rawEnglish);

    CFPropertyListRef blacklistRaw = CFPreferencesCopyAppValue(CFSTR("ContextBlacklist"), (__bridge CFStringRef)kPreferencesDomain);
    if (blacklistRaw) {
        kPrefContextBlacklist = WKSNormalizedClassSetFromValue((__bridge id)blacklistRaw);
        CFRelease(blacklistRaw);
    } else {
        kPrefContextBlacklist = nil;
    }

    CFPropertyListRef whitelistRaw = CFPreferencesCopyAppValue(CFSTR("ContextWhitelist"), (__bridge CFStringRef)kPreferencesDomain);
    if (whitelistRaw) {
        kPrefContextWhitelist = WKSNormalizedClassSetFromValue((__bridge id)whitelistRaw);
        CFRelease(whitelistRaw);
    } else {
        kPrefContextWhitelist = nil;
    }

    CFPropertyListRef identifierBlacklistRaw = CFPreferencesCopyAppValue(CFSTR("IdentifierBlacklist"), (__bridge CFStringRef)kPreferencesDomain);
    if (identifierBlacklistRaw) {
        kPrefContextIdentifierBlacklist = WKSNormalizedClassSetFromValue((__bridge id)identifierBlacklistRaw);
        CFRelease(identifierBlacklistRaw);
    } else {
        kPrefContextIdentifierBlacklist = nil;
    }

    NSMutableSet<NSString *> *identifierCombined = [NSMutableSet setWithSet:WKSDefaultIdentifierBlacklist()];
    if (kPrefContextIdentifierBlacklist.count > 0) {
        [identifierCombined unionSet:kPrefContextIdentifierBlacklist];
    }
    kPrefContextIdentifierBlacklist = [identifierCombined copy];

    if (kPrefDisableInSearchFields) {
        NSMutableSet<NSString *> *combined = [NSMutableSet setWithSet:WKSDefaultSearchBlacklist()];
        if (kPrefContextBlacklist.count > 0) {
            [combined unionSet:kPrefContextBlacklist];
        }
        kPrefContextBlacklist = [combined copy];
    }

    kRuntimeDebugEnabled = kPrefDebugLogging;
#if !WKS_DEBUG
    kRuntimeDebugEnabled = NO;
#endif

#if WKS_DEBUG
    WKSLog(@"Preferences loaded - Enabled: %d, DebugLogging: %d", kPrefEnabled, kPrefDebugLogging);
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

static BOOL WKSResponderAttributesMatchTokens(UIResponder *responder, NSSet<NSString *> *tokens) {
    if (!responder || tokens.count == 0) {
        return NO;
    }
    NSArray<NSString *> *selectorNames = @[ @"accessibilityIdentifier",
                                            @"accessibilityLabel",
                                            @"placeholder",
                                            @"title",
                                            @"hint" ];
    for (NSString *selectorName in selectorNames) {
        SEL selector = NSSelectorFromString(selectorName);
        if (selector && [responder respondsToSelector:selector]) {
            id attribute = WKSCallSelectorReturningId(responder, selector);
            if ([attribute isKindOfClass:[NSString class]] && WKSStringContainsTokenSet(attribute, tokens)) {
                return YES;
            }
        }
    }
    SEL restorationIdentifierSel = @selector(restorationIdentifier);
    if ([responder respondsToSelector:restorationIdentifierSel]) {
        id restorationIdentifier = WKSCallSelectorReturningId(responder, restorationIdentifierSel);
        if ([restorationIdentifier isKindOfClass:[NSString class]] && WKSStringContainsTokenSet(restorationIdentifier, tokens)) {
            return YES;
        }
    }
    return NO;
}

static BOOL WKSResponderMatchesIdentifierSet(UIResponder *responder, NSSet<NSString *> *set) {
    if (!responder || set.count == 0) {
        return NO;
    }
    NSMutableSet<UIResponder *> *visited = [NSMutableSet set];
    UIResponder *current = responder;
    NSUInteger depth = 0;
    while (current && depth < 10) {
        if ([visited containsObject:current]) {
            break;
        }
        [visited addObject:current];
        if (WKSResponderAttributesMatchTokens(current, set)) {
            return YES;
        }
        UIResponder *nextResponder = current.nextResponder;
        if ([current isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)current;
            if (view.superview) {
                nextResponder = view.superview;
            } else if (!nextResponder) {
                nextResponder = view.nextResponder;
            }
        }
        current = nextResponder;
        depth++;
    }
    return NO;
}

static BOOL WKSResponderMatchesSet(UIResponder *responder, NSSet<NSString *> *set) {
    if (!responder || set.count == 0) {
        return NO;
    }
    NSMutableSet<UIResponder *> *visited = [NSMutableSet set];
    UIResponder *current = responder;
    NSUInteger depth = 0;
    while (current && depth < 10) {
        if ([visited containsObject:current]) {
            break;
        }
        [visited addObject:current];
        NSString *normalized = WKSNormalizeClassName(NSStringFromClass([current class]));
        if (normalized.length > 0 && [set containsObject:normalized]) {
            return YES;
        }
        UIResponder *nextResponder = current.nextResponder;
        if ([current isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)current;
            if (view.superview) {
                nextResponder = view.superview;
            } else if (!nextResponder) {
                nextResponder = view.nextResponder;
            }
        }
        current = nextResponder;
        depth++;
    }
    return NO;
}

static BOOL WKSResponderLooksLikeSearch(UIResponder *responder) {
    if (!responder) {
        return NO;
    }
    static Class searchBarFieldClass = Nil;
    static Class searchTextFieldClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        searchBarFieldClass = NSClassFromString(@"UISearchBarTextField");
        searchTextFieldClass = NSClassFromString(@"UISearchTextField");
    });
    if ((searchBarFieldClass && [responder isKindOfClass:searchBarFieldClass]) ||
        (searchTextFieldClass && [responder isKindOfClass:searchTextFieldClass])) {
        return YES;
    }
    NSString *className = [NSStringFromClass([responder class]) lowercaseString];
    if ([className containsString:@"search"]) {
        return YES;
    }
    SEL textContentTypeSel = @selector(textContentType);
    if ([responder respondsToSelector:textContentTypeSel]) {
        id contentType = WKSCallSelectorReturningId(responder, textContentTypeSel);
        if ([contentType isKindOfClass:[NSString class]] &&
            [[(NSString *)contentType lowercaseString] containsString:@"search"]) {
            return YES;
        }
    }
    SEL placeholderSel = @selector(placeholder);
    if ([responder respondsToSelector:placeholderSel]) {
        id placeholder = WKSCallSelectorReturningId(responder, placeholderSel);
        if ([placeholder isKindOfClass:[NSString class]] &&
            [[(NSString *)placeholder lowercaseString] containsString:@"search"]) {
            return YES;
        }
    }
    if ([responder isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)responder;
        UIView *current = view.superview;
        NSUInteger depth = 0;
        while (current && depth < 5) {
            NSString *name = [NSStringFromClass([current class]) lowercaseString];
            if ([name containsString:@"search"]) {
                return YES;
            }
            current = current.superview;
            depth++;
        }
    }
    return NO;
}

static UIResponder *WKSCurrentFirstResponder(void) {
    return WKSPerformOnMainThreadReturningId(^id{
        WKSWeakFirstResponder = nil;
        Class appClass = NSClassFromString(@"UIApplication");
        SEL sharedSel = @selector(sharedApplication);
        UIApplication *application = nil;
        if (appClass && [appClass respondsToSelector:sharedSel]) {
            application = WKSCallSelectorReturningId(appClass, sharedSel);
        }
        if (application) {
            [application sendAction:@selector(wks_captureFirstResponder:) to:nil from:nil forEvent:nil];
        }
        if (WKSWeakFirstResponder) {
            return WKSWeakFirstResponder;
        }
        UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
        if (!impl) {
            impl = [UIKeyboardImpl sharedInstance];
        }
        SEL delegateSel = @selector(delegate);
        if (impl && [impl respondsToSelector:delegateSel]) {
            id delegate = WKSCallSelectorReturningId(impl, delegateSel);
            if (delegate) {
                return delegate;
            }
        }
        SEL responderSel = NSSelectorFromString(@"responder");
        if (impl && [impl respondsToSelector:responderSel]) {
            id delegate = WKSCallSelectorReturningId(impl, responderSel);
            if (delegate) {
                return delegate;
            }
        }
        SEL privateDelegateSel = NSSelectorFromString(@"_delegate");
        if (impl && [impl respondsToSelector:privateDelegateSel]) {
            id delegate = WKSCallSelectorReturningId(impl, privateDelegateSel);
            if (delegate) {
                return delegate;
            }
        }
        return nil;
    });
}

static void WKSInvalidateHardwareKeyboardCache(void) {
    gHardwareKeyboardLastCheckTime = 0;
#if WKS_DEBUG
    WKSLog(@"Hardware keyboard cache invalidated");
#endif
}

static void WKSHardwareKeyboardDidChange(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    WKSInvalidateHardwareKeyboardCache();
    [[WKSKeyboardLifecycleManager sharedManager] hardwareKeyboardAvailabilityDidChange];
}

static void WKSRegisterHardwareKeyboardObservers(void) {
    if (gHardwareKeyboardObserversRegistered) {
        return;
    }
    gHardwareKeyboardObserversRegistered = YES;
    
    NSArray<NSString *> *notificationNames = @[
        @"UIKeyboardHardwareKeyboardAvailabilityChangedNotification",
        @"UIKeyboardPrivateHardwareKeyboardDidChangeNotification",
        @"UITextInputCurrentInputModeDidChangeNotification",
    ];
    
    for (NSString *notificationName in notificationNames) {
        CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
        if (center) {
            CFNotificationCenterAddObserver(center,
                                           NULL,
                                           WKSHardwareKeyboardDidChange,
                                           (__bridge CFStringRef)notificationName,
                                           NULL,
                                           CFNotificationSuspensionBehaviorDeliverImmediately);
        }
    }
    
    NSNotificationCenter *nsCenter = [NSNotificationCenter defaultCenter];
    if (nsCenter) {
        for (NSString *notificationName in notificationNames) {
            [nsCenter addObserverForName:notificationName
                                  object:nil
                                   queue:[NSOperationQueue mainQueue]
                              usingBlock:^(NSNotification *note) {
                WKSInvalidateHardwareKeyboardCache();
                [[WKSKeyboardLifecycleManager sharedManager] hardwareKeyboardAvailabilityDidChange];
            }];
        }
    }
    
#if WKS_DEBUG
    WKSLog(@"Registered hardware keyboard observers");
#endif
}

static BOOL WKSIsHardwareKeyboardConnected(void) {
    CFTimeInterval now = CACurrentMediaTime();
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
                                                @"isHardwareKeyboardActive" ];
            for (NSString *name in selectors) {
                SEL sel = NSSelectorFromString(name);
                if (sel && [impl respondsToSelector:sel]) {
                    if (((BOOL (*)(id, SEL))objc_msgSend)(impl, sel)) {
#if WKS_DEBUG
                        WKSLog(@"Hardware keyboard detected via %@", name);
#endif
                        return YES;
                    }
                }
            }
            SEL configurationSel = NSSelectorFromString(@"hardwareKeyboardConfiguration");
            if (configurationSel && [impl respondsToSelector:configurationSel]) {
                id configuration = WKSCallSelectorReturningId(impl, configurationSel);
                if (configuration) {
                    SEL countSel = @selector(count);
                    if ([configuration respondsToSelector:countSel]) {
                        NSInteger count = ((NSInteger (*)(id, SEL))objc_msgSend)(configuration, countSel);
                        if (count > 0) {
#if WKS_DEBUG
                            WKSLog(@"Hardware keyboard detected via configuration count");
#endif
                            return YES;
                        }
                    } else {
                        return YES;
                    }
                }
            }
            return NO;
        } @catch (NSException *exception) {
#if WKS_DEBUG
            WKSLog(@"Exception checking hardware keyboard: %@", exception);
#endif
            return NO;
        }
    });
    return gHardwareKeyboardCachedResult;
}

static BOOL WKSIsResponderAllowed(UIResponder *responder) {
    if (!responder) {
        return YES;
    }
    BOOL isWhitelisted = NO;
    if (kPrefContextWhitelist.count > 0) {
        isWhitelisted = WKSResponderMatchesSet(responder, kPrefContextWhitelist);
        if (!isWhitelisted) {
            return NO;
        }
    }
    if (!isWhitelisted) {
        if (WKSResponderIsBlacklistedByHeuristics(responder)) {
#if WKS_DEBUG
            WKSLog(@"Responder blocked by heuristic blacklist");
#endif
            return NO;
        }
        if (kPrefContextBlacklist.count > 0 && WKSResponderMatchesSet(responder, kPrefContextBlacklist)) {
#if WKS_DEBUG
            WKSLog(@"Responder blocked by class blacklist");
#endif
            return NO;
        }
        if (kPrefContextIdentifierBlacklist.count > 0 && WKSResponderMatchesIdentifierSet(responder, kPrefContextIdentifierBlacklist)) {
#if WKS_DEBUG
            WKSLog(@"Responder blocked by identifier blacklist");
#endif
            return NO;
        }
        if (kPrefDisableInSearchFields && WKSResponderLooksLikeSearch(responder)) {
#if WKS_DEBUG
            WKSLog(@"Responder blocked: looks like search field");
#endif
            return NO;
        }
    }
    return YES;
}

static BOOL WKSShouldActivateForResponder(UIResponder *responder) {
    if (!kPrefEnabled) {
        return NO;
    }
    if (kPrefOnlyWeChat && !WKSIsWeChatProcess()) {
        return NO;
    }
    if (WKSIsHardwareKeyboardConnected()) {
        return NO;
    }
    if (!WKSIsResponderAllowed(responder)) {
        return NO;
    }
    return YES;
}

static BOOL WKSShouldActivate(void) {
    UIResponder *responder = WKSCurrentFirstResponder();
    return WKSShouldActivateForResponder(responder);
}

static BOOL WKSShouldProvideHapticFeedback(void) {
    return kPrefHapticFeedback;
}

static id WKSImpactGenerator(void) {
    Class generatorClass = NSClassFromString(@"UIImpactFeedbackGenerator");
    if (!generatorClass) {
        return nil;
    }
    static id generator = nil;
    static UIImpactFeedbackStyle cachedStyle = UIImpactFeedbackStyleLight;
    if (!generator || cachedStyle != kPrefHapticStrength) {
        generator = [[generatorClass alloc] initWithStyle:kPrefHapticStrength];
        cachedStyle = kPrefHapticStrength;
    }
    return generator;
}

static void WKSTriggerHapticFeedback(void) {
    if (!WKSShouldProvideHapticFeedback()) {
        return;
    }
    id generator = WKSImpactGenerator();
    if (generator && [generator respondsToSelector:@selector(impactOccurred)]) {
        [generator impactOccurred];
        if ([generator respondsToSelector:@selector(prepare)]) {
            [generator prepare];
        }
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

@interface UIResponder (WKSFirstResponderCapture)
- (void)wks_captureFirstResponder:(id)sender;
@end

@implementation UIResponder (WKSFirstResponderCapture)
- (void)wks_captureFirstResponder:(id)sender {
    if ([self isKindOfClass:[UIResponder class]]) {
        WKSWeakFirstResponder = self;
    }
}
@end

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

- (NSString *)identifierMatchingPreference:(NSString *)preference {
    NSString *cleanPreference = WKSNormalizeInputModeIdentifier(preference);
    if (cleanPreference.length == 0) {
        return nil;
    }
    NSString *lowerPreference = [cleanPreference lowercaseString];
    NSArray *modes = [self activeInputModes];
    for (id mode in modes) {
        NSString *identifier = WKSIdentifierFromMode(mode);
        if (identifier.length > 0 && [identifier caseInsensitiveCompare:cleanPreference] == NSOrderedSame) {
            return identifier;
        }
    }
    for (id mode in modes) {
        NSString *identifier = WKSIdentifierFromMode(mode);
        if (identifier.length == 0) {
            continue;
        }
        NSString *lowerIdentifier = [identifier lowercaseString];
        if ([lowerIdentifier containsString:lowerPreference]) {
            return identifier;
        }
        NSString *language = WKSPrimaryLanguageFromMode(mode);
        if (language.length > 0 && [[language lowercaseString] containsString:lowerPreference]) {
            return identifier;
        }
        SEL displayNameSel = NSSelectorFromString(@"displayName");
        if (displayNameSel && [mode respondsToSelector:displayNameSel]) {
            id displayName = WKSCallSelectorReturningId(mode, displayNameSel);
            if ([displayName isKindOfClass:[NSString class]]) {
                NSString *lowerDisplayName = [(NSString *)displayName lowercaseString];
                if ([lowerDisplayName containsString:lowerPreference]) {
                    return identifier;
                }
            }
        }
    }
    return nil;
}

- (NSString *)preferredChineseInputModeIdentifier {
    NSString *preferred = [self identifierMatchingPreference:kPrefChineseMode];
    if (preferred.length > 0) {
        return preferred;
    }
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
    NSString *preferred = [self identifierMatchingPreference:kPrefEnglishMode];
    if (preferred.length > 0) {
        return preferred;
    }
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

- (BOOL)verifyInputModeIdentifier:(NSString *)targetIdentifier {
    if (targetIdentifier.length == 0) {
        return NO;
    }
    id currentMode = [self currentInputMode];
    NSString *currentIdentifier = WKSIdentifierFromMode(currentMode);
    if (currentIdentifier.length > 0 && [currentIdentifier isEqualToString:targetIdentifier]) {
        return YES;
    }
    NSString *targetLower = [targetIdentifier lowercaseString];
    NSString *currentLower = currentIdentifier.length > 0 ? [currentIdentifier lowercaseString] : nil;
    if (currentLower && [currentLower containsString:targetLower]) {
        return YES;
    }
    return NO;
}

- (BOOL)switchToInputModeObject:(id)mode {
    if (!mode) {
        return NO;
    }
    return WKSPerformOnMainThreadReturningBOOL(^BOOL{
        @try {
            NSString *targetIdentifier = WKSIdentifierFromMode(mode);
            if (targetIdentifier.length == 0) {
#if WKS_DEBUG
                WKSLog(@"Cannot switch: target mode has no identifier");
#endif
                return NO;
            }
            
            id controller = [self inputModeController];
            UIKeyboardImpl *impl = [UIKeyboardImpl activeInstance];
            if (!impl) {
                impl = [UIKeyboardImpl sharedInstance];
            }
            
            for (NSUInteger attempt = 0; attempt <= kWKSSwitchMaxRetries; attempt++) {
                if (attempt > 0) {
#if WKS_DEBUG
                    WKSLog(@"Switch retry attempt %lu", (unsigned long)attempt);
#endif
                    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWKSSwitchRetryDelay]];
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
                
                if (didInvoke) {
                    if (impl) {
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
                    
                    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWKSSwitchRetryDelay]];
                    
                    if ([self verifyInputModeIdentifier:targetIdentifier]) {
#if WKS_DEBUG
                        WKSLog(@"Switch verified to: %@", targetIdentifier);
#endif
                        return YES;
                    }
                }
            }
            
            BOOL didCycle = [self _cycleToNextInputModeLockedWithImpl:impl controller:controller];
            if (didCycle) {
                [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWKSSwitchRetryDelay]];
                if ([self verifyInputModeIdentifier:targetIdentifier]) {
#if WKS_DEBUG
                    WKSLog(@"Switch verified after cycling to: %@", targetIdentifier);
#endif
                    return YES;
                }
            }
            
#if WKS_DEBUG
            WKSLog(@"Switch failed after %lu attempts to: %@", (unsigned long)(kWKSSwitchMaxRetries + 1), targetIdentifier);
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

@implementation WKSKeyboardLifecycleManager {
    NSHashTable<UIView *> *_trackedViews;
    BOOL _observersSetup;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static WKSKeyboardLifecycleManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _trackedViews = [NSHashTable weakObjectsHashTable];
        [self setupObserversIfNeeded];
        WKSRegisterHardwareKeyboardObservers();
    }
    return self;
}

- (void)setupObserversIfNeeded {
    if (_observersSetup) {
        return;
    }
    _observersSetup = YES;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSArray<NSNotificationName> *showNotifications = @[
        UIKeyboardWillShowNotification,
        UIKeyboardDidShowNotification,
        UIKeyboardWillChangeFrameNotification,
        UIKeyboardDidChangeFrameNotification
    ];
    for (NSNotificationName name in showNotifications) {
        [center addObserver:self
                   selector:@selector(keyboardWillOrDidShow:)
                       name:name
                     object:nil];
    }

    NSArray<NSNotificationName> *hideNotifications = @[
        UIKeyboardWillHideNotification,
        UIKeyboardDidHideNotification
    ];
    for (NSNotificationName name in hideNotifications) {
        [center addObserver:self
                   selector:@selector(keyboardWillOrDidHide:)
                       name:name
                     object:nil];
    }

    [center addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
}

- (void)keyboardWillOrDidShow:(NSNotification *)notification {
#if WKS_DEBUG
    WKSLog(@"Keyboard notification (%@) received", notification.name);
#endif
    WKSInvalidateHardwareKeyboardCache();
    [self revalidateAllKeyboards];
}

- (void)keyboardWillOrDidHide:(NSNotification *)notification {
#if WKS_DEBUG
    WKSLog(@"Keyboard hide notification (%@) received", notification.name);
#endif
    [self detachAllGestures];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self revalidateAllKeyboards];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self detachAllGestures];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self detachAllGestures];
}

- (void)registerKeyboardView:(UIView *)keyboardView {
    if (!keyboardView) {
        return;
    }
    WKSPerformOnMainThread(^{
        [_trackedViews addObject:keyboardView];
#if WKS_DEBUG
        WKSLog(@"Registered keyboard view: %@", NSStringFromClass([keyboardView class]));
#endif
    });
}

- (void)unregisterKeyboardView:(UIView *)keyboardView {
    if (!keyboardView) {
        return;
    }
    WKSPerformOnMainThread(^{
        [_trackedViews removeObject:keyboardView];
#if WKS_DEBUG
        WKSLog(@"Unregistered keyboard view: %@", NSStringFromClass([keyboardView class]));
#endif
    });
}

- (void)detachAllGestures {
    WKSPerformOnMainThread(^{
        NSArray<UIView *> *views = [_trackedViews allObjects];
        for (UIView *view in views) {
            if (view) {
                WKSDetachGesturesFromKeyboardView(view);
            }
        }
#if WKS_DEBUG
        WKSLog(@"Detached all gestures from %lu tracked views", (unsigned long)views.count);
#endif
    });
}

- (void)revalidateAllKeyboards {
    WKSPerformOnMainThread(^{
        NSArray<UIView *> *views = [_trackedViews allObjects];
        BOOL shouldActivate = WKSShouldActivate();
        for (UIView *view in views) {
            if (!view || !view.window) {
                [_trackedViews removeObject:view];
                continue;
            }
            if (shouldActivate && WKSViewIsEligibleKeyboardView(view)) {
                WKSAttachGesturesToKeyboardView(view);
            } else {
                WKSDetachGesturesFromKeyboardView(view);
            }
        }
#if WKS_DEBUG
        WKSLog(@"Revalidated %lu keyboard views", (unsigned long)views.count);
#endif
    });
}

- (void)hardwareKeyboardAvailabilityDidChange {
    WKSInvalidateHardwareKeyboardCache();
    [self revalidateAllKeyboards];
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
    CGPoint _initialTouchPoint;
    BOOL _hasInitialTouchPoint;
}

- (instancetype)initWithKeyboardView:(UIView *)keyboardView {
    self = [super init];
    if (self) {
        _keyboardView = keyboardView;
        _lastTrigger = 0;
        _initialTouchPoint = CGPointZero;
        _hasInitialTouchPoint = NO;
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
        _swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
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
    @try {
        UIView *view = _keyboardView;
        if (_swipeUp) {
            if (view && [view.gestureRecognizers containsObject:_swipeUp]) {
                [view removeGestureRecognizer:_swipeUp];
            }
            _swipeUp = nil;
        }
        if (_swipeDown) {
            if (view && [view.gestureRecognizers containsObject:_swipeDown]) {
                [view removeGestureRecognizer:_swipeDown];
            }
            _swipeDown = nil;
        }
    } @catch (NSException *exception) {
#if WKS_DEBUG
        WKSLog(@"Exception detaching gestures: %@", exception);
#endif
    } @finally {
        _swipeUp = nil;
        _swipeDown = nil;
        _keyboardView = nil;
        _hasInitialTouchPoint = NO;
        _initialTouchPoint = CGPointZero;
    }
#if WKS_DEBUG
    WKSLog(@"Detached swipe gestures");
#endif
}

- (void)dealloc {
    [self detach];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) {
        return;
    }
    if (!_keyboardView) {
        return;
    }

    UIResponder *responder = WKSCurrentFirstResponder();
    if (!WKSShouldActivateForResponder(responder)) {
        return;
    }

    CFTimeInterval now = CACurrentMediaTime();
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
        WKSLog(@"Gesture ignored due to global debounce (%.2f s)", now - gLastSwitchTimestamp);
#endif
        return;
    }

    CGPoint currentPoint = [gesture locationInView:_keyboardView];
    if (!_hasInitialTouchPoint) {
        _initialTouchPoint = currentPoint;
    }

    CGFloat deltaX = currentPoint.x - _initialTouchPoint.x;
    CGFloat deltaY = currentPoint.y - _initialTouchPoint.y;
    CGFloat distance = fabs(deltaY);
    CGFloat requiredDistance = WKSGestureRequiredDistance();
    if (distance < requiredDistance) {
#if WKS_DEBUG
        WKSLog(@"Gesture ignored due to short travel (%.1f < %.1f)", distance, requiredDistance);
#endif
        return;
    }
    if (fabs(deltaY) < fabs(deltaX)) {
#if WKS_DEBUG
        WKSLog(@"Gesture ignored due to horizontal bias (|%.1f| ≥ |%.1f|)", deltaX, deltaY);
#endif
        return;
    }

    _lastTrigger = now;
    gLastSwitchTimestamp = now;
    gSwitchOperationInFlight = YES;
    _hasInitialTouchPoint = NO;
    _initialTouchPoint = CGPointZero;

    BOOL isUpGesture = (gesture == _swipeUp) || ((gesture.direction & UISwipeGestureRecognizerDirectionUp) != 0) || (deltaY < 0.0f);
    BOOL targetChinese = isUpGesture ? !kPrefInvertDirection : kPrefInvertDirection;

    if (gSwitchWatchdogTimer) {
        dispatch_source_cancel(gSwitchWatchdogTimer);
        gSwitchWatchdogTimer = nil;
    }

    gSwitchWatchdogTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (gSwitchWatchdogTimer) {
        dispatch_source_set_timer(gSwitchWatchdogTimer,
                                 dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                                 DISPATCH_TIME_FOREVER,
                                 (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_source_set_event_handler(gSwitchWatchdogTimer, ^{
            gSwitchOperationInFlight = NO;
            if (gSwitchWatchdogTimer) {
                dispatch_source_cancel(gSwitchWatchdogTimer);
                gSwitchWatchdogTimer = nil;
            }
#if WKS_DEBUG
            WKSLog(@"Watchdog timer reset switch operation flag");
#endif
        });
        dispatch_resume(gSwitchWatchdogTimer);
    }

    WKSPerformOnMainThread(^{
        @try {
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
                WKSTriggerFeedback();
            }
        } @catch (NSException *exception) {
#if WKS_DEBUG
            WKSLog(@"Exception during switch: %@", exception);
#endif
        } @finally {
            gSwitchOperationInFlight = NO;
            if (gSwitchWatchdogTimer) {
                dispatch_source_cancel(gSwitchWatchdogTimer);
                gSwitchWatchdogTimer = nil;
            }
        }
    });
}

#pragma mark - UIGestureRecognizerDelegate

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
    NSUInteger depth = 0;
    Class dockViewClass = NSClassFromString(@"UIKeyboardDockView");
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
    @try {
        if (!WKSViewIsEligibleKeyboardView(keyboardView)) {
            return;
        }
        WKSKeyboardGestureHandler *handler = objc_getAssociatedObject(keyboardView, kWKSHandlerAssociationKey);
        if (!handler) {
            handler = [[WKSKeyboardGestureHandler alloc] initWithKeyboardView:keyboardView];
            objc_setAssociatedObject(keyboardView, kWKSHandlerAssociationKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [handler install];
        }
    } @catch (NSException *exception) {
#if WKS_DEBUG
        WKSLog(@"Exception attaching gestures: %@", exception);
#endif
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

static void WKSScanForKeyboardViews(UIView *rootView, NSUInteger depth) {
    if (!rootView || depth > 4) {
        return;
    }
    if (WKSViewIsEligibleKeyboardView(rootView)) {
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:rootView];
    }
    for (UIView *subview in rootView.subviews) {
        WKSScanForKeyboardViews(subview, depth + 1);
    }
}

%hook UIKeyboardLayout

- (void)willMoveToWindow:(UIWindow *)window {
    %orig;
    if (!window) {
        WKSDetachGesturesFromKeyboardView(self);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) {
            WKSDetachGesturesFromKeyboardView(self);
            [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
            return;
        }
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
        BOOL shouldActivate = WKSShouldActivate();
        if (shouldActivate && WKSViewIsEligibleKeyboardView(self)) {
            WKSAttachGesturesToKeyboardView(self);
        } else {
            WKSDetachGesturesFromKeyboardView(self);
        }
    } @catch (NSException *exception) {
#if WKS_DEBUG
        WKSLog(@"Exception in didMoveToWindow: %@", exception);
#endif
    }
}

%end

%hook UIKeyboardLayoutStar

- (void)willMoveToWindow:(UIWindow *)window {
    %orig;
    if (!window) {
        WKSDetachGesturesFromKeyboardView(self);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) {
            WKSDetachGesturesFromKeyboardView(self);
            [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
            return;
        }
        [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
        BOOL shouldActivate = WKSShouldActivate();
        if (shouldActivate && WKSViewIsEligibleKeyboardView(self)) {
            WKSAttachGesturesToKeyboardView(self);
        } else {
            WKSDetachGesturesFromKeyboardView(self);
        }
    } @catch (NSException *exception) {
#if WKS_DEBUG
        WKSLog(@"Exception in didMoveToWindow: %@", exception);
#endif
    }
}

%end

%hook UIInputSetHostView

- (void)willMoveToWindow:(UIWindow *)window {
    %orig;
    if (!window) {
        WKSDetachGesturesFromKeyboardView(self);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)didMoveToWindow {
    %orig;
    if (!self.window) {
        WKSDetachGesturesFromKeyboardView(self);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
        return;
    }
    WKSScanForKeyboardViews(self, 0);
    [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
}

- (void)didAddSubview:(UIView *)subview {
    %orig;
    if (subview) {
        WKSScanForKeyboardViews(subview, 0);
        [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
    }
}

- (void)willRemoveSubview:(UIView *)subview {
    if (subview) {
        WKSDetachGesturesFromKeyboardView(subview);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:subview];
    }
    %orig;
}

%end

%hook UIKBKeyplaneView

- (void)willMoveToWindow:(UIWindow *)window {
    %orig;
    if (!window) {
        WKSDetachGesturesFromKeyboardView(self);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
    }
}

- (void)didMoveToWindow {
    %orig;
    if (!self.window) {
        WKSDetachGesturesFromKeyboardView(self);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:self];
        return;
    }
    [[WKSKeyboardLifecycleManager sharedManager] registerKeyboardView:self];
    [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
}

- (void)didAddSubview:(UIView *)subview {
    %orig;
    if (subview) {
        WKSScanForKeyboardViews(subview, 0);
        [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
    }
}

%end

%hook UIRemoteKeyboardWindow

- (void)didAddSubview:(UIView *)subview {
    %orig;
    if ([subview isKindOfClass:[UIView class]]) {
        WKSScanForKeyboardViews((UIView *)subview, 0);
        [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
    }
}

- (void)willRemoveSubview:(UIView *)subview {
    if (subview) {
        WKSDetachGesturesFromKeyboardView(subview);
        [[WKSKeyboardLifecycleManager sharedManager] unregisterKeyboardView:subview];
    }
    %orig;
}

%end

__attribute__((unused))
static void WKSRunDebugSmokeTests(void) {
#if WKS_DEBUG
    WKSLog(@"Running debug smoke tests...");
    
    if (!WKSIsMainThread()) {
        WKSLog(@"Test FAILED: Not on main thread");
    } else {
        WKSLog(@"Test PASSED: Main thread check");
    }
    
    BOOL hardwareKeyboardState = WKSIsHardwareKeyboardConnected();
    WKSLog(@"Hardware keyboard state: %d", hardwareKeyboardState);
    
    WKSKeyboardInputHelper *helper = [WKSKeyboardInputHelper sharedHelper];
    NSArray *modes = [helper activeInputModes];
    WKSLog(@"Active input modes count: %lu", (unsigned long)modes.count);
    
    id currentMode = [helper currentInputMode];
    NSString *currentId = WKSIdentifierFromMode(currentMode);
    WKSLog(@"Current input mode: %@", currentId ?: @"(nil)");
    
    NSSet<NSString *> *testTokens = [NSSet setWithObjects:@"search", @"login", nil];
    BOOL matchTest = WKSStringContainsTokenSet(@"SearchField", testTokens);
    if (matchTest) {
        WKSLog(@"Test PASSED: String token matching");
    } else {
        WKSLog(@"Test FAILED: String token matching");
    }
    
    WKSLog(@"Debug smoke tests completed");
#endif
}

%ctor {
    @autoreleasepool {
        WKSLoadPreferences();
        WKSRegisterForPreferenceChanges();
        [[WKSKeyboardLifecycleManager sharedManager] revalidateAllKeyboards];
        %init;
#if WKS_DEBUG
        WKSLog(@"WeChatKeyboardSwitch loaded - Enabled: %d, OnlyWeChat: %d", kPrefEnabled, kPrefOnlyWeChat);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WKSRunDebugSmokeTests();
        });
#endif
    }
}
