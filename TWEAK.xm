#include <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#include <string.h>

// ====================================================================
// 🛑 بێدەنگکردنی ئیرۆری وەشانە نوێیەکانی ئایۆئێس
// ====================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

// پێناسەکردنی فەنکشنی Dobby بە شێوازێکی تەواو جێگیر بۆ هەموو وەشانەکانی کۆمپایلەر
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *target_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// ==========================================
// 🎯 پێناسی ئۆفسێتەکان
// ==========================================
#define OFFSET_AIM_LINE               0x2c138UL   
#define OFFSET_POCKETS                0xec9ccUL   
#define OFFSET_AUTOPLAY               0x1318ff4UL 
#define OFFSET_TABLES                 0x118568UL  
#define OFFSET_GET_AIM_POINT          0x8e35f8UL
#define OFFSET_GET_AIM_ANGLE          0x1da9b0UL
#define OFFSET_GET_AIM_TIME           0xbb0dd0UL
#define OFFSET_GET_AIM_EVENT          0x1113d8UL
#define OFFSET_SETUP_CUE_BALL_RACK    0x6274ecUL

#define OFFSET_GENERAL_PATCH_1        0x2a3da8UL 
#define OFFSET_GENERAL_PATCH_2        0x2a3ee4UL 
#define OFFSET_FORCE_SHOW_GUIDELINE   0x11b488UL 
#define OFFSET_WIDE_LINE              0x30c2fc0UL
#define OFFSET_ANTI_BAN               0x2fdcaa0UL

// ==========================================
// 🕹️ دۆخی دوگمەکان (Booleans)
// ==========================================
static BOOL aimLineEnabled          = NO;
static BOOL pocketsEnabled          = NO;
static BOOL autoplayEnabled         = NO;
static BOOL tablesEnabled          = NO;
static BOOL customAimPointEnabled   = NO;
static BOOL customAimAngleEnabled   = NO;
static BOOL infinityAimTimeEnabled  = NO;
static BOOL customRackEnabled       = NO;
static BOOL customAimEventEnabled   = NO; 
static BOOL generalPatchEnabled     = NO;
static BOOL forceShowGuideEnabled   = NO;
static BOOL wideLineEnabled         = NO;
static BOOL antiBanEnabled          = NO;

// ==========================================
// 🛠️ فەنکشنەکانی جێگرەوە (Hooks Logic)
// ==========================================

bool (*old_isAimCorrect)(void* instance);
bool new_isAimCorrect(void* instance) {
    if (aimLineEnabled) return true; 
    return old_isAimCorrect(instance);
}

bool (*old_getPocketAimPoints)(void* instance);
bool new_getPocketAimPoints(void* instance) {
    if (pocketsEnabled) return true;
    return old_getPocketAimPoints(instance);
}

bool (*old_isAutoplayEnabled)(void* instance);
bool new_isAutoplayEnabled(void* instance) {
    if (autoplayEnabled) return true;
    return old_isAutoplayEnabled(instance);
}

bool (*old_tablesBypass)(void* instance);
bool new_tablesBypass(void* instance) {
    if (tablesEnabled) return true;
    return old_tablesBypass(instance);
}

void* (*old_getAimPoint)(void* instance, void* param1, void* param2, void* param3);
void* new_getAimPoint(void* instance, void* param1, void* param2, void* param3) {
    return old_getAimPoint(instance, param1, param2, param3);
}

double (*old_getAimAngleTarget)(void* instance, void* param2);
double new_getAimAngleTarget(void* instance, void* param2) {
    if (customAimAngleEnabled) return 0.0; 
    return old_getAimAngleTarget(instance, param2);
}

double (*old_getAimTimePerShot)(void* instance, void* param2);
double new_getAimTimePerShot(void* instance, void* param2) {
    if (infinityAimTimeEnabled) return 9999.0; 
    return old_getAimTimePerShot(instance, param2);
}

void (*old_setupCueBallRack)(void* instance, void* param2);
void new_setupCueBallRack(void* instance, void* param2) {
    old_setupCueBallRack(instance, param2);
}

void* (*old_getAimEvent)(void* instance, void* param1, void* param2, int param3);
void* new_getAimEvent(void* instance, void* param1, void* param2, int param3) {
    return old_getAimEvent(instance, param1, param2, param3);
}

bool (*old_generalPatch1)(void* instance);
bool new_generalPatch1(void* instance) {
    if (generalPatchEnabled) return true;
    return old_generalPatch1(instance);
}

bool (*old_generalPatch2)(void* instance);
bool new_generalPatch2(void* instance) {
    if (generalPatchEnabled) return true;
    return old_generalPatch2(instance);
}

