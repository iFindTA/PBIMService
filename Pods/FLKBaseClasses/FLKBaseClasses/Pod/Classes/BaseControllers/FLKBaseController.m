//
//  FLKBaseController.m
//  FLKSecretSessionPro
//
//  Created by nanhu on 2016/11/10.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKBaseController.h"
#import <objc/message.h>

/**
 excute block func in main tread
 
 @param block to be excuted
 */
static void excuteMainBlock(void(^block)()) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/**
 vcr's view Presentation style
 */
typedef NS_ENUM(NSUInteger, FLKViewPresentation) {
    FLKViewPresentationPushed                   =   1   <<  0,
    FLKViewPresentationPresented                =   1   <<  1
};

@interface FLKBaseController ()

@property (nonatomic, assign) FLKViewPresentation presentationMode;

@property (nonatomic, assign, readwrite) BOOL wetherInited;

@property (nonatomic, strong, readwrite) UINavigationBar *navigationBar;

@end

@implementation FLKBaseController

#pragma mark -- init url mediator router

- (BOOL)canOpenedByNativeUrl:(NSURL *)url {
    return false;
}

- (BOOL)canOpenedByRemoteUrl:(NSURL *)url {
    return false;
}

- (void)loadView {
    [super loadView];
    
    //self.navigationController.navigationBarHidden = true;//disable swipe back gesture
    self.navigationController.navigationBar.hidden = true;
    //customize settings
    UIColor *fontColor = [UIColor pb_colorWithHexString:PB_NAVIBAR_TINT_STRING];
    UIColor *tintColor = [UIColor pb_colorWithHexString:@"#6C6C6C"];
    UIFont *font = [UIFont systemFontOfSize:PBFontTitleSize+2];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:fontColor, NSForegroundColorAttributeName,font,NSFontAttributeName, nil];
    CGSize mainSize = [UIScreen mainScreen].bounds.size;
    CGRect barBounds = CGRectMake(0, 0, mainSize.width, PB_NAVIBAR_HEIGHT);
    UINavigationBar *naviBar = [[UINavigationBar alloc] initWithFrame:barBounds];
    naviBar.barStyle  = UIBarStyleBlack;
    //naviBar.backgroundColor = [UIColor redColor];
    [naviBar setShadowImage:[UIImage new]];// line
    naviBar.barTintColor = [UIColor whiteColor];
    naviBar.tintColor = tintColor;
    [naviBar setTranslucent:false];
    [naviBar setTitleTextAttributes:attributes];
    [self.view addSubview:naviBar];
    self.navigationBar = naviBar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.wetherInited = false;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_wetherInited) {
        //record presentaion mode
        BOOL isModal = false;
        if (self.navigationController != nil) {
            isModal = self.navigationController.isBeingPresented;
        } else {
            isModal = self.isBeingPresented;
        }
        self.presentationMode = 1<<(isModal?1:0);
        
        self.wetherInited = true;
    } else {
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self endEditingMode];
}

- (void)endEditingMode {
    [self.view endEditing:true];
}

#pragma mark -- custom navigation left back barItem

- (void)hiddenNavigationBar {
//    CGRect frame = self.navigationBar.frame;
//    frame.origin.y -= PB_NAVIBAR_HEIGHT;
//    self.navigationBar.frame = frame;
    
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    @synchronized (self.navigationBar) {
        [self.navigationBar.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSClassFromString(@"UIButton")]
                ||[obj isMemberOfClass:NSClassFromString(@"UIButton")]) {
                obj.alpha = 1;
            } else {
                obj.alpha = 0;
            }
        }];
    }
    //[self printHierarchy4View:self.navigationBar];
    
}

- (void)printHierarchy4View:(UIView *)view {
    if (view == nil) {
        return;
    }
    
    NSArray *subviews = [view subviews];
    if (subviews.count == 0) {
        return;
    }
    NSEnumerator *enumrator = [subviews objectEnumerator];
    UIView *tmp = nil;
    while (tmp = [enumrator nextObject]) {
        NSLog(@"viewClass:%@---subClass:%@",NSStringFromClass(view.class),NSStringFromClass(tmp.class));
    }
}

- (UIBarButtonItem *)barSpacer {
    UIBarButtonItem *barSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    barSpacer.width = -PB_CONTENT_MARGIN;
    return barSpacer;
}

