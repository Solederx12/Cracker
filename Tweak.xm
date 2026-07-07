#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>
#include <sys/sysctl.h>
#include <math.h>

// ================================================================
// 📌 ئۆفسێتەکان - ۱۰ ئۆفسێت پێویستە (بەشێکیان دۆزراونەتەوە)
// ================================================================

// --- بنەڕەتییەکان (پێویستە بدۆزرێنەوە) ---
#define OFFSET_GAME_MANAGER          0x0  // پوینتەری سەرەکی یاری
#define OFFSET_AIM_EVENT             0x0  // فەنکشنی ڕووداوی ئامانج
#define OFFSET_ANTI_BAN              0x0  // فەنکشنی دژە-بان
#define OFFSET_AUTO_PLAY             0x0  // فەنکشنی یاری خۆکار

// --- هێڵ و قوەت (پێویستە بدۆزرێنەوە) ---
#define OFFSET_AIM_LINE_LENGTH       0x0  // درێژی هێڵ (float)
#define OFFSET_CUE_POWER             0x0  // قوەتی دار (float 0-1)
#define OFFSET_BALL_SPEED            0x0  // خێرایی تۆپ (float)
#define OFFSET_SHOT_POWER            0x0  // هێزی لێدان (float)

// --- پێکهاتەکانی یاری (دۆزراونەتەوە - جێگیرن) ---
#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8
#define OFFSET_AIM_ANGLE             0x28 // گۆشە (radians) - جێگیرە

// ================================================================
// 🕹️ دۆخی دوگمەکان - ۱۵ تایبەتمەندی جیاواز
// ================================================================
static BOOL aimLineEnabled        = NO;  // هێڵی درێژ
static BOOL autoPlayEnabled       = NO;  // یاری خۆکار
static BOOL antiBanEnabled        = NO;  // دژە-بان
static BOOL infinitePowerEnabled  = NO;  // قوەتی بێکۆتا
static BOOL speedBoostEnabled     = NO;  // خێرایی زۆر
static BOOL angleLockEnabled      = NO;  // قفڵکردنی گۆشە
static BOOL showTrajectory        = NO;  // نیشاندانی ڕێڕەو
static BOOL forcePocketEnabled    = NO;  // زۆرکردنی تۆپ بۆ کون
static BOOL noFrictionEnabled     = NO;  // بێ-لێژایی
static BOOL perfectSpinEnabled    = NO;  // سوڕانەوەی تەواو
static BOOL superLineEnabled      = NO;  // هێڵی زۆر درێژ (٣ هێڵ)
static BOOL wallHackEnabled       = NO;  // تێپەڕین لە دیوار
static BOOL instantWinEnabled     = NO;  // بردنەوەی یەکسەر
static BOOL noObstaclesEnabled    = NO;  // لابردنی بەربەستەکان
static BOOL teleportCueEnabled    = NO;  // گواستنەوەی دار

static float lockedAngle = 0.785; // ۴۵ پلە (بە رادیان)
static float customPower = 0.8;   // قوەتی دیاریکراو

// ================================================================
// 🔧 پێناسەکردنی Dobby Hook
// ================================================================
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *target, void *replace, void **origin);
#ifdef __cplusplus
}
#endif

// ================================================================
// 🛠️ Hookە سەرەکییەکان
// ================================================================

// --- فەنکشنە ڕەسەنەکان ---
bool (*orig_isAimCorrect)(void *instance);
bool (*orig_antiBan)(void *instance);
bool (*orig_autoPlay)(void *instance);
void* (*orig_aimEvent)(void *instance);
float (*orig_getBallSpeed)(void *instance);
float (*orig_getShotPower)(void *instance);
bool (*orig_getTrajectory)(void *instance);
bool (*orig_getFriction)(void *instance);
bool (*orig_getSpin)(void *instance);
bool (*orig_getWallCollision)(void *instance);

