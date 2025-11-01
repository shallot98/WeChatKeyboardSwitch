#import <UIKit/UIKit.h>

static NSString *const kWKSPrefsDomain = @"com.example.wechatkeyboardswitch";
static NSString *const kWKSLogPrefix = @"[WeChatKeyboardSwitch]";

static inline void WKSLog(NSString *message) {
    NSLog(@"%@ %@", kWKSLogPrefix, message);
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig(application);
    WKSLog([NSString stringWithFormat:@"Rootless skeleton tweak loaded (prefs domain: %@)", kWKSPrefsDomain]);
}

%end

%ctor {
    WKSLog(@"Constructor executed");
}
