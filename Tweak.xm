#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "Offsets.hpp"

// ================================================================
// 🔧 Feature state
// ================================================================
static BOOL aimLineEnabled        = NO;
static BOOL superLineEnabled      = NO;
static BOOL autoPlayEnabled       = NO;
static BOOL antiBanEnabled        = NO;
static BOOL infinitePowerEnabled  = NO;
static BOOL angleLockEnabled      = NO;
static BOOL noFrictionEnabled     = NO;
static BOOL wideGuideLineEnabled  = NO;
static BOOL predictionPathEnabled = NO;

static float lockedAngle          = 0.785f;
static float customPower          = 0.8f;

// ================================================================
// 🧭 Real offsets (fun.ction.txt) — ئێستا لە Offsets.hpp دێن
// ================================================================
// GameManager::visualCue            → ldrsw x8,[x8,#0x728]
// Table::frictionProperties         → ldrsw x8,[x8,#0x1e8]
// VisualCue::maxCuePowerOffset      → ldrsw x8,[x8,#0x48]
// UserSettingsManager::wideGuideline→ ldrb  w8,[x0,#0x13]  (1 BYTE!)
// BallPropertiesCue::getBalls       → ldr   x0,[x0,#0x8]

// ================================================================
// 🎯 Class names
// ================================================================
static const char *kClass_GameManager            = "GameManager";
static const char *kClass_GameplayTutorial       = "GameplayTutorial";
static const char *kClass_Table                  = "Table";
static const char *kClass_BallPropertiesCue      = "BallPropertiesCue";
static const char *kClass_VisualCue              = "VisualCue";
static const char *kClass_UserSettingsManager    = "UserSettingsManager";
static const char *kClass_AimEvent               = "AimEvent";
static const char *kClass_AFSDKChecksum          = "AFSDKChecksum";
static const char *kClass_PAGDeviceHelper        = "PAGDeviceHelper";
static const char *kClass_STKDevice              = "STKDevice";

// ================================================================
// 🪝 Original implementations
// ================================================================
static IMP orig_isAimCorrect            = NULL;
static IMP orig_visualCue               = NULL;
static IMP orig_hideGuidelinesMode      = NULL;
static IMP orig_getAimEvent             = NULL;
static IMP orig_updateInfoShotPower     = NULL;
static IMP orig_getBalls                = NULL;
static IMP orig_getBallByNumber         = NULL;
static IMP orig_frictionProperties      = NULL;
static IMP orig_setMaxCuePowerOffset    = NULL;
static IMP orig_wideGuideline           = NULL;
static IMP orig_setWideGuideline        = NULL;
static IMP orig_bu_isJailBroken         = NULL;
static IMP orig_isJailbroken            = NULL;
static IMP orig_calculateV2SanityFlags  = NULL;
static IMP orig_calculateV2Value        = NULL;

// ================================================================
// 🧠 Memory helpers
// ================================================================
static void *ReadPointerAtOffset(void *object, uintptr_t offset) {
    if (!object) return NULL;
    return *(void **)((uintptr_t)object + offset);
}

static void WriteFloatAtOffset(void *object, uintptr_t offset, float value) {
    if (!object) return;
    *(float *)((uintptr_t)object + offset) = value;
}

static float ReadFloatAtOffset(void *object, uintptr_t offset) {
    if (!object) return 0.0f;
    return *(float *)((uintptr_t)object + offset);
}

// ⚠️ گرنگ: wideGuideline بە ldrb (1 byte) دەخوێنرێتەوە، نەک 4 bytes
static void WriteByteAtOffset(void *object, uintptr_t offset, uint8_t value) {
    if (!object) return;
    *(uint8_t *)((uintptr_t)object + offset) = value;
}

static uint8_t ReadByteAtOffset(void *object, uintptr_t offset) {
    if (!object) return 0;
    return *(uint8_t *)((uintptr_t)object + offset);
}

