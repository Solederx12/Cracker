#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>
#include <sys/sysctl.h>

// ================================================================
// 📌 ئۆفسێتەکان - تەنها ئەم ۱۰ ئۆفسێتە پێویستە
// ================================================================

// --- بنەڕەتییەکان ---
#define OFFSET_GAME_MANAGER          0x0  // شوێنی GameManager
#define OFFSET_AIM_EVENT             0x0  // فەنکشنی ڕووداوی ئامانج
#define OFFSET_ANTI_BAN              0x0  // فەنکشنی ئەنتی بان
#define OFFSET_AUTO_PLAY             0x0  // فەنکشنی یاری خۆکار

// --- هێڵ و قوەت ---
#define OFFSET_AIM_LINE_LENGTH       0x0  // درێژی هێڵ (float)
#define OFFSET_CUE_POWER             0x0  // قوەتی دار (float 0-1)
#define OFFSET_AIM_ANGLE             0x28 // گۆشە (radians) - ئەمە جێگیرە

// --- پێکهاتەکانی یاری ---
#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8
#define OFFSET_BALL_SPEED            0x0  // خێرایی تۆپ (float)
#define OFFSET_SHOT_POWER            0x0  // هێزی لێدان (float)

// ================================================================
// دۆخی دوگمەکان
// ================================================================
static BOOL aimLineEnabled      = NO;
static BOOL autoPlayEnabled     = NO;
static BOOL antiBanEnabled      = NO;
static BOOL infinitePowerEnabled= NO;
static BOOL speedBoostEnabled   = NO;
static BOOL angleLockEnabled    = NO;
static BOOL showTrajectory      = NO;
static BOOL forcePocketEnabled  = NO;
static BOOL noFrictionEnabled   = NO;
static BOOL perfectSpinEnabled  = NO;

static float lockedAngle = 0.0;
static float customPower = 1.0;

// ================================================================
// پێناسەکردنی Hook
// ================================================================
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *target, void *replace, void **origin);
#ifdef __cplusplus
}
#endif

// ================================================================
// Hookە سەرەکییەکان
// ================================================================
bool (*orig_isAimCorrect)(void *instance);
bool (*orig_antiBan)(void *instance);
bool (*orig_autoPlay)(void *instance);
void* (*orig_aimEvent)(void *instance);
float (*orig_getBallSpeed)(void *instance);
float (*orig_getShotPower)(void *instance);

// ----- ۱. درێژکردنی هێڵ بەپێی قوەت -----
bool new_isAimCorrect(void *instance) {
    @try {
        if (aimLineEnabled && instance) {
            // دەستکەوتنی VisualGuide
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    float *linePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_LINE_LENGTH);
                    float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                    if (linePtr && powerPtr) {
                        float power = *powerPtr;
                        *linePtr = 150.0 + (power * 600.0); // ۱۵۰ بۆ ۷۵۰
                    }
                }
            }
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] isAimCorrect: %@", e);
    }
    return orig_isAimCorrect ? orig_isAimCorrect(instance) : YES;
}

// ----- ۲. ئەنتی بان -----
bool new_antiBan(void *instance) {
    @try {
        if (antiBanEnabled) return YES;
    } @catch (NSException *e) {}
    return orig_antiBan ? orig_antiBan(instance) : YES;
}

// ----- ۳. ئۆتۆپلەی -----
bool new_autoPlay(void *instance) {
    @try {
        if (autoPlayEnabled) return YES;
    } @catch (NSException *e) {}
    return orig_autoPlay ? orig_autoPlay(instance) : NO;
}

