#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIKeyboardImpl : UIView
+ (instancetype)sharedInstance;
- (void)switchToKeyboard:(NSString *)identifier;
@end

@interface UITextInputMode : NSObject
@property (nonatomic, readonly) NSString *primaryLanguage;
+ (UITextInputMode *)activeInputMode;
+ (NSArray *)activeInputModes;
@end

static UISwipeGestureRecognizer *upSwipeGesture = nil;
static UISwipeGestureRecognizer *downSwipeGesture = nil;

%hook UIInputWindowController

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupSwipeGestures];
    });
}

%new
- (void)setupSwipeGestures {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.tencent.xin"]) {
        return;
    }
    
    UIView *keyboardView = [self view];
    if (!keyboardView) return;
    
    if (upSwipeGesture) {
        [keyboardView removeGestureRecognizer:upSwipeGesture];
        upSwipeGesture = nil;
    }
    if (downSwipeGesture) {
        [keyboardView removeGestureRecognizer:downSwipeGesture];
        downSwipeGesture = nil;
    }
    
    upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpSwipe:)];
    upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    upSwipeGesture.numberOfTouchesRequired = 1;
    upSwipeGesture.cancelsTouchesInView = NO;
    upSwipeGesture.delaysTouchesEnded = NO;
    [keyboardView addGestureRecognizer:upSwipeGesture];
    
    downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDownSwipe:)];
    downSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    downSwipeGesture.numberOfTouchesRequired = 1;
    downSwipeGesture.cancelsTouchesInView = NO;
    downSwipeGesture.delaysTouchesEnded = NO;
    [keyboardView addGestureRecognizer:downSwipeGesture];
}

%new
- (void)handleUpSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        [self switchToEnglishInput];
        [self triggerHapticFeedback];
    }
}

%new
- (void)handleDownSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        [self switchToChineseInput];
        [self triggerHapticFeedback];
    }
}

%new
- (void)switchToEnglishInput {
    NSArray *inputModes = [UITextInputMode activeInputModes];
    
    for (UITextInputMode *mode in inputModes) {
        NSString *language = mode.primaryLanguage;
        if ([language hasPrefix:@"en"] || [language isEqualToString:@"en-US"] || [language isEqualToString:@"en_US"]) {
            [[UIKeyboardImpl sharedInstance] performSelector:@selector(setInputMode:) withObject:mode];
            return;
        }
    }
}

%new
- (void)switchToChineseInput {
    NSArray *inputModes = [UITextInputMode activeInputModes];
    
    for (UITextInputMode *mode in inputModes) {
        NSString *language = mode.primaryLanguage;
        if ([language hasPrefix:@"zh"] || [language isEqualToString:@"zh-Hans"] || [language isEqualToString:@"zh_CN"]) {
            [[UIKeyboardImpl sharedInstance] performSelector:@selector(setInputMode:) withObject:mode];
            return;
        }
    }
}

%new
- (void)triggerHapticFeedback {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

%end

%hook UIKeyboardImpl

- (void)setInputMode:(UITextInputMode *)mode {
    %orig;
}

%end

%ctor {
    %init;
}
