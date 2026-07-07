#import <UIKit/UIKit.h>

// ================================================================
// 🕹️ دۆخی دوگمەکان - تەنها بۆ UI
// ================================================================
static BOOL aimLineEnabled     = NO;
static BOOL superLineEnabled   = NO;
static BOOL autoPlayEnabled    = NO;
static BOOL antiBanEnabled     = NO;
static BOOL infinitePowerEnabled = NO;
static BOOL speedBoostEnabled  = NO;
static BOOL angleLockEnabled   = NO;
static BOOL noFrictionEnabled  = NO;

static float lockedAngle = 0.785;
static float customPower = 0.8;

// ================================================================
// 🖥️ مێنیووی UI (بە ۸ دوگمە) - هەمان شێوەی خۆت
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

%hook GameManager
- (BOOL)isOnCreatorMode { return YES; }
- (BOOL)isOnGoldenShotMode { return YES; }
- (BOOL)isOnPracticeMode { return YES; }
- (BOOL)isOnTournamentMode { return YES; }
%end

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

%hook AutomationManager
- (BOOL)isProUnlocked { return YES; }
- (BOOL)isAdFree { return YES; }
- (int)proPlanStatus { return 1; }
- (float)aimStrength { return 0.07; }
- (float)maxAimSpeed { return 140.0; }
- (float)waitTime { return 1.00; }
%end

%hook AimController
- (NSString *)spinStyle { return @"Off"; }
- (NSString *)aimMode { return @"Guide"; }
- (NSString *)humanization { return @"Med"; }
- (NSString *)skillLevel { return @"Pro"; }
- (NSString *)breakMode { return @"Single"; }
%end

%hook ShortcutManager
- (BOOL)shortcutButtonEnabled { return YES; }
- (BOOL)bestShotGhostEnabled { return YES; }
- (BOOL)autoSelectPocketEnabled { return YES; }
- (BOOL)ballInHandSkipEnabled { return YES; }
- (BOOL)pauseOnTouchEnabled { return YES; }
%end

%hook i3rbyStoreViewController
- (void)viewDidLoad {
    %orig;
    @try {
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
                [subview removeFromSuperview];
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
// 🚀 لۆدبوونی مۆد (تەنها UI و Logos، بەبێ libspector)
// ================================================================
__attribute__((constructor)) static void initMod() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [SimpleMenu showMenu];
        });
    }];
}