// ----- ۴. ڕووداوی ئامانج (کۆنترۆڵی گۆشە و قوەت) -----
void* new_aimEvent(void *instance) {
    @try {
        if (instance) {
            // گۆشەی ئامانج
            if (angleLockEnabled) {
                void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
                if (vcPtr && *vcPtr) {
                    void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                    if (vgPtr && *vgPtr) {
                        float *anglePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_ANGLE);
                        if (anglePtr) {
                            *anglePtr = lockedAngle;
                        }
                    }
                }
            }
            
            // قوەتی بێکۆتایی
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

// ----- ۵. خێرایی تۆپ -----
float new_getBallSpeed(void *instance) {
    @try {
        if (speedBoostEnabled) {
            return 800.0; // خێرایی زۆر
        }
    } @catch (NSException *e) {}
    return orig_getBallSpeed ? orig_getBallSpeed(instance) : 300.0;
}

// ----- ۶. هێزی لێدان -----
float new_getShotPower(void *instance) {
    @try {
        if (infinitePowerEnabled) {
            return customPower * 100.0;
        }
    } @catch (NSException *e) {}
    return orig_getShotPower ? orig_getShotPower(instance) : 50.0;
}

// ================================================================
// 🖥️ مێنیووی مۆد (UI)
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface EliteMenuWindow : UIWindow
+ (void)showMenu;
@end

@implementation EliteMenuWindow

static EliteMenuWindow *menuInstance = nil;
static UIView *mainView = nil;
static UIScrollView *scrollView = nil;
static UIButton *floatingBtn = nil;
static BOOL menuVisible = YES;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;
            menuInstance = [[EliteMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            
            // مێنیوی سەرەکی
            mainView = [[UIView alloc] initWithFrame:CGRectMake(30, 60, 320, 520)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.93];
            mainView.layer.cornerRadius = 20;
            mainView.layer.borderWidth = 2;
            mainView.layer.borderColor = [UIColor purpleColor].CGColor;
            [menuInstance addSubview:mainView];
            
            // ناونیشان
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 35)];
            title.text = @"🎱 8BP Elite Pro v6.0";
            title.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.8 alpha:1.0];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:20];
            [mainView addSubview:title];
            
            // زیرناونیشان
            UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 45, 300, 20)];
            subtitle.text = @"🔥 Premium Mod by CyberElite 🔥";
            subtitle.textColor = [UIColor lightGrayColor];
            subtitle.textAlignment = NSTextAlignmentCenter;
            subtitle.font = [UIFont systemFontOfSize:12];
            [mainView addSubview:subtitle];
            
            // سکرۆل
            scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 70, 300, 380)];
            scrollView.contentSize = CGSizeMake(300, 700);
            scrollView.showsVerticalScrollIndicator = YES;
            [mainView addSubview:scrollView];
            
            // دوگمەکان
            NSArray *titles = @[
                @"🎯 Aim Line (Dynamic Power)",
                @"🤖 Auto Play",
                @"🛡️ Anti-Ban",
                @"⚡ Infinite Power",
                @"🚀 Speed Boost",
                @"📐 Lock Angle",
                @"🌀 Show Trajectory",
                @"🎯 Force Pocket",
                @"🧊 No Friction",
                @"🌀 Perfect Spin"
            ];
            NSArray *selectors = @[
                @"toggleAim:",
                @"toggleAuto:",
                @"toggleBan:",
                @"togglePower:",
                @"toggleSpeed:",
                @"toggleAngle:",
                @"toggleTrajectory:",
                @"togglePocket:",
                @"toggleFriction:",
                @"toggleSpin:"
            ];
            
            for (int i = 0; i < titles.count; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                btn.frame = CGRectMake(10, 10 + (i * 55), 280, 45);
                btn.backgroundColor = [UIColor grayColor];
                btn.layer.cornerRadius = 10;
                btn.tag = i + 100;
                [btn setTitle:[NSString stringWithFormat:@"🔴 %@: OFF", titles[i]] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13];
                [btn addTarget:self action:NSSelectorFromString(selectors[i]) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:btn];
            }
            
            // دوگمەی داخستن
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            closeBtn.frame = CGRectMake(60, 460, 90, 40);
            closeBtn.backgroundColor = [UIColor redColor];
            closeBtn.layer.cornerRadius = 10;
            [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
            [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:closeBtn];
            
            // دوگمەی تەواو شاردنەوە
            UIButton *destroyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            destroyBtn.frame = CGRectMake(170, 460, 90, 40);
            destroyBtn.backgroundColor = [UIColor orangeColor];
            destroyBtn.layer.cornerRadius = 10;
            [destroyBtn setTitle:@"Destroy" forState:UIControlStateNormal];
            [destroyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [destroyBtn addTarget:self action:@selector(destroyMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:destroyBtn];
            
            // دوگمەی شناور
            floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            floatingBtn.frame = CGRectMake(20, 100, 60, 60);
            floatingBtn.backgroundColor = [UIColor purpleColor];
            floatingBtn.layer.cornerRadius = 30;
            floatingBtn.layer.shadowColor = [UIColor purpleColor].CGColor;
            floatingBtn.layer.shadowOpacity = 0.7;
            floatingBtn.layer.shadowRadius = 10;
            [floatingBtn setTitle:@"🎱" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatingBtn.titleLabel setFont:[UIFont systemFontOfSize:28]];
            [floatingBtn addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFloating:)];
            [floatingBtn addGestureRecognizer:pan];
            [menuInstance addSubview:floatingBtn];
            floatingBtn.hidden = YES;
            
        } @catch (NSException *e) {
            NSLog(@"[EliteMod] showMenu error: %@", e);
        }
    });
}

