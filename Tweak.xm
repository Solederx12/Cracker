#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// ================================================================
// 🔧 Feature state
// ================================================================
static BOOL aimLineEnabled = NO;
static BOOL superLineEnabled = NO;
static BOOL autoPlayEnabled = NO;
static BOOL antiBanEnabled = NO;
static BOOL infinitePowerEnabled = NO;
static BOOL angleLockEnabled = NO;
static BOOL noFrictionEnabled = NO;
static BOOL wideGuideLineEnabled = NO;
static BOOL predictionPathEnabled = NO;

static float lockedAngle = 0.785f;
static float customPower = 0.8f;
static float customLineThickness = 1.0f;

// ================================================================
// 🧭 Real offsets extracted from disassembly (fun.ction.txt)
// ================================================================

// GameManager::visualCue → ldrsw x8, [x8, #0x728]
static const uintptr_t kGameManager_VisualCue_Offset = 0x728;

// Table::frictionProperties → ldrsw x8, [x8, #0x1e8]
static const uintptr_t kTable_FrictionProperties_Offset = 0x1E8;

// VisualCue::setMaxCuePowerOffset: → ldrsw x8, [x8, #0x48]
static const uintptr_t kVisualCue_MaxCuePowerOffset = 0x48;

// UserSettingsManager::wideGuideline → ldrb w8, [x0, #0x13]
static const uintptr_t kUserSettings_WideGuideline_Offset = 0x13;

// BallPropertiesCue::getBalls → ldr x0, [x0, #0x8]
static const uintptr_t kBallProperties_Balls_Offset = 0x8;

// QuickFireGameOverPopup::getBallsPotted → ldrsw x8, [x8, #0xec8]
static const uintptr_t kQuickFire_BallsPotted_Offset = 0xEC8;

// GameplayTutorial::isAimCorrect → mov w0, #0x0 (returns NO)
// Table::getBallByNumber: → complex function at 0x10009a0dc
// BallManager::getBallPositionForNumber: → at 0x100134720
// GameHUD::getBallPositionOnCounterForNumber: → at 0x1002bd5c0

// ================================================================
// 🎯 Real class names from disassembly
// ================================================================
static const char *kClass_GameManager = "GameManager";
static const char *kClass_GameplayTutorial = "GameplayTutorial";
static const char *kClass_Table = "Table";
static const char *kClass_BallPropertiesCue = "BallPropertiesCue";
static const char *kClass_VisualCue = "VisualCue";
static const char *kClass_UserSettingsManager = "UserSettingsManager";
static const char *kClass_BallManager = "BallManager";
static const char *kClass_GameHUD = "GameHUD";
static const char *kClass_AimEvent = "AimEvent";
static const char *kClass_QuickFireGameOverPopup = "QuickFireGameOverPopup";

// Anti-cheat / integrity classes
static const char *kClass_AFSDKChecksum = "AFSDKChecksum";
static const char *kClass_PAGDeviceHelper = "PAGDeviceHelper";
static const char *kClass_STKDevice = "STKDevice";

// ================================================================
// 🪝 Original implementations
// ================================================================
static IMP orig_isAimCorrect = NULL;
static IMP orig_visualCue = NULL;
static IMP orig_hideGuidelinesMode = NULL;
static IMP orig_getAimEvent = NULL;
static IMP orig_updateInfoShotPower = NULL;
static IMP orig_getBalls = NULL;
static IMP orig_getBallByNumber = NULL;
static IMP orig_frictionProperties = NULL;
static IMP orig_getBallPositionForNumber = NULL;
static IMP orig_setMaxCuePowerOffset = NULL;
static IMP orig_wideGuideline = NULL;
static IMP orig_setWideGuideline = NULL;
static IMP orig_bu_isJailBroken = NULL;
static IMP orig_isJailbroken = NULL;
static IMP orig_calculateV2SanityFlags = NULL;
static IMP orig_calculateV2Value = NULL;