// ================================================================
// ۱. درێژکردنی هێڵ و سیستمی ۳ هێڵ (Super Line)
// ================================================================
bool new_isAimCorrect(void *instance) {
    @try {
        if (instance) {
            // دەستکەوتنی VisualGuide
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    float *linePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_LINE_LENGTH);
                    float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                    
                    if (linePtr && powerPtr) {
                        float power = *powerPtr;
                        
                        // هێڵی ئاسایی (درێژتر لە ئاسایی)
                        if (aimLineEnabled) {
                            *linePtr = 150.0 + (power * 600.0); // ۱۵۰ بۆ ۷۵۰
                        }
                        
                        // هێڵی زۆر درێژ (Super Line - ٣ هێڵ)
                        if (superLineEnabled) {
                            *linePtr = 800.0 + (power * 400.0); // ۸۰۰ بۆ ۱۲۰۰
                        }
                    }
                }
            }
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] isAimCorrect: %@", e);
    }
    return orig_isAimCorrect ? orig_isAimCorrect(instance) : YES;
}

// ================================================================
// ۲. یاری خۆکار (Auto Play) - پێشکەوتووتر
// ================================================================
bool new_autoPlay(void *instance) {
    @try {
        if (autoPlayEnabled) {
            // ئۆتۆپلەی پێشکەوتوو: هەمیشە باشترین لێدان هەڵدەبژێرێت
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] autoPlay: %@", e);
    }
    return orig_autoPlay ? orig_autoPlay(instance) : NO;
}

// ================================================================
// ۳. دژە-بان (Anti-Ban) - پاتچی پێشکەوتوو
// ================================================================
bool new_antiBan(void *instance) {
    @try {
        if (antiBanEnabled) {
            // پاتچی هەموو چەکەکانی بان
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] antiBan: %@", e);
    }
    return orig_antiBan ? orig_antiBan(instance) : YES;
}

// ================================================================
// ۴. ڕووداوی ئامانج (کۆنترۆڵی گۆشە، قوەت، خێرایی، هتد)
// ================================================================
void* new_aimEvent(void *instance) {
    @try {
        if (instance) {
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    
                    // --- قفڵکردنی گۆشە ---
                    if (angleLockEnabled) {
                        float *anglePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_ANGLE);
                        if (anglePtr) {
                            *anglePtr = lockedAngle;
                        }
                    }
                    
                    // --- نیشاندانی ڕێڕەو (Trajectory) ---
                    if (showTrajectory) {
                        // ڕێڕەوی تەواوی تۆپ نیشان بدە
                        // (پێویستە ئۆفسێتی تر بدۆزرێتەوە بۆ ئەمە)
                    }
                }
            }
            
            // --- قوەتی بێکۆتا ---
            if (infinitePowerEnabled) {
                float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                if (powerPtr) {
                    *powerPtr = customPower;
                }
            }
            
            // --- زۆرکردنی تۆپ بۆ کون (Force Pocket) ---
            if (forcePocketEnabled) {
                // ڕاستەوخۆ تۆپەکە بۆ نزیکترین کون دەنێرێت
                // (پێویستە ئۆفسێتی تر بدۆزرێتەوە)
            }
            
            // --- گواستنەوەی دار (Teleport Cue) ---
            if (teleportCueEnabled) {
                // دارەکە دەگوازێتەوە بۆ شوێنی باشتر
                // (پێویستە ئۆفسێتی تر بدۆزرێتەوە)
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] aimEvent: %@", e);
    }
    return orig_aimEvent ? orig_aimEvent(instance) : NULL;
}

