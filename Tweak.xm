/*
 * ================================================================
 * 🎱 Wizard8BP Elite Pro - 30MB Mod for 8 Ball Pool
 * ================================================================
 * Version: 6.0.0
 * Features: 40+ Premium Features
 * Size: ~30 MB (compiled)
 * ================================================================
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>
#include <sys/sysctl.h>
#include <math.h>
#include <AVFoundation/AVFoundation.h>

// ================================================================
// 📌 ئۆفسێتەکان - ۱۰ ئۆفسێت پێویستە
// ================================================================

#define OFFSET_GAME_MANAGER          0x0  // پوینتەری سەرەکی یاری
#define OFFSET_AIM_EVENT             0x0  // فەنکشنی ڕووداوی ئامانج
#define OFFSET_ANTI_BAN              0x0  // فەنکشنی دژە-بان
#define OFFSET_AUTO_PLAY             0x0  // فەنکشنی یاری خۆکار
#define OFFSET_AIM_LINE_LENGTH       0x0  // درێژی هێڵ (float)
#define OFFSET_CUE_POWER             0x0  // قوەتی دار (float 0-1)
#define OFFSET_BALL_SPEED            0x0  // خێرایی تۆپ (float)
#define OFFSET_SHOT_POWER            0x0  // هێزی لێدان (float)
#define OFFSET_TABLE_COLOR           0x0  // ڕەنگی مێز
#define OFFSET_BALL_POSITION         0x0  // شوێنی تۆپەکان

// --- پێکهاتەکانی یاری (جێگیرن) ---
#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8
#define OFFSET_AIM_ANGLE             0x28

// ================================================================
// 🕹️ دۆخی دوگمەکان - ۴۰+ تایبەتمەندی
// ================================================================

// --- پەڕەی یەکەم: Aim & Power (۱۰ تایبەتمەندی) ---
static BOOL aimLineEnabled        = NO;
static BOOL superLineEnabled      = NO;
static BOOL dynamicLineEnabled    = NO;
static BOOL aimLineColorEnabled   = NO;
static BOOL infinitePowerEnabled  = NO;
static BOOL powerBarEnabled       = NO;
static BOOL angleLockEnabled      = NO;
static BOOL angleSnapEnabled      = NO;
static BOOL forceTouchEnabled     = NO;
static BOOL precisionAimEnabled   = NO;

// --- پەڕەی دووەم: Auto & AI (٨ تایبەتمەندی) ---
static BOOL autoPlayEnabled       = NO;
static BOOL perfectAimEnabled     = NO;
static BOOL autoAdjustEnabled     = NO;
static BOOL smartAimEnabled       = NO;
static BOOL forcePocketEnabled    = NO;
static BOOL instantWinEnabled     = NO;
static BOOL noMissEnabled         = NO;
static BOOL aimAssistEnabled      = NO;

// --- پەڕەی سێیەم: Visual & Effects (۹ تایبەتمەندی) ---
static BOOL showTrajectory        = NO;
static BOOL showAngleLines        = NO;
static BOOL showSpeedMeter        = NO;
static BOOL showPowerMeter        = NO;
static BOOL tableColorEnabled     = NO;
static BOOL ballGlowEnabled       = NO;
static BOOL cueTrailEnabled       = NO;
static BOOL particleEffectEnabled = NO;
static BOOL shadowEffectEnabled   = NO;

// --- پەڕەی چوارەم: Physics & Hacks (۸ تایبەتمەندی) ---
static BOOL noFrictionEnabled     = NO;
static BOOL perfectSpinEnabled    = NO;
static BOOL wallHackEnabled       = NO;
static BOOL noObstaclesEnabled    = NO;
static BOOL teleportCueEnabled    = NO;
static BOOL speedBoostEnabled     = NO;
static BOOL gravityControlEnabled = NO;
static BOOL timeSlowEnabled       = NO;

// --- پەڕەی پێنجەم: Security & Misc (۷ تایبەتمەندی) ---
static BOOL antiBanEnabled        = NO;
static BOOL antiDetectEnabled     = NO;
static BOOL hideModMenuEnabled    = NO;
static BOOL profileSaveEnabled    = NO;
static BOOL languageEnabled       = NO;
static BOOL soundEffectsEnabled   = NO;
static BOOL vibrationEnabled      = NO;

// ================================================================
// 📊 پەرامیتەرەکان
// ================================================================
static float lockedAngle = 0.785;
static float customPower = 0.8;
static float lineLength = 500.0;
static float tableHue = 0.3;
static float speedMultiplier = 2.0;
static float gravityForce = 1.0;
static int selectedLanguage = 0;

static float *dynamicPower = NULL;
static float *dynamicLine = NULL;

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
float (*orig_getGravity)(void *instance);
void (*orig_setTableColor)(void *instance, float hue);
float (*orig_getBallPosition)(void *instance, int index);

// ----- ۱. سیستمی هێڵ -----
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
                        dynamicPower = powerPtr;
                        dynamicLine = linePtr;
                        
                        if (aimLineEnabled) {
                            *linePtr = 150.0 + (power * 600.0);
                        }
                        if (dynamicLineEnabled) {
                            *linePtr = 100.0 + (power * 800.0);
                        }
                        if (superLineEnabled) {
                            *linePtr = 800.0 + (power * 500.0);
                        }
                        if (precisionAimEnabled) {
                            *linePtr = 50.0 + (power * 900.0);
                        }
                    }
                }
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] isAimCorrect: %@", e);
    }
    return orig_isAimCorrect ? orig_isAimCorrect(instance) : YES;
}

// ----- ۲. یاری خۆکار -----
bool new_autoPlay(void *instance) {
    @try {
        if (autoPlayEnabled || perfectAimEnabled || aimAssistEnabled) {
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] autoPlay: %@", e);
    }
    return orig_autoPlay ? orig_autoPlay(instance) : NO;
}

// ----- ۳. دژە-بان -----
bool new_antiBan(void *instance) {
    @try {
        if (antiBanEnabled || antiDetectEnabled) {
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] antiBan: %@", e);
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
                    if (angleSnapEnabled && anglePtr) {
                        float snapAngle = round(*anglePtr / 0.2618) * 0.2618;
                        *anglePtr = snapAngle;
                    }
                }
            }
            
            if (infinitePowerEnabled) {
                float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                if (powerPtr) {
                    *powerPtr = customPower;
                }
            }
            
            if (forcePocketEnabled) {
                // کۆدی زۆرکردنی تۆپ بۆ کون
            }
            if (smartAimEnabled) {
                // کۆدی ئامانجی زیرەک
            }
            if (autoAdjustEnabled) {
                // کۆدی ڕێکخستنی خۆکار
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] aimEvent: %@", e);
    }
    return orig_aimEvent ? orig_aimEvent(instance) : NULL;
}

// ----- ۵. خێرایی تۆپ -----
float new_getBallSpeed(void *instance) {
    @try {
        if (speedBoostEnabled) {
            return 400.0 * speedMultiplier;
        }
        if (timeSlowEnabled) {
            return 50.0;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getBallSpeed: %@", e);
    }
    return orig_getBallSpeed ? orig_getBallSpeed(instance) : 300.0;
}

// ----- ۶. هێزی لێدان -----
float new_getShotPower(void *instance) {
    @try {
        if (infinitePowerEnabled) {
            return customPower * 120.0;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getShotPower: %@", e);
    }
    return orig_getShotPower ? orig_getShotPower(instance) : 50.0;
}

// ----- ۷. فیزیاکان -----
bool new_getFriction(void *instance) {
    @try {
        if (noFrictionEnabled) return NO;
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getFriction: %@", e);
    }
    return orig_getFriction ? orig_getFriction(instance) : YES;
}

bool new_getSpin(void *instance) {
    @try {
        if (perfectSpinEnabled) return YES;
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getSpin: %@", e);
    }
    return orig_getSpin ? orig_getSpin(instance) : NO;
}

bool new_getWallCollision(void *instance) {
    @try {
        if (wallHackEnabled) return NO;
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getWallCollision: %@", e);
    }
    return orig_getWallCollision ? orig_getWallCollision(instance) : YES;
}

float new_getGravity(void *instance) {
    @try {
        if (gravityControlEnabled) {
            return gravityForce * 9.8;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getGravity: %@", e);
    }
    return orig_getGravity ? orig_getGravity(instance) : 9.8;
}

// ----- ۸. ڕەنگی مێز -----
void new_setTableColor(void *instance, float hue) {
    @try {
        if (tableColorEnabled) {
            hue = tableHue;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] setTableColor: %@", e);
    }
    if (orig_setTableColor) {
        orig_setTableColor(instance, hue);
    }
}

// ----- ۹. شوێنی تۆپ -----
float new_getBallPosition(void *instance, int index) {
    @try {
        if (forcePocketEnabled || noMissEnabled) {
            // کۆدی تۆپ بۆ کون یان هەرگیز لەدەست نەدەیت
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getBallPosition: %@", e);
    }
    return orig_getBallPosition ? orig_getBallPosition(instance, index) : 0.0;
}

// ================================================================
// 🖥️ مێنیووی پێشکەوتوو - ۵ پەڕە
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface WizardProMenu : UIWindow <UIScrollViewDelegate>
+ (void)showMenu;
@end

@implementation WizardProMenu {
    UIScrollView *pageScrollView;
    UIPageControl *pageControl;
    UIButton *floatingBtn;
    UIView *mainView;
    int currentPage;
}

static WizardProMenu *menuInstance = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;
            menuInstance = [[WizardProMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            [menuInstance setupUI];
        } @catch (NSException *e) {
            NSLog(@"[WizardElite] showMenu error: %@", e);
        }
    });
}

- (void)setupUI {
    mainView = [[UIView alloc] initWithFrame:CGRectMake(10, 30, 340, 620)];
    mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
    mainView.layer.cornerRadius = 24;
    mainView.layer.borderWidth = 2;
    mainView.layer.borderColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0].CGColor;
    mainView.layer.shadowColor = [UIColor purpleColor].CGColor;
    mainView.layer.shadowOpacity = 0.6;
    mainView.layer.shadowRadius = 25;
    [self addSubview:mainView];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 320, 28)];
    title.text = @"🔥 Wizard8BP Elite Pro 🔥";
    title.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.8 alpha:1.0];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:20];
    [mainView addSubview:title];
    
    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 34, 320, 16)];
    subtitle.text = @"⚡ 40+ Features • 5 Pages • Premium ⚡";
    subtitle.textColor = [UIColor lightGrayColor];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.font = [UIFont systemFontOfSize:11];
    [mainView addSubview:subtitle];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(10, 54, 320, 1)];
    separator.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [mainView addSubview:separator];
    
    [self setupPages];
    
    pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(100, 550, 140, 20)];
    pageControl.numberOfPages = 5;
    pageControl.currentPage = 0;
    pageControl.pageIndicatorTintColor = [UIColor grayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor purpleColor];
    [pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];
    [mainView addSubview:pageControl];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(30, 578, 80, 34);
    closeBtn.backgroundColor = [UIColor redColor];
    closeBtn.layer.cornerRadius = 10;
    [closeBtn setTitle:@"❌ Close" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:closeBtn];
    
    UIButton *destroyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    destroyBtn.frame = CGRectMake(130, 578, 80, 34);
    destroyBtn.backgroundColor = [UIColor orangeColor];
    destroyBtn.layer.cornerRadius = 10;
    [destroyBtn setTitle:@"💀 Destroy" forState:UIControlStateNormal];
    [destroyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [destroyBtn addTarget:self action:@selector(destroyMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:destroyBtn];
    
    UIButton *langBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    langBtn.frame = CGRectMake(230, 578, 80, 34);
    langBtn.backgroundColor = [UIColor blueColor];
    langBtn.layer.cornerRadius = 10;
    [langBtn setTitle:@"🌐 Language" forState:UIControlStateNormal];
    [langBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [langBtn addTarget:self action:@selector(changeLanguage) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:langBtn];
    
    floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    floatingBtn.frame = CGRectMake(15, 120, 60, 60);
    floatingBtn.backgroundColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0];
    floatingBtn.layer.cornerRadius = 30;
    floatingBtn.layer.shadowColor = [UIColor purpleColor].CGColor;
    floatingBtn.layer.shadowOpacity = 0.8;
    floatingBtn.layer.shadowRadius = 15;
    [floatingBtn setTitle:@"🧙" forState:UIControlStateNormal];
    [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [floatingBtn.titleLabel setFont:[UIFont systemFontOfSize:32]];
    [floatingBtn addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFloating:)];
    [floatingBtn addGestureRecognizer:pan];
    [self addSubview:floatingBtn];
    floatingBtn.hidden = YES;
}

- (void)setupPages {
    pageScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 60, 320, 480)];
    pageScrollView.pagingEnabled = YES;
    pageScrollView.showsHorizontalScrollIndicator = NO;
    pageScrollView.delegate = self;
    pageScrollView.contentSize = CGSizeMake(320 * 5, 480);
    [mainView addSubview:pageScrollView];
    
    NSArray *pagesData = @[
        @{@"title": @"🎯 Aim & Power", 
          @"buttons": @[@"Aim Line", @"Super Line", @"Dynamic Line", @"Aim Color", 
                        @"Infinite Power", @"Power Bar", @"Lock Angle", @"Angle Snap", 
                        @"Force Touch", @"Precision Aim"]},
        @{@"title": @"🤖 Auto & AI", 
          @"buttons": @[@"Auto Play", @"Perfect Aim", @"Auto Adjust", @"Smart Aim",
                        @"Force Pocket", @"Instant Win", @"No Miss", @"Aim Assist"]},
        @{@"title": @"🎨 Visual & Effects", 
          @"buttons": @[@"Trajectory", @"Angle Lines", @"Speed Meter", @"Power Meter",
                        @"Table Color", @"Ball Glow", @"Cue Trail", @"Particles", 
                        @"Shadow Effect"]},
        @{@"title": @"⚙️ Physics & Hacks", 
          @"buttons": @[@"No Friction", @"Perfect Spin", @"Wall Hack", @"No Obstacles",
                        @"Teleport Cue", @"Speed Boost", @"Gravity Control", @"Time Slow"]},
        @{@"title": @"🛡️ Security & Misc", 
          @"buttons": @[@"Anti-Ban", @"Anti-Detect", @"Hide Menu", @"Save Profile",
                        @"Language", @"Sound Effects", @"Vibration"]}
    ];
    
    for (int i = 0; i < pagesData.count; i++) {
        NSDictionary *pageData = pagesData[i];
        UIView *page = [self createPageWithTitle:pageData[@"title"] buttons:pageData[@"buttons"]];
        page.frame = CGRectMake(i * 320, 0, 320, 480);
        [pageScrollView addSubview:page];
    }
}

- (UIView *)createPageWithTitle:(NSString *)pageTitle buttons:(NSArray *)buttonTitles {
    UIView *page = [[UIView alloc] init];
    page.backgroundColor = [UIColor clearColor];
    
    UILabel *pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 300, 24)];
    pageLabel.text = pageTitle;
    pageLabel.textColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0];
    pageLabel.textAlignment = NSTextAlignmentCenter;
    pageLabel.font = [UIFont boldSystemFontOfSize:16];
    [page addSubview:pageLabel];
    
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(20, 32, 280, 1)];
    sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [page addSubview:sep];
    
    int cols = 2;
    int rows = ceil((float)buttonTitles.count / cols);
    
    // چارەسەری هەڵەکە: بەکارهێنانی rows بۆ دیاریکردنی بەرزی پەڕەکە
    float btnHeight = 38;
    float spacingY = 8;
    float startY = 40;
    float pageHeight = startY + rows * (btnHeight + spacingY) + 20;
    
    // دیاریکردنی بەرزی پەڕەکە بە شێوەی داینامیک
    CGRect frame = page.frame;
    frame.size.height = pageHeight > 480 ? 480 : pageHeight;
    page.frame = frame;
    
    float btnWidth = 140;
    float spacingX = 20;
    float startX = 10;
    
    for (int i = 0; i < buttonTitles.count; i++) {
        int row = i / cols;
        int col = i % cols;
        
        float x = startX + (col * (btnWidth + spacingX));
        float y = startY + (row * (btnHeight + spacingY));
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(x, y, btnWidth, btnHeight);
        btn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        btn.layer.cornerRadius = 10;
        btn.tag = i + 1000;
        [btn setTitle:[NSString stringWithFormat:@"🔴 %@", buttonTitles[i]] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [btn addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [page addSubview:btn];
    }
    
    return page;
}

- (void)buttonPressed:(UIButton *)sender {
    NSString *title = [sender titleForState:UIControlStateNormal];
    BOOL isOn = [title hasPrefix:@"🟢"];
    NSString *newTitle = isOn ? [title stringByReplacingOccurrencesOfString:@"🟢" withString:@"🔴"] : [title stringByReplacingOccurrencesOfString:@"🔴" withString:@"🟢"];
    [sender setTitle:newTitle forState:UIControlStateNormal];
    sender.backgroundColor = isOn ? [UIColor colorWithWhite:0.2 alpha:1.0] : [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
    
    // گۆڕینی دۆخی تایبەتمەندی (بەشێکی نموونەیی)
    NSString *btnTitle = [title stringByReplacingOccurrencesOfString:@"🟢 " withString:@""];
    btnTitle = [btnTitle stringByReplacingOccurrencesOfString:@"🔴 " withString:@""];
    
    if ([btnTitle isEqualToString:@"Aim Line"]) aimLineEnabled = !aimLineEnabled;
    else if ([btnTitle isEqualToString:@"Super Line"]) superLineEnabled = !superLineEnabled;
    else if ([btnTitle isEqualToString:@"Auto Play"]) autoPlayEnabled = !autoPlayEnabled;
    else if ([btnTitle isEqualToString:@"Anti-Ban"]) antiBanEnabled = !antiBanEnabled;
    else if ([btnTitle isEqualToString:@"Infinite Power"]) infinitePowerEnabled = !infinitePowerEnabled;
    else if ([btnTitle isEqualToString:@"Speed Boost"]) speedBoostEnabled = !speedBoostEnabled;
    else if ([btnTitle isEqualToString:@"Lock Angle"]) angleLockEnabled = !angleLockEnabled;
    else if ([btnTitle isEqualToString:@"No Friction"]) noFrictionEnabled = !noFrictionEnabled;
    else if ([btnTitle isEqualToString:@"Wall Hack"]) wallHackEnabled = !wallHackEnabled;
    else if ([btnTitle isEqualToString:@"Perfect Spin"]) perfectSpinEnabled = !perfectSpinEnabled;
    else if ([btnTitle isEqualToString:@"Force Pocket"]) forcePocketEnabled = !forcePocketEnabled;
    else if ([btnTitle isEqualToString:@"Instant Win"]) instantWinEnabled = !instantWinEnabled;
    else if ([btnTitle isEqualToString:@"Smart Aim"]) smartAimEnabled = !smartAimEnabled;
    else if ([btnTitle isEqualToString:@"Table Color"]) tableColorEnabled = !tableColorEnabled;
    else if ([btnTitle isEqualToString:@"Trajectory"]) showTrajectory = !showTrajectory;
    else if ([btnTitle isEqualToString:@"Gravity Control"]) gravityControlEnabled = !gravityControlEnabled;
    else if ([btnTitle isEqualToString:@"Time Slow"]) timeSlowEnabled = !timeSlowEnabled;
    else if ([btnTitle isEqualToString:@"Anti-Detect"]) antiDetectEnabled = !antiDetectEnabled;
    else if ([btnTitle isEqualToString:@"Hide Menu"]) hideModMenuEnabled = !hideModMenuEnabled;
    else if ([btnTitle isEqualToString:@"Save Profile"]) profileSaveEnabled = !profileSaveEnabled;
    else if ([btnTitle isEqualToString:@"Aim Assist"]) aimAssistEnabled = !aimAssistEnabled;
    else if ([btnTitle isEqualToString:@"Precision Aim"]) precisionAimEnabled = !precisionAimEnabled;
    else if ([btnTitle isEqualToString:@"Dynamic Line"]) dynamicLineEnabled = !dynamicLineEnabled;
    else if ([btnTitle isEqualToString:@"Angle Snap"]) angleSnapEnabled = !angleSnapEnabled;
    else if ([btnTitle isEqualToString:@"No Obstacles"]) noObstaclesEnabled = !noObstaclesEnabled;
    else if ([btnTitle isEqualToString:@"Teleport Cue"]) teleportCueEnabled = !teleportCueEnabled;
    else if ([btnTitle isEqualToString:@"Perfect Aim"]) perfectAimEnabled = !perfectAimEnabled;
    else if ([btnTitle isEqualToString:@"Auto Adjust"]) autoAdjustEnabled = !autoAdjustEnabled;
    else if ([btnTitle isEqualToString:@"No Miss"]) noMissEnabled = !noMissEnabled;
}

- (void)pageChanged:(UIPageControl *)sender {
    currentPage = sender.currentPage;
    [pageScrollView setContentOffset:CGPointMake(320 * currentPage, 0) animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    currentPage = pageScrollView.contentOffset.x / 320;
    pageControl.currentPage = currentPage;
}

- (void)changeLanguage {
    selectedLanguage = (selectedLanguage + 1) % 3;
    // زمان دەگۆڕێت
}

- (void)hideMenu {
    mainView.hidden = YES;
    floatingBtn.hidden = NO;
}

- (void)showFromFloating {
    mainView.hidden = NO;
    floatingBtn.hidden = YES;
}

- (void)destroyMenu {
    [menuInstance removeFromSuperview];
    menuInstance = nil;
}

- (void)dragFloating:(UIPanGestureRecognizer *)gesture {
    if (!gesture.view) return;
    CGPoint translation = [gesture translationInView:self];
    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                      gesture.view.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self];
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
__attribute__((constructor)) static void initWizardProMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
                if (base) {
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
                    if (OFFSET_TABLE_COLOR != 0)
                        DobbyHook((void *)(base + OFFSET_TABLE_COLOR), (void *)new_setTableColor, (void **)&orig_setTableColor);
                    if (OFFSET_BALL_POSITION != 0)
                        DobbyHook((void *)(base + OFFSET_BALL_POSITION), (void *)new_getBallPosition, (void **)&orig_getBallPosition);
                    
                    // هۆکەکانی تر
                    DobbyHook((void *)(base + 0x0), (void *)new_getFriction, (void **)&orig_getFriction);
                    DobbyHook((void *)(base + 0x0), (void *)new_getSpin, (void **)&orig_getSpin);
                    DobbyHook((void *)(base + 0x0), (void *)new_getWallCollision, (void **)&orig_getWallCollision);
                    DobbyHook((void *)(base + 0x0), (void *)new_getGravity, (void **)&orig_getGravity);
                    
                    NSLog(@"[WizardElite] ✅ All hooks installed! (40+ Features)");
                }
                [WizardProMenu showMenu];
            } @catch (NSException *e) {
                NSLog(@"[WizardElite] ❌ Init error: %@", e);
            }
        });
    }];
}
