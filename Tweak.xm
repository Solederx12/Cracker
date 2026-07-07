#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>
#import <libspector/spector.h>  // ✅ بەکارهێنانی libspector

// ================================================================
// 📌 ئۆفسێتەکان - ۱۰ ئۆفسێت پێویستە (پێویستە خۆت پڕبکەیتەوە)
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

#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8
#define OFFSET_AIM_ANGLE             0x28

// ================================================================
// 🕹️ دۆخی دوگمەکان - تەنها ٨ تایبەتمەندی کارا
// ================================================================
static BOOL aimLineEnabled     = NO;   // هێڵی درێژ
static BOOL superLineEnabled   = NO;   // سوپەر لاین (۳ هێڵ)
static BOOL autoPlayEnabled    = NO;   // یاری خۆکار
static BOOL antiBanEnabled     = NO;   // دژە-بان
static BOOL infinitePowerEnabled = NO; // قوەتی بێکۆتا
static BOOL speedBoostEnabled  = NO;   // خێرایی زۆر
static BOOL angleLockEnabled   = NO;   // قفڵکردنی گۆشە
static BOOL noFrictionEnabled  = NO;   // بێ-لێژایی

// ================================================================
// 📊 پەرامیتەرەکان
// ================================================================
static float lockedAngle = 0.785;   // ۴۵ پلە
static float customPower = 0.8;

// ================================================================
// 🛠️ Hookە سەرەکییەکان (بۆ libspector)
// ================================================================
bool (*orig_isAimCorrect)(void *instance);
bool (*orig_antiBan)(void *instance);
bool (*orig_autoPlay)(void *instance);
void* (*orig_aimEvent)(void *instance);
float (*orig_getBallSpeed)(void *instance);
float (*orig_getShotPower)(void *instance);
bool (*orig_getFriction)(void *instance);
void (*orig_setTableColor)(void *instance, float hue);

// ----- ۱. هێڵی درێژ و سوپەر لاین -----
bool new_isAimCorrect(void *instance) {
    @try {
        if (instance) {
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    float *linePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_LINE_LENGTH);
                    float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                    
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

// ----- ۴. ڕووداوی ئامانج (کۆنترۆڵی گۆشە و قوەت) -----
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

// ----- ۵. خێرایی تۆپ -----
float new_getBallSpeed(void *instance) {
    @try {
        if (speedBoostEnabled) return 800.0;
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] getBallSpeed: %@", e);
    }
    return orig_getBallSpeed ? orig_getBallSpeed(instance) : 300.0;
}

// ----- ۶. هێزی لێدان -----
float new_getShotPower(void *instance) {
    @try {
        if (infinitePowerEnabled) return 100.0;
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] getShotPower: %@", e);
    }
    return orig_getShotPower ? orig_getShotPower(instance) : 50.0;
}

// ----- ۷. بێ-لێژایی -----
bool new_getFriction(void *instance) {
    @try {
        if (noFrictionEnabled) return NO;
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] getFriction: %@", e);
    }
    return orig_getFriction ? orig_getFriction(instance) : YES;
}

// ----- ۸. ڕەنگی مێز (پێویستە ئۆفسێتەکە بدۆزیتەوە) -----
void new_setTableColor(void *instance, float hue) {
    @try {
        // hue = 0.5; // نموونە
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] setTableColor: %@", e);
    }
    if (orig_setTableColor) {
        orig_setTableColor(instance, hue);
    }
}

// ================================================================
// 🖥️ مێنیووی UI (بە ۸ دوگمە + دوگمەی سەرەوە)
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface SimpleMenu : UIWindow
+ (void)showMenu;
@end

@implementation SimpleMenu

