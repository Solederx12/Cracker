#include "dobby.h" // زیادکردنی کتێبخانەی دۆبی لەجیاتی سوبسترەیت
#include <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#include <string.h>

// ==========================================
// 🎯 پێناسی ئۆفسێتەکان (Offsets & Base Addresses)
// ==========================================

// -- ئۆفسێتە کۆنەکان --
#define OFFSET_AIM_LINE               0x2c138UL   
#define OFFSET_POCKETS                0xec9ccUL   
#define OFFSET_AUTOPLAY               0x1318ff4UL 
#define OFFSET_TABLES                 0x118568UL  

// -- ئۆفسێتە نوێیەکانی فەنکشن (Executable Hooks) --
#define OFFSET_GET_AIM_POINT          0x8e35f8UL
#define OFFSET_GET_AIM_ANGLE          0x1da9b0UL
#define OFFSET_GET_AIM_TIME           0xbb0dd0UL
#define OFFSET_GET_AIM_EVENT          0x1113d8UL
#define OFFSET_SETUP_CUE_BALL_RACK    0x6274ecUL

// ==========================================
// 🎛️ دۆخی دوگمەکان (Booleans)
// ==========================================
static BOOL aimLineEnabled          = NO;
static BOOL pocketsEnabled          = NO;
static BOOL autoplayEnabled         = NO;
static BOOL tablesEnabled           = NO;
static BOOL customAimPointEnabled   = NO;
static BOOL customAimAngleEnabled   = NO;
static BOOL infinityAimTimeEnabled  = NO;
static BOOL customRackEnabled       = NO;
static BOOL customAimEventEnabled   = NO; 

// ==========================================
// 🛠️ فەنکشنەکانی هۆک (Detours)
// ==========================================

// ١- هۆکی دەرکەوتنی خەت
bool (*old_isAimCorrect)(void* instance);
bool new_isAimCorrect(void* instance) {
    if (aimLineEnabled) return true; 
    return old_isAimCorrect(instance);
}

// ٢- هۆکی کونی ساحەکان
bool (*old_getPocketAimPoints)(void* instance);
bool new_getPocketAimPoints(void* instance) {
    if (pocketsEnabled) return true;
    return old_getPocketAimPoints(instance);
}

// ٣- هۆکی ئەوتۆ پلەی
bool (*old_isAutoplayEnabled)(void* instance);
bool new_isAutoplayEnabled(void* instance) {
    if (autoplayEnabled) return true;
    return old_isAutoplayEnabled(instance);
}

// ٤- هۆکی گۆڕینی ساحەکان
bool (*old_tablesBypass)(void* instance);
bool new_tablesBypass(void* instance) {
    if (tablesEnabled) return true;
    return old_tablesBypass(instance);
}

// ٥- هۆکی خاڵی نیشانەگرتنی سەر مێز
void* (*old_getAimPoint)(void* instance, void* param1, void* param2, void* param3);
void* new_getAimPoint(void* instance, void* param1, void* param2, void* param3) {
    if (customAimPointEnabled) {
        // لۆجیکی دەستکاری خاڵی لێدان
    }
    return old_getAimPoint(instance, param1, param2, param3);
}

// ٦- هۆکی گۆشەی نیشانەگرتن
double (*old_getAimAngleTarget)(void* instance, void* param2);
double new_getAimAngleTarget(void* instance, void* param2) {
    if (customAimAngleEnabled) {
        return 0.0; 
    }
    return old_getAimAngleTarget(instance, param2);
}

// ٧- هۆکی کاتی نیشانەگرتن
double (*old_getAimTimePerShot)(void* instance, void* param2);
double new_getAimTimePerShot(void* instance, void* param2) {
    if (infinityAimTimeEnabled) {
        return 9999.0; 
    }
    return old_getAimTimePerShot(instance, param2);
}

// ٨- هۆکی ڕێکخستنی تۆپەکان لەسەر مێز
void (*old_setupCueBallRack)(void* instance, void* param2);
void new_setupCueBallRack(void* instance, void* param2) {
    if (customRackEnabled) {
        // کۆنترۆڵکردنی ڕێکی تۆپەکان
    }
    old_setupCueBallRack(instance, param2);
}

// ٩- هۆکی کۆنترۆڵکردنی ڕووداوی لێدان
void* (*old_getAimEvent)(void* instance, void* param1, void* param2, int param3);
void* new_getAimEvent(void* instance, void* param1, void* param2, int param3) {
    if (customAimEventEnabled) {
        // لۆجیکی تایبەت بە ڕووداوی خەت و لێدان
    }
    return old_getAimEvent(instance, param1, param2, param3);
}

// ==========================================
// 🎯 ڕووکاری بەکارهێنەر (Mod Menu)
// ==========================================
@interface ModMenuWindow : UIWindow
+ (void)showMenu;
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
            titleLabel.text = @"🎱 80p Kurdish Menu V3";
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.font = [UIFont boldSystemFontOfSize:18];
            [mainMenuView addSubview:titleLabel];
            
            buttonScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5, 60, 240, 350)];
            buttonScrollView.contentSize = CGSizeMake(240, 470);
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