- (UIBarButtonItem *)backBarButtonItem:(NSString * _Nullable)backTitle {
    return [self backBarButtonItem:backTitle withIcon:@"FLKNaviBack"];
}

- (UIBarButtonItem *)backBarButtonItem:(NSString * _Nullable)backTitle  withIcon:(NSString * _Nullable)img {
    UIImage *image = [UIImage imageNamed:img];
    UIFont *font = [UIFont systemFontOfSize:PBFontTitleSize];
    UIColor *fontColor = [UIColor pb_colorWithHexString:PB_NAVIBAR_TINT_STRING];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 51, 31);
    btn.exclusiveTouch = true;
    btn.titleLabel.font = font;
    [btn setTitle:backTitle?backTitle:@"返回" forState:UIControlStateNormal];
    [btn setTitleColor:fontColor forState:UIControlStateNormal];
    [btn setImage:image forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backBarItemTouchEvent) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [barItem setTintColor:fontColor];
    return barItem;
}

- (UIBarButtonItem *)barWithIcon:(NSString *)icon withTarget:(nullable id)target withSelector:(nullable SEL)selector{
    UIColor *color = [UIColor pb_colorWithHexString:PB_NAVIBAR_TINT_STRING];
    return [self barWithIcon:icon withColor:color withTarget:target withSelector:selector];
}

- (UIBarButtonItem *)barWithIcon:(NSString *)icon withColor:(UIColor *)color withTarget:(nullable id)target withSelector:(nullable SEL)selector{
    return [self barWithIcon:icon withSize:PB_NAVIBAR_ITEM_SIZE withColor:color withTarget:target withSelector:selector];
}

- (UIBarButtonItem *)barWithIcon:(NSString *)icon withSize:(NSInteger)size withColor:(UIColor *)color withTarget:(nullable id)target withSelector:(nullable SEL)selector{
    UIImage *bar_img = [UIImage pb_iconFont:nil withName:icon withSize:size withColor:color];
    return [self assembleBar:bar_img withTarget:target withSelector:selector];
}

- (UIBarButtonItem *)barWithImage:(UIImage *)icon withTarget:(id)target withSelector:(SEL)selector {
    return [self barWithImage:icon withColor:nil withTarget:target withSelector:selector];
}

- (UIBarButtonItem *)barWithImage:(UIImage *)icon withColor:(UIColor *)color withTarget:(id)target withSelector:(SEL)selector {
    if (color != nil) {
        icon = [icon pb_darkColor:color lightLevel:1];
    }
    return [self assembleBar:icon withTarget:target withSelector:selector];
}

- (UIBarButtonItem *)assembleBar:(UIImage *)icon withTarget:(id)target withSelector:(SEL)selector {
    
    CGSize m_bar_size = {PB_NAVIBAR_ITEM_SIZE, PB_NAVIBAR_ITEM_SIZE};
    UIButton *menu = [UIButton buttonWithType:UIButtonTypeCustom];
    //    menu.backgroundColor = [UIColor blueColor];
    menu.frame = (CGRect){.origin = CGPointZero,.size = m_bar_size};
    [menu setImage:icon forState:UIControlStateNormal];
    //    [menu setBackgroundImage:icon forState:UIControlStateNormal];
    [menu addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bar = [[UIBarButtonItem alloc] initWithCustomView:menu];
    return bar;
}

#pragma mark -- navigationBar event

- (void)backBarItemTouchEvent {
    if (self.presentationMode & FLKViewPresentationPushed) {
        [self.navigationController popViewControllerAnimated:true];
    } else {
        [self dismissViewControllerAnimated:true completion:nil];
    }
}

- (void)defaultGoBackStack {
    [self backBarItemTouchEvent];
}

#pragma mark -- navigationBar stack change method

- (void)backStack2Class:(Class)aClass {
    if (aClass == nil) {
        return;
    }
    NSArray *tmps = self.navigationController.viewControllers;
    __block NSMutableArray *__tmp = [NSMutableArray array];
    [tmps enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:aClass] ||
            [obj isMemberOfClass:aClass] ||
            obj.class == aClass) {
            
            *stop = true;
        }
        [__tmp addObject:obj];
    }];
    [self.navigationController setViewControllers:[__tmp copy] animated:true];
}

