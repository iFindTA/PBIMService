//
//  FLKBaseNavigationController.m
//  FLKSecretSessionPro
//
//  Created by nanhu on 2016/11/10.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKBaseNavigationController.h"
#import <objc/message.h>

NSString * const FLK_NAVISTACK_PUSH_SAME_SEL            =   @"canPushThisClassRepeatly";

@interface FLKBaseNavigationController ()

@property (nonatomic, strong) dispatch_queue_t excuteQueue;

@end

@implementation FLKBaseNavigationController

- (void)loadView {
    [super loadView];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- override push method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    BOOL isExists = [self isClassExist4Instance:viewController];
    if (isExists) {
        SEL aSel = NSSelectorFromString(FLK_NAVISTACK_PUSH_SAME_SEL);
        if ([viewController respondsToSelector:aSel]) {
            BOOL (*msgSend)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
            BOOL canRepeatly = msgSend(viewController, aSel);
            if (canRepeatly) {
                [super pushViewController:viewController animated:animated];
            }
        }
    } else {
        [super pushViewController:viewController animated:animated];
    }
}

- (dispatch_queue_t)excuteQueue {
    if (!_excuteQueue) {
        _excuteQueue = dispatch_queue_create("com.flk.navigator-io.com", NULL);
    }
    
    return _excuteQueue;
}

- (BOOL)isClassExist4Instance:(UIViewController *)var {
    __block BOOL exist = false;
    
    NSArray <UIViewController *>*stacks = self.viewControllers;
    if (stacks.count > 0) {
        NSString *varClass = NSStringFromClass(var.class);
        UIViewController *tmpVar = [stacks lastObject];
        NSString *previousClass = NSStringFromClass(tmpVar.class);
        if (previousClass.length && [previousClass isEqualToString:varClass]) {
            exist = true;
        }
    }
//    __block NSMutableString *aClassSets = [NSMutableString stringWithCapacity:0];
//    [stacks enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [aClassSets appendString:NSStringFromClass(obj.class)];
//    }];
//    if (aClassSets.length > 0 && [aClassSets rangeOfString:NSStringFromClass(var.class)].location != NSNotFound) {
//        exist = true;
//    }
    
    return exist;
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
