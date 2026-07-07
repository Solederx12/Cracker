#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>

// ====================================================================
// 📌 ئۆفسێتەکان - پێویستە خۆت بدۆزیتەوە بۆ ڤێرشنی 56.26.1
// ====================================================================
#define OFFSET_AIM_LINE              0x0 // بگۆڕە
#define OFFSET_CUE_POWER             0x0
#define OFFSET_GET_AIM_EVENT         0x0
#define OFFSET_ANTI_BAN              0x0

// ====================================================================
// دۆخی دوگمەکان
// ====================================================================
static BOOL aimLineEnabled = NO;
static BOOL antiBanEnabled = NO;

// ====================================================================
// پێناسەکردنی Dobby Hook
// ====================================================================
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *target, void *replace, void **origin);
#ifdef __cplusplus
}
#endif

// ====================================================================
// Hookەکان
// ====================================================================
bool (*orig_isAimCorrect)(void *instance);
bool (*orig_antiBan)(void *instance);
void* (*orig_getAimEvent)(void *instance);

bool new_isAimCorrect(void *instance) {
    @try {
        if (aimLineEnabled) return YES;
    } @catch (NSException *e) {
        NSLog(@"[Mod] isAimCorrect: %@", e);
    }
    return orig_isAimCorrect ? orig_isAimCorrect(instance) : YES;
}

bool new_antiBan(void *instance) {
    @try {
        if (antiBanEnabled) return YES;
    } @catch (NSException *e) {
        NSLog(@"[Mod] antiBan: %@", e);
    }
    return orig_antiBan ? orig_antiBan(instance) : YES;
}

void* new_getAimEvent(void *instance) {
    @try {
        if (aimLineEnabled && instance != NULL) {
            // کاتی ئۆفسێتەکان دۆزییەوە، ئەم بەشە چالاک بکە
            /*
            float *power = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
            float *line  = (float *)((uintptr_t)instance + OFFSET_AIM_LINE);
            if (power && line) {
                *line = 200.0 + (*power * 400.0);
            }
            */
        }
    } @catch (NSException *e) {
        NSLog(@"[Mod] getAimEvent: %@", e);
    }
    return orig_getAimEvent ? orig_getAimEvent(instance) : NULL;
}

// ====================================================================
// 🖥️ مێنیوو - بە پشتگوێخستنی ئاگادارییەکانی iOS 26
// ====================================================================
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface ModMenuWindow : UIWindow
+ (void)showMenu;
@end

@implementation ModMenuWindow

static ModMenuWindow *menuInstance = nil;
static UIView *mainView = nil;
static UIButton *floatingBtn = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;
            // ئەم دوو هێڵە ئاگاداری دەردەکەن، بە پشتیوانی iOS 26
            menuInstance = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            
            mainView = [[UIView alloc] initWithFrame:CGRectMake(60, 100, 250, 220)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
            mainView.layer.cornerRadius = 16;
            mainView.layer.borderWidth = 2;
            mainView.layer.borderColor = [UIColor purpleColor].CGColor;
            [menuInstance addSubview:mainView];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 230, 30)];
            title.text = @"🎱 8BP Mod V5";
            title.textColor = [UIColor whiteColor];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:18];
            [mainView addSubview:title];
            
            UIButton *aimBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            aimBtn.frame = CGRectMake(20, 60, 210, 45);
            aimBtn.backgroundColor = [UIColor grayColor];
            aimBtn.layer.cornerRadius = 8;
            aimBtn.tag = 1;
            [aimBtn setTitle:@"🔴 Aim Line: OFF" forState:UIControlStateNormal];
            [aimBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [aimBtn addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:aimBtn];
            
            UIButton *banBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            banBtn.frame = CGRectMake(20, 115, 210, 45);
            banBtn.backgroundColor = [UIColor grayColor];
            banBtn.layer.cornerRadius = 8;
            banBtn.tag = 2;
            [banBtn setTitle:@"🔴 Anti-Ban: OFF" forState:UIControlStateNormal];
            [banBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [banBtn addTarget:self action:@selector(toggleBan:) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:banBtn];
            
            UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
            close.frame = CGRectMake(60, 170, 130, 35);
            close.backgroundColor = [UIColor redColor];
            close.layer.cornerRadius = 8;
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
            [menuInstance addSubview:floatingBtn];
            floatingBtn.hidden = YES;
            
        } @catch (NSException *e) {
            NSLog(@"[Mod] showMenu error: %@", e);
        }
    });
}

+ (void)toggleAim:(UIButton *)sender {
    aimLineEnabled = !aimLineEnabled;
    sender.backgroundColor = aimLineEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:aimLineEnabled ? @"🟢 Aim Line: ON" : @"🔴 Aim Line: OFF" forState:UIControlStateNormal];
}

+ (void)toggleBan:(UIButton *)sender {
    antiBanEnabled = !antiBanEnabled;
    sender.backgroundColor = antiBanEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:antiBanEnabled ? @"🟢 Anti-Ban: ON" : @"🔴 Anti-Ban: OFF" forState:UIControlStateNormal];
}

+ (void)hideMenu {
    mainView.hidden = YES;
    floatingBtn.hidden = NO;
}

+ (void)showFromFloating {
    mainView.hidden = NO;
    floatingBtn.hidden = YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

@end

#pragma clang diagnostic pop

// ====================================================================
// 🚀 لۆدبوون
// ====================================================================
__attribute__((constructor)) static void initMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
                if (base && OFFSET_AIM_LINE != 0) {
                    DobbyHook((void *)(base + OFFSET_AIM_LINE), (void *)new_isAimCorrect, (void **)&orig_isAimCorrect);
                    DobbyHook((void *)(base + OFFSET_GET_AIM_EVENT), (void *)new_getAimEvent, (void **)&orig_getAimEvent);
                    DobbyHook((void *)(base + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)&orig_antiBan);
                }
                [ModMenuWindow showMenu];
            } @catch (NSException *e) {
                NSLog(@"[Mod] init error: %@", e);
            }
        });
    }];
}