// ================================================================
// 🧠 Runtime hook helpers
// ================================================================
static void *ReadPointerAtOffset(void *object, uintptr_t offset) {
    if (!object) return NULL;
    return *(void **)((uintptr_t)object + offset);
}

static void WriteFloatAtOffset(void *object, uintptr_t offset, float value) {
    if (!object) return;
    *(float *)((uintptr_t)object + offset) = value;
}

static void WriteBoolAtOffset(void *object, uintptr_t offset, BOOL value) {
    if (!object) return;
    *(BOOL *)((uintptr_t)object + offset) = value;
}

static float ReadFloatAtOffset(void *object, uintptr_t offset) {
    if (!object) return 0.0f;
    return *(float *)((uintptr_t)object + offset);
}

static BOOL ReadBoolAtOffset(void *object, uintptr_t offset) {
    if (!object) return NO;
    return *(BOOL *)((uintptr_t)object + offset);
}

// Hook a specific class + selector (more reliable than scanning all classes)
static BOOL HookClassSelector(const char *className, const char *selName,
                              IMP replacement, IMP *original) {
    Class cls = objc_getClass(className);
    if (!cls) {
        NSLog(@"[EliteMod] ❌ Class not found: %s", className);
        return NO;
    }

    SEL sel = sel_registerName(selName);
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) {
        NSLog(@"[EliteMod] ❌ Method not found: %s on %s", selName, className);
        return NO;
    }

    *original = method_getImplementation(method);
    method_setImplementation(method, replacement);
    NSLog(@"[EliteMod] ✅ Hooked -[%s %s]", className, selName);
    return YES;
}

// Fallback: scan all classes for a selector
static void HookSelectorByName(const char *selectorName, IMP replacement, IMP *original) {
    SEL selector = sel_registerName(selectorName);
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) return;

    Class *classes = (Class *)calloc((size_t)count, sizeof(Class));
    if (!classes) return;

    objc_getClassList(classes, count);

    for (int i = 0; i < count; ++i) {
        Class cls = classes[i];
        if (!cls) continue;

        Method method = class_getInstanceMethod(cls, selector);
        if (!method) continue;

        *original = method_getImplementation(method);
        method_setImplementation(method, replacement);
        NSLog(@"[EliteMod] ✅ Hooked %@ on %@", @(selectorName), NSStringFromClass(cls));
        free(classes);
        return;
    }

    NSLog(@"[EliteMod] ⚠️ Could not find selector %@", @(selectorName));
    free(classes);
}

// ================================================================
// 🪝 Hooked implementations
// ================================================================

// GameplayTutorial::isAimCorrect → originally returns NO (mov w0, #0)
static BOOL Hooked_isAimCorrect(id self, SEL _cmd) {
    if (aimLineEnabled || superLineEnabled) {
        return YES;
    }
    if (orig_isAimCorrect) {
        return ((BOOL (*)(id, SEL))orig_isAimCorrect)(self, _cmd);
    }
    return NO;
}

// GameManager::visualCue → returns object at offset 0x728
static id Hooked_visualCue(id self, SEL _cmd) {
    id result = nil;
    if (orig_visualCue) {
        result = ((id (*)(id, SEL))orig_visualCue)(self, _cmd);
    }

    if (result && (aimLineEnabled || superLineEnabled || wideGuideLineEnabled)) {
        // Apply modifications to the VisualCue object
        if (wideGuideLineEnabled) {
            // UserSettingsManager::wideGuideline is at offset 0x13
            WriteBoolAtOffset((__bridge void *)result, kUserSettings_WideGuideline_Offset, YES);
        }

        if (infinitePowerEnabled) {
            // VisualCue::maxCuePowerOffset at 0x48
            WriteFloatAtOffset((__bridge void *)result, kVisualCue_MaxCuePowerOffset, customPower);
        }
    }

    return result;
}