bool (*old_forceShowGuideline)(void* instance);
bool new_forceShowGuideline(void* instance) {
    if (forceShowGuideEnabled) return true;
    return old_forceShowGuideline(instance);
}

bool (*old_wideLine)(void* instance);
bool new_wideLine(void* instance) {
    if (wideLineEnabled) return true;
    return old_wideLine(instance);
}

bool (*old_antiBan)(void* instance);
bool new_antiBan(void* instance) {
    if (antiBanEnabled) return true;
    return old_antiBan(instance);
}

// ====================================================================
//  ڕووکاری بەکارهێنەر (Mod Menu Interface)
// ====================================================================
@interface ModMenuWindow : UIWindow
+ (void)showMenu;
+ (void)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag yPos:(CGFloat)y action:(SEL)action;
+ (void)toggleAim:(UIButton *)sender;
+ (void)togglePockets:(UIButton *)sender;
+ (void)toggleAutoplay:(UIButton *)sender;
+ (void)toggleTables:(UIButton *)sender;
+ (void)toggleAimPoint:(UIButton *)sender;
+ (void)toggleAimAngle:(UIButton *)sender;
+ (void)toggleAimTime:(UIButton *)sender;
+ (void)toggleRack:(UIButton *)sender;
+ (void)toggleAimEvent:(UIButton *)sender;
+ (void)toggleAntiBan:(UIButton *)sender;
+ (void)toggleWideLine:(UIButton *)sender;
+ (void)toggleForceGuide:(UIButton *)sender;
+ (void)toggleGeneralPatch:(UIButton *)sender;
+ (void)hideMenu;
+ (void)showFromFloating;
+ (void)dragButton:(UIPanGestureRecognizer *)gesture;
@end

@implementation ModMenuWindow
static ModMenuWindow *menuInstance = nil;
static UIView *mainMenuView = nil;
static UIScrollView *buttonScrollView = nil;
static UIButton *floatingButton = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!menuInstance) {
            menuInstance = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelStatusBar + 1000.0;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.userInteractionEnabled = YES;
            menuInstance.hidden = NO;
            
            mainMenuView = [[UIView alloc] initWithFrame:CGRectMake(60, 80, 250, 480)];
            mainMenuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
            mainMenuView.layer.cornerRadius = 16;
            mainMenuView.layer.borderWidth = 2;
            mainMenuView.layer.borderColor = [UIColor purpleColor].CGColor;
            [menuInstance addSubview:mainMenuView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 230, 35)];
            titleLabel.text = @"🎱 80p Kurdish Menu V4";
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.font = [UIFont boldSystemFontOfSize:18];
            [mainMenuView addSubview:titleLabel];
            
            buttonScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5, 60, 240, 350)];
            buttonScrollView.contentSize = CGSizeMake(240, 670); 
            buttonScrollView.showsVerticalScrollIndicator = YES;
            [mainMenuView addSubview:buttonScrollView];
            
            [self createButtonWithTitle:@"دەرکەوتنی خەت: OFF" tag:1 yPos:5 action:@selector(toggleAim:)];
            [self createButtonWithTitle:@"کونی ساحەکان: OFF" tag:2 yPos:55 action:@selector(togglePockets:)];
            [self createButtonWithTitle:@"ئەوتۆ پلەی: OFF" tag:3 yPos:105 action:@selector(toggleAutoplay:)];
            [self createButtonWithTitle:@"ساحەکان: OFF" tag:4 yPos:155 action:@selector(toggleTables:)];
            [self createButtonWithTitle:@"ڕێڕەوی نیشانە: OFF" tag:5 yPos:205 action:@selector(toggleAimPoint:)];
            [self createButtonWithTitle:@"گۆشەی ئامانج: OFF" tag:6 yPos:255 action:@selector(toggleAimAngle:)];
            [self createButtonWithTitle:@"کاتی بێکۆتایی: OFF" tag:7 yPos:305 action:@selector(toggleAimTime:)];
            [self createButtonWithTitle:@"ڕێکخستنی تۆپ: OFF" tag:8 yPos:355 action:@selector(toggleRack:)];
            [self createButtonWithTitle:@"کۆنترۆڵی لێدان: OFF" tag:9 yPos:405 action:@selector(toggleAimEvent:)]; 
            [self createButtonWithTitle:@"ئەنتی بان (Anti-Ban): OFF" tag:10 yPos:455 action:@selector(toggleAntiBan:)]; 
            [self createButtonWithTitle:@"هێڵی پان (Wide Line): OFF" tag:11 yPos:505 action:@selector(toggleWideLine:)]; 
            [self createButtonWithTitle:@"دەرخستنی زۆرەملێ: OFF" tag:12 yPos:555 action:@selector(toggleForceGuide:)]; 
            [self createButtonWithTitle:@"پاتچی گشتی: OFF" tag:13 yPos:605 action:@selector(toggleGeneralPatch:)]; 
            
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            closeBtn.frame = CGRectMake(20, 420, 210, 40);
            closeBtn.backgroundColor = [UIColor redColor];
            closeBtn.layer.cornerRadius = 8;
            [closeBtn setTitle:@"داخستنی مینو" forState:UIControlStateNormal];
            [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
            [mainMenuView addSubview:closeBtn];
            
            floatingButton = [UIButton buttonWithType:UIButtonTypeSystem];
            floatingButton.frame = CGRectMake(15, 120, 55, 55);
            floatingButton.backgroundColor = [UIColor purpleColor];
            floatingButton.layer.cornerRadius = 27.5;
            [floatingButton setTitle:@"80p" forState:UIControlStateNormal];
            [floatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatingButton addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
            
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragButton:)];
            [floatingButton addGestureRecognizer:panGesture];
            [menuInstance addSubview:floatingButton];
            floatingButton.hidden = YES;
        }
    });
}

