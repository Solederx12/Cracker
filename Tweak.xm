#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>
#import "dobby.h" // ✅ بەکارهێنانی Dobby بۆ بێ جەیڵبرێک

// ================================================================
// 📌 ئۆفسێتەکان
// ================================================================
#define OFFSET_GAME_MANAGER          0x0
#define OFFSET_AIM_EVENT             0x0
#define OFFSET_ANTI_BAN              0x0
#define OFFSET_AUTO_PLAY             0x0
#define OFFSET_AIM_LINE_LENGTH       0x0
#define OFFSET_CUE_POWER             0x0
#define OFFSET_BALL_SPEED            0x0
#define OFFSET_SHOT_POWER            0x0
#define OFFSET_TABLE_COLOR           0x0
#define OFFSET_BALL_POSITION         0x0
#define OFFSET_WIDE_GUIDE_LINE       0x0 
#define OFFSET_LINE_THICKNESS        0x0 
#define OFFSET_PREDICTION_PATH       0x0 

#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8
#define OFFSET_AIM_ANGLE             0x28

// ================================================================
// 🕹️ دۆخی دوگمەکان
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

// ================================================================
// 📊 پەرامیتەرەکان
// ================================================================
static float lockedAngle = 0.785;
static float customPower = 0.8;
static float customLineThickness = 1.0; 

// ================================================================
// 🛠️ Hookە سەرەکییەکان
// ================================================================
bool (*orig_isAimCorrect)(void *instance);
bool (*orig_antiBan)(void *instance);
bool (*orig_autoPlay)(void *instance);
void* (*orig_aimEvent)(void *instance);
float (*orig_getBallSpeed)(void *instance);
float (*orig_getShotPower)(void *instance);
bool (*orig_getFriction)(void *instance);
void (*orig_setTableColor)(void *instance, float hue);

// ----- ۱. هێڵی درێژ، هێڵی فراوان، و ئەستووری -----
bool new_isAimCorrect(void *instance) {
    @try {
        if (instance) {
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    float *linePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_LINE_LENGTH);
                    float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                    
                    if (wideGuideLineEnabled) {
                         bool *wideGuidePtr = (bool *)((uintptr_t)(*vgPtr) + OFFSET_WIDE_GUIDE_LINE);
                         if (wideGuidePtr) *wideGuidePtr = true;
                         
                         float *thicknessPtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_LINE_THICKNESS);
                         if(thicknessPtr) *thicknessPtr = customLineThickness + 2.0; 
                    } else {
                         bool *wideGuidePtr = (bool *)((uintptr_t)(*vgPtr) + OFFSET_WIDE_GUIDE_LINE);
                         if (wideGuidePtr) *wideGuidePtr = false;
                         
                         float *thicknessPtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_LINE_THICKNESS);
                         if(thicknessPtr) *thicknessPtr = customLineThickness; 
                    }

                    if (linePtr && powerPtr) {
                        float power = *powerPtr;
                        if (aimLineEnabled) {
                            *linePtr = 150.0 + (power * 600.0);
                        }
                        if (superLineEnabled) {
                            *linePtr = 800.0 + (power * 500.0);
                        }
                    }
                }
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] isAimCorrect: %@", e);
    }
    return orig_isAimCorrect ? orig_isAimCorrect(instance) : YES;
}

// ----- ۲. یاری خۆکار -----
bool new_autoPlay(void *instance) {
    @try {
        if (autoPlayEnabled) return YES;
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] autoPlay: %@", e);
    }
    return orig_autoPlay ? orig_autoPlay(instance) : NO;
}

// ----- ۳. دژە-بان -----
bool new_antiBan(void *instance) {
    @try {
        if (antiBanEnabled) return YES;
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] antiBan: %@", e);
    }
    return orig_antiBan ? orig_antiBan(instance) : YES;
}

