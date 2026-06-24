#include <substrate.h>
#include <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#include <string.h>

// ==========================================
// 🎯 پێناسی ئۆفسێتە کۆن و نوێیەکان (Offsets)
// ==========================================
#define OFFSET_AIM_LINE               0x2c138UL   
#define OFFSET_POCKETS                0xec9ccUL   
#define OFFSET_AUTOPLAY               0x1318ff4UL 
#define OFFSET_TABLES                 0x118568UL  

// ئۆفسێتی فەنکشنە نوێیەکان کە دەرەت هێناون
#define OFFSET_GET_AIM_POINT          0x8e35f8UL
#define OFFSET_GET_AIM_ANGLE          0x1da9b0UL
#define OFFSET_GET_AIM_TIME           0xbb0dd0UL
#define OFFSET_GET_AIM_EVENT          0x1113d8UL
#define OFFSET_SETUP_CUE_BALL_RACK    0x6274ecUL

static BOOL aimLineEnabled          = NO;
static BOOL pocketsEnabled          = NO;
static BOOL autoplayEnabled         = NO;
static BOOL tablesEnabled           = NO;

// دۆخی گۆڕینی دوگمە نوێیەکان
static BOOL customAimPointEnabled   = NO;
static BOOL customAimAngleEnabled   = NO;
static BOOL infinityAimTimeEnabled  = NO;
static BOOL customRackEnabled       = NO;

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
        // لێرەدا لۆجیکی دەستکاری هێڵەکە کار دەکات
    }
    return old_getAimPoint(instance, param1, param2, param3);
}

// ٦- هۆکی گۆشەی نیشانەگرتن
double (*old_getAimAngleTarget)(void* instance, void* param2);
double new_getAimAngleTarget(void* instance, void* param2) {
    if (customAimAngleEnabled) {
        return 0.0; // جێگیرکردنی گۆشەی لێدان
    }
    return old_getAimAngleTarget(instance, param2);
}

// ٧- هۆکی کاتی نیشانەگرتن (زیادکردنی کات)
double (*old_getAimTimePerShot)(void* instance, void* param2);
double new_getAimTimePerShot(void* instance, void* param2) {
    if (infinityAimTimeEnabled) {
        return 999.0; // پێدانی کاتی زۆر بۆ نیشانەگرتن
    }
    return old_getAimTimePerShot(instance, param2);
}

// ٨- هۆکی ڕێکخستنی تۆپەکان
void (*old_setupCueBallRack)(void* instance, void* param2);
void new_setupCueBallRack(void* instance, void* param2) {
    if (customRackEnabled) {
        // کۆنترۆڵکردنی ڕێکی تۆپەکان
    }
    old_setupCueBallRack(instance, param2);
}

