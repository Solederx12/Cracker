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
// 🧭 Extracted method names and offsets from the provided dump
// ================================================================
static const char *kTargetMethodNames[] = {
    "isAimCorrect",
    "antiBan",
    "autoPlay",
    "aimEvent",
    "getBallSpeed",
    "getShotPower",
    "getFriction",
    "setTableColor:"
};

static const uintptr_t kVisualCueOffset = 0x4d0;
static const uintptr_t kVisualGuideOffset = 0x3b8;
static const uintptr_t kAimAngleOffset = 0x28;
static const uintptr_t kAimLineLengthOffset = 0x0;
static const uintptr_t kCuePowerOffset = 0x0;
static const uintptr_t kWideGuideLineOffset = 0x0;
static const uintptr_t kLineThicknessOffset = 0x0;
static const uintptr_t kPredictionPathOffset = 0x0;

static const uintptr_t kDisasmVisualCueOffset = 0x728;

// ================================================================
// 🪝 Original implementations
// ================================================================
static IMP orig_isAimCorrect = NULL;
static IMP orig_antiBan = NULL;
static IMP orig_autoPlay = NULL;
static IMP orig_aimEvent = NULL;
static IMP orig_getBallSpeed = NULL;
static IMP orig_getShotPower = NULL;
static IMP orig_getFriction = NULL;
static IMP orig_setTableColor = NULL;

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

static void HookSelectorByName(const char *selectorName, IMP replacement, IMP *original) {
    SEL selector = sel_registerName(selectorName);
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) {
        NSLog(@"[EliteMod] No classes available to inspect");
        return;
    }

    Class *classes = (Class *)calloc((size_t)count, sizeof(Class));
    if (!classes) {
        NSLog(@"[EliteMod] Failed to allocate class list");
        return;
    }

    objc_getClassList(classes, count);

    for (int i = 0; i < count; ++i) {
        Class cls = classes[i];
        if (!cls) continue;

        Method method = class_getInstanceMethod(cls, selector);
        if (!method) continue;

        *original = method_getImplementation(method);
        method_setImplementation(method, replacement);
        NSLog(@"[EliteMod] Hooked %@ on %@", @(selectorName), NSStringFromClass(cls));
        free(classes);
        return;
    }

    NSLog(@"[EliteMod] Could not find selector %@", @(selectorName));
    free(classes);
}

// ================================================================
// 🪝 Hooked implementations
// ================================================================
static BOOL Hooked_isAimCorrect(id self, SEL _cmd) {
    if (self) {
        void *visualCue = ReadPointerAtOffset(self, kVisualCueOffset);
        if (!visualCue) {
            visualCue = ReadPointerAtOffset(self, kDisasmVisualCueOffset);
        }

        void *visualGuide = NULL;
        if (visualCue) {
            visualGuide = ReadPointerAtOffset(visualCue, kVisualGuideOffset);
        }

        if (visualGuide) {
            if (wideGuideLineEnabled) {
                WriteBoolAtOffset(visualGuide, kWideGuideLineOffset, YES);
                WriteFloatAtOffset(visualGuide, kLineThicknessOffset, customLineThickness + 2.0f);
            } else {
                WriteBoolAtOffset(visualGuide, kWideGuideLineOffset, NO);
                WriteFloatAtOffset(visualGuide, kLineThicknessOffset, customLineThickness);
            }

            if (aimLineEnabled || superLineEnabled) {
                float *lineLength = (float *)((uintptr_t)visualGuide + kAimLineLengthOffset);
                float *cuePower = (float *)((uintptr_t)self + kCuePowerOffset);
                if (lineLength && cuePower) {
                    float power = *cuePower;
                    if (aimLineEnabled) {
                        *lineLength = 150.0f + (power * 600.0f);
                    } else if (superLineEnabled) {
                        *lineLength = 800.0f + (power * 500.0f);
                    }
                }
            }
        }
    }

    if (orig_isAimCorrect) {
        return ((BOOL (*)(id, SEL))orig_isAimCorrect)(self, _cmd);
    }
    return YES;
}

static BOOL Hooked_antiBan(id self, SEL _cmd) {
    if (antiBanEnabled) {
        return YES;
    }

    if (orig_antiBan) {
        return ((BOOL (*)(id, SEL))orig_antiBan)(self, _cmd);
    }
    return YES;
}

static BOOL Hooked_autoPlay(id self, SEL _cmd) {
    if (autoPlayEnabled) {
        return YES;
    }

    if (orig_autoPlay) {
        return ((BOOL (*)(id, SEL))orig_autoPlay)(self, _cmd);
    }
    return NO;
}