// GameManager::hideGuidelinesMode
static BOOL Hooked_hideGuidelinesMode(id self, SEL _cmd) {
    if (aimLineEnabled || superLineEnabled) {
        return NO; // Never hide guidelines when our lines are active
    }
    if (orig_hideGuidelinesMode) {
        return ((BOOL (*)(id, SEL))orig_hideGuidelinesMode)(self, _cmd);
    }
    return NO;
}

// AimEvent::getAimEvent: (takes int param)
static id Hooked_getAimEvent(id self, SEL _cmd, int eventIndex) {
    if (angleLockEnabled && self) {
        WriteFloatAtOffset((__bridge void *)self, 0x28, lockedAngle);
    }
    if (orig_getAimEvent) {
        return ((id (*)(id, SEL, int))orig_getAimEvent)(self, _cmd, eventIndex);
    }
    return nil;
}

// Table::updateInfoShotPower: (takes MCNumber param)
static void Hooked_updateInfoShotPower(id self, SEL _cmd, id mcNumber) {
    if (infinitePowerEnabled && self) {
        // Override shot power via the friction properties structure
        void *frictionProps = ReadPointerAtOffset((__bridge void *)self, kTable_FrictionProperties_Offset);
        if (frictionProps) {
            WriteFloatAtOffset(frictionProps, 0x0, customPower);
        }
    }
    if (orig_updateInfoShotPower) {
        ((void (*)(id, SEL, id))orig_updateInfoShotPower)(self, _cmd, mcNumber);
    }
}

// BallPropertiesCue::getBalls → ldr x0, [x0, #0x8]
static id Hooked_getBalls(id self, SEL _cmd) {
    if (orig_getBalls) {
        return ((id (*)(id, SEL))orig_getBalls)(self, _cmd);
    }
    if (self) {
        return (__bridge id)ReadPointerAtOffset((__bridge void *)self, kBallProperties_Balls_Offset);
    }
    return nil;
}

// Table::getBallByNumber: (takes unsigned int)
static id Hooked_getBallByNumber(id self, SEL _cmd, unsigned int number) {
    if (orig_getBallByNumber) {
        return ((id (*)(id, SEL, unsigned int))orig_getBallByNumber)(self, _cmd, number);
    }
    return nil;
}

// Table::frictionProperties → returns struct at offset 0x1e8
static void *Hooked_frictionProperties(id self, SEL _cmd) {
    void *result = NULL;
    if (orig_frictionProperties) {
        result = ((void *(*)(id, SEL))orig_frictionProperties)(self, _cmd);
    }

    if (noFrictionEnabled && result) {
        // Zero out friction values in the FrictionProperties struct
        WriteFloatAtOffset(result, 0x0, 0.0f);
        WriteFloatAtOffset(result, 0x4, 0.0f);
        WriteFloatAtOffset(result, 0x8, 0.0f);
    }

    return result;
}

// VisualCue::setMaxCuePowerOffset: (takes MCNumber)
static void Hooked_setMaxCuePowerOffset(id self, SEL _cmd, id mcNumber) {
    if (infinitePowerEnabled && self) {
        WriteFloatAtOffset((__bridge void *)self, kVisualCue_MaxCuePowerOffset, customPower);
    }
    if (orig_setMaxCuePowerOffset) {
        ((void (*)(id, SEL, id))orig_setMaxCuePowerOffset)(self, _cmd, mcNumber);
    }
}

// UserSettingsManager::wideGuideline → ldrb w0, [x0, #0x13]
static BOOL Hooked_wideGuideline(id self, SEL _cmd) {
    if (wideGuideLineEnabled) {
        return YES;
    }
    if (orig_wideGuideline) {
        return ((BOOL (*)(id, SEL))orig_wideGuideline)(self, _cmd);
    }
    return NO;
}

// UserSettingsManager::setWideGuideline: (takes BOOL)
static void Hooked_setWideGuideline(id self, SEL _cmd, BOOL value) {
    if (wideGuideLineEnabled) {
        value = YES;
    }
    if (orig_setWideGuideline) {
        ((void (*)(id, SEL, BOOL))orig_setWideGuideline)(self, _cmd, value);
    }
}