// ================================================================
// Hook helper
// ================================================================
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
        // هەوڵبدە class method
        method = class_getClassMethod(cls, sel);
    }
    if (!method) {
        NSLog(@"[EliteMod] ⚠️ Method not found: -[%s %s]", className, selName);
        return NO;
    }

    if (original) {
        *original = method_getImplementation(method);
    }
    method_setImplementation(method, replacement);
    NSLog(@"[EliteMod] ✅ Hooked -[%s %s]", className, selName);
    return YES;
}

// ================================================================
// 🪝 Hooked implementations
// ================================================================

// GameplayTutorial::isAimCorrect → orig returns NO (mov w0,#0)
static BOOL Hooked_isAimCorrect(id self, SEL _cmd) {
    if (aimLineEnabled || superLineEnabled) {
        return YES;
    }
    if (orig_isAimCorrect) {
        return ((BOOL (*)(id, SEL))orig_isAimCorrect)(self, _cmd);
    }
    return NO;
}

// GameManager::visualCue → object at offset 0x728
static id Hooked_visualCue(id self, SEL _cmd) {
    id result = nil;
    if (orig_visualCue) {
        result = ((id (*)(id, SEL))orig_visualCue)(self, _cmd);
    }

    // تەنها maxCuePowerOffset لەسەر VisualCue (offset 0x48) — ئەمە ڕاستە
    if (result && infinitePowerEnabled) {
        WriteFloatAtOffset((__bridge void *)result,
                           GameOffsets::VisualCue_MaxCuePowerOffset, customPower);
    }
    return result;
}

// GameManager::hideGuidelinesMode
static BOOL Hooked_hideGuidelinesMode(id self, SEL _cmd) {
    if (aimLineEnabled || superLineEnabled || predictionPathEnabled) {
        return NO;
    }
    if (orig_hideGuidelinesMode) {
        return ((BOOL (*)(id, SEL))orig_hideGuidelinesMode)(self, _cmd);
    }
    return NO;
}

// AimEvent::getAimEvent: (int)
static id Hooked_getAimEvent(id self, SEL _cmd, int eventIndex) {
    if (angleLockEnabled && self) {
        // تێبینی: offsetـی angle پێویستی بە پشتڕاستکردنەوە هەیە
        WriteFloatAtOffset((__bridge void *)self, 0x28, lockedAngle);
    }
    if (orig_getAimEvent) {
        return ((id (*)(id, SEL, int))orig_getAimEvent)(self, _cmd, eventIndex);
    }
    return nil;
}

// Table::updateInfoShotPower: (MCNumber)
static void Hooked_updateInfoShotPower(id self, SEL _cmd, id mcNumber) {
    if (infinitePowerEnabled && self) {
        void *frictionProps = ReadPointerAtOffset((__bridge void *)self,
                                                  GameOffsets::Table_FrictionProperties);
        if (frictionProps) {
            WriteFloatAtOffset(frictionProps, 0x0, customPower);
        }
    }
    if (orig_updateInfoShotPower) {
        ((void (*)(id, SEL, id))orig_updateInfoShotPower)(self, _cmd, mcNumber);
    }
}

// BallPropertiesCue::getBalls → ldr x0,[x0,#0x8]
static id Hooked_getBalls(id self, SEL _cmd) {
    if (orig_getBalls) {
        return ((id (*)(id, SEL))orig_getBalls)(self, _cmd);
    }
    if (self) {
        return (__bridge id)ReadPointerAtOffset((__bridge void *)self,
                                                GameOffsets::BallProperties_Balls);
    }
    return nil;
}

// Table::getBallByNumber: (unsigned int)
static id Hooked_getBallByNumber(id self, SEL _cmd, unsigned int number) {
    if (orig_getBallByNumber) {
        return ((id (*)(id, SEL, unsigned int))orig_getBallByNumber)(self, _cmd, number);
    }
    return nil;
}

// Table::frictionProperties → struct at offset 0x1e8
static void *Hooked_frictionProperties(id self, SEL _cmd) {
    void *result = NULL;
    if (orig_frictionProperties) {
        result = ((void *(*)(id, SEL))orig_frictionProperties)(self, _cmd);
    }
    if (noFrictionEnabled && result) {
        WriteFloatAtOffset(result, 0x0, 0.0f);
        WriteFloatAtOffset(result, 0x4, 0.0f);
        WriteFloatAtOffset(result, 0x8, 0.0f);
    }
    return result;
}

