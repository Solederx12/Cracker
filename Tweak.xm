#import <UIKit/UIKit.h>

// ================================================================
// ⚠️ پێناسەکردنی کلاسەکان (Forward Declarations)
// ================================================================
@interface GameManager : NSObject
@end

@interface GraphicsManager : NSObject
@end

@interface PredictionManager : NSObject
@end

@interface AutomationManager : NSObject
@end

@interface AimController : NSObject
@end

@interface ShortcutManager : NSObject
@end

@interface PhysicsManager : NSObject
@end

@interface ShotPowerManager : NSObject
@end

@interface i3rbyStoreViewController : UIViewController
@end

// ================================================================
// 🕹️ دۆخی گۆڕاوەکان (Variables State)
// ================================================================
static BOOL aimLineEnabled       = NO;
static BOOL superLineEnabled     = NO;
static BOOL autoPlayEnabled      = NO;
static BOOL antiBanEnabled       = NO;
static BOOL infinitePowerEnabled = NO;
static BOOL speedBoostEnabled    = NO;
static BOOL angleLockEnabled     = NO;
static BOOL noFrictionEnabled    = NO;

static float lockedAngle = 0.785f;
static float customPower = 0.8f;

// ================================================================
// 🖥️ دروستکردنی مێنیووی UI
// ================================================================
@interface SimpleMenu : UIWindow
+ (void)showMenu;
- (void)drag:(UIPanGestureRecognizer *)g;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation SimpleMenu {
    UIView *mainView;
    UIButton *floatingBtn;
}

static SimpleMenu *menuInstance = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (menuInstance) return;
            
            menuInstance = [[SimpleMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuInstance.windowLevel = UIWindowLevelAlert + 1.0;
            menuInstance.backgroundColor = [UIColor clearColor];
            [menuInstance makeKeyAndVisible];
            menuInstance.userInteractionEnabled = YES;
            
            [menuInstance setupUI];
        } @catch (NSException *e) {
            NSLog(@"[EliteMod] showMenu error: %@", e);
        }
    });
}

- (void)setupUI {
    mainView = [[UIView alloc] initWithFrame:CGRectMake(40, 80, 280, 480)];
    mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
    mainView.layer.cornerRadius = 20;
    mainView.layer.borderWidth = 2;
    mainView.layer.borderColor = [UIColor purpleColor].CGColor;
    [self addSubview:mainView];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 260, 30)];
    title.text = @"🎱 8BP Kurdish Elite Mod";
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
    floatingBtn.titleLabel.font = [UIFont systemFontOfSize:25];
    [floatingBtn addTarget:self action:@selector(showFromFloating) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [floatingBtn addGestureRecognizer:pan];
    [self addSubview:floatingBtn];
    floatingBtn.hidden = YES;
}

- (void)toggleAim:(UIButton *)sender    { aimLineEnabled = !aimLineEnabled; [self updateButton:sender title:@"Aim Line" on:aimLineEnabled]; }
- (void)toggleSuper:(UIButton *)sender  { superLineEnabled = !superLineEnabled; [self updateButton:sender title:@"Super Line" on:superLineEnabled]; }
- (void)toggleAuto:(UIButton *)sender   { autoPlayEnabled = !autoPlayEnabled; [self updateButton:sender title:@"Auto Play" on:autoPlayEnabled]; }
- (void)toggleBan:(UIButton *)sender    { antiBanEnabled = !antiBanEnabled; [self updateButton:sender title:@"Anti-Ban" on:antiBanEnabled]; }
- (void)togglePower:(UIButton *)sender  { infinitePowerEnabled = !infinitePowerEnabled; [self updateButton:sender title:@"Infinite Power" on:infinitePowerEnabled]; }
- (void)toggleSpeed:(UIButton *)sender  { speedBoostEnabled = !speedBoostEnabled; [self updateButton:sender title:@"Speed Boost" on:speedBoostEnabled]; }
- (void)toggleAngle:(UIButton *)sender  { angleLockEnabled = !angleLockEnabled; [self updateButton:sender title:@"Lock Angle" on:angleLockEnabled]; }
- (void)toggleFriction:(UIButton *)sender { noFrictionEnabled = !noFrictionEnabled; [self updateButton:sender title:@"No Friction" on:noFrictionEnabled]; }

- (void)updateButton:(UIButton *)btn title:(NSString *)title on:(BOOL)on {
    btn.backgroundColor = on ? [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0] : [UIColor grayColor];
    [btn setTitle:[NSString stringWithFormat:@"%@ %@: %@", on ? @"🟢" : @"🔴", title, on ? @"ON" : @"OFF"] forState:UIControlStateNormal];
}

- (void)hideMenu { mainView.hidden = YES; floatingBtn.hidden = NO; }
- (void)showFromFloating { mainView.hidden = NO; floatingBtn.hidden = YES; }

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self];
    g.view.center = CGPointMake(g.view.center.x + t.x, g.view.center.y + t.y);
    [g setTranslation:CGPointZero inView:self];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    if (v == self) return nil;
    return v;
}

