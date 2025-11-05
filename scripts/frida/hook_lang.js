// Frida script for probing WeType wxkb_plugin language switching paths
// Usage: frida -U -f com.tencent.wetype.keyboard -l hook_lang.js --no-pause

'use strict';

if (!ObjC.available) {
  console.log('Objective-C runtime is not available.');
  return;
}

const keywordFilters = ['InputMode', 'Language', 'Switch'];

function hookInstanceMethod(clsName, selector) {
  try {
    const cls = ObjC.classes[clsName];
    if (!cls) {
      console.log('[!] Class not available: ' + clsName);
      return;
    }
    const method = cls[selector];
    if (!method) {
      console.log('[!] Selector ' + selector + ' not found on ' + clsName);
      return;
    }
    const argCount = (selector.match(/:/g) || []).length;
    Interceptor.attach(method.implementation, {
      onEnter(args) {
        let message = '[+] ' + clsName + ' ' + selector;
        try {
          message += ' self=' + new ObjC.Object(args[0]).toString();
        } catch (err) {
          message += ' self=' + args[0];
        }
        console.log(message);
        for (let i = 0; i < argCount; i++) {
          const idx = 2 + i;
          let desc;
          try {
            desc = new ObjC.Object(args[idx]).toString();
          } catch (err) {
            desc = args[idx];
          }
          console.log('    arg' + i + ': ' + desc);
        }
      }
    });
    console.log('[*] Hooked ' + clsName + ' ' + selector);
  } catch (err) {
    console.log('[!] Failed to hook ' + clsName + ' ' + selector + ': ' + err);
  }
}

// Enumerate classes/methods matching filter keywords for manual inspection.
(function enumerateMatches() {
  console.log('[*] Enumerating classes containing keywords: ' + keywordFilters.join(', '));
  ObjC.enumerateLoadedClasses({
    onMatch(name, meta) {
      const match = keywordFilters.some(function (kw) {
        return name.indexOf(kw) !== -1;
      });
      if (!match) {
        return;
      }
      const cls = ObjC.classes[name];
      const ownMethods = cls.$ownMethods;
      const interesting = ownMethods.filter(function (sel) {
        return keywordFilters.some(function (kw) {
          return sel.indexOf(kw) !== -1;
        });
      });
      if (interesting.length > 0) {
        console.log('  [class] ' + name);
        interesting.forEach(function (sel) {
          console.log('    [sel] ' + sel);
        });
      }
    },
    onComplete() {
      console.log('[*] Enumeration complete.');
    }
  });
})();

// Priority hooks derived from static analysis
const priorityHooks = [
  { cls: 'WBInputViewController', sel: '- setInputMode:' },
  { cls: 'WBInputViewController', sel: '- handleInputModeListFromView:withEvent:' },
  { cls: 'WBInputViewController', sel: '- keyboardView:willSwitchPanelView:toPanelView:isPush:' },
  { cls: 'WBLanguageSwitchView', sel: '- setSelectedLanguage:' },
  { cls: 'WBLanguageSwitchView', sel: '- setLanguage:' },
  { cls: 'WBControlCenterView', sel: '- performSwitchWithOn:animated:shouldSendEvent:' }
];

priorityHooks.forEach(function (item) {
  hookInstanceMethod(item.cls, item.sel);
});