// VisualCue::setMaxCuePowerOffset: (MCNumber)
static void Hooked_setMaxCuePowerOffset(id self, SEL _cmd, id mcNumber) {
    if (infinitePowerEnabled && self) {
        WriteFloatAtOffset((__bridge void *)self,
                           GameOffsets::VisualCue_MaxCuePowerOffset, customPower);
    }
    if (orig_setMaxCuePowerOffset) {
        ((void (*)(id, SEL, id))orig_setMaxCuePowerOffset)(self, _cmd, mcNumber);
    }
}

// UserSettingsManager::wideGuideline → ldrb w0,[x0,#0x13]  (1 BYTE)
static BOOL Hooked_wideGuideline(id self, SEL _cmd) {
    if (wideGuideLineEnabled) {
        return YES;
    }
    if (orig_wideGuideline) {
        return ((BOOL (*)(id, SEL))orig_wideGuideline)(self, _cmd);
    }
    return NO;
}

// UserSettingsManager::setWideGuideline: (BOOL)
static void Hooked_setWideGuideline(id self, SEL _cmd, BOOL value) {
    if (wideGuideLineEnabled) {
        value = YES;
        // بە 1 byte بینووسە چونکە ldrbـە
        if (self) {
            WriteByteAtOffset((__bridge void *)self,
                              GameOffsets::UserSettings_WideGuideline, 1);
        }
    }
    if (orig_setWideGuideline) {
        ((void (*)(id, SEL, BOOL))orig_setWideGuideline)(self, _cmd, value);
    }
}

// ================================================================
// 🛡️ Anti-Ban / Anti-Cheat
// ================================================================

static BOOL Hooked_bu_isJailBroken(id self, SEL _cmd) {
    if (antiBanEnabled) return NO;
    if (orig_bu_isJailBroken) {
        return ((BOOL (*)(id, SEL))orig_bu_isJailBroken)(self, _cmd);
    }
    return NO;
}

static BOOL Hooked_isJailbroken(id self, SEL _cmd) {
    if (antiBanEnabled) return NO;
    if (orig_isJailbroken) {
        return ((BOOL (*)(id, SEL))orig_isJailbroken)(self, _cmd);
    }
    return NO;
}

// AFSDKChecksum::calculateV2SanityFlagsWithIsSimulator:isDevBuild:isJailbroken:isDebug:isTestFlight:
// 5 BOOL params: isSim, isDev, isJail, isDebug, isTestFlight
// ⚠️ return nil مەکرە! بانگکردنی orig بە isJailbroken=NO سەلامەتترە
static id Hooked_calculateV2SanityFlags(id self, SEL _cmd,
                                        BOOL isSim, BOOL isDev, BOOL isJail,
                                        BOOL isDebug, BOOL isTestFlight) {
    if (antiBanEnabled) {
        // هەموو flagـە مەترسیدارەکان بکوژێنەوە
        isSim      = NO;
        isDev      = NO;
        isJail     = NO;
        isDebug    = NO;
        isTestFlight = NO;
    }
    if (orig_calculateV2SanityFlags) {
        return ((id (*)(id, SEL, BOOL, BOOL, BOOL, BOOL, BOOL))orig_calculateV2SanityFlags)(
            self, _cmd, isSim, isDev, isJail, isDebug, isTestFlight);
    }
    return nil;
}

// AFSDKChecksum::calculateV2ValueWithTimestamp:uid:systemVersion:firstLaunch:...
// ⚠️ disassembly: 5 id + 5 BOOL (param_8 + 4 stack)
static id Hooked_calculateV2Value(id self, SEL _cmd,
                                  id timestamp, id uid, id sysVer,
                                  id firstLaunch, id extra,
                                  BOOL f1, BOOL f2, BOOL f3, BOOL f4, BOOL f5) {
    if (antiBanEnabled) {
        // flagـەکان پاکبکەوە
        f1 = NO; f2 = NO; f3 = NO; f4 = NO; f5 = NO;
    }
    if (orig_calculateV2Value) {
        return ((id (*)(id, SEL, id, id, id, id, id, BOOL, BOOL, BOOL, BOOL, BOOL))
                orig_calculateV2Value)(self, _cmd, timestamp, uid, sysVer,
                                       firstLaunch, extra, f1, f2, f3, f4, f5);
    }
    return nil;
}

