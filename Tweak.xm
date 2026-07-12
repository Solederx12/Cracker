#import <UIKit/UIKit.h>

// ==========================================
// ١. پێناسەکردنی کلاسی مۆد مینۆی OUTLAW
// ==========================================
@interface OutlawModMenu : NSObject
+ (void)showMenu;
@end

// گۆڕاوەکان بۆ هەڵگرتنی دۆخی دوگمەکانی هاکەکە
bool predictionLines = false;
bool opponentLines = false;
float lineThickness = 1.0f;
float lineOpacity = 0.90f;

// ==========================================
// ٢. دروستکردنی ڕووکاری مۆدەکە بە ڕەنگی سوور
// ==========================================
@implementation OutlawModMenu

static UIWindow *menuWindow;
static UIView *mainView;

+ (void)showMenu {
    // دروستکردنی پەنجەرەی سەرەکی مۆدەکە لەسەر شاشە
    menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(100, 100, 320, 430)];
    menuWindow.windowLevel = UIWindowLevelAlert + 1;
    menuWindow.backgroundColor = [UIColor clearColor];
    [menuWindow makeKeyAndVisible];
    menuWindow.hidden = NO;

    // دروستکردنی چوارگۆشەی پشتەوە (ڕەساسی تۆخ + هێڵی سوور)
    mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 430)];
    mainView.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:0.97]; // Dark Theme
    mainView.layer.cornerRadius = 20.0; // سووچی خڕ وەک ڕەسنی ئایفۆن
    mainView.layer.masksToBounds = YES;
    mainView.layer.borderWidth = 2.0;
    mainView.layer.borderColor = [[UIColor systemRedColor] CGColor]; // ڕەنگی سووری ئاوتلاو
    [menuWindow addSubview:mainView];

    // --- بەشی سەرەوە: ناوی براندەکەت ---
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 320, 30)];
    titleLabel.text = @"OUTLAW STORE";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:22]; // ناوی سەرەکی گەورە
    [mainView addSubview:titleLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, 320, 20)];
    subtitleLabel.text = @"8 Ball Pool Premium Menu";
    subtitleLabel.textColor = [UIColor systemRedColor]; // ژێرناو بە سوور
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    [mainView addSubview:subtitleLabel];

    // --- بەشی ناوەڕاست: لۆگۆ نوێیەکەت (داڵەکە) ---
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(125, 75, 70, 70)];
    logoView.image = [UIImage imageNamed:@"outlaw_logo.png"]; // ناوی فایلی وێنەکە
    logoView.layer.cornerRadius = 35; // لۆگۆکە دەکاتە بازنەیی و زۆر شیک دەردەکەوێت
    logoView.clipsToBounds = YES;
    logoView.layer.borderWidth = 1.5;
    logoView.layer.borderColor = [[UIColor systemRedColor] CGColor];
    logoView.contentMode = UIViewContentModeScaleAspectFill;
    [mainView addSubview:logoView];

    // --- بەشی ئۆپشنەکان (Controls) ---
    
    // سویچی یەکەم: Prediction Lines
    UILabel *lblLines = [[UILabel alloc] initWithFrame:CGRectMake(20, 165, 180, 30)];
    lblLines.text = @"Prediction Lines";
    lblLines.textColor = [UIColor whiteColor];
    lblLines.font = [UIFont systemFontOfSize:15];
    [mainView addSubview:lblLines];

    UISwitch *swLines = [[UISwitch alloc] initWithFrame:CGRectMake(240, 165, 0, 0)];
    swLines.onTintColor = [UIColor systemRedColor]; // گۆڕینی ڕەنگی سویچ بۆ سوور
    [swLines addTarget:self action:@selector(toggleLines:) forControlEvents:UIControlEventValueChanged];
    [mainView addSubview:swLines];

    // سویچی دووەم: Opponent Lines
    UILabel *lblOpponent = [[UILabel alloc] initWithFrame:CGRectMake(20, 215, 180, 30)];
    lblOpponent.text = @"Opponent Lines";
    lblOpponent.textColor = [UIColor whiteColor];
    lblOpponent.font = [UIFont systemFontOfSize:15];
    [mainView addSubview:lblOpponent];

    UISwitch *swOpponent = [[UISwitch alloc] initWithFrame:CGRectMake(240, 215, 0, 0)];
    swOpponent.onTintColor = [UIColor systemRedColor];
    [swOpponent addTarget:self action:@selector(toggleOpponent:) forControlEvents:UIControlEventValueChanged];
    [mainView addSubview:swOpponent];

    // سلایدەر: Line Opacity
    UILabel *lblOpacity = [[UILabel alloc] initWithFrame:CGRectMake(20, 265, 180, 25)];
    lblOpacity.text = @"Line Opacity";
    lblOpacity.textColor = [UIColor whiteColor];
    lblOpacity.font = [UIFont systemFontOfSize:14];
    [mainView addSubview:lblOpacity];

    UISlider *sldOpacity = [[UISlider alloc] initWithFrame:CGRectMake(20, 295, 280, 30)];
    sldOpacity.minimumValue = 0.0;
    sldOpacity.maximumValue = 1.0;
    sldOpacity.value = 0.90;
    sldOpacity.minimumTrackTintColor = [UIColor systemRedColor]; // هێڵی سلایدەری سوور
    [sldOpacity addTarget:self action:@selector(changeOpacity:) forControlEvents:UIControlEventValueChanged];
    [mainView addSubview:sldOpacity];

    // --- بەشی خوارەوە: دوگمەی پەیجی تێلیگرامەکەت ---
    UIButton *btnTelegram = [UIButton buttonWithType:UIButtonTypeCustom];
    btnTelegram.frame = CGRectMake(20, 360, 280, 45)];
    btnTelegram.backgroundColor = [UIColor systemRedColor]; // دوگمەی سوور
    btnTelegram.layer.cornerRadius = 12;
    [btnTelegram setTitle:@"Join OUTLAW Telegram" forState:UIControlStateNormal];
    btnTelegram.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [btnTelegram addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:btnTelegram];
}

// کارپێکردنی فرمانەکان کاتێک سویچەکان دادەگیرێن
+ (void)toggleLines:(UISwitch *)sender { predictionLines = sender.isOn; }
+ (void)toggleOpponent:(UISwitch *)sender { opponentLines = sender.isOn; }
+ (void)changeOpacity:(UISlider *)sender { lineOpacity = sender.value; }

// کردنەوەی لایەن بە فەرمی بەستراوەتەوە بە ئایدی پەیجەکەتەوە
+ (void)openTelegram {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/Outlaw8BP"] options:@{} completionHandler:nil];
}
@end


// ==========================================
// ٣. هۆککردنی بزوێنەری یاری 8 Ball Pool
// ==========================================
%hook GamePhysicsManager
- (void)calculateTrajectory {
    if (predictionLines) {
        // لێرەدا کۆدی ماتماتیکی هێڵە درێژەکان کاردەکات
    }
    %orig; 
}
%end


// ==========================================
// ٤. نیشاندانی خۆکار لە کاتی بووت بوونی ئەپەکە
// ==========================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [OutlawModMenu showMenu];
    }];
}
