# Contributing to WeChat Keyboard Switch

Thank you for your interest in contributing to WeChat Keyboard Switch! This document provides guidelines and instructions for contributing to the project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:

1. **Clear title**: Brief description of the issue
2. **Environment details**:
   - iOS version
   - Jailbreak type and version
   - Device model
3. **Steps to reproduce**: Detailed steps to trigger the bug
4. **Expected behavior**: What should happen
5. **Actual behavior**: What actually happens
6. **Logs**: Relevant system logs or error messages
7. **Screenshots**: If applicable

### Suggesting Features

Feature requests are welcome! Please create an issue with:

1. **Clear description**: What feature you'd like to see
2. **Use case**: Why this feature would be useful
3. **Proposed implementation**: If you have ideas on how to implement it
4. **Alternatives**: Any alternative solutions you've considered

### Code Contributions

#### Getting Started

1. **Fork the repository**
```bash
git clone https://github.com/yourusername/WeChatKeyboardSwitch.git
cd WeChatKeyboardSwitch
```

2. **Set up Theos**
```bash
export THEOS=~/theos
```

3. **Create a feature branch**
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b bugfix/issue-description
```

#### Development Guidelines

##### Code Style

- Use **Objective-C** with **Logos syntax** for hooks
- Follow **Apple's coding conventions** for Objective-C
- Use **descriptive variable names**
- Add **comments for complex logic**
- Keep functions **small and focused**

Example:
```objc
// Good
static BOOL isWeChatKeyboardActive(UIKeyboardInputMode *mode) {
    if (!mode) return NO;
    return [mode.identifier containsString:@"com.tencent.xin"];
}

// Not so good
static BOOL check(id m) {
    return m && [((UIKeyboardInputMode*)m).identifier containsString:@"com.tencent.xin"];
}
```

##### Hook Guidelines

- Only hook **necessary methods**
- Use `%orig` to call original implementation when appropriate
- Add **null checks** before accessing properties
- Handle **errors gracefully** with @try/@catch blocks

```objc
%hook UIKeyboardImpl

- (void)someMethod:(id)arg {
    @try {
        // Your code here
        %orig;  // Call original implementation
    } @catch (NSException *exception) {
        NSLog(@"[WeChatKeyboardSwitch] Error: %@", exception);
        %orig;  // Still call original on error
    }
}

%end
```

##### Memory Management

- Use **ARC** (enabled in project)
- Properly manage **gesture recognizers**
- Clean up **static variables** when appropriate
- Avoid **retain cycles** in blocks

##### Logging

- Use descriptive log messages
- Include the tweak name prefix
- Log important events and errors

```objc
NSLog(@"[WeChatKeyboardSwitch] Switching to %@ mode", toEnglish ? @"English" : @"Chinese");
```

#### Making Changes

1. **Make your changes**
   - Keep commits focused and atomic
   - Test thoroughly on your device

2. **Test your changes**
```bash
make clean
make package
make install
# Then test on device
```

3. **Commit your changes**
```bash
git add .
git commit -m "feat: add new feature"
# or
git commit -m "fix: resolve issue with gesture recognition"
```

#### Commit Message Guidelines

Use conventional commit format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Build process or auxiliary tool changes

Examples:
```
feat: add haptic feedback option
fix: gesture recognizer memory leak
docs: update installation instructions
refactor: simplify input mode detection logic
```

#### Pull Request Process

1. **Update documentation** if needed
   - README.md for user-facing changes
   - CHANGELOG.md with your changes
   - Code comments for complex logic

2. **Ensure it builds**
```bash
make clean
make package
```

3. **Test thoroughly**
   - Test on your device
   - Test with WeChat keyboard
   - Test enable/disable in settings
   - Test on different iOS versions if possible

4. **Create pull request**
   - Use a clear title
   - Describe your changes in detail
   - Reference any related issues
   - Add screenshots/videos if applicable

5. **Respond to feedback**
   - Address review comments
   - Update code as needed
   - Be open to suggestions

### Testing Checklist

Before submitting a pull request, verify:

- [ ] Code compiles without errors or warnings
- [ ] Tweak installs correctly
- [ ] Settings appear in Settings app
- [ ] Toggle switch enables/disables functionality
- [ ] Gestures work correctly
- [ ] Input mode switches properly
- [ ] No crashes or performance issues
- [ ] Works on target iOS versions
- [ ] Documentation updated if needed
- [ ] CHANGELOG.md updated

## Project Structure

```
WeChatKeyboardSwitch/
├── Tweak.xm                    # Main tweak implementation
├── Makefile                    # Build configuration
├── control                     # Package metadata
├── WeChatKeyboardSwitch.plist  # MobileSubstrate filter
├── wechatkeyboardswitchprefs/  # Preference bundle
│   ├── Makefile
│   ├── entry.plist
│   ├── Resources/
│   │   └── Root.plist
│   └── *.h, *.m                # Controller files
└── layout/                     # Additional installation files
```

## Adding New Features

### Adding a Preference Option

1. **Update Root.plist**
```xml
<dict>
    <key>cell</key>
    <string>PSSwitchCell</string>
    <key>default</key>
    <true/>
    <key>defaults</key>
    <string>com.yourrepo.wechatkeyboardswitch</string>
    <key>key</key>
    <string>yourNewOption</string>
    <key>label</key>
    <string>Your Option Label</string>
    <key>PostNotification</key>
    <string>com.yourrepo.wechatkeyboardswitch/prefsChanged</string>
</dict>
```

2. **Load preference in Tweak.xm**
```objc
static BOOL yourNewOption = YES;

static void loadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    if (prefs) {
        yourNewOption = [prefs[@"yourNewOption"] boolValue];
    }
}
```

3. **Use the preference**
```objc
if (yourNewOption) {
    // Your feature code
}
```

### Adding a New Hook

1. **Define interface if needed**
```objc
@interface YourClass : NSObject
- (void)methodToHook;
@end
```

2. **Add hook**
```objc
%hook YourClass

- (void)methodToHook {
    // Pre-processing
    %orig;  // Call original
    // Post-processing
}

%end
```

## Resources

### Theos Documentation
- [Theos Wiki](https://theos.dev)
- [Logos Syntax](https://theos.dev/docs/logos-syntax)

### iOS Development
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [iOS Runtime Headers](https://github.com/nst/iOS-Runtime-Headers)

### Jailbreak Development
- [r/jailbreakdevelopers](https://www.reddit.com/r/jailbreakdevelopers/)
- [iPhone Dev Wiki](https://iphonedev.wiki/)

## Code Review Process

All submissions require review before merging:

1. **Automated checks**: Code must build successfully
2. **Manual review**: Maintainers review code quality and functionality
3. **Testing**: Changes should be tested on device
4. **Approval**: At least one maintainer must approve
5. **Merge**: Once approved, changes are merged

## Community Guidelines

- **Be respectful** to other contributors
- **Be patient** with review process
- **Be constructive** in feedback
- **Be open** to learning and improving

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Questions?

If you have questions about contributing:

1. Check existing issues and discussions
2. Create a new issue with your question
3. Reach out to maintainers

Thank you for contributing to WeChat Keyboard Switch! 🎉