+ (void)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag yPos:(CGFloat)y action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(15, y, 210, 45);
    btn.backgroundColor = [UIColor grayColor];
    btn.layer.cornerRadius = 8;
    btn.tag = tag;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [buttonScrollView addSubview:btn];
}

+ (void)toggleAim:(UIButton *)sender { aimLineEnabled = !aimLineEnabled; sender.backgroundColor = aimLineEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:aimLineEnabled ? @"دەرکەوتنی خەت: ON" : @"دەرکەوتنی خەت: OFF" forState:UIControlStateNormal]; }
+ (void)togglePockets:(UIButton *)sender { pocketsEnabled = !pocketsEnabled; sender.backgroundColor = pocketsEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:pocketsEnabled ? @"کونی ساحەکان: ON" : @"کونی ساحەکان: OFF" forState:UIControlStateNormal]; }
+ (void)toggleAutoplay:(UIButton *)sender { autoplayEnabled = !autoplayEnabled; sender.backgroundColor = autoplayEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:autoplayEnabled ? @"ئەوتۆ پلەی: ON" : @"ئەوتۆ پلەی: OFF" forState:UIControlStateNormal]; }
+ (void)toggleTables:(UIButton *)sender { tablesEnabled = !tablesEnabled; sender.backgroundColor = tablesEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:tablesEnabled ? @"ساحەکان: ON" : @"ساحەکان: OFF" forState:UIControlStateNormal]; }
+ (void)toggleAimPoint:(UIButton *)sender { customAimPointEnabled = !customAimPointEnabled; sender.backgroundColor = customAimPointEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:customAimPointEnabled ? @"ڕێڕەوی نیشانە: ON" : @"ڕێڕەوی نیشانە: OFF" forState:UIControlStateNormal]; }
+ (void)toggleAimAngle:(UIButton *)sender { customAimAngleEnabled = !customAimAngleEnabled; sender.backgroundColor = customAimAngleEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:customAimAngleEnabled ? @"گۆشەی ئامانج: ON" : @"گۆشەی ئامانج: OFF" forState:UIControlStateNormal]; }
+ (void)toggleAimTime:(UIButton *)sender { infinityAimTimeEnabled = !infinityAimTimeEnabled; sender.backgroundColor = infinityAimTimeEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:infinityAimTimeEnabled ? @"کاتی بێکۆتایی: ON" : @"کاتی بێکۆتایی: OFF" forState:UIControlStateNormal]; }
+ (void)toggleRack:(UIButton *)sender { customRackEnabled = !customRackEnabled; sender.backgroundColor = customRackEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:customRackEnabled ? @"ڕێکخستنی تۆپ: ON" : @"ڕێکخستنی تۆپ: OFF" forState:UIControlStateNormal]; }
+ (void)toggleAimEvent:(UIButton *)sender { customAimEventEnabled = !customAimEventEnabled; sender.backgroundColor = customAimEventEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:customAimEventEnabled ? @"کۆنترۆڵی لێدان: ON" : @"کۆنترۆڵی لێدان: OFF" forState:UIControlStateNormal]; }
+ (void)toggleAntiBan:(UIButton *)sender { antiBanEnabled = !antiBanEnabled; sender.backgroundColor = antiBanEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:antiBanEnabled ? @"ئەنتی بان (Anti-Ban): ON" : @"ئەنتی بان (Anti-Ban): OFF" forState:UIControlStateNormal]; }
+ (void)toggleWideLine:(UIButton *)sender { wideLineEnabled = !wideLineEnabled; sender.backgroundColor = wideLineEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:wideLineEnabled ? @"هێڵی پان (Wide Line): ON" : @"هێڵی پان (Wide Line): OFF" forState:UIControlStateNormal]; }
+ (void)toggleForceGuide:(UIButton *)sender { forceShowGuideEnabled = !forceShowGuideEnabled; sender.backgroundColor = forceShowGuideEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:forceShowGuideEnabled ? @"دەرخستنی زۆرەملێ: ON" : @"دەرخستنی زۆرەملێ: OFF" forState:UIControlStateNormal]; }
+ (void)toggleGeneralPatch:(UIButton *)sender { generalPatchEnabled = !generalPatchEnabled; sender.backgroundColor = generalPatchEnabled ? [UIColor greenColor] : [UIColor grayColor]; [sender setTitle:generalPatchEnabled ? @"پاتچی گشتی: ON" : @"پاتچی گشتی: OFF" forState:UIControlStateNormal]; }

