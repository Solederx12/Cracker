#include <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <string.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

// ====================================================================
// 🛠️ پێناسەکردنی Dobby Hook
// ====================================================================
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *target_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// ====================================================================
// 📌 ئۆفسێتەکان - پێویستە خۆت بدۆزیتەوە بۆ ڤێرشنی 56.26.1
// ====================================================================
// ڕێنمایی: بە Cheat Engine یان Game Guardian بەدوای نرخەکاندا بگەڕێ
#define OFFSET_AIM_LINE              0x0 // ئەمە بگۆڕە بە ئۆفسێتی ڕاست
#define OFFSET_CUE_POWER             0x0 // شوێنی قوەتی دارەکە
#define OFFSET_GET_AIM_EVENT         0x0 // فەنکشنی ڕووداوی ئامانج
#define OFFSET_ANTI_BAN              0x0 // پاتچی ئەنتی بان

// ====================================================================
// 🕹️ دۆخی دوگمەکان
// ====================================================================
static BOOL aimLineEnabled = NO;
static BOOL antiBanEnabled = NO;

// ====================================================================
// 🛠️ Hookەکان بە پاراستن لە کڕاش
// ====================================================================

// --- فەنکشنی ئەسڵی کۆن ---
bool (*old_isAimCorrect)(void* instance);
bool (*old_antiBan)(void* instance);
void* (*old_getAimEvent)(void* instance);

// --- فەنکشنی نوێ بۆ هێڵی ئامانج ---
bool new_isAimCorrect(void* instance) {
    @try {
        if (aimLineEnabled) {
            return YES;
        }
    } @catch (NSException *exception) {
        NSLog(@"[Mod] Exception in new_isAimCorrect: %@", exception);
    }
    return old_isAimCorrect ? old_isAimCorrect(instance) : YES;
}

// --- فەنکشنی نوێ بۆ ئەنتی بان ---
bool new_antiBan(void* instance) {
    @try {
        if (antiBanEnabled) {
            return YES;
        }
    } @catch (NSException *exception) {
        NSLog(@"[Mod] Exception in new_antiBan: %@", exception);
    }
    return old_antiBan ? old_antiBan(instance) : YES;
}

// --- فەنکشنی نوێ بۆ ڕووداوی ئامانج (دەستکاری قوەت و هێڵ) ---
void* new_getAimEvent(void* instance) {
    @try {
        if (aimLineEnabled && instance != NULL) {
            // هەوڵبدە قوەتەکە بدۆزیتەوە (ئۆفسێتەکە پێویستە دروست بکرێت)
            // ئاگادار: ئەمە تەنها نموونەیە، پێویستە ئۆفسێتی ڕاست دابنێیت
            /*
            float *powerPtr = (float *)((uintptr_t)instance + OFFSET_CUE_POWER);
            if (powerPtr) {
                float power = *powerPtr;
                // درێژی هێڵەکە بەپێی قوەت دیاری بکە
                float *linePtr = (float *)((uintptr_t)instance + OFFSET_AIM_LINE);
                if (linePtr) {
                    *linePtr = 200.0 + (power * 400.0);
                }
            }
            */
        }
    } @catch (NSException *exception) {
        NSLog(@"[Mod] Exception in new_getAimEvent: %@", exception);
    }
    // گەڕانەوەی فەنکشنی ڕەسەن
    if (old_getAimEvent) {
        return old_getAimEvent(instance);
    }
    return NULL;
}

// ====================================================================
// 🔧 Method Swizzling بۆ پاتچی FBSDK (جێگرەوەی %hook)
// ====================================================================
static void SwizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) return;
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

// فەنکشنی نوێ بۆ fetchDeviceReceipt
static id new_fetchDeviceReceipt(id self, SEL _cmd) {
    // بانگی فەنکشنی ڕەسەن
    SEL origSel = @selector(orig_fetchDeviceReceipt);
    Method origMethod = class_getInstanceMethod([self class], origSel);
    if (origMethod) {
        id (*origImp)(id, SEL) = (id (*)(id, SEL))method_getImplementation(origMethod);
        if (origImp) {
            id result = origImp(self, origSel);
            if (result) return result;
        }
    }
    // گەڕانەوەی بەهای دەستکرد
    return [@"Bypass_6902_Active" dataUsingEncoding:NSUTF8StringEncoding];
}

// ====================================================================
// 🖥️ مێنیووی مۆد (بە UI باشترکراو)
// ====================================================================
@interface ModMenuWindow : UIWindow
+ (void)showMenu;
@end

@implementation ModMenuWindow