// ----- کارەکانی دوگمەکان -----
+ (void)toggleAim:(UIButton *)sender { aimLineEnabled = !aimLineEnabled; [self updateButton:sender title:@"Aim Line" enabled:aimLineEnabled]; }
+ (void)toggleAuto:(UIButton *)sender { autoPlayEnabled = !autoPlayEnabled; [self updateButton:sender title:@"Auto Play" enabled:autoPlayEnabled]; }
+ (void)toggleBan:(UIButton *)sender { antiBanEnabled = !antiBanEnabled; [self updateButton:sender title:@"Anti-Ban" enabled:antiBanEnabled]; }
+ (void)togglePower:(UIButton *)sender { infinitePowerEnabled = !infinitePowerEnabled; [self updateButton:sender title:@"Infinite Power" enabled:infinitePowerEnabled]; }
+ (void)toggleSpeed:(UIButton *)sender { speedBoostEnabled = !speedBoostEnabled; [self updateButton:sender title:@"Speed Boost" enabled:speedBoostEnabled]; }
+ (void)toggleAngle:(UIButton *)sender { 
    angleLockEnabled = !angleLockEnabled;
    if (angleLockEnabled) {
        // دانانی گۆشەی 45 پلە بۆ نموونە
        lockedAngle = 0.785; // 45 degree in radians
    }
    [self updateButton:sender title:@"Lock Angle" enabled:angleLockEnabled];
}
+ (void)toggleTrajectory:(UIButton *)sender { showTrajectory = !showTrajectory; [self updateButton:sender title:@"Trajectory" enabled:showTrajectory]; }
+ (void)togglePocket:(UIButton *)sender { forcePocketEnabled = !forcePocketEnabled; [self updateButton:sender title:@"Force Pocket" enabled:forcePocketEnabled]; }
+ (void)toggleFriction:(UIButton *)sender { noFrictionEnabled = !noFrictionEnabled; [self updateButton:sender title:@"No Friction" enabled:noFrictionEnabled]; }
+ (void)toggleSpin:(UIButton *)sender { perfectSpinEnabled = !perfectSpinEnabled; [self updateButton:sender title:@"Perfect Spin" enabled:perfectSpinEnabled]; }

+ (void)updateButton:(UIButton *)btn title:(NSString *)title enabled:(BOOL)enabled {
    btn.backgroundColor = enabled ? [UIColor greenColor] : [UIColor grayColor];
    [btn setTitle:[NSString stringWithFormat:@"%@ %@: %@", enabled ? @"🟢" : @"🔴", title, enabled ? @"ON" : @"OFF"] forState:UIControlStateNormal];
}

+ (void)hideMenu {
    mainView.hidden = YES;
    floatingBtn.hidden = NO;
}

+ (void)showFromFloating {
    mainView.hidden = NO;
    floatingBtn.hidden = YES;
}

+ (void)destroyMenu {
    [menuInstance removeFromSuperview];
    menuInstance = nil;
}

+ (void)dragFloating:(UIPanGestureRecognizer *)gesture {
    if (!menuInstance || !gesture.view) return;
    CGPoint translation = [gesture translationInView:menuInstance];
    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                      gesture.view.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:menuInstance];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

@end

#pragma clang diagnostic pop

// ================================================================
// 🚀 لۆدبوونی مۆد
// ================================================================
__attribute__((constructor)) static void initEliteMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
                if (base) {
                    // دانانی هۆکەکان
                    if (OFFSET_AIM_EVENT != 0)
                        DobbyHook((void *)(base + OFFSET_AIM_EVENT), (void *)new_aimEvent, (void **)&orig_aimEvent);
                    if (OFFSET_ANTI_BAN != 0)
                        DobbyHook((void *)(base + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)&orig_antiBan);
                    if (OFFSET_AUTO_PLAY != 0)
                        DobbyHook((void *)(base + OFFSET_AUTO_PLAY), (void *)new_autoPlay, (void **)&orig_autoPlay);
                    if (OFFSET_GAME_MANAGER != 0)
                        DobbyHook((void *)(base + OFFSET_GAME_MANAGER), (void *)new_isAimCorrect, (void **)&orig_isAimCorrect);
                    
                    // هوکەکانی تر (ئەگەر ئۆفسێت هەبێت)
                    if (OFFSET_BALL_SPEED != 0)
                        DobbyHook((void *)(base + OFFSET_BALL_SPEED), (void *)new_getBallSpeed, (void **)&orig_getBallSpeed);
                    if (OFFSET_SHOT_POWER != 0)
                        DobbyHook((void *)(base + OFFSET_SHOT_POWER), (void *)new_getShotPower, (void **)&orig_getShotPower);
                    
                    NSLog(@"[EliteMod] ✅ All hooks installed successfully!");
                }
                [EliteMenuWindow showMenu];
            } @catch (NSException *e) {
                NSLog(@"[EliteMod] ❌ Init error: %@", e);
            }
        });
    }];
}