// ----- ۴. ڕووداوی ئامانج -----
void* new_aimEvent(void *instance) {
    @try {
        if (instance) {
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    float *anglePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_ANGLE);
                    if (angleLockEnabled && anglePtr) {
                        *anglePtr = lockedAngle;
                    }
                    
                    if (predictionPathEnabled) {
                         bool *predictionPtr = (bool *)((uintptr_t)(*vgPtr) + OFFSET_PREDICTION_PATH);
                         if (predictionPtr) *predictionPtr = true;
                    }
                }
            }
            if (infinitePowerEnabled) {
                float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                if (powerPtr) {
                    *powerPtr = customPower;
                }
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] aimEvent: %@", e);
    }
    return orig_aimEvent ? orig_aimEvent(instance) : NULL;
}

// ----- ۵. بێ-لێژایی -----
bool new_getFriction(void *instance) {
    @try {
        if (noFrictionEnabled) return NO;
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] getFriction: %@", e);
    }
    return orig_getFriction ? orig_getFriction(instance) : YES;
}


// ================================================================
// 🖥️ مێنیووی سادە (UI)
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface SimpleMenu : UIWindow
+ (void)showMenu;
@end

@implementation SimpleMenu

static SimpleMenu *menuInstance = nil;
static UIScrollView *scrollView = nil;
static UIView *mainView = nil;
static UIButton *floatingBtn = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;
            menuInstance = [[SimpleMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            
            mainView = [[UIView alloc] initWithFrame:CGRectMake(40, 80, 280, 480)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
            mainView.layer.cornerRadius = 20;
            mainView.layer.borderWidth = 2;
            mainView.layer.borderColor = [UIColor purpleColor].CGColor;
            mainView.clipsToBounds = YES;
            [menuInstance addSubview:mainView];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 260, 30)];
            title.text = @"🎱 8BP Elite Mod";
            title.textColor = [UIColor whiteColor];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:18];
            [mainView addSubview:title];
            
            scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 50, 280, 370)];
            [mainView addSubview:scrollView];
            
            NSArray *titles = @[
                @"Aim Line", @"Super Line", @"Auto Play", @"Anti-Ban",
                @"Infinite Power", @"Lock Angle", @"No Friction",
                @"Wide Guide Line", @"Prediction Path" 
            ];
            NSArray *selectors = @[
                @"toggleAim:", @"toggleSuper:", @"toggleAuto:", @"toggleBan:",
                @"togglePower:", @"toggleAngle:", @"toggleFriction:",
                @"toggleWideGuide:", @"togglePrediction:" 
            ];
            
            CGFloat contentHeight = 0;
            for (int i = 0; i < titles.count; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                btn.frame = CGRectMake(15, (i * 45), 250, 38);
                btn.backgroundColor = [UIColor grayColor];
                btn.layer.cornerRadius = 8;
                btn.tag = i + 100;
                [btn setTitle:[NSString stringWithFormat:@"🔴 %@: OFF", titles[i]] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13];
                [btn addTarget:self action:NSSelectorFromString(selectors[i]) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:btn];
                contentHeight += 45;
            }
            scrollView.contentSize = CGSizeMake(280, contentHeight);
            
            UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
            close.frame = CGRectMake(90, 430, 100, 35);
            close.backgroundColor = [UIColor redColor];
            close.layer.cornerRadius = 10;
            [close setTitle:@"Close" forState:UIControlStateNormal];
            [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [close addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:close];
            
            floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            floatingBtn.frame = CGRectMake(20, 150, 55, 55);
            floatingBtn.backgroundColor = [UIColor purpleColor];
            floatingBtn.layer.cornerRadius = 27.5;
            [floatingBtn setTitle:@"🎱" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatingBtn addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
            [floatingBtn addGestureRecognizer:pan];
            [menuInstance addSubview:floatingBtn];
            floatingBtn.hidden = YES;
            
        } @catch (NSException *e) {
            NSLog(@"[EliteMod] showMenu error: %@", e);
        }
    });
}