- (void)replaceStack4Class:(Class)aClass {
    if (aClass == nil) {
        return;
    }
    
    UIViewController * m_instance = [[aClass alloc] init];
    if (m_instance) {
        [self replaceStack4Instance:m_instance];
    }
}

- (void)replaceStack4Instance:(UIViewController *)aInstance {
    NSArray *tmps = self.navigationController.viewControllers;
    __block NSMutableArray *__tmp = [NSMutableArray array];
    [tmps enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[self class]] ||
            [obj isMemberOfClass:[self class]] ||
            obj.class == self.class) {
            *stop = true;
        }else{
            [__tmp addObject:obj];
        }
    }];
    
    if (aInstance != nil) {
        [__tmp addObject:aInstance];
        [self.navigationController setViewControllers:[__tmp copy] animated:true];
    }
}

#pragma mark -- handle networking error

/**
 此方法在用户授权成功后调用，此时需要更新Authorization Token
 @attentions: this method need be implememented by the subClasses.
 */
- (void)resumeCMDWhileAfterUsrAuthorizeSuccess {
    
}

//push or present usr oauthor profiler

- (void)displayUserAuthorizationProfiler:(UIViewController *)ctr {
    if (!ctr) {
        return;
    }
    
    UINavigationController *naviCtr = self.navigationController;
    if (naviCtr) {
        [naviCtr pushViewController:ctr animated:true];
    } else {
        [self presentViewController:ctr animated:true completion:nil];
    }
}

- (void)handleNetworkingActivityError:(NSError *)error {
    if (error == nil) {
        return;
    }
    //deal with error logic!
    NSInteger code = error.code;
    if (code == 1000) {     //need usr authorized
        NSString *selfClassStr = NSStringFromClass(self.class).lowercaseString;
        NSRange loginRange = [selfClassStr rangeOfString:@"login"];
        NSRange authorRange = [selfClassStr rangeOfString:@"author"];
        NSRange signRange = [selfClassStr rangeOfString:@"sign"];
        if (loginRange.location != NSNotFound || authorRange.location != NSNotFound || signRange.location != NSNotFound) {
            //self class is the login view
            excuteMainBlock(^{
                [SVProgressHUD showErrorWithStatus:error.domain];
            });
        } else {
            //TODO: need present login view, switch to login vcr
            
            /** Program 1: switch root view
             *
             *  must implement the selector:#switchRootView2AuthorProfiler for appDelegate class!!!
             *
             *  result:not the better
             
            AppDelegate *app = [self appDelegate];
            SEL aSelector = @selector(switchRootView2AuthorProfiler);
            if (app && [app respondsToSelector:aSelector]) {
                [app performSelectorOnMainThread:aSelector withObject:nil waitUntilDone:true];
            }
             */
            
            /** Program 2:present or push login by url mediator
             *
             *  use url mediator router
             *
             */
            NSString *urlString = [NSString stringWithFormat:@"%@://FLKAuthorProfile/%@",PB_SAFE_SCHEME, PB_INIT_METHOD_PARAMS];
            NSURL *nativeURL = [NSURL URLWithString:urlString];
            __weak typeof(&*self) weakSelf = self;
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf,PB_OBJC_CMD_TARGET, nil];
            UIViewController *authorProfiler = [[PBMediator shared] nativeCallWithURL:nativeURL withParams:params];
            [self displayUserAuthorizationProfiler:authorProfiler];
        }
    } else if (code == 1001) {
        
    } else {
        // other error that unknown, also can report it to service
        excuteMainBlock(^{
            [SVProgressHUD showErrorWithStatus:error.domain];
        });
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

#pragma mark == extern or export variables/functions

void checkNavigationStack(UIViewController *wk) {
    assert(wk.navigationController != nil);
}

NSString * const PB_STORAGE_DB_NAME                                         =   @"com.flk.app.db";

NSString * const PB_SERVICE_GROUP_IDENTIFIER                                =   @"com.flk.app-ios.service.group";

NSString * const PB_CLIENT_DID_AUTHORIZED_NOTIFICATION                      =   @"com.flk.app.notify-did.authorized";
NSString * const PB_CLIENT_DID_UNAUTHORIZED_NOTIFICATION                    =   @"com.flk.app.notify-did.unauthorized";
