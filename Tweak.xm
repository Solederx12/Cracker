#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <objc/runtime.h>

// ============================================================
// 📌 ئۆفسێتەکان - تەنها ئەم سێیە پێویستە
// ============================================================
#define OFFSET_GAME_MANAGER          0x0  // شوێنی GameManager
#define OFFSET_CUE_POWER             0x0  // شوێنی قوەت (float 0-1)
#define OFFSET_AIM_LINE_LENGTH       0x0  // شوێنی درێژی هێڵ (float)

// ئەم ئۆفسێتانە جێگیرن (لە پێکهاتەی تۆوە)
#define OFFSET_VISUAL_CUE            0x4d0
#define OFFSET_VISUAL_GUIDE          0x3b8

// ============================================================
// دۆخی دوگمەکان
// ============================================================
static BOOL aimLineEnabled = NO;

// ============================================================
// پێناسەکردنی Dobby Hook
// ============================================================
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *target, void *replace, void **origin);
#ifdef __cplusplus
}
#endif

// ============================================================
// Hookەکان - تەنها یەک Hook پێویستە
// ============================================================
bool (*orig_isAimCorrect)(void *instance);

bool new_isAimCorrect(void *instance) {
    @try {
        if (aimLineEnabled && instance) {
            // دەستکەوتنی GameManager
            uintptr_t gmPtr = (uintptr_t)instance;
            
            // بەدەستهێنانی VisualCue
            void **vcPtr = (void **)(gmPtr + OFFSET_VISUAL_CUE);
            if (vcPtr && *vcPtr) {
                // بەدەستهێنانی VisualGuide
                void **vgPtr = (void **)((uintptr_t)(*vcPtr) + OFFSET_VISUAL_GUIDE);
                if (vgPtr && *vgPtr) {
                    // دەستکەوتنی قوەت
                    float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
                    // دەستکەوتنی درێژی هێڵ
                    float *linePtr = (float *)((uintptr_t)(*vgPtr) + OFFSET_AIM_LINE_LENGTH);
                    
                    if (powerPtr && linePtr) {
                        float power = *powerPtr;
                        // درێژی هێڵ لە ۲۰۰ بۆ ۷۰۰ پیکسڵ
                        *linePtr = 200.0 + (power * 500.0);
                    }
                }
            }
            return YES;
        }
    } @catch (NSException *e) {
        NSLog(@"[Mod] isAimCorrect: %@", e);
    }
    return orig_isAimCorrect ? orig_isAimCorrect(instance) : YES;
}

// ============================================================
// 🖥️ مێنیوو
// ============================================================
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
            menuInstance = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1;
            menuInstance.backgroundColor = [UIColor clearColor];
            menuInstance.hidden = NO;
            
            mainView = [[UIView alloc] initWithFrame:CGRectMake(60, 100, 250, 160)];
            mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
            mainView.layer.cornerRadius = 16;
            mainView.layer.borderWidth = 2;
            mainView.layer.borderColor = [UIColor purpleColor].CGColor;
            [menuInstance addSubview:mainView];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 230, 30)];
            title.text = @"🎱 8BP Aim Mod";
            title.textColor = [UIColor whiteColor];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont boldSystemFontOfSize:18];
            [mainView addSubview:title];
            
            UIButton *aimBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            aimBtn.frame = CGRectMake(20, 50, 210, 45);
            aimBtn.backgroundColor = [UIColor grayColor];
            aimBtn.layer.cornerRadius = 8;
            [aimBtn setTitle:@"🔴 Aim Line: OFF" forState:UIControlStateNormal];
            [aimBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [aimBtn addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventTouchUpInside];
            [mainView addSubview:aimBtn];
            
            UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
            close.frame = CGRectMake(60, 110, 130, 35);
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

// ============================================================
// 🚀 لۆدبوون
// ============================================================
__attribute__((constructor)) static void initMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
                if (base && OFFSET_GAME_MANAGER != 0) {
                    DobbyHook((void *)(base + OFFSET_GAME_MANAGER), (void *)new_isAimCorrect, (void **)&orig_isAimCorrect);
                }
                [ModMenuWindow showMenu];
            } @catch (NSException *e) {
                NSLog(@"[Mod] init error: %@", e);
            }
        });
    }];
}