// ================================================================
// 🖥️ Menu UI — UIView overlay (نەک UIWindow وەک subview)
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface EliteOverlayView : UIView
@end

@implementation EliteOverlayView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    // ئەگەر تەنها overlayـەکە خۆی بوو، ڕایمەگە بۆ یارییەکە
    return (v == self) ? nil : v;
}
@end

@interface SimpleMenu : NSObject
+ (void)showMenu;
+ (void)hideMenu;
+ (void)showFromFloating;
+ (void)toggleAim:(UIButton *)sender;
+ (void)toggleSuper:(UIButton *)sender;
+ (void)toggleAuto:(UIButton *)sender;
+ (void)toggleBan:(UIButton *)sender;
+ (void)togglePower:(UIButton *)sender;
+ (void)toggleAngle:(UIButton *)sender;
+ (void)toggleFriction:(UIButton *)sender;
+ (void)toggleWideGuide:(UIButton *)sender;
+ (void)togglePrediction:(UIButton *)sender;
@end

@implementation SimpleMenu

static EliteOverlayView *overlay     = nil;
static UIView           *mainView    = nil;
static UIScrollView     *scrollView  = nil;
static UIButton         *floatingBtn = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (overlay) return;

            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            if (!window) {
                window = [[UIApplication sharedApplication].windows firstObject];
            }
            if (!window) return;

            overlay = [[EliteOverlayView alloc] initWithFrame:window.bounds];
            overlay.backgroundColor = [UIColor clearColor];
            overlay.userInteractionEnabled = YES;
            [window addSubview:overlay];

            mainView = [[UIView alloc] initWithFrame:CGRectMake(40, 80, 280, 500)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92f];
            mainView.layer.cornerRadius = 20.0f;
            mainView.layer.borderWidth = 2.0f;
            mainView.layer.borderColor = [UIColor purpleColor].CGColor;
            mainView.clipsToBounds = YES;
            [overlay addSubview:mainView];

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
            [overlay addSubview:floatingBtn];
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

@end

#pragma clang diagnostic pop

// ================================================================
// 🚀 Initialization
// ================================================================
__attribute__((constructor)) static void initMod(void) {
    @autoreleasepool {
        // offsets دابنێ (لە Offsets.hpp)
        GameOffsets::SetOffsets(
            0x728,  // GameManager visualCue
            0x1E8,  // Table frictionProperties
            0x48,   // VisualCue maxCuePowerOffset
            0x13,   // UserSettings wideGuideline (1 byte)
            0x8     // BallProperties balls
        );

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{
                @try {
                    NSLog(@"[EliteMod] 🚀 Starting hook installation...");

                    // ── Gameplay hooks ──
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

                    // ── Anti-cheat / integrity bypass ──
                    HookClassSelector(kClass_PAGDeviceHelper, "bu_isJailBroken",
                                      (IMP)Hooked_bu_isJailBroken, &orig_bu_isJailBroken);

                    HookClassSelector(kClass_STKDevice, "isJailbroken",
                                      (IMP)Hooked_isJailbroken, &orig_isJailbroken);

                    HookClassSelector(kClass_AFSDKChecksum,
                        "calculateV2SanityFlagsWithIsSimulator:isDevBuild:isJailbroken:isDebug:isTestFlight:",
                        (IMP)Hooked_calculateV2SanityFlags, &orig_calculateV2SanityFlags);

                    // ⚠️ تێبینی: ناوی selectorـی خوارەوە ڕەنگە پێویستی بە ڕێکخستن بێت
                    // ئەگەر hook سەرکەوتوو نەبوو، هیچ crashـێک ڕوونادات (skip دەکرێت)
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
