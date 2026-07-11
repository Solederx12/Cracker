#import <UIKit/UIKit.h>

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

// ================================================================
// 🖥️ دروستکردنی مێنیووی UI بە سکڕۆڵەوە (Scrollable Menu)
// ================================================================
@interface SimpleMenu : UIWindow
+ (void)showMenu;
- (void)drag:(UIPanGestureRecognizer *)g;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation SimpleMenu {
    UIView *mainView;
    UIScrollView *scrollView;
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
    // 1. گونجاندنی بەرزی مێنیووەکە لەگەڵ شاشەی تەنیشت (Landscape)
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat menuHeight = screenH - 40; // جێهێشتنی کەمێک بۆشایی
    if (menuHeight > 400) menuHeight = 400; // زۆرترین بەرزی

    mainView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 280, menuHeight)];
    mainView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
    mainView.layer.cornerRadius = 15;
    mainView.layer.borderWidth = 2;
    mainView.layer.borderColor = [UIColor purpleColor].CGColor;
    [self addSubview:mainView];
    
    // 2. تایتڵ
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 260, 30)];
    title.text = @"🎱 8BP Kurdish Elite Mod";
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:18];
    [mainView addSubview:title];
    
    // 3. دروستکردنی ScrollView بۆ ئەوەی دوگمەکان نەچنە دەرەوەی شاشە
    CGFloat scrollY = 50;
    CGFloat scrollHeight = menuHeight - scrollY - 50; // جێهێشتنی شوێن بۆ دوگمەی داخستن لە خوارەوە
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollY, 280, scrollHeight)];
    scrollView.showsVerticalScrollIndicator = YES;
    [mainView addSubview:scrollView];
    
    NSArray *titles = @[
        @"Aim Line", @"Super Line", @"Auto Play", @"Anti-Ban",
        @"Infinite Power", @"Speed Boost", @"Lock Angle", @"No Friction"
    ];
    NSArray *selectors = @[
        @"toggleAim:", @"toggleSuper:", @"toggleAuto:", @"toggleBan:",
        @"togglePower:", @"toggleSpeed:", @"toggleAngle:", @"toggleFriction:"
    ];
    
    // 4. زیادکردنی دوگمەکان بۆ ناو ScrollView
    CGFloat buttonY = 0;
    for (int i = 0; i < titles.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(15, buttonY, 250, 38);
        btn.backgroundColor = [UIColor darkGrayColor];
        btn.layer.cornerRadius = 8;
        btn.tag = i + 100;
        [btn setTitle:[NSString stringWithFormat:@"🔴 %@: OFF", titles[i]] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self action:NSSelectorFromString(selectors[i]) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:btn];
        
        buttonY += 45; // مەودای نێوان دوگمەکان
    }
    
    // دیاریکردنی قەبارەی ناوەوەی ScrollView
    scrollView.contentSize = CGSizeMake(280, buttonY + 10);
    
    // 5. دوگمەی داخستن (جێگیرکراو لە خوارەوەی مێنیووەکە)
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(90, menuHeight - 40, 100, 30);
    close.backgroundColor = [UIColor redColor];
    close.layer.cornerRadius = 8;
    [close setTitle:@"Close" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [close addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:close];
    
    // 6. دوگمەی سەر شاشە (Floating Button)
    floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    floatingBtn.frame = CGRectMake(20, 20, 55, 55);
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

// فرمانەکانی دوگمەکان
- (void)toggleAim:(UIButton *)sender    { aimLineEnabled = !aimLineEnabled; [self updateButton:sender title:@"Aim Line" on:aimLineEnabled]; }
- (void)toggleSuper:(UIButton *)sender  { superLineEnabled = !superLineEnabled; [self updateButton:sender title:@"Super Line" on:superLineEnabled]; }
- (void)toggleAuto:(UIButton *)sender   { autoPlayEnabled = !autoPlayEnabled; [self updateButton:sender title:@"Auto Play" on:autoPlayEnabled]; }
- (void)toggleBan:(UIButton *)sender    { antiBanEnabled = !antiBanEnabled; [self updateButton:sender title:@"Anti-Ban" on:antiBanEnabled]; }
- (void)togglePower:(UIButton *)sender  { infinitePowerEnabled = !infinitePowerEnabled; [self updateButton:sender title:@"Infinite Power" on:infinitePowerEnabled]; }
- (void)toggleSpeed:(UIButton *)sender  { speedBoostEnabled = !speedBoostEnabled; [self updateButton:sender title:@"Speed Boost" on:speedBoostEnabled]; }
- (void)toggleAngle:(UIButton *)sender  { angleLockEnabled = !angleLockEnabled; [self updateButton:sender title:@"Lock Angle" on:angleLockEnabled]; }
- (void)toggleFriction:(UIButton *)sender { noFrictionEnabled = !noFrictionEnabled; [self updateButton:sender title:@"No Friction" on:noFrictionEnabled]; }

- (void)updateButton:(UIButton *)btn title:(NSString *)title on:(BOOL)on {
    btn.backgroundColor = on ? [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0] : [UIColor darkGrayColor];
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
    if (v == self) return nil; // ڕێگەدان بە دەستلێدانی شاشەی پشتەوەی مێنیووەکە
    return v;
}

@end
#pragma clang diagnostic pop


// ================================================================
// 🚀 لۆدکردنی مۆد
// ================================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SimpleMenu showMenu];
    });
}
