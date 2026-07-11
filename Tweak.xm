#import <UIKit/UIKit.h>

// ================================================================
// ⚠️ پێناسەکردنی کلاسەکان (Forward Declarations)
// ================================================================
@interface GameManager : NSObject
- (BOOL)isOnCreatorMode;
- (BOOL)isOnGoldenShotMode;
- (BOOL)isOnPracticeMode;
- (BOOL)isOnTournamentMode;
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
            if (menuInstance) {
                return;
            }
            
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

- (void)toggleAim:(UIButton *)sender {
    aimLineEnabled = !aimLineEnabled;
    [self updateButton:sender title:@"Aim Line" on:aimLineEnabled];
}

- (void)toggleSuper:(UIButton *)sender {
    superLineEnabled = !superLineEnabled;
    [self updateButton:sender title:@"Super Line" on:superLineEnabled];
}

- (void)toggleAuto:(UIButton *)sender {
    autoPlayEnabled = !autoPlayEnabled;
    [self updateButton:sender title:@"Auto Play" on:autoPlayEnabled];
}

- (void)toggleBan:(UIButton *)sender {
    antiBanEnabled = !antiBanEnabled;
    [self updateButton:sender title:@"Anti-Ban" on:antiBanEnabled];
}

- (void)togglePower:(UIButton *)sender {
    infinitePowerEnabled = !infinitePowerEnabled;
    [self updateButton:sender title:@"Infinite Power" on:infinitePowerEnabled];
}

- (void)toggleSpeed:(UIButton *)sender {
    speedBoostEnabled = !speedBoostEnabled;
    [self updateButton:sender title:@"Speed Boost" on:speedBoostEnabled];
}

- (void)toggleAngle:(UIButton *)sender {
    angleLockEnabled = !angleLockEnabled;
    [self updateButton:sender title:@"Lock Angle" on:angleLockEnabled];
}

- (void)toggleFriction:(UIButton *)sender {
    noFrictionEnabled = !noFrictionEnabled;
    [self updateButton:sender title:@"No Friction" on:noFrictionEnabled];
}

- (void)updateButton:(UIButton *)btn title:(NSString *)title on:(BOOL)on {
    btn.backgroundColor = on ? [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0] : [UIColor grayColor];
    [btn setTitle:[NSString stringWithFormat:@"%@ %@: %@", on ? @"🟢" : @"🔴", title, on ? @"ON" : @"OFF"] forState:UIControlStateNormal];
}

- (void)hideMenu {
    mainView.hidden = YES;
    floatingBtn.hidden = NO;
}

- (void)showFromFloating {
    mainView.hidden = NO;
    floatingBtn.hidden = YES;
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self];
    g.view.center = CGPointMake(g.view.center.x + t.x, g.view.center.y + t.y);
    [g setTranslation:CGPointZero inView:self];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    if (v == self) {
        return nil;
    }
    return v;
}

@end
#pragma clang diagnostic pop

// ================================================================
// 👑 هۆکەکانی لۆگۆس (بە شێوازی سەلامەت بۆ کۆمپایلەر)
// ================================================================

%hook GameManager

- (BOOL)isOnCreatorMode {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)isOnGoldenShotMode {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)isOnPracticeMode {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)isOnTournamentMode {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

%end


%hook GraphicsManager

- (float)lineOpacity {
    if (aimLineEnabled) {
        return 1.00f;
    }
    return %orig;
}

- (float)endBallSize {
    return 1.00f;
}

- (float)pocketRingSize {
    return 1.00f;
}

- (float)initialPull {
    return 1.00f;
}

- (float)lineScaleX {
    if (superLineEnabled) {
        return 3.0f;
    }
    return 1.0f;
}

- (float)lineScaleY {
    if (superLineEnabled) {
        return 3.0f;
    }
    return 1.0f;
}

- (float)lineThickness {
    if (aimLineEnabled) {
        return 1.5f;
    }
    return %orig;
}

%end


%hook PredictionManager

- (BOOL)showPredictionLines {
    return aimLineEnabled;
}

- (BOOL)showOpponentLines {
    return aimLineEnabled;
}

- (BOOL)showTableOutline {
    return aimLineEnabled;
}

- (BOOL)showPocketRings {
    return aimLineEnabled;
}

- (BOOL)showEndDots {
    return aimLineEnabled;
}

- (BOOL)showPrecisePaths {
    return aimLineEnabled;
}

- (int)maxBounces {
    if (aimLineEnabled) {
        return 6;
    }
    return %orig;
}

- (int)maxTargetBounces {
    if (aimLineEnabled) {
        return 4;
    }
    return %orig;
}

- (BOOL)renderMultiLines {
    return aimLineEnabled;
}

- (BOOL)calculateAllBallPaths {
    return aimLineEnabled;
}

%end


%hook AutomationManager

- (BOOL)isProUnlocked {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)isAdFree {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (int)proPlanStatus {
    if (autoPlayEnabled) {
        return 1;
    }
    return %orig;
}

- (float)aimStrength {
    if (autoPlayEnabled) {
        return 0.07f;
    }
    return %orig;
}

- (float)maxAimSpeed {
    if (speedBoostEnabled) {
        return 300.0f;
    }
    if (autoPlayEnabled) {
        return 140.0f;
    }
    return %orig;
}

- (float)waitTime {
    if (autoPlayEnabled) {
        return 1.00f;
    }
    return %orig;
}

%end


%hook AimController

- (id)spinStyle {
    return @"Off";
}

- (id)aimMode {
    if (autoPlayEnabled) {
        return @"Guide";
    }
    return %orig;
}

- (id)humanization {
    return @"Med";
}

- (id)skillLevel {
    if (autoPlayEnabled) {
        return @"Pro";
    }
    return %orig;
}

- (id)breakMode {
    return @"Single";
}

- (float)currentAngle {
    if (angleLockEnabled) {
        return lockedAngle;
    }
    return %orig;
}

- (void)setAngle:(float)angle {
    if (!angleLockEnabled) {
        %orig;
    }
}

%end


%hook ShortcutManager

- (BOOL)shortcutButtonEnabled {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)bestShotGhostEnabled {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)autoSelectPocketEnabled {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)ballInHandSkipEnabled {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

- (BOOL)pauseOnTouchEnabled {
    if (autoPlayEnabled) {
        return YES;
    }
    return %orig;
}

%end


%hook PhysicsManager

- (float)friction {
    if (noFrictionEnabled) {
        return 0.0f;
    }
    return %orig;
}

%end


%hook ShotPowerManager

- (float)maxPower {
    if (infinitePowerEnabled) {
        return 999.0f;
    }
    return %orig;
}

- (float)power {
    if (infinitePowerEnabled) {
        return customPower;
    }
    return %orig;
}

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
