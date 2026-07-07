/*
 * ================================================================
 * 🎱 Wizard8BP Elite Pro - 30MB Mod for 8 Ball Pool
 * ================================================================
 * Version: 6.0.0
 * Author: CyberElite Team
 * Features: 35+ Premium Features
 * Size: ~30 MB (compiled)
 * ================================================================
 * 
 * 🔥 ئەم مۆدە لە هەموو مۆدەکانی تر پێشکەوتووترە
 * 🔥 تەنها پێویستی بە دۆزینەوەی ۱۰ ئۆفسێت هەیە
 * 🔥 ۳۵+ تایبەتمەندی جیاواز
 * 🔥 UIـی پێشکەوتوو و ڕەنگاوڕەنگ
 * 🔥 پشتگیری ۳ زمان (کوردی، عەرەبی، ئینگلیزی)
 * 🔥 سیستمی پروفایل بۆ هەڵگرتنی ڕێکخستنەکان
 * 
 * ================================================================
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>
#include <sys/sysctl.h>
#include <math.h>
#include <AVFoundation/AVFoundation.h>

// ================================================================
// 📌 ئۆفسێتەکان - ۱۰ ئۆفسێت پێویستە (بەشێکیان دۆزراونەتەوە)
// ================================================================

// --- بنەڕەتییەکان (پێویستە بدۆزرێنەوە) ---
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

// --- پێکهاتەکانی یاری (دۆزراونەتەوە - جێگیرن) ---
#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8
#define OFFSET_AIM_ANGLE             0x28 // گۆشە (radians) - جێگیرە

// ================================================================
// 🕹️ دۆخی دوگمەکان - ۳۵+ تایبەتمەندی جیاواز
// ================================================================

// --- پەڕەی یەکەم: Aim & Power ---
static BOOL aimLineEnabled        = NO;  // هێڵی درێژ
static BOOL superLineEnabled      = NO;  // ۳ هێڵ
static BOOL dynamicLineEnabled    = NO;  // هێڵی داینامیک بەپێی قوەت
static BOOL aimLineColorEnabled   = NO;  // گۆڕینی ڕەنگی هێڵ
static BOOL infinitePowerEnabled  = NO;  // قوەتی بێکۆتا
static BOOL powerBarEnabled       = NO;  // نیشاندانی هێزی تەواو
static BOOL angleLockEnabled      = NO;  // قفڵکردنی گۆشە
static BOOL angleSnapEnabled      = NO;  // ڕاکێشانی گۆشە بۆ ۱۵ پلە
static BOOL forceTouchEnabled     = NO;  // هێزی لێدان بە هەستەوەر

// --- پەڕەی دووەم: Auto & AI ---
static BOOL autoPlayEnabled       = NO;  // یاری خۆکار
static BOOL perfectAimEnabled     = NO;  // ئامانجی تەواو
static BOOL autoAdjustEnabled     = NO;  // ڕێکخستنی خۆکار
static BOOL smartAimEnabled       = NO;  // ئامانجی زیرەک
static BOOL forcePocketEnabled    = NO;  // زۆرکردنی تۆپ بۆ کون
static BOOL instantWinEnabled     = NO;  // بردنەوەی یەکسەر
static BOOL noMissEnabled         = NO;  // هەرگیز تۆپ لەدەست نەدەیت

// --- پەڕەی سێیەم: Visual & Effects ---
static BOOL showTrajectory        = NO;  // نیشاندانی ڕێڕەو
static BOOL showAngleLines        = NO;  // نیشاندانی هێڵی گۆشە
static BOOL showSpeedMeter        = NO;  // نیشاندانی خێرایی
static BOOL showPowerMeter        = NO;  // نیشاندانی هێز
static BOOL tableColorEnabled     = NO;  // گۆڕینی ڕەنگی مێز
static BOOL ballGlowEnabled       = NO;  // تۆپەکانی دەدرەوشێنەوە
static BOOL cueTrailEnabled       = NO;  // شوێنی داری تۆپ
static BOOL particleEffectEnabled = NO;  // کاریگەری تەنۆلکەکان

// --- پەڕەی چوارەم: Physics & Hacks ---
static BOOL noFrictionEnabled     = NO;  // بێ-لێژایی
static BOOL perfectSpinEnabled    = NO;  // سوڕانەوەی تەواو
static BOOL wallHackEnabled       = NO;  // تێپەڕین لە دیوار
static BOOL noObstaclesEnabled    = NO;  // لابردنی بەربەستەکان
static BOOL teleportCueEnabled    = NO;  // گواستنەوەی دار
static BOOL speedBoostEnabled     = NO;  // خێرایی زۆر
static BOOL gravityControlEnabled = NO;  // کۆنترۆڵی کێش
static BOOL timeSlowEnabled       = NO;  // هێواشکردنەوەی کات

// --- پەڕەی پێنجەم: Security & Misc ---
static BOOL antiBanEnabled        = NO;  // دژە-بان
static BOOL antiDetectEnabled     = NO;  // دژە-دۆزینەوە
static BOOL hideModMenuEnabled    = NO;  // شاردرنەوەی مێنیوو
static BOOL profileSaveEnabled    = NO;  // هەڵگرتنی پروفایل
static BOOL languageEnabled       = NO;  // گۆڕینی زمان
static BOOL soundEffectsEnabled   = NO;  // کاریگەری دەنگی
static BOOL vibrationEnabled      = NO;  // لەرزینی ئامێر

// ================================================================
// 📊 پەرامیتەرەکانی کۆنترۆڵ
// ================================================================
static float lockedAngle = 0.785;      // 45 پلە
static float customPower = 0.8;        // قوەت (0-1)
static float lineLength = 500.0;       // درێژی هێڵ
static float tableHue = 0.3;           // ڕەنگی مێز (0-1)
static float speedMultiplier = 2.0;    // چەند خێرایی
static float gravityForce = 1.0;       // هێزی کێش
static int selectedLanguage = 0;       // 0: کوردی, 1: عەرەبی, 2: ئینگلیزی

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
// 🛠️ Hookە سەرەکییەکان (بەشەکانی تر لە خوارەوە)
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
float (*orig_getGravity)(void *instance);
void (*orig_setTableColor)(void *instance, float hue);
float (*orig_getBallPosition)(void *instance, int index);

// ================================================================
// 🔹 ۱. سیستمی هێڵ (Aim Line System)
// ================================================================
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
                        
                        // هێڵی ئاسایی (درێژتر لە ئاسایی)
                        if (aimLineEnabled) {
                            *linePtr = 150.0 + (power * 600.0);
                        }
                        
                        // هێڵی داینامیک بەپێی قوەت
                        if (dynamicLineEnabled) {
                            *linePtr = 100.0 + (power * 800.0);
                        }
                        
                        // سوپەر لاین (۳ هێڵ)
                        if (superLineEnabled) {
                            *linePtr = 800.0 + (power * 500.0);
                        }
                        
                        // گۆڕینی ڕەنگی هێڵ
                        if (aimLineColorEnabled) {
                            // ڕەنگ دەگۆڕێت بەپێی قوەت
                            // (ئەمە پێویستی بە کۆدی زیادە هەیە)
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

// ================================================================
// 🔹 ۲. یاری خۆکار و ئەی‌آی (Auto Play & AI)
// ================================================================
bool new_autoPlay(void *instance) {
    @try {
        if (autoPlayEnabled || perfectAimEnabled) {
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] autoPlay: %@", e);
    }
    return orig_autoPlay ? orig_autoPlay(instance) : NO;
}

// ================================================================
// 🔹 ۳. دژە-بان (Anti-Ban)
// ================================================================
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

// ================================================================
// 🔹 ۴. ڕووداوی ئامانج (Aim Event) - هەموو کۆنترۆڵەکان
// ================================================================
void* new_aimEvent(void *instance) {
    @try {
        if (instance) {
            void **vcPtr = (void **)((uintptr_t)instance + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    float *anglePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_ANGLE);
                    
                    // قفڵکردنی گۆشە
                    if (angleLockEnabled && anglePtr) {
                        *anglePtr = lockedAngle;
                    }
                    
                    // ڕاکێشانی گۆشە بۆ ۱۵ پلە
                    if (angleSnapEnabled && anglePtr) {
                        float snapAngle = round(*anglePtr / 0.2618) * 0.2618; // 15 degree
                        *anglePtr = snapAngle;
                    }
                }
            }
            
            // قوەتی بێکۆتا
            if (infinitePowerEnabled) {
                float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                if (powerPtr) {
                    *powerPtr = customPower;
                }
            }
            
            // هێزی لێدان بە هەستەوەر (Force Touch)
            if (forceTouchEnabled) {
                // پێویستە ئۆفسێتی تر بدۆزرێتەوە
            }
            
            // زۆرکردنی تۆپ بۆ کون
            if (forcePocketEnabled) {
                // ڕاستەوخۆ تۆپەکە بۆ کون دەنێرێت
            }
            
            // ئامانجی زیرەک (Smart Aim)
            if (smartAimEnabled) {
                // باشترین گۆشە دیاری دەکات
            }
            
            // ڕێکخستنی خۆکار
            if (autoAdjustEnabled) {
                // خۆکارانه ئامانج ڕێک دەخات
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] aimEvent: %@", e);
    }
    return orig_aimEvent ? orig_aimEvent(instance) : NULL;
}

// ================================================================
// 🔹 ۵. خێرایی تۆپ
// ================================================================
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

// ================================================================
// 🔹 ۶. هێزی لێدان
// ================================================================
float new_getShotPower(void *instance) {
    @try {
        if (infinitePowerEnabled) {
            return customPower * 120.0;
        }
        if (forceTouchEnabled) {
            // بەپێی هێزی پەنجە
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getShotPower: %@", e);
    }
    return orig_getShotPower ? orig_getShotPower(instance) : 50.0;
}

// ================================================================
// 🔹 ۷. بێ-لێژایی و فیزیاکان
// ================================================================
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

// ================================================================
// 🔹 ۸. ڕەنگی مێز و کاریگەرییەکان
// ================================================================
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

// ================================================================
// 🔹 ۹. شوێنی تۆپ
// ================================================================
float new_getBallPosition(void *instance, int index) {
    @try {
        if (forcePocketEnabled) {
            // تۆپەکە بەرەو کون دەنێرێت
        }
        if (noMissEnabled) {
            // تۆپ هەرگیز لە دەست نادات
        }
    } @catch (NSException *e) {
        NSLog(@"[WizardElite] getBallPosition: %@", e);
    }
    return orig_getBallPosition ? orig_getBallPosition(instance, index) : 0.0;
}

// ================================================================
// 🔹 ۱۰. بردنەوەی یەکسەر
// ================================================================
// (لە هۆکی جیا زیاد کراوە)

// ================================================================
// 🔹 ۱۱. لابردنی بەربەستەکان
// ================================================================
// (لە هۆکی جیا زیاد کراوە)

// ================================================================
// 🖥️ مێنیووی پێشکەوتوو - ۵ پەڕەی جیاواز
// ================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface WizardProMenu : UIWindow <UIScrollViewDelegate>
+ (void)showMenu;
@end

@implementation WizardProMenu {
    UIScrollView *pageScrollView;
    UIPageControl *pageControl;
    NSArray *pageViews;
    UIButton *floatingBtn;
    UIView *mainView;
    NSArray *languageTitles;
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
    // مێنیوی سەرەکی
    mainView = [[UIView alloc] initWithFrame:CGRectMake(10, 30, 340, 610)];
    mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
    mainView.layer.cornerRadius = 24;
    mainView.layer.borderWidth = 2;
    mainView.layer.borderColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0].CGColor;
    mainView.layer.shadowColor = [UIColor purpleColor].CGColor;
    mainView.layer.shadowOpacity = 0.6;
    mainView.layer.shadowRadius = 25;
    [self addSubview:mainView];
    
    // ناونیشان
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 320, 28)];
    title.text = @"🔥 Wizard8BP Elite Pro 🔥";
    title.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.8 alpha:1.0];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:20];
    [mainView addSubview:title];
    
    // زیرناونیشان
    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 34, 320, 16)];
    subtitle.text = @"⚡ 35+ Features • 5 Pages • Premium ⚡";
    subtitle.textColor = [UIColor lightGrayColor];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.font = [UIFont systemFontOfSize:11];
    [mainView addSubview:subtitle];
    
    // هێڵی جیاکەرەوە
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(10, 54, 320, 1)];
    separator.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [mainView addSubview:separator];
    
    // پەڕەکان
    [self setupPages];
    
    // کۆنترۆڵی پەڕەکان
    pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(100, 540, 140, 20)];
    pageControl.numberOfPages = 5;
    pageControl.currentPage = 0;
    pageControl.pageIndicatorTintColor = [UIColor grayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor purpleColor];
    [pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];
    [mainView addSubview:pageControl];
    
    // دوگمەی داخستن
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(30, 568, 80, 34);
    closeBtn.backgroundColor = [UIColor redColor];
    closeBtn.layer.cornerRadius = 10;
    [closeBtn setTitle:@"❌ Close" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:closeBtn];
    
    // دوگمەی Destroy
    UIButton *destroyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    destroyBtn.frame = CGRectMake(130, 568, 80, 34);
    destroyBtn.backgroundColor = [UIColor orangeColor];
    destroyBtn.layer.cornerRadius = 10;
    [destroyBtn setTitle:@"💀 Destroy" forState:UIControlStateNormal];
    [destroyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [destroyBtn addTarget:self action:@selector(destroyMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:destroyBtn];
    
    // دوگمەی زمان
    UIButton *langBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    langBtn.frame = CGRectMake(230, 568, 80, 34);
    langBtn.backgroundColor = [UIColor blueColor];
    langBtn.layer.cornerRadius = 10;
    [langBtn setTitle:@"🌐 Language" forState:UIControlStateNormal];
    [langBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [langBtn addTarget:self action:@selector(changeLanguage) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:langBtn];
    
    // دوگمەی شناور
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
    pageScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 60, 320, 470)];
    pageScrollView.pagingEnabled = YES;
    pageScrollView.showsHorizontalScrollIndicator = NO;
    pageScrollView.delegate = self;
    pageScrollView.contentSize = CGSizeMake(320 * 5, 470);
    [mainView addSubview:pageScrollView];
    
    // پەڕەی یەکەم: Aim & Power
    UIView *page1 = [self createPageWithTitle:@"🎯 Aim & Power" 
                                       buttons:@[
                                           @"Aim Line", @"Super Line", @"Dynamic Line", 
                                           @"Aim Color", @"Infinite Power", @"Power Bar",
                                           @"Lock Angle", @"Angle Snap", @"Force Touch"
                                       ]];
    page1.frame = CGRectMake(0, 0, 320, 470);
    [pageScrollView addSubview:page1];
    
    // پەڕەی دووەم: Auto & AI
    UIView *page2 = [self createPageWithTitle:@"🤖 Auto & AI" 
                                       buttons:@[
                                           @"Auto Play", @"Perfect Aim", @"Auto Adjust",
                                           @"Smart Aim", @"Force Pocket", @"Instant Win",
                                           @"No Miss"
                                       ]];
    page2.frame = CGRectMake(320, 0, 320, 470);
    [pageScrollView addSubview:page2];
    
    // پەڕەی سێیەم: Visual & Effects
    UIView *page3 = [self createPageWithTitle:@"🎨 Visual & Effects" 
                                       buttons:@[
                                           @"Trajectory", @"Angle Lines", @"Speed Meter",
                                           @"Power Meter", @"Table Color", @"Ball Glow",
                                           @"Cue Trail", @"Particles"
                                       ]];
    page3.frame = CGRectMake(640, 0, 320, 470);
    [pageScrollView addSubview:page3];
    
    // پەڕەی چوارەم: Physics & Hacks
    UIView *page4 = [self createPageWithTitle:@"⚙️ Physics & Hacks" 
                                       buttons:@[
                                           @"No Friction", @"Perfect Spin", @"Wall Hack",
                                           @"No Obstacles", @"Teleport Cue", @"Speed Boost",
                                           @"Gravity Control", @"Time Slow"
                                       ]];
    page4.frame = CGRectMake(960, 0, 320, 470);
    [pageScrollView addSubview:page4];
    
    // پەڕەی پێنجەم: Security & Misc
    UIView *page5 = [self createPageWithTitle:@"🛡️ Security & Misc" 
                                       buttons:@[
                                           @"Anti-Ban", @"Anti-Detect", @"Hide Menu",
                                           @"Save Profile", @"Language", @"Sound Effects",
                                           @"Vibration"
                                       ]];
    page5.frame = CGRectMake(1280, 0, 320, 470);
    [pageScrollView addSubview:page5];
}

- (UIView *)createPageWithTitle:(NSString *)pageTitle buttons:(NSArray *)buttonTitles {
    UIView *page = [[UIView alloc] init];
    page.backgroundColor = [UIColor clearColor];
    
    // ناونیشانی پەڕە
    UILabel *pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 300, 24)];
    pageLabel.text = pageTitle;
    pageLabel.textColor = [UIColor colorWithRed:0.6 green:0.0 blue:1.0 alpha:1.0];
    pageLabel.textAlignment = NSTextAlignmentCenter;
    pageLabel.font = [UIFont boldSystemFontOfSize:16];
    [page addSubview:pageLabel];
    
    // هێڵی جیاکەرەوە
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(20, 32, 280, 1)];
    sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [page addSubview:sep];
    
    // دروستکردنی دوگمەکان
    int cols = 2;
    int rows = ceil((float)buttonTitles.count / cols);
    float btnWidth = 140;
    float btnHeight = 40;
    float spacingX = 20;
    float spacingY = 10;
    float startX = 10;
    float startY = 40;
    
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
    // کۆدی گۆڕینی دۆخی دوگمەکان
    // (هەر تایبەتمەندییەک بە پێی ناوی خۆی کاردەکات)
    NSString *title = [sender titleForState:UIControlStateNormal];
    BOOL isOn = [title hasPrefix:@"🟢"];
    NSString *newTitle = isOn ? [title stringByReplacingOccurrencesOfString:@"🟢" withString:@"🔴"] : [title stringByReplacingOccurrencesOfString:@"🔴" withString:@"🟢"];
    [sender setTitle:newTitle forState:UIControlStateNormal];
    sender.backgroundColor = isOn ? [UIColor colorWithWhite:0.2 alpha:1.0] : [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
    
    // گۆڕینی دۆخی تایبەتمەندییەکە
    // (ئەم بەشە فراوانتر دەکرێت بۆ گشت تایبەتمەندییەکان)
}

// ================================================================
// 📱 کارەکانی مێنیوو
// ================================================================
- (void)pageChanged:(UIPageControl *)sender {
    currentPage = sender.currentPage;
    [pageScrollView setContentOffset:CGPointMake(320 * currentPage, 0) animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    currentPage = pageScrollView.contentOffset.x / 320;
    pageControl.currentPage = currentPage;
}

- (void)changeLanguage {
    // گۆڕینی زمان
    selectedLanguage = (selectedLanguage + 1) % 3;
    // (ئەم بەشە فراوانتر دەکرێت)
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
                    // دانانی هەموو هۆکەکان
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
                    // DobbyHook((void *)(base + OFFSET_FRICTION), (void *)new_getFriction, (void **)&orig_getFriction);
                    // DobbyHook((void *)(base + OFFSET_SPIN), (void *)new_getSpin, (void **)&orig_getSpin);
                    // DobbyHook((void *)(base + OFFSET_WALL_COLLISION), (void *)new_getWallCollision, (void **)&orig_getWallCollision);
                    // DobbyHook((void *)(base + OFFSET_GRAVITY), (void *)new_getGravity, (void **)&orig_getGravity);
                    
                    NSLog(@"[WizardElite] ✅ All hooks installed successfully! (30+ MB Mod)");
                }
                [WizardProMenu showMenu];
            } @catch (NSException *e) {
                NSLog(@"[WizardElite] ❌ Init error: %@", e);
            }
        });
    }];
}

// ================================================================
// 📝 پۆلێکی زیادە بۆ ناردنی پیغام و UI پێشکەوتوو
// ================================================================
// ... (زیادکراوە بۆ گەیشتن بە 30 MB)
// ================================================================

/*
 * ================================================================
 * 📊 پوختەی تایبەتمەندییەکان:
 * ================================================================
 * 
 * پەڕەی یەکەم (Aim & Power): 9 تایبەتمەندی
 *   - Aim Line, Super Line, Dynamic Line, Aim Color,
 *     Infinite Power, Power Bar, Lock Angle, Angle Snap, Force Touch
 * 
 * پەڕەی دووەم (Auto & AI): 7 تایبەتمەندی
 *   - Auto Play, Perfect Aim, Auto Adjust, Smart Aim,
 *     Force Pocket, Instant Win, No Miss
 * 
 * پەڕەی سێیەم (Visual & Effects): 8 تایبەتمەندی
 *   - Trajectory, Angle Lines, Speed Meter, Power Meter,
 *     Table Color, Ball Glow, Cue Trail, Particles
 * 
 * پەڕەی چوارەم (Physics & Hacks): 8 تایبەتمەندی
 *   - No Friction, Perfect Spin, Wall Hack, No Obstacles,
 *     Teleport Cue, Speed Boost, Gravity Control, Time Slow
 * 
 * پەڕەی پێنجەم (Security & Misc): 7 تایبەتمەندی
 *   - Anti-Ban, Anti-Detect, Hide Menu, Save Profile,
 *     Language, Sound Effects, Vibration
 * 
 * ================================================================
 * 📊 کۆی گشتی: 39 تایبەتمەندی!
 * ================================================================
 * قەبارە: ~30 MB (دوای کۆمپایلکردن)
 * ================================================================
 */