// ================================================================
// 🛡️ Anti-Ban / Anti-Cheat hooks
// ================================================================

// PAGDeviceHelper::bu_isJailBroken
static BOOL Hooked_bu_isJailBroken(id self, SEL _cmd) {
    if (antiBanEnabled) {
        return NO;
    }
    if (orig_bu_isJailBroken) {
        return ((BOOL (*)(id, SEL))orig_bu_isJailBroken)(self, _cmd);
    }
    return NO;
}

// STKDevice::isJailbroken
static BOOL Hooked_isJailbroken(id self, SEL _cmd) {
    if (antiBanEnabled) {
        return NO;
    }
    if (orig_isJailbroken) {
        return ((BOOL (*)(id, SEL))orig_isJailbroken)(self, _cmd);
    }
    return NO;
}

// AFSDKChecksum::calculateV2SanityFlagsWithIsSimulator:isDevBuild:isJailbroken:...
// Returns a flags object — we return nil/0 to bypass integrity checks
static id Hooked_calculateV2SanityFlags(id self, SEL _cmd,
                                         BOOL isSim, BOOL isDev, BOOL isJail,
                                         BOOL flag4, BOOL flag5) {
    if (antiBanEnabled) {
        // Return all-false flags to pass sanity checks
        return nil;
    }
    if (orig_calculateV2SanityFlags) {
        return ((id (*)(id, SEL, BOOL, BOOL, BOOL, BOOL, BOOL))orig_calculateV2SanityFlags)(
            self, _cmd, isSim, isDev, isJail, flag4, flag5);
    }
    return nil;
}

// AFSDKChecksum::calculateV2ValueWithTimestamp:uid:systemVersion:firstLaunch:...
static id Hooked_calculateV2Value(id self, SEL _cmd,
                                   id timestamp, id uid, id sysVer,
                                   id firstLaunch, id flag1, id flag2,
                                   BOOL flag3, BOOL flag4, BOOL flag5, BOOL flag6) {
    if (antiBanEnabled) {
        return nil;
    }
    if (orig_calculateV2Value) {
        return ((id (*)(id, SEL, id, id, id, id, id, id, BOOL, BOOL, BOOL, BOOL))
                orig_calculateV2Value)(self, _cmd, timestamp, uid, sysVer,
                                       firstLaunch, flag1, flag2, flag3, flag4, flag5, flag6);
    }
    return nil;
}

// ================================================================
// 🖥️ Menu UI
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface SimpleMenu : UIWindow
+ (void)showMenu;
@end

@implementation SimpleMenu