static SimpleMenu *menuInstance = nil;
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
            [menuInstance addSubview:mainView];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 260, 30)];
            title.text = @"🎱 8BP Elite Mod";
            title.textColor = [UIColor whiteColor];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:18];
            [mainView addSubview:title];
            
            // دوگمەکان (۸ تایبەتمەندی)
            NSArray *titles = @[
                @"Aim Line", @"Super Line", @"Auto Play", @"Anti-Ban",
                @"Infinite Power", @"Speed Boost", @"Lock Angle", @"No Friction"
            ];
            NSArray *selectors = @[
                @"toggleAim:", @"toggleSuper:", @"toggleAuto:", @"toggleBan:",
                @"togglePower:", @"toggleSpeed:", @"toggleAngle:", @"toggleFriction:"
            ];
            
            for (int i = 0; i < titles.count; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
                btn.frame = CGRectMake(15, 50 + (i * 45), 250, 38);
                btn.backgroundColor = [UIColor grayColor];
                btn.layer.cornerRadius = 8;
                btn.tag = i + 100;
                [btn setTitle:[NSString stringWithFormat:@"🔴 %@: OFF", titles[i]] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13];
                [btn addTarget:self action:NSSelectorFromString(selectors[i]) forControlEvents:UIControlEventTouchUpInside];
                [mainView addSubview:btn];
            }
            
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
+ (void)toggleSpeed:(UIButton *)sender { speedBoostEnabled = !speedBoostEnabled; [self update:sender title:@"Speed Boost" on:speedBoostEnabled]; }
+ (void)toggleAngle:(UIButton *)sender { angleLockEnabled = !angleLockEnabled; [self update:sender title:@"Lock Angle" on:angleLockEnabled]; }
+ (void)toggleFriction:(UIButton *)sender { noFrictionEnabled = !noFrictionEnabled; [self update:sender title:@"No Friction" on:noFrictionEnabled]; }

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
// 👑 هۆکەکانی لۆگۆس (Logos) - تایبەتمەندییەکانی i3rby
// ================================================================

// هۆکی سەرەکی بۆ گەیشتن بە هەموو تایبەتمەندییەکان
%hook GameManager
- (BOOL)isOnCreatorMode { return YES; }
- (BOOL)isOnGoldenShotMode { return YES; }
- (BOOL)isOnPracticeMode { return YES; }
- (BOOL)isOnTournamentMode { return YES; }
%end

// هۆکی بینایی (هێڵەکان، پۆکێتەکان، خاڵەکان)
%hook GraphicsManager
- (float)lineOpacity { return 0.90; }
- (float)endBallSize { return 1.00; }
- (float)pocketRingSize { return 1.20; }
- (float)initialPull { return 1.00; }
- (float)shiftX { return 0.0; }
- (float)shiftY { return 0.0; }
- (float)lineScaleX { return 1.000; }
- (float)lineScaleY { return 1.000; }
- (float)lineThickness { return 1.00; }
%end

// هۆکی هێڵەکانی پێشبینی
%hook PredictionManager
- (BOOL)showPredictionLines { return YES; }
- (BOOL)showOpponentLines { return YES; }
- (BOOL)showTableOutline { return YES; }
- (BOOL)showPocketRings { return YES; }
- (BOOL)showEndDots { return YES; }
- (BOOL)showPrecisePaths { return YES; }
- (BOOL)showScratchAlert { return YES; }
- (BOOL)showWrongBallAlert { return YES; }
- (BOOL)showStreamProof { return YES; }
%end

// هۆکی ئۆتۆمەیشن و PRO
%hook AutomationManager
- (BOOL)isProUnlocked { return YES; }
- (BOOL)isAdFree { return YES; }
- (int)proPlanStatus { return 1; } // 0=day, 1=week, 2=month
- (float)aimStrength { return 0.07; }
- (float)maxAimSpeed { return 140.0; }
- (float)waitTime { return 1.00; }
%end

// هۆکی Spin و Aim
%hook AimController
- (NSString *)spinStyle { return @"Off"; } // Off, Suggest, Assist, Guide
- (NSString *)aimMode { return @"Guide"; }
- (NSString *)humanization { return @"Med"; } // Low, Med, High
- (NSString *)skillLevel { return @"Pro"; } // Casual, Pro, Stealth
- (NSString *)breakMode { return @"Single"; } // Single, Multi
%end