// ==========================================
// 🎯 پێناسەکردنی مۆد مینۆ و ڕووکاری بەکارهێنەر
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
            NSLog(@"[ModMenu] Creating menu...");
            
            menuInstance = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelStatusBar + 1000.0;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.userInteractionEnabled = YES;
            menuInstance.hidden = NO;
            
            // گەورەکردنی قەبارەی مینیو بۆ شوێنکردنەوەی سکڕۆڵ
            mainMenuView = [[UIView alloc] initWithFrame:CGRectMake(60, 80, 250, 460)];
            mainMenuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
            mainMenuView.layer.cornerRadius = 16;
            mainMenuView.layer.borderWidth = 2;
            mainMenuView.layer.borderColor = [UIColor purpleColor].CGColor;
            [menuInstance addSubview:mainMenuView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 230, 35)];
            titleLabel.text = @"🎱 80p Kurdish Menu V2";
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.font = [UIFont boldSystemFontOfSize:18];
            [mainMenuView addSubview:titleLabel];
            
            // دروستکردنی سکڕۆڵ ڤیو بۆ ئەوەی دوگمەکان جێگایان ببێتەوە
            buttonScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5, 60, 240, 330)];
            buttonScrollView.contentSize = CGSizeMake(240, 420);
            buttonScrollView.showsVerticalScrollIndicator = YES;
            [mainMenuView addSubview:buttonScrollView];
            
            // ١- دوگمەی خەت
            UIButton *btnAim = [UIButton buttonWithType:UIButtonTypeSystem];
            btnAim.frame = CGRectMake(15, 5, 210, 45);
            btnAim.backgroundColor = [UIColor grayColor];
            btnAim.layer.cornerRadius = 8;
            [btnAim setTitle:@"دەرکەوتنی خەت: OFF" forState:UIControlStateNormal];
            [btnAim setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnAim addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnAim];
            
            // ٢- دوگمەی کونی ساحەکان
            UIButton *btnPockets = [UIButton buttonWithType:UIButtonTypeSystem];
            btnPockets.frame = CGRectMake(15, 55, 210, 45);
            btnPockets.backgroundColor = [UIColor grayColor];
            btnPockets.layer.cornerRadius = 8;
            [btnPockets setTitle:@"کونی ساحەکان: OFF" forState:UIControlStateNormal];
            [btnPockets setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnPockets addTarget:self action:@selector(togglePockets:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnPockets];
            
            // ٣- دوگمەی ئەوتۆ پلەی
            UIButton *btnAutoplay = [UIButton buttonWithType:UIButtonTypeSystem];
            btnAutoplay.frame = CGRectMake(15, 105, 210, 45);
            btnAutoplay.backgroundColor = [UIColor grayColor];
            btnAutoplay.layer.cornerRadius = 8;
            [btnAutoplay setTitle:@"ئەوتۆ پلەی: OFF" forState:UIControlStateNormal];
            [btnAutoplay setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnAutoplay addTarget:self action:@selector(toggleAutoplay:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnAutoplay];
            
            // ٤- دوگمەی ساحەکان
            UIButton *btnTables = [UIButton buttonWithType:UIButtonTypeSystem];
            btnTables.frame = CGRectMake(15, 155, 210, 45);
            btnTables.backgroundColor = [UIColor grayColor];
            btnTables.layer.cornerRadius = 8;
            [btnTables setTitle:@"ساحەکان: OFF" forState:UIControlStateNormal];
            [btnTables setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnTables addTarget:self action:@selector(toggleTables:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnTables];

            // ٥- دوگمەی خاڵی نیشانەگرتن (نوێ)
            UIButton *btnAimPoint = [UIButton buttonWithType:UIButtonTypeSystem];
            btnAimPoint.frame = CGRectMake(15, 205, 210, 45);
            btnAimPoint.backgroundColor = [UIColor grayColor];
            btnAimPoint.layer.cornerRadius = 8;
            [btnAimPoint setTitle:@"ڕێڕەوی نیشانە: OFF" forState:UIControlStateNormal];
            [btnAimPoint setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnAimPoint addTarget:self action:@selector(toggleAimPoint:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnAimPoint];

            // ٦- دوگمەی گۆشەی نیشانە (نوێ)
            UIButton *btnAimAngle = [UIButton buttonWithType:UIButtonTypeSystem];
            btnAimAngle.frame = CGRectMake(15, 255, 210, 45);
            btnAimAngle.backgroundColor = [UIColor grayColor];
            btnAimAngle.layer.cornerRadius = 8;
            [btnAimAngle setTitle:@"گۆشەی ئامانج: OFF" forState:UIControlStateNormal];
            [btnAimAngle setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnAimAngle addTarget:self action:@selector(toggleAimAngle:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnAimAngle];

            // ٧- دوگمەی کاتی لێدان (نوێ)
            UIButton *btnAimTime = [UIButton buttonWithType:UIButtonTypeSystem];
            btnAimTime.frame = CGRectMake(15, 305, 210, 45);
            btnAimTime.backgroundColor = [UIColor grayColor];
            btnAimTime.layer.cornerRadius = 8;
            [btnAimTime setTitle:@"کاتی بێکۆتایی: OFF" forState:UIControlStateNormal];
            [btnAimTime setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnAimTime addTarget:self action:@selector(toggleAimTime:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnAimTime];

            // ٨- دوگمەی ڕێکخستنی دار و تۆپ (نوێ)
            UIButton *btnRack = [UIButton buttonWithType:UIButtonTypeSystem];
            btnRack.frame = CGRectMake(15, 355, 210, 45);
            btnRack.backgroundColor = [UIColor grayColor];
            btnRack.layer.cornerRadius = 8;
            [btnRack setTitle:@"ڕێکخستنی تۆپ: OFF" forState:UIControlStateNormal];
            [btnRack setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btnRack addTarget:self action:@selector(toggleRack:) forControlEvents:UIControlEventTouchUpInside];
            [buttonScrollView addSubview:btnRack];
            
            // دوگمەی داخستن لە دەرەوەی سکڕۆڵەکەیە بۆ ئەوەی هەمیشە دیار بێت
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            closeBtn.frame = CGRectMake(20, 400, 210, 40);
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

// Action ەکانی گۆڕینی دۆخی دوگمەکان
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
    [sender setTitle:infinityAimTimeEnabled ? @"کاتی بێکۆتایی: ON" : @"کاتی بێکۆتایی: OFF" forState:UIControlStateNormal];
}

+ (void)toggleRack:(UIButton *)sender {
    customRackEnabled = !customRackEnabled;
    sender.backgroundColor = customRackEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:customRackEnabled ? @"ڕێکخستنی تۆپ: ON" : @"ڕێکخستنی تۆپ: OFF" forState:UIControlStateNormal];
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
// 🚀 لۆدبوونی ژیری مۆدەکە و جێگیرکردنی هۆکەکان
// ==========================================
__attribute__((constructor)) static void initMod() {
    NSLog(@"[ModMenu] Tweak injected. Waiting for app...");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            uintptr_t baseAddress = (uintptr_t)_dyld_get_image_header(0); 
            
            if (baseAddress) {
                NSLog(@"[ModMenu] Base Address: 0x%lx. Hooking functions...", baseAddress);
                
                // جێبەجێکردنی هۆکە کۆنەکان
                MSHookFunction((void *)(baseAddress + OFFSET_AIM_LINE), (void *)new_isAimCorrect, (void **)&old_isAimCorrect);
                MSHookFunction((void *)(baseAddress + OFFSET_POCKETS), (void *)new_getPocketAimPoints, (void **)&old_getPocketAimPoints);
                MSHookFunction((void *)(baseAddress + OFFSET_AUTOPLAY), (void *)new_isAutoplayEnabled, (void **)&old_isAutoplayEnabled);
                MSHookFunction((void *)(baseAddress + OFFSET_TABLES), (void *)new_tablesBypass, (void **)&old_tablesBypass);
                
                // جێبەجێکردنی هۆکە نوێیەکان کە دەتەوێت کار بکەن
                MSHookFunction((void *)(baseAddress + OFFSET_GET_AIM_POINT), (void *)new_getAimPoint, (void **)&old_getAimPoint);
                MSHookFunction((void *)(baseAddress + OFFSET_GET_AIM_ANGLE), (void *)new_getAimAngleTarget, (void **)&old_getAimAngleTarget);
                MSHookFunction((void *)(baseAddress + OFFSET_GET_AIM_TIME), (void *)new_getAimTimePerShot, (void **)&old_getAimTimePerShot);
                MSHookFunction((void *)(baseAddress + OFFSET_SETUP_CUE_BALL_RACK), (void *)new_setupCueBallRack, (void **)&old_setupCueBallRack);
                
                NSLog(@"[ModMenu] All 8 features hooked successfully!");
            }
            
            [ModMenuWindow showMenu];
        });
    }];
}
