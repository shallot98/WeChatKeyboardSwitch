#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface WKSRootListController : PSListController
@end

@implementation WKSRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

@end