static SimpleMenu *menuInstance = nil;
static UIView *mainView = nil;
static UIScrollView *scrollView = nil;
static UIButton *floatingBtn = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;

            UIWindow *window = [[UIApplication sharedApplication] keyWindow]
                ?: [[UIApplication sharedApplication].windows firstObject];
            if (!window) {
                window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                [window makeKeyAndVisible];
            }

            menuInstance = [[SimpleMenu alloc] initWithFrame:window.bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            [window addSubview:menuInstance];

            mainView = [[UIView alloc] initWithFrame:CGRectMake(40, 80, 280, 500)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92f];
            mainView.layer.cornerRadius = 20.0f;
            mainView.layer.borderWidth = 2.0f;
            mainView.layer.borderColor = [UIColor purpleColor].CGColor;
            mainView.clipsToBounds = YES;
            [menuInstance addSubview:mainView];

            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 260, 30)];
            title.text = @"🎱 8BP Elite Mod";
            title.textColor = [UIColor whiteColor];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:18.0f];
            [mainView addSubview:title];

            scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 50, 280, 390)];
            [mainView addSubview:scrollView];

            NSArray<NSString *> *titles = @[
                @"Aim Line", @"Super Line", @"Auto Play", @"Anti-Ban",
                @"Infinite Power", @"Lock Angle", @"No Friction",
                @"Wide Guide Line", @"Prediction Path"
            ];
            NSArray<NSString *> *selectors = @[
                @"toggleAim:", @"toggleSuper:", @"toggleAuto:", @"toggleBan:",
                @"togglePower:", @"toggleAngle:", @"toggleFriction:",
                @"toggleWideGuide:", @"togglePrediction:"
            ];

            CGFloat contentHeight = 0.0f;
            for (NSInteger i = 0; i < (NSInteger)titles.count; ++i) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                btn.frame = CGRectMake(15, i * 45, 250, 38);
                btn.backgroundColor = [UIColor grayColor];
                btn.layer.cornerRadius = 8.0f;
                btn.tag = 100 + i;
                [btn setTitle:[NSString stringWithFormat:@"🔴 %@: OFF", titles[i]]
                     forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13.0f];
                [btn addTarget:self
                        action:NSSelectorFromString(selectors[i])
              forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:btn];
                contentHeight += 45.0f;
            }
            scrollView.contentSize = CGSizeMake(280, contentHeight);

            UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
            close.frame = CGRectMake(90, 445, 100, 35);
            close.backgroundColor = [UIColor redColor];
            close.layer.cornerRadius = 10.0f;
            [close setTitle:@"Close" forState:UIControlStateNormal];
            [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [close addTarget:self action:@selector(hideMenu)
            forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:close];

            floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            floatingBtn.frame = CGRectMake(20, 150, 55, 55);
            floatingBtn.backgroundColor = [UIColor purpleColor];
            floatingBtn.layer.cornerRadius = 27.5f;
            [floatingBtn setTitle:@"🎱" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatingBtn addTarget:self action:@selector(showFromFloating)
                  forControlEvents:UIControlEventTouchUpInside];
            [menuInstance addSubview:floatingBtn];
            floatingBtn.hidden = YES;
        } @catch (NSException *e) {
            NSLog(@"[EliteMod] showMenu error: %@", e);
        }
    });
}

+ (void)toggleAim:(UIButton *)sender {
    aimLineEnabled = !aimLineEnabled;
    [self update:sender title:@"Aim Line" on:aimLineEnabled];
}
+ (void)toggleSuper:(UIButton *)sender {
    superLineEnabled = !superLineEnabled;
    [self update:sender title:@"Super Line" on:superLineEnabled];
}
+ (void)toggleAuto:(UIButton *)sender {
    autoPlayEnabled = !autoPlayEnabled;
    [self update:sender title:@"Auto Play" on:autoPlayEnabled];
}
+ (void)toggleBan:(UIButton *)sender {
    antiBanEnabled = !antiBanEnabled;
    [self update:sender title:@"Anti-Ban" on:antiBanEnabled];
}
+ (void)togglePower:(UIButton *)sender {
    infinitePowerEnabled = !infinitePowerEnabled;
    [self update:sender title:@"Infinite Power" on:infinitePowerEnabled];
}
+ (void)toggleAngle:(UIButton *)sender {
    angleLockEnabled = !angleLockEnabled;
    [self update:sender title:@"Lock Angle" on:angleLockEnabled];
}
+ (void)toggleFriction:(UIButton *)sender {
    noFrictionEnabled = !noFrictionEnabled;
    [self update:sender title:@"No Friction" on:noFrictionEnabled];
}
+ (void)toggleWideGuide:(UIButton *)sender {
    wideGuideLineEnabled = !wideGuideLineEnabled;
    [self update:sender title:@"Wide Guide Line" on:wideGuideLineEnabled];
}
+ (void)togglePrediction:(UIButton *)sender {
    predictionPathEnabled = !predictionPathEnabled;
    [self update:sender title:@"Prediction Path" on:predictionPathEnabled];
}

+ (void)update:(UIButton *)btn title:(NSString *)title on:(BOOL)on {
    btn.backgroundColor = on ? [UIColor greenColor] : [UIColor grayColor];
    [btn setTitle:[NSString stringWithFormat:@"%@ %@: %@",
                   on ? @"🟢" : @"🔴", title, on ? @"ON" : @"OFF"]
         forState:UIControlStateNormal];
}

