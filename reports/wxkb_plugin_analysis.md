# wxkb_plugin Analysis Report

## 1. Scope & Materials
- **Artifact**: `/home/engine/project/1 2.zip` (user-provided package)
- **Extraction**: Unzipped into `extracted/1/` → revealed `Info.plist` and `wxkb_plugin` Mach-O binary (≈41.8 MB)
- **Target**: WeType keyboard extension (`CFBundleIdentifier: com.tencent.wetype.keyboard`)
- **Principal class**: `WBInputViewController` (from `Info.plist` → `NSExtensionPrincipalClass`)

> Commands
> ```sh
> cd /home/engine/project
> mkdir -p extracted
> cd extracted
> unzip '../1 2.zip'
> python - <<'PY'
> import plistlib
> print(plistlib.load(open('1/Info.plist','rb'))['NSExtension']['NSExtensionPrincipalClass'])
> PY
> ```

## 2. Tooling & Methodology
1. **Binary metadata** – Parsed `Info.plist` via Python `plistlib` because `plutil`/`jtool2` unavailable.
2. **Objective-C metadata sweep** – Used Python regex against the Mach-O binary to capture `T@"Class"` property encodings and selector strings (length- & charset-filtered) as lightweight replacements for `class-dump`.
3. **Focused string greps** – `strings -a wxkb_plugin | grep <pattern>` for selectors like `setInputMode:` or `handleInputModeListFromView:withEvent:`.
4. **Keyword inventory** – Saved in `scripts/grep_patterns.txt` for reproducible searches.

> Limitation: Without `jtool2`/`class-dump`, method signatures that are stripped of metadata cannot be fully reconstructed. The report highlights observable selectors, but deeper Iverson-style method lists may require full ObjC runtime inspection on-device.

## 3. Keyboard Interface Class Candidates (≥5)
| Class | Evidence string(s) | Rationale |
| --- | --- | --- |
| `WBInputViewController` | `NSExtensionPrincipalClass` (`Info.plist`); `WBInputViewController.mm`; `-[WBInputViewController dealloc]` | Entry point for the keyboard extension, inherits from `UIInputViewController` – **critical for UI lifecycle & input mode switching**. |
| `WBMainInputView` | `T@"WBMainInputView",W,N,V_mainInputView` | Primary keyboard content view attached to controller – likely hosts key grid / sub-panels. |
| `WBRootViewManager` | `T@"WBRootViewManager",R,N,V_rootInputViewManager` | Manages root input view hierarchy; probable coordinator for switching between language panels. |
| `WBKeyboardView` | `T@"WBKeyboardView",R,N,V_keyboardView` | Explicit keyboard view wrapper; good vantage point for key layout toggles. |
| `WBLanguageSwitchView` | `T@"WBLanguageSwitchView",&,N,V_languageSwitchView` | Dedicated language-switch UI component. |
| `WBControlCenterView` | `T@"WBControlCenterView",R,N,V_controlCenter` | Container for feature toggles (emoji/voice/language) – likely issues switching actions. |
| `WBCCInputTypeControl` | `T@"WBCCInputTypeControl",&,N,V_inputTypeControl` | Control center element responsible for switching input types (Chinese ↔ English). |
| `WBKeyView` | `T@"WBKeyView",W,N` | Individual key component; watchers for globe/space long-press behaviour. |

(Additional notable hits: `WBRootInputView`, `WBInputViewContext`, `WBLanguageSwitchView`, `WBVoiceInputControlBar`, `WBPlusEntranceView`.)

## 4. Language Switching Selector Candidates (≥5)
| Selector | Source string | Why it matters |
| --- | --- | --- |
| `-setInputMode:` | `strings -a wxkb_plugin | grep 'setInputMode'` → `setInputMode:` | Core API on `UIInputViewController` used to force OS-level language change. |
| `-handleInputModeListFromView:withEvent:` | `handleInputModeListFromView:withEvent:` | Triggered when user taps/holds the globe key; ideal for intercepting toggles. |
| `-keyboardView:willSwitchPanelView:toPanelView:isPush:` | `keyboardView:willSwitchPanelView:toPanelView:isPush:` | Internal panel transition callback (observed `Switch` literal) – likely invoked when changing between Chinese/English layouts. |
| `-setSelectedLanguage:` / `-setSelectedLanguage:notify:` | `setSelectedLanguage:` | Directly mutates language model in `WBLanguageSwitchView`. |
| `-setUsingChineseForLanguageType:` | `setUsingChineseForLanguageType:` | Flag setter indicating Chinese vs English selection inside session state. |
| `-performSwitchWithOn:animated:shouldSendEvent:` | `performSwitchWithOn:animated:shouldSendEvent:` | Toggle orchestration within `WBControlCenterView`. |
| `-setSwitchOn:` / `-setSwitchControl:` | `setSwitchOn:` etc. | Pairing functions that physically update switch widgets bound to language mode. |
| `-didDetectSentTextLanguage:lastSentKeyword:` | `didDetectSentTextLanguage:lastSentKeyword:` | Telemetry when language detection fires – hookable for observing automatic language switching heuristics. |
| `-toolBar:didSelectTranslationLanguage:` | `toolBar:didSelectTranslationLanguage:` | UI callback when translation toolbar language changes; may cascade into keyboard switching. |
| `-setVoiceInputLanguage:` | `setVoiceInputLanguage:` | Voice dictation path – ensures spoken input uses correct locale. |