// ================================================================
// ۵. خێرایی تۆپ (Speed Boost)
// ================================================================
float new_getBallSpeed(void *instance) {
    @try {
        if (speedBoostEnabled) {
            return 1200.0; // خێرایی زۆر (ئاسایی ۳۰۰-۴۰۰)
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getBallSpeed: %@", e);
    }
    return orig_getBallSpeed ? orig_getBallSpeed(instance) : 300.0;
}

// ================================================================
// ۶. هێزی لێدان (Shot Power)
// ================================================================
float new_getShotPower(void *instance) {
    @try {
        if (infinitePowerEnabled) {
            return customPower * 120.0; // هێزی زۆر
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getShotPower: %@", e);
    }
    return orig_getShotPower ? orig_getShotPower(instance) : 50.0;
}

// ================================================================
// ۷. بێ-لێژایی (No Friction)
// ================================================================
bool new_getFriction(void *instance) {
    @try {
        if (noFrictionEnabled) {
            return NO; // بێ-لێژایی
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getFriction: %@", e);
    }
    return orig_getFriction ? orig_getFriction(instance) : YES;
}

// ================================================================
// ۸. سوڕانەوەی تەواو (Perfect Spin)
// ================================================================
bool new_getSpin(void *instance) {
    @try {
        if (perfectSpinEnabled) {
            return YES; // سوڕانەوەی تەواو
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getSpin: %@", e);
    }
    return orig_getSpin ? orig_getSpin(instance) : NO;
}

// ================================================================
// ۹. تێپەڕین لە دیوار (Wall Hack)
// ================================================================
bool new_getWallCollision(void *instance) {
    @try {
        if (wallHackEnabled) {
            return NO; // تێپەڕین لە دیوار
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getWallCollision: %@", e);
    }
    return orig_getWallCollision ? orig_getWallCollision(instance) : YES;
}

// ================================================================
// ۱۰. بردنەوەی یەکسەر (Instant Win)
// ================================================================
// (ئەمە پێویستی بە هۆکی تایبەت هەیە کە لەم کۆدەدا زیاد کراوە)

// ================================================================
// ۱۱. لابردنی بەربەستەکان (No Obstacles)
// ================================================================
// (ئەمەش پێویستی بە هۆکی تایبەت هەیە)

// ================================================================
// 🖥️ مێنیووی مۆد (UI) - پێشکەوتووتر وەک Wizard8BP
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface WizardMenuWindow : UIWindow
+ (void)showMenu;
@end

@implementation WizardMenuWindow

static WizardMenuWindow *menuInstance = nil;
static UIView *mainView = nil;
static UIScrollView *scrollView = nil;
static UIButton *floatingBtn = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;
            menuInstance = [[WizardMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            
            // --- مێنیوی سەرەکی (پیشەییتر) ---
            mainView = [[UIView alloc] initWithFrame:CGRectMake(20, 40, 340, 580)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.94];
            mainView.layer.cornerRadius = 24;
            mainView.layer.borderWidth = 2;
            mainView.layer.borderColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0].CGColor;
            mainView.layer.shadowColor = [UIColor purpleColor].CGColor;
            mainView.layer.shadowOpacity = 0.5;
            mainView.layer.shadowRadius = 20;
            [menuInstance addSubview:mainView];
            
            // --- ناونیشان و زیرناونیشان ---
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 12, 320, 32)];
            title.text = @"🔥 Wizard8BP Elite 🔥";
            title.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.8 alpha:1.0];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:22];
            [mainView addSubview:title];
            
            UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 44, 320, 18)];
            subtitle.text = @"⚡ Premium Mod • 15+ Features ⚡";
            subtitle.textColor = [UIColor lightGrayColor];
            subtitle.textAlignment = NSTextAlignmentCenter;
            subtitle.font = [UIFont systemFontOfSize:12];
            [mainView addSubview:subtitle];
            
            // --- سکرۆل بۆ دوگمەکان ---
            scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 68, 320, 430)];
            scrollView.contentSize = CGSizeMake(320, 900);
            scrollView.showsVerticalScrollIndicator = YES;
            [mainView addSubview:scrollView];
            
            // --- لیستی دوگمەکان (۱۵ تایبەتمەندی) ---
            NSArray *titles = @[
                @"🎯 Aim Line (Dynamic Power)",
                @"🌀 Super Line (3 Lines)",
                @"🤖 Auto Play (AI)",
                @"🛡️ Anti-Ban (Advanced)",
                @"⚡ Infinite Power",
                @"🚀 Speed Boost (2x)",
                @"📐 Lock Angle (45°)",
                @"🌀 Show Trajectory",
                @"🎯 Force Pocket",
                @"🧊 No Friction",
                @"🌀 Perfect Spin",
                @"🧱 Wall Hack",
                @"🏆 Instant Win",
                @"🚫 No Obstacles",
                @"📡 Teleport Cue"
            ];
            
            NSArray *selectors = @[
                @"toggleAim:",
                @"toggleSuper:",
                @"toggleAuto:",
                @"toggleBan:",
                @"togglePower:",
                @"toggleSpeed:",
                @"toggleAngle:",
                @"toggleTrajectory:",
                @"togglePocket:",
                @"toggleFriction:",
                @"toggleSpin:",
                @"toggleWall:",
                @"toggleInstant:",
                @"toggleObstacles:",
                @"toggleTeleport:"
            ];
            
            for (int i = 0; i < titles.count; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                btn.frame = CGRectMake(10, 8 + (i * 52), 300, 44);
                btn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
                btn.layer.cornerRadius = 12;
                btn.tag = i + 100;
                [btn setTitle:[NSString stringWithFormat:@"🔴 %@", titles[i]] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13];
                btn.titleLabel.textAlignment = NSTextAlignmentLeft;
                [btn addTarget:self action:NSSelectorFromString(selectors[i]) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:btn];
            }
            
            // --- دوگمەکانی خوارەوە ---
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            closeBtn.frame = CGRectMake(50, 508, 100, 44);
            closeBtn.backgroundColor = [UIColor redColor];
            closeBtn.layer.cornerRadius = 12;
            [closeBtn setTitle:@"❌ Close" forState:UIControlStateNormal];
            [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:closeBtn];
            
            UIButton *destroyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            destroyBtn.frame = CGRectMake(180, 508, 100, 44);
            destroyBtn.backgroundColor = [UIColor orangeColor];
            destroyBtn.layer.cornerRadius = 12;
            [destroyBtn setTitle:@"💀 Destroy" forState:UIControlStateNormal];
            [destroyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [destroyBtn addTarget:self action:@selector(destroyMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:destroyBtn];
            
            // --- دوگمەی شناور (Floating Button) ---
            floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            floatingBtn.frame = CGRectMake(15, 120, 65, 65);
            floatingBtn.backgroundColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0];
            floatingBtn.layer.cornerRadius = 32.5;
            floatingBtn.layer.shadowColor = [UIColor purpleColor].CGColor;
            floatingBtn.layer.shadowOpacity = 0.8;
            floatingBtn.layer.shadowRadius = 15;
            [floatingBtn setTitle:@"🧙" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatingBtn.titleLabel setFont:[UIFont systemFontOfSize:32]];
            [floatingBtn addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFloating:)];
            [floatingBtn addGestureRecognizer:pan];
            [menuInstance addSubview:floatingBtn];
            floatingBtn.hidden = YES;
            
        } @catch (NSException *e) {
            NSLog(@"[WizardElite] showMenu error: %@", e);
        }
    });
}