@end
#pragma clang diagnostic pop

// ================================================================
// 👑 هۆکەکانی لۆگۆس (بەپێی هێڵکاری وێنەکە)
// ================================================================

%hook GameManager
- (BOOL)isOnCreatorMode { return autoPlayEnabled ? YES : %orig; }
- (BOOL)isOnGoldenShotMode { return autoPlayEnabled ? YES : %orig; }
- (BOOL)isOnPracticeMode { return autoPlayEnabled ? YES : %orig; }
- (BOOL)isOnTournamentMode { return autoPlayEnabled ? YES : %orig; }
%end

%hook GraphicsManager
// ڕێکخستنی کواڵیتی و ڕوونی هێڵەکان وەک ناو وێنەکە
- (float)lineOpacity { return aimLineEnabled ? 1.00f : %orig; } 
- (float)endBallSize { return 1.00f; }
- (float)pocketRingSize { return 1.00f; }
- (float)initialPull { return 1.00f; }

// ئەستووری و درێژی هێڵە زیکزاکییەکان
- (float)lineScaleX { return superLineEnabled ? 3.0f : 1.0f; }
- (float)lineScaleY { return superLineEnabled ? 3.0f : 1.0f; }
- (float)lineThickness { return aimLineEnabled ? 1.5f : %orig; }
%end

%hook PredictionManager
// چالاککردنی پێشبینیکردنی هێڵی فرە-بەرکەوتن (Multi-Bounce) هاوشێوەی وێنەکە
- (BOOL)showPredictionLines { return aimLineEnabled; }
- (BOOL)showOpponentLines { return aimLineEnabled; }
- (BOOL)showTableOutline { return aimLineEnabled; }
- (BOOL)showPocketRings { return aimLineEnabled; }
- (BOOL)showEndDots { return aimLineEnabled; }
- (BOOL)showPrecisePaths { return aimLineEnabled; }

// زیادکردنی ژمارەی بەرکەوتنەکان بە دیوارەوە (Bounce Limits) بۆ دروستکردنی هێڵی زیکزاکی درێژ
- (int)maxBounces { return aimLineEnabled ? 6 : %orig; } 
- (int)maxTargetBounces { return aimLineEnabled ? 4 : %orig; } 

// پیشاندانی هێڵی سەرجەم تۆپەکانی سەر مێزەکە بە جیاوازی (Multi Colored Lines)
- (BOOL)renderMultiLines { return aimLineEnabled; }
- (BOOL)calculateAllBallPaths { return aimLineEnabled; }
%end

%hook AutomationManager
- (BOOL)isProUnlocked { return autoPlayEnabled ? YES : %orig; }
- (BOOL)isAdFree { return autoPlayEnabled ? YES : %orig; }
- (int)proPlanStatus { return autoPlayEnabled ? 1 : %orig; }
- (float)aimStrength { return autoPlayEnabled ? 0.07f : %orig; }
- (float)maxAimSpeed {
    if (speedBoostEnabled) return 300.0f;
    return autoPlayEnabled ? 140.0f : %orig;
}
- (float)waitTime { return autoPlayEnabled ? 1.00f : %orig; }
%end

%hook AimController
- (id)spinStyle { return @"Off"; }
- (id)aimMode { return autoPlayEnabled ? @"Guide" : %orig; }
- (id)humanization { return @"Med"; }
- (id)skillLevel { return autoPlayEnabled ? @"Pro" : %orig; }
- (id)breakMode { return @"Single"; }
- (float)currentAngle { return angleLockEnabled ? lockedAngle : %orig; }
- (void)setAngle:(float)angle { if (!angleLockEnabled) %orig; }
%end

%hook ShortcutManager
- (BOOL)shortcutButtonEnabled { return autoPlayEnabled ? YES : %orig; }
- (BOOL)bestShotGhostEnabled { return autoPlayEnabled ? YES : %orig; }
- (BOOL)autoSelectPocketEnabled { return autoPlayEnabled ? YES : %orig; }
- (BOOL)ballInHandSkipEnabled { return autoPlayEnabled ? YES : %orig; }
- (BOOL)pauseOnTouchEnabled { return autoPlayEnabled ? YES : %orig; }
%end

%hook PhysicsManager
- (float)friction { return noFrictionEnabled ? 0.0f : %orig; }
%end

%hook ShotPowerManager
- (float)maxPower { return infinitePowerEnabled ? 999.0f : %orig; }
- (float)power { return infinitePowerEnabled ? customPower : %orig; }
%end

%hook i3rbyStoreViewController
- (void)viewDidLoad {
    %orig;
    @try {
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)subview;
                if ([label.text containsString:@"i3rby"] || [label.text containsString:@"Telegram"]) {
                    [label removeFromSuperview];
                }
            }
        }
    } @catch (NSException *e) {}
}
%end

// ================================================================
// 🚀 لۆدکردنی مۆد
// ================================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SimpleMenu showMenu];
    });
}