static ModMenuWindow *menuInstance = nil;
static UIView *mainMenuView = nil;
static UIButton *floatingButton = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (!menuInstance) {
                menuInstance = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                menuInstance.windowLevel = UIWindowLevelAlert + 1;
                menuInstance.backgroundColor = [UIColor clearColor];
                menuInstance.userInteractionEnabled = YES;
                menuInstance.hidden = NO;
                
                // مێنیووی سەرەکی
                mainMenuView = [[UIView alloc] initWithFrame:CGRectMake(60, 100, 250, 220)];
                mainMenuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
                mainMenuView.layer.cornerRadius = 16;
                mainMenuView.layer.borderWidth = 2;
                mainMenuView.layer.borderColor = [UIColor purpleColor].CGColor;
                [menuInstance addSubview:mainMenuView];
                
                // ناونیشان
                UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 230, 30)];
                titleLabel.text = @"🎱 8BP Mod V5";
                titleLabel.textColor = [UIColor whiteColor];
                titleLabel.textAlignment = NSTextAlignmentCenter;
                titleLabel.font = [UIFont boldSystemFontOfSize:18];
                [mainMenuView addSubview:titleLabel];
                
                // دوگمەی هێڵی ئامانج
                UIButton *aimBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                aimBtn.frame = CGRectMake(20, 60, 210, 45);
                aimBtn.backgroundColor = [UIColor grayColor];
                aimBtn.layer.cornerRadius = 8;
                aimBtn.tag = 1;
                [aimBtn setTitle:@"🔴 هێڵی ئامانج: OFF" forState:UIControlStateNormal];
                [aimBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [aimBtn addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventTouchUpInside];
                [mainMenuView addSubview:aimBtn];
                
                // دوگمەی ئەنتی بان
                UIButton *antiBanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                antiBanBtn.frame = CGRectMake(20, 115, 210, 45);
                antiBanBtn.backgroundColor = [UIColor grayColor];
                antiBanBtn.layer.cornerRadius = 8;
                antiBanBtn.tag = 2;
                [antiBanBtn setTitle:@"🔴 ئەنتی بان: OFF" forState:UIControlStateNormal];
                [antiBanBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [antiBanBtn addTarget:self action:@selector(toggleAntiBan:) forControlEvents:UIControlEventTouchUpInside];
                [mainMenuView addSubview:antiBanBtn];
                
                // دوگمەی داخستن
                UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                closeBtn.frame = CGRectMake(60, 170, 130, 35);
                closeBtn.backgroundColor = [UIColor redColor];
                closeBtn.layer.cornerRadius = 8;
                [closeBtn setTitle:@"داخستن" forState:UIControlStateNormal];
                [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
                [mainMenuView addSubview:closeBtn];
                
                // دوگمەی شناور (Floating)
                floatingButton = [UIButton buttonWithType:UIButtonTypeSystem];
                floatingButton.frame = CGRectMake(20, 150, 55, 55);
                floatingButton.backgroundColor = [UIColor purpleColor];
                floatingButton.layer.cornerRadius = 27.5;
                [floatingButton setTitle:@"🎱" forState:UIControlStateNormal];
                [floatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [floatingButton addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
                [menuInstance addSubview:floatingButton];
                floatingButton.hidden = YES;
            }
        } @catch (NSException *exception) {
            NSLog(@"[Mod] Exception in showMenu: %@", exception);
        }
    });
}

// --- کارەکانی دوگمەکان ---
+ (void)toggleAim:(UIButton *)sender {
    aimLineEnabled = !aimLineEnabled;
    sender.backgroundColor = aimLineEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:aimLineEnabled ? @"🟢 هێڵی ئامانج: ON" : @"🔴 هێڵی ئامانج: OFF" forState:UIControlStateNormal];
}

+ (void)toggleAntiBan:(UIButton *)sender {
    antiBanEnabled = !antiBanEnabled;
    sender.backgroundColor = antiBanEnabled ? [UIColor greenColor] : [UIColor grayColor];
    [sender setTitle:antiBanEnabled ? @"🟢 ئەنتی بان: ON" : @"🔴 ئەنتی بان: OFF" forState:UIControlStateNormal];
}

+ (void)hideMenu {
    if (mainMenuView) mainMenuView.hidden = YES;
    if (floatingButton) floatingButton.hidden = NO;
}

+ (void)showFromFloating {
    if (mainMenuView) mainMenuView.hidden = NO;
    if (floatingButton) floatingButton.hidden = YES;
}

- (BOOL)canBecomeFirstResponder { return YES; }
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

@end

// ====================================================================
// 🚀 لۆدبوونی مۆد (بە پاراستن)
// ====================================================================
__attribute__((constructor)) static void initMod() {
    @try {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    uintptr_t baseAddress = (uintptr_t)_dyld_get_image_header(0);
                    
                    if (baseAddress && OFFSET_AIM_LINE != 0) {
                        // تەنها ئەگەر ئۆفسێتەکان دیاری کرابوون Hook بکە
                        DobbyHook((void *)(baseAddress + OFFSET_AIM_LINE), (void *)new_isAimCorrect, (void **)&old_isAimCorrect);
                        DobbyHook((void *)(baseAddress + OFFSET_GET_AIM_EVENT), (void *)new_getAimEvent, (void **)&old_getAimEvent);
                        DobbyHook((void *)(baseAddress + OFFSET_ANTI_BAN), (void *)new_antiBan, (void **)&old_antiBan);
                    }
                    
                    // Method Swizzling بۆ پاتچی FBSDK
                    @try {
                        Class fbClass = NSClassFromString(@"FBSDKPaymentProductRequestor");
                        if (fbClass) {
                            SEL origSel = @selector(fetchDeviceReceipt);
                            SEL newSel = @selector(new_fetchDeviceReceipt);
                            // فەنکشنی نوێ زیاد بکە
                            class_addMethod(fbClass, newSel, (IMP)new_fetchDeviceReceipt, "@@:");
                            // گۆڕینی جێبەجێکردن
                            Method origMethod = class_getInstanceMethod(fbClass, origSel);
                            Method newMethod = class_getInstanceMethod(fbClass, newSel);
                            if (origMethod && newMethod) {
                                method_exchangeImplementations(origMethod, newMethod);
                            }
                        }
                    } @catch (NSException *e) {
                        NSLog(@"[Mod] FBSDK Swizzle failed: %@", e);
                    }
                    
                    [ModMenuWindow showMenu];
                    
                } @catch (NSException *exception) {
                    NSLog(@"[Mod] Exception in init block: %@", exception);
                }
            });
        }];
    } @catch (NSException *exception) {
        NSLog(@"[Mod] Exception in initMod: %@", exception);
    }
}

#pragma clang diagnostic pop