(Additional hits: `setLanguage:`, `setLanguageChangeBlock:`, `setSwitchValue:`, `userCoordinateSwitch:`.)

## 5. Priority Hooking Plan (Top 5)
| Priority | Class & Selector | Expected trigger | Purpose |
| --- | --- | --- | --- |
| 1 | `WBInputViewController` – `-setInputMode:` | Any language change request | Direct control over system input mode; hooking confirms final language applied. |
| 2 | `WBInputViewController` – `-handleInputModeListFromView:withEvent:` | Globe key tap / long-press | Captures user intent before mode switch; can short-circuit / log selection. |
| 3 | `WBInputViewController` – `-keyboardView:willSwitchPanelView:toPanelView:isPush:` | Panel transition (e.g., Chinese ↔ English) | Observes internal view swap & movement history. |
| 4 | `WBLanguageSwitchView` – `-setSelectedLanguage:` | Toggle within custom switch UI | Updates UI/logic for chosen language; hooking yields high-level state. |
| 5 | `WBControlCenterView` – `-performSwitchWithOn:animated:shouldSendEvent:` | Control center switch toggles | Applies toggle logic + optional analytics – intercept for forced Chinese/English. |

Fallback strategy (if symbols resolved at runtime only): leverage provided Frida script to enumerate additional `Language` / `InputMode` selectors dynamically and expand coverage.

## 6. Produced Artifacts
- `reports/wxkb_plugin_analysis.md` (this document)
- `scripts/grep_patterns.txt` – reusable string/regex filters for the binary
- `scripts/frida/hook_lang.js` – Frida probing script enumerating & hooking target selectors

### Frida Script Usage
```sh
# Device already running the WeType keyboard
frida -U -n "SpringBoard" -l scripts/frida/hook_lang.js --no-pause
# or attach directly if the appex hosts a custom process name
```
The script:
1. Enumerates Objective-C classes whose names contain `InputMode`/`Language`/`Switch` and prints their interesting selectors.
2. Attaches hooks to the five high-priority selectors listed above, logging `self` and arguments whenever they fire.

### Logos Hook Template
```logos
%hook WBInputViewController
- (void)setInputMode:(id)mode {
    HBLogDebug(@"[WeType] setInputMode:%@", mode);
    %orig;
}

- (void)handleInputModeListFromView:(id)view withEvent:(UIEvent *)event {
    HBLogDebug(@"[WeType] input list from view:%@ event:%@", view, event);
    %orig;
}
%end

%hook WBLanguageSwitchView
- (void)setSelectedLanguage:(id)lang {
    HBLogDebug(@"[WeType] setSelectedLanguage:%@", lang);
    %orig;
}
%end
```
> Integrate into existing tweak (e.g., `Tweak.xm`) and rebuild via Theos. Add `%ctor` if needed to ensure hooks load with the extension.

## 7. On-Device Validation Workflow
1. **Deploy extension build** (if modified) via `make package install` (Theos) or sideload official WeType (requires full disk access on jailbroken device).
2. **Identify process**: use `frida-ps -U | grep wxkb` to confirm the keyboard appex’s host process (usually a system `keyboardd` child or app host when active).
3. **Activate keyboard**: open any text field, switch to WeType keyboard to load `wxkb_plugin` into memory.
4. **Run hooks**:
   - **Frida**: execute command shown above, observe console logs when pressing the globe / Chinese-English toggle.
   - **Logos/Theos tweak**: after installing, check `/var/log/syslog` or `log stream --predicate 'sender CONTAINS "WeType"'` for `HBLogDebug` output while toggling languages.
5. **Verification**: confirm selectors fire in sequence (`handleInputModeListFromView` → `setSelectedLanguage` → `setInputMode`). Capture logs/time stamps for later automation scripts.
6. **Fallback enumeration**: if selectors differ by build, use runtime enumeration block in Frida script (`keywordFilters`) to list all loaded selectors containing `Language`/`InputMode` and broaden hook coverage.

## 8. Next Steps & Gaps
- **Binary symbol coverage**: Acquire `jtool2`/`class-dump` on macOS to export full ObjC class dump for cross-reference with runtime hooks.
- **Additional keyword sweeps**: Extend patterns to `Locale`, `pinYin`, `FullEnglish`, `WBCC` to capture more specialized modules.
- **Behavioural logging**: Combine Frida log outputs with event timestamps to map complete switching state machine.
- **C++ backend**: Numerous `wxime::` symbols suggest deeper engine logic; hooking the Objective-C layer should suffice for UI toggles, but the engine may need instrumentation if toggles propagate asynchronously.

---
Prepared by: *cto.new analysis agent*
Date: 2025-11-05