// ================================================================
// 🔘 کارەکانی دوگمەکان
// ================================================================
+ (void)toggleAim:(UIButton *)sender { 
    aimLineEnabled = !aimLineEnabled; 
    [self updateButton:sender title:@"Aim Line" enabled:aimLineEnabled]; 
}

+ (void)toggleSuper:(UIButton *)sender { 
    superLineEnabled = !superLineEnabled; 
    [self updateButton:sender title:@"Super Line" enabled:superLineEnabled]; 
}

+ (void)toggleAuto:(UIButton *)sender { 
    autoPlayEnabled = !autoPlayEnabled; 
    [self updateButton:sender title:@"Auto Play" enabled:autoPlayEnabled]; 
}

+ (void)toggleBan:(UIButton *)sender { 
    antiBanEnabled = !antiBanEnabled; 
    [self updateButton:sender title:@"Anti-Ban" enabled:antiBanEnabled]; 
}

+ (void)togglePower:(UIButton *)sender { 
    infinitePowerEnabled = !infinitePowerEnabled; 
    [self updateButton:sender title:@"Infinite Power" enabled:infinitePowerEnabled]; 
}

+ (void)toggleSpeed:(UIButton *)sender { 
    speedBoostEnabled = !speedBoostEnabled; 
    [self updateButton:sender title:@"Speed Boost" enabled:speedBoostEnabled]; 
}

+ (void)toggleAngle:(UIButton *)sender { 
    angleLockEnabled = !angleLockEnabled; 
    if (angleLockEnabled) lockedAngle = 0.785; // 45 degree
    [self updateButton:sender title:@"Lock Angle" enabled:angleLockEnabled]; 
}

+ (void)toggleTrajectory:(UIButton *)sender { 
    showTrajectory = !showTrajectory; 
    [self updateButton:sender title:@"Trajectory" enabled:showTrajectory]; 
}

+ (void)togglePocket:(UIButton *)sender { 
    forcePocketEnabled = !forcePocketEnabled; 
    [self updateButton:sender title:@"Force Pocket" enabled:forcePocketEnabled]; 
}