+ (void)toggleAim:(UIButton *)sender {
    aimLineEnabled = !aimLineEnabled;
    sender.backgroundColor = aimLineEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:aimLineEnabled ? @"دەرکەوتنی خەت: ON" : @"دەرکەوتنی خەت: OFF" forState:UIControlStateNormal];
}
+ (void)togglePockets:(UIButton *)sender {
    pocketsEnabled = !pocketsEnabled;
    sender.backgroundColor = pocketsEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:pocketsEnabled ? @"کونی ساحەکان: ON" : @"کونی ساحەکان: OFF" forState:UIControlStateNormal];
}
+ (void)toggleAutoplay:(UIButton *)sender {
    autoplayEnabled = !autoplayEnabled;
    sender.backgroundColor = autoplayEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:autoplayEnabled ? @"ئەوتۆ پلەی: ON" : @"ئەوتۆ پلەی: OFF" forState:UIControlStateNormal];
}
+ (void)toggleTables:(UIButton *)sender {
    tablesEnabled = !tablesEnabled;
    sender.backgroundColor = tablesEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:tablesEnabled ? @"ساحەکان: ON" : @"ساحەکان: OFF" forState:UIControlStateNormal];
}
+ (void)toggleAimPoint:(UIButton *)sender {
    customAimPointEnabled = !customAimPointEnabled;
    sender.backgroundColor = customAimPointEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:customAimPointEnabled ? @"ڕێڕەوی نیشانە: ON" : @"ڕێڕەوی نیشانە: OFF" forState:UIControlStateNormal];
}
+ (void)toggleAimAngle:(UIButton *)sender {
    customAimAngleEnabled = !customAimAngleEnabled;
    sender.backgroundColor = customAimAngleEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:customAimAngleEnabled ? @"گۆشەی ئامانج: ON" : @"گۆشەی ئامانج: OFF" forState:UIControlStateNormal];
}
+ (void)toggleAimTime:(UIButton *)sender {
    infinityAimTimeEnabled = !infinityAimTimeEnabled;
    sender.backgroundColor = infinityAimTimeEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:infinityAimTimeEnabled ? @"کاتی bێکۆتایی: ON" : @"کاتی bێکۆتایی: OFF" forState:UIControlStateNormal];
}
+ (void)toggleRack:(UIButton *)sender {
    customRackEnabled = !customRackEnabled;
    sender.backgroundColor = customRackEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:customRackEnabled ? @"ڕێکخستنی تۆپ: ON" : @"ڕێکخستنی تۆپ: OFF" forState:UIControlStateNormal];
}
+ (void)toggleAimEvent:(UIButton *)sender {
    customAimEventEnabled = !customAimEventEnabled;
    sender.backgroundColor = customAimEventEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:customAimEventEnabled ? @"کۆنترۆڵی لێدان: ON" : @"کۆنترۆڵی لێدان: OFF" forState:UIControlStateNormal];
}

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
// 🚀 لۆدبوونی ئۆتۆماتیکی و جێگیرکردنی هوکەکان بە Dobby
// ==========================================
__attribute__((constructor)) static void initMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // وەرگرتنی ناونیشانی سەرەکی یارییەکە لە مێمۆریدا
            uintptr_t baseAddress = (uintptr_t)_dyld_get_image_header(0); 
            
            if (baseAddress) {
                // جێگیرکردنی هۆکەکان بە بەکارهێنانی DobbyHook لەجیاتی MSHookFunction
                DobbyHook((void *)(baseAddress + OFFSET_AIM_LINE), (void *)new_isAimCorrect, (void **)&old_isAimCorrect);
                DobbyHook((void *)(baseAddress + OFFSET_POCKETS), (void *)new_getPocketAimPoints, (void **)&old_getPocketAimPoints);
                DobbyHook((void *)(baseAddress + OFFSET_AUTOPLAY), (void *)new_isAutoplayEnabled, (void **)&old_isAutoplayEnabled);
                DobbyHook((void *)(baseAddress + OFFSET_TABLES), (void *)new_tablesBypass, (void **)&old_tablesBypass);
                
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_POINT), (void *)new_getAimPoint, (void **)&old_getAimPoint);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_ANGLE), (void *)new_getAimAngleTarget, (void **)&old_getAimAngleTarget);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_TIME), (void *)new_getAimTimePerShot, (void **)&old_getAimTimePerShot);
                DobbyHook((void *)(baseAddress + OFFSET_SETUP_CUE_BALL_RACK), (void *)new_setupCueBallRack, (void **)&old_setupCueBallRack);
                DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_EVENT), (void *)new_getAimEvent, (void **)&old_getAimEvent);
            }
            [ModMenuWindow showMenu];
        });
    }];
}
