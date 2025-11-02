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
static BOOL kPrefDebugLogging = NO;
static __weak UIResponder *WKSWeakFirstResponder = nil;

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

@interface UIResponder (WKSPrivate)
- (id)_responderForEditing;
@end

@interface UITextField : UIControl <UITextInput>
@end

@interface UITextView : UIScrollView <UITextInput>
@end

@interface UISearchBar : UIView
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

static BOOL WKSIsHardwareKeyboardConnected(void) {
    static CFTimeInterval lastCheck = 0;
    static BOOL cachedResult = NO;
    CFTimeInterval now = CACurrentMediaTime();
    if ((now - lastCheck) < 0.5) {
        return cachedResult;
    }
    lastCheck = now;
    cachedResult = WKSPerformOnMainThreadReturningBOOL(^BOOL{
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
                        return YES;
                    }
                } else {
                    return YES;
                }
            }
        }
        return NO;
    });
    return cachedResult;
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
    if (!isWhitelisted && kPrefContextBlacklist.count > 0 && WKSResponderMatchesSet(responder, kPrefContextBlacklist)) {
        return NO;
    }
    if (!isWhitelisted && kPrefDisableInSearchFields && WKSResponderLooksLikeSearch(responder)) {
        return NO;
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
    _hasInitialTouchPoint = NO;
    _initialTouchPoint = CGPointZero;
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
    _hasInitialTouchPoint = NO;
    _initialTouchPoint = CGPointZero;

    BOOL isUpGesture = (gesture == _swipeUp) || ((gesture.direction & UISwipeGestureRecognizerDirectionUp) != 0) || (deltaY < 0.0f);
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
            WKSTriggerFeedback();
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
    while (view && view != _keyboardView && depth < 10) {
        NSString *className = NSStringFromClass([view class]);
        NSString *lowerClassName = [className lowercaseString];
        if ([lowerClassName containsString:@"dock"] ||
            [lowerClassName containsString:@"dictation"] ||
            [lowerClassName containsString:@"globe"] ||
            [view isKindOfClass:[UIKeyboardDockView class]]) {
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
    if ([windowClassName rangeOfString:@"Keyboard" options:NSCaseInsensitiveSearch].location == NSNotFound &&
        [windowClassName rangeOfString:@"TextEffects" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        return NO;
    }
    UIView *current = keyboardView;
    NSUInteger depth = 0;
    while (current && depth < 8) {
        NSString *className = NSStringFromClass([current class]);
        if ([className rangeOfString:@"Keyboard" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
        current = current.superview;
        depth++;
    }
    return NO;
}

static void WKSAttachGesturesToKeyboardView(UIView *keyboardView) {
    if (!keyboardView || !WKSViewIsEligibleKeyboardView(keyboardView)) {
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
    if (self.window && shouldActivate && WKSViewIsEligibleKeyboardView(self)) {
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
    if (self.window && shouldActivate && WKSViewIsEligibleKeyboardView(self)) {
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