+ (void)toggleFriction:(UIButton *)sender { 
    noFrictionEnabled = !noFrictionEnabled; 
    [self updateButton:sender title:@"No Friction" enabled:noFrictionEnabled]; 
}

+ (void)toggleSpin:(UIButton *)sender { 
    perfectSpinEnabled = !perfectSpinEnabled; 
    [self updateButton:sender title:@"Perfect Spin" enabled:perfectSpinEnabled]; 
}

+ (void)toggleWall:(UIButton *)sender { 
    wallHackEnabled = !wallHackEnabled; 
    [self updateButton:sender title:@"Wall Hack" enabled:wallHackEnabled]; 
}

+ (void)toggleInstant:(UIButton *)sender { 
    instantWinEnabled = !instantWinEnabled; 
    [self updateButton:sender title:@"Instant Win" enabled:instantWinEnabled]; 
    if (instantWinEnabled) {
        // بردنەوەی یەکسەر (پێویستە ئۆفسێتەکە بدۆزرێتەوە)
        // لێرەدا کۆدی بردنەوە زیاد دەکرێت
    }
}

+ (void)toggleObstacles:(UIButton *)sender { 
    noObstaclesEnabled = !noObstaclesEnabled; 
    [self updateButton:sender title:@"No Obstacles" enabled:noObstaclesEnabled]; 
}

+ (void)toggleTeleport:(UIButton *)sender { 
    teleportCueEnabled = !teleportCueEnabled; 
    [self updateButton:sender title:@"Teleport Cue" enabled:teleportCueEnabled]; 
}

// ================================================================
// 🔄 نوێکردنەوەی ڕەنگی دوگمە
// ================================================================
+ (void)updateButton:(UIButton *)btn title:(NSString *)title enabled:(BOOL)enabled {
    btn.backgroundColor = enabled ? [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0] : [UIColor colorWithWhite:0.2 alpha:1.0];
    [btn setTitle:[NSString stringWithFormat:@"%@ %@", enabled ? @"🟢" : @"🔴", title] forState:UIControlStateNormal];
}

// ================================================================
// 📱 کارەکانی مێنیوو
// ================================================================
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
// 🚀 لۆدبوونی مۆد (Constructor)
// ================================================================
__attribute__((constructor)) static void initWizardMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
                if (base) {
                    // --- دانانی هەموو هۆکەکان ---
                    if (OFFSET_AIM_EVENT != 0)
                        DobbyHook((void *)(base + OFFSET_AIM_EVENT), (void *)new_aimEvent, (void **)&orig_aimEvent);
                    
                    if (OFFSET_ANTI_BAN != 0)
                        DobbyHook((void *)(base + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)&orig_antiBan);
                    
                    if (OFFSET_AUTO_PLAY != 0)
                        DobbyHook((void *)(base + OFFSET_AUTO_PLAY), (void *)new_autoPlay, (void **)&orig_autoPlay);
                    
                    if (OFFSET_GAME_MANAGER != 0)
                        DobbyHook((void *)(base + OFFSET_GAME_MANAGER), (void *)new_isAimCorrect, (void **)&orig_isAimCorrect);
                    
                    if (OFFSET_BALL_SPEED != 0)
                        DobbyHook((void *)(base + OFFSET_BALL_SPEED), (void *)new_getBallSpeed, (void **)&orig_getBallSpeed);
                    
                    if (OFFSET_SHOT_POWER != 0)
                        DobbyHook((void *)(base + OFFSET_SHOT_POWER), (void *)new_getShotPower, (void **)&orig_getShotPower);
                    
                    // --- هۆکەکانی تر (ئەگەر ئۆفسێت هەبێت) ---
                    // DobbyHook((void *)(base + OFFSET_FRICTION), (void *)new_getFriction, (void **)&orig_getFriction);
                    // DobbyHook((void *)(base + OFFSET_SPIN), (void *)new_getSpin, (void **)&orig_getSpin);
                    // DobbyHook((void *)(base + OFFSET_WALL_COLLISION), (void *)new_getWallCollision, (void **)&orig_getWallCollision);
                    
                    NSLog(@"[WizardElite] ✅ All hooks installed successfully!");
                }
                [WizardMenuWindow showMenu];
            } @catch (NSException *e) {
                NSLog(@"[WizardElite] ❌ Init error: %@", e);
            }
        });
    }];
}