static id Hooked_aimEvent(id self, SEL _cmd) {
    if (self) {
        void *visualCue = ReadPointerAtOffset(self, kVisualCueOffset);
        if (!visualCue) {
            visualCue = ReadPointerAtOffset(self, kDisasmVisualCueOffset);
        }

        void *visualGuide = NULL;
        if (visualCue) {
            visualGuide = ReadPointerAtOffset(visualCue, kVisualGuideOffset);
        }

        if (visualGuide) {
            if (angleLockEnabled) {
                WriteFloatAtOffset(visualGuide, kAimAngleOffset, lockedAngle);
            }

            if (predictionPathEnabled) {
                WriteBoolAtOffset(visualGuide, kPredictionPathOffset, YES);
            }
        }

        if (infinitePowerEnabled) {
            WriteFloatAtOffset(self, kCuePowerOffset, customPower);
        }
    }

    if (angleLockEnabled) {
        if ([self respondsToSelector:NSSelectorFromString(@"setLockedAngle:")]) {
            [self performSelector:NSSelectorFromString(@"setLockedAngle:") withObject:@(lockedAngle)];
        }
    }

    if (infinitePowerEnabled) {
        if ([self respondsToSelector:NSSelectorFromString(@"setCuePower:")]) {
            [self performSelector:NSSelectorFromString(@"setCuePower:") withObject:@(customPower)];
        }
    }

    if (predictionPathEnabled) {
        if ([self respondsToSelector:NSSelectorFromString(@"setPredictionPath:")]) {
            [self performSelector:NSSelectorFromString(@"setPredictionPath:") withObject:@(YES)];
        }
    }

    if (orig_aimEvent) {
        return ((id (*)(id, SEL))orig_aimEvent)(self, _cmd);
    }
    return nil;
}

static float Hooked_getBallSpeed(id self, SEL _cmd) {
    if (orig_getBallSpeed) {
        return ((float (*)(id, SEL))orig_getBallSpeed)(self, _cmd);
    }
    return 0.0f;
}

static float Hooked_getShotPower(id self, SEL _cmd) {
    if (infinitePowerEnabled) {
        return customPower;
    }

    if (orig_getShotPower) {
        return ((float (*)(id, SEL))orig_getShotPower)(self, _cmd);
    }
    return 0.0f;
}

static BOOL Hooked_getFriction(id self, SEL _cmd) {
    if (noFrictionEnabled) {
        return NO;
    }

    if (orig_getFriction) {
        return ((BOOL (*)(id, SEL))orig_getFriction)(self, _cmd);
    }
    return YES;
}

static void Hooked_setTableColor(id self, SEL _cmd, float hue) {
    if (orig_setTableColor) {
        ((void (*)(id, SEL, float))orig_setTableColor)(self, _cmd, hue);
    }
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

            UIWindow *window = [[UIApplication sharedApplication] keyWindow] ?: [[UIApplication sharedApplication].windows firstObject];
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
            for (NSInteger i = 0; i < titles.count; ++i) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                btn.frame = CGRectMake(15, i * 45, 250, 38);
                btn.backgroundColor = [UIColor grayColor];
                btn.layer.cornerRadius = 8.0f;
                btn.tag = 100 + i;
                [btn setTitle:[NSString stringWithFormat:@"🔴 %@: OFF", titles[i]] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13.0f];
                [btn addTarget:self action:NSSelectorFromString(selectors[i]) forControlEvents:UIControlEventTouchUpInside];
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
            [close addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:close];

            floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            floatingBtn.frame = CGRectMake(20, 150, 55, 55);
            floatingBtn.backgroundColor = [UIColor purpleColor];
            floatingBtn.layer.cornerRadius = 27.5f;
            [floatingBtn setTitle:@"🎱" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatingBtn addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
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
    [btn setTitle:[NSString stringWithFormat:@"%@ %@: %@", on ? @"🟢" : @"🔴", title, on ? @"ON" : @"OFF"] forState:UIControlStateNormal];
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
// 🚀 Initialization
// ================================================================
__attribute__((constructor)) static void initMod(void) {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                          queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                @try {
                    HookSelectorByName(kTargetMethodNames[0], (IMP)Hooked_isAimCorrect, &orig_isAimCorrect);
                    HookSelectorByName(kTargetMethodNames[1], (IMP)Hooked_antiBan, &orig_antiBan);
                    HookSelectorByName(kTargetMethodNames[2], (IMP)Hooked_autoPlay, &orig_autoPlay);
                    HookSelectorByName(kTargetMethodNames[3], (IMP)Hooked_aimEvent, &orig_aimEvent);
                    HookSelectorByName(kTargetMethodNames[4], (IMP)Hooked_getBallSpeed, &orig_getBallSpeed);
                    HookSelectorByName(kTargetMethodNames[5], (IMP)Hooked_getShotPower, &orig_getShotPower);
                    HookSelectorByName(kTargetMethodNames[6], (IMP)Hooked_getFriction, &orig_getFriction);
                    HookSelectorByName(kTargetMethodNames[7], (IMP)Hooked_setTableColor, &orig_setTableColor);

                    [SimpleMenu showMenu];
                    NSLog(@"[EliteMod] ✅ Runtime hooks initialized");
                } @catch (NSException *e) {
                    NSLog(@"[EliteMod] Init error: %@", e);
                }
            });
        }];
    }
}
