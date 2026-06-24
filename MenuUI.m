#import <UIKit/UIKit.h>

// گۆڕینی extern "C" بۆ externـی ئاسایی چونکە ئەمە Objective-Cـە نەک C++
extern void TriggerMenuFeatures(BOOL enable);

@interface ModMenuWindow : UIWindow
+ (void)showMenu;
@end

@implementation ModMenuWindow

static ModMenuWindow *instance = nil;
static UIView *mainView = nil;
static UIButton *floatingBtn = nil;
static BOOL state = NO;

+ (void)showMenu {
    if (!instance) {
        instance = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        instance.windowLevel = UIWindowLevelAlert + 1;
        instance.backgroundColor = [UIColor clearColor];
        instance.hidden = NO;
        
        mainView = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 250, 300)];
        mainView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        mainView.layer.cornerRadius = 15;
        mainView.layer.borderWidth = 2;
        mainView.layer.borderColor = [UIColor purpleColor].CGColor;
        [instance addSubview:mainView];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 250, 30)];
        title.text = @"Kurdish Mod Menu";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:20];
        [mainView addSubview:title];
        
        UIButton *toggleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toggleBtn.frame = CGRectMake(25, 70, 200, 45);
        toggleBtn.backgroundColor = [UIColor systemBlueColor];
        toggleBtn.layer.cornerRadius = 10;
        [toggleBtn setTitle:@"Enable Aim Line" forState:UIControlStateNormal];
        [toggleBtn addTarget:self action:@selector(toggleLines:) forControlEvents:UIControlEventTouchUpInside];
        [mainView addSubview:toggleBtn];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(25, 240, 200, 45);
        closeBtn.backgroundColor = [UIColor systemRedColor];
        closeBtn.layer.cornerRadius = 10;
        [closeBtn setTitle:@"Close Menu" forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
        [mainView addSubview:closeBtn];
        
        floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(20, 80, 50, 50);
        floatingBtn.backgroundColor = [UIColor purpleColor];
        floatingBtn.layer.cornerRadius = 25;
        [floatingBtn setTitle:@"K" forState:UIControlStateNormal];
        [floatingBtn addTarget:self action:@selector(showMenuFromFloating) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragIcon:)];
        [floatingBtn addGestureRecognizer:pan];
        
        [instance addSubview:floatingBtn];
        floatingBtn.hidden = YES;
    }
}

+ (void)toggleLines:(UIButton *)sender {
    state = !state;
    if (state) {
        [sender setTitle:@"Disable Aim Line" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemGreenColor];
        TriggerMenuFeatures(YES);
    } else {
        [sender setTitle:@"Enable Aim Line" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemBlueColor];
        TriggerMenuFeatures(NO);
    }
}

+ (void)hideMenu {
    mainView.hidden = YES;
    floatingBtn.hidden = NO;
}

+ (void)showMenuFromFloating {
    mainView.hidden = NO;
    floatingBtn.hidden = YES;
}

+ (void)dragIcon:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:instance];
    p.view.center = CGPointMake(p.view.center.x + t.x, p.view.center.y + t.y);
    [p setTranslation:CGPointZero inView:instance];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

@end