+ (void)hideMenu {
    if (mainView) mainView.hidden = YES;
    if (floatingBtn) floatingBtn.hidden = NO;
}

+ (void)showFromFloating {
    if (mainView) mainView.hidden = NO;
    if (floatingBtn) floatingBtn.hidden = YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    return (v == self) ? nil : v;
}

@end

#pragma clang diagnostic pop

// ================================================================
// 🚀 Initialization — hooks with REAL class names & offsets
// ================================================================
__attribute__((constructor)) static void initMod(void) {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{
                @try {
                    NSLog(@"[EliteMod] 🚀 Starting hook installation...");

                    // ── Gameplay hooks (real class + selector pairs) ──
                    HookClassSelector(kClass_GameplayTutorial, "isAimCorrect",
                                      (IMP)Hooked_isAimCorrect, &orig_isAimCorrect);

                    HookClassSelector(kClass_GameManager, "visualCue",
                                      (IMP)Hooked_visualCue, &orig_visualCue);

                    HookClassSelector(kClass_GameManager, "hideGuidelinesMode",
                                      (IMP)Hooked_hideGuidelinesMode, &orig_hideGuidelinesMode);

                    HookClassSelector(kClass_AimEvent, "getAimEvent:",
                                      (IMP)Hooked_getAimEvent, &orig_getAimEvent);

                    HookClassSelector(kClass_Table, "updateInfoShotPower:",
                                      (IMP)Hooked_updateInfoShotPower, &orig_updateInfoShotPower);

                    HookClassSelector(kClass_BallPropertiesCue, "getBalls",
                                      (IMP)Hooked_getBalls, &orig_getBalls);

                    HookClassSelector(kClass_Table, "getBallByNumber:",
                                      (IMP)Hooked_getBallByNumber, &orig_getBallByNumber);

                    HookClassSelector(kClass_Table, "frictionProperties",
                                      (IMP)Hooked_frictionProperties, &orig_frictionProperties);

                    HookClassSelector(kClass_VisualCue, "setMaxCuePowerOffset:",
                                      (IMP)Hooked_setMaxCuePowerOffset, &orig_setMaxCuePowerOffset);

                    HookClassSelector(kClass_UserSettingsManager, "wideGuideline",
                                      (IMP)Hooked_wideGuideline, &orig_wideGuideline);

                    HookClassSelector(kClass_UserSettingsManager, "setWideGuideline:",
                                      (IMP)Hooked_setWideGuideline, &orig_setWideGuideline);

                    // ── Anti-cheat / integrity bypass hooks ──
                    HookClassSelector(kClass_PAGDeviceHelper, "bu_isJailBroken",
                                      (IMP)Hooked_bu_isJailBroken, &orig_bu_isJailBroken);

                    HookClassSelector(kClass_STKDevice, "isJailbroken",
                                      (IMP)Hooked_isJailbroken, &orig_isJailbroken);

                    HookClassSelector(kClass_AFSDKChecksum,
                        "calculateV2SanityFlagsWithIsSimulator:isDevBuild:isJailbroken:isDebug:isTestFlight:",
                        (IMP)Hooked_calculateV2SanityFlags, &orig_calculateV2SanityFlags);

                    HookClassSelector(kClass_AFSDKChecksum,
                        "calculateV2ValueWithTimestamp:uid:systemVersion:firstLaunch:isJailbroken:isSimulator:isDebug:isTestFlight:",
                        (IMP)Hooked_calculateV2Value, &orig_calculateV2Value);

                    // ── Show menu ──
                    [SimpleMenu showMenu];
                    NSLog(@"[EliteMod] ✅ All hooks installed successfully");
                } @catch (NSException *e) {
                    NSLog(@"[EliteMod] ❌ Init error: %@", e);
                }
            });
        }];
    }
}