// هۆکی دوگمە و Ghost
%hook ShortcutManager
- (BOOL)shortcutButtonEnabled { return YES; }
- (BOOL)bestShotGhostEnabled { return YES; }
- (BOOL)autoSelectPocketEnabled { return YES; }
- (BOOL)ballInHandSkipEnabled { return YES; }
- (BOOL)pauseOnTouchEnabled { return YES; }
%end

// ================================================================
// ❌ لابردنی ناو و لۆگۆی i3rby لە هەموو شوێنێک + زیادکردنی ناوی خۆت
// ================================================================
%hook i3rbyStoreViewController
- (void)viewDidLoad {
    %orig;
    @try {
        // لابردنی هەموو ئەو UI عناصرەی کە ناوی i3rby, Telegram, Facebook یان لۆگۆیان تیاە
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)subview;
                if ([label.text containsString:@"i3rby"] || 
                    [label.text containsString:@"Telegram"] || 
                    [label.text containsString:@"Facebook"] ||
                    [label.text containsString:@"i3rby Store"]) {
                    [label removeFromSuperview];
                }
            }
            if ([subview isKindOfClass:[UIImageView class]]) {
                [subview removeFromSuperview]; // لابردنی لۆگۆ
            }
            if ([subview isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)subview;
                if ([btn.titleLabel.text containsString:@"Telegram"] || 
                    [btn.titleLabel.text containsString:@"FB"] ||
                    [btn.titleLabel.text containsString:@"i3rby"]) {
                    [btn removeFromSuperview];
                }
            }
        }
        // زیادکردنی ناوی خۆت (ئەمە بە ناوی خۆت بگۆڕە)
        UILabel *myLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 250, 30)];
        myLabel.text = @"🔥 Hack by [ناوی تۆ]";
        myLabel.textColor = [UIColor systemYellowColor];
        myLabel.font = [UIFont boldSystemFontOfSize:16];
        [self.view addSubview:myLabel];
    } @catch (NSException *e) {
        NSLog(@"[EliteMod] Branding removal error: %@", e);
    }
}
%end

// ================================================================
// 🚀 لۆدبوونی مۆد (libspector + Logos)
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
                    // گۆڕینی هەموو DobbyHook بۆ spector_hook
                    if (OFFSET_AIM_EVENT != 0)
                        spector_hook((void *)(base + OFFSET_AIM_EVENT), (void *)new_aimEvent, (void **)&orig_aimEvent);
                    if (OFFSET_ANTI_BAN != 0)
                        spector_hook((void *)(base + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)&orig_antiBan);
                    if (OFFSET_AUTO_PLAY != 0)
                        spector_hook((void *)(base + OFFSET_AUTO_PLAY), (void *)new_autoPlay, (void **)&orig_autoPlay);
                    if (OFFSET_GAME_MANAGER != 0)
                        spector_hook((void *)(base + OFFSET_GAME_MANAGER), (void *)new_isAimCorrect, (void **)&orig_isAimCorrect);
                    if (OFFSET_BALL_SPEED != 0)
                        spector_hook((void *)(base + OFFSET_BALL_SPEED), (void *)new_getBallSpeed, (void **)&orig_getBallSpeed);
                    if (OFFSET_SHOT_POWER != 0)
                        spector_hook((void *)(base + OFFSET_SHOT_POWER), (void *)new_getShotPower, (void **)&orig_getShotPower);
                    if (OFFSET_TABLE_COLOR != 0)
                        spector_hook((void *)(base + OFFSET_TABLE_COLOR), (void *)new_setTableColor, (void **)&orig_setTableColor);
                    // بۆ getFriction ئەگەر ئۆفسێتەکەت هەیە ئەم هێڵە لابراوە لابە
                    // spector_hook((void *)(base + OFFSET_FRICTION), (void *)new_getFriction, (void **)&orig_getFriction);
                    
                    NSLog(@"[EliteMod] ✅ Hooks installed with libspector!");
                }
                [SimpleMenu showMenu];
            } @catch (NSException *e) {
                NSLog(@"[EliteMod] ❌ Init error: %@", e);
            }
        });
    }];
}