+ (void)hideMenu {
    if (mainMenuView) mainMenuView.hidden = YES;
    if (floatingButton) floatingButton.hidden = NO;
}
+ (void)showFromFloating {
    if (mainMenuView) mainMenuView.hidden = NO;
    if (floatingButton) floatingButton.hidden = YES;
}
+ (void)dragButton:(UIPanGestureRecognizer *)gesture {
    if (!menuInstance || !gesture.view) return;
    CGPoint translation = [gesture translationInView:menuInstance];
    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x, gesture.view.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:menuInstance];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}
@end

// ==========================================
// 🚀 لۆدبوونی ئۆتۆماتیکی هوکەکان
// ==========================================
__attribute__((constructor)) static void initMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            uintptr_t baseAddress = (uintptr_t)_dyld_get_image_header(0); 
            
            if (baseAddress) {
                // بەکارهێنانی کاستی جێگیر بۆ ڕێگری لە گرتنی ئیرۆری پۆینتەر لە زمانی C++
                DobbyHook((void *)(baseAddress + OFFSET_AIM_LINE), (void *)new_isAimCorrect, (void **)(uintptr_t)&old_isAimCorrect);
                DobbyHook((void *)(baseAddress + OFFSET_POCKETS), (void *)new_getPocketAimPoints, (void **)(uintptr_t)&old_getPocketAimPoints);
                DobbyHook((void *)(baseAddress + OFFSET_AUTOPLAY), (void *)new_isAutoplayEnabled, (void **)(uintptr_t)&old_isAutoplayEnabled);
                DobbyHook((void *)(baseAddress + OFFSET_TABLES), (void *)new_tablesBypass, (void **)(uintptr_t)&old_tablesBypass);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_POINT), (void *)new_getAimPoint, (void **)(uintptr_t)&old_getAimPoint);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_ANGLE), (void *)new_getAimAngleTarget, (void **)(uintptr_t)&old_getAimAngleTarget);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_TIME), (void *)new_getAimTimePerShot, (void **)(uintptr_t)&old_getAimTimePerShot);
                DobbyHook((void *)(baseAddress + OFFSET_SETUP_CUE_BALL_RACK), (void *)new_setupCueBallRack, (void **)(uintptr_t)&old_setupCueBallRack);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_EVENT), (void *)new_getAimEvent, (void **)(uintptr_t)&old_getAimEvent);

                DobbyHook((void *)(baseAddress + OFFSET_GENERAL_PATCH_1), (void *)new_generalPatch1, (void **)(uintptr_t)&old_generalPatch1);
                DobbyHook((void *)(baseAddress + OFFSET_GENERAL_PATCH_2), (void *)new_generalPatch2, (void **)(uintptr_t)&old_generalPatch2);
                DobbyHook((void *)(baseAddress + OFFSET_FORCE_SHOW_GUIDELINE), (void *)new_forceShowGuideline, (void **)(uintptr_t)&old_forceShowGuideline);
                DobbyHook((void *)(baseAddress + OFFSET_WIDE_LINE), (void *)new_wideLine, (void **)(uintptr_t)&old_wideLine);
                DobbyHook((void *)(baseAddress + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)(uintptr_t)&old_antiBan);
            }
            [ModMenuWindow showMenu];
        });
    }];
}

#pragma clang diagnostic pop