// ----- کارەکانی دوگمەکان -----
+ (void)toggleAim:(UIButton *)sender { aimLineEnabled = !aimLineEnabled; [self update:sender title:@"Aim Line" on:aimLineEnabled]; }
+ (void)toggleSuper:(UIButton *)sender { superLineEnabled = !superLineEnabled; [self update:sender title:@"Super Line" on:superLineEnabled]; }
+ (void)toggleAuto:(UIButton *)sender { autoPlayEnabled = !autoPlayEnabled; [self update:sender title:@"Auto Play" on:autoPlayEnabled]; }
+ (void)toggleBan:(UIButton *)sender { antiBanEnabled = !antiBanEnabled; [self update:sender title:@"Anti-Ban" on:antiBanEnabled]; }
+ (void)togglePower:(UIButton *)sender { infinitePowerEnabled = !infinitePowerEnabled; [self update:sender title:@"Infinite Power" on:infinitePowerEnabled]; }
+ (void)toggleAngle:(UIButton *)sender { angleLockEnabled = !angleLockEnabled; [self update:sender title:@"Lock Angle" on:angleLockEnabled]; }
+ (void)toggleFriction:(UIButton *)sender { noFrictionEnabled = !noFrictionEnabled; [self update:sender title:@"No Friction" on:noFrictionEnabled]; }
+ (void)toggleWideGuide:(UIButton *)sender { wideGuideLineEnabled = !wideGuideLineEnabled; [self update:sender title:@"Wide Guide Line" on:wideGuideLineEnabled]; }
+ (void)togglePrediction:(UIButton *)sender { predictionPathEnabled = !predictionPathEnabled; [self update:sender title:@"Prediction Path" on:predictionPathEnabled]; }

+ (void)update:(UIButton *)btn title:(NSString *)title on:(BOOL)on {
    btn.backgroundColor = on ? [UIColor greenColor] : [UIColor grayColor];
    [btn setTitle:[NSString stringWithFormat:@"%@ %@: %@", on ? @"🟢" : @"🔴", title, on ? @"ON" : @"OFF"] forState:UIControlStateNormal];
}

+ (void)hideMenu {
    mainView.hidden = YES;
    floatingBtn.hidden = NO;
}

+ (void)showFromFloating {
    mainView.hidden = NO;
    floatingBtn.hidden = YES;
}

+ (void)drag:(UIPanGestureRecognizer *)g {
    if (!menuInstance || !g.view) return;
    CGPoint t = [g translationInView:menuInstance];
    g.view.center = CGPointMake(g.view.center.x + t.x, g.view.center.y + t.y);
    [g setTranslation:CGPointZero inView:menuInstance];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    return (v == self) ? nil : v;
}

@end

#pragma clang diagnostic pop

// ================================================================
// 🚀 لۆدبوونی مۆد (بە DobbyHook)
// ================================================================
__attribute__((constructor)) static void initMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
                if (base) {
                    // بەکارهێنانی DobbyHook لەبری spector_hook
                    if (OFFSET_AIM_EVENT != 0)
                        DobbyHook((void *)(base + OFFSET_AIM_EVENT), (void *)new_aimEvent, (void **)&orig_aimEvent);
                    if (OFFSET_ANTI_BAN != 0)
                        DobbyHook((void *)(base + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)&orig_antiBan);
                    if (OFFSET_AUTO_PLAY != 0)
                        DobbyHook((void *)(base + OFFSET_AUTO_PLAY), (void *)new_autoPlay, (void **)&orig_autoPlay);
                    if (OFFSET_GAME_MANAGER != 0)
                        DobbyHook((void *)(base + OFFSET_GAME_MANAGER), (void *)new_isAimCorrect, (void **)&orig_isAimCorrect);
                    
                    NSLog(@"[EliteMod] ✅ Hooks installed with Dobby!");
                }
                [SimpleMenu showMenu];
            } @catch (NSException *e) {
                NSLog(@"[EliteMod] ❌ Init error: %@", e);
            }
        });
    }];
}

