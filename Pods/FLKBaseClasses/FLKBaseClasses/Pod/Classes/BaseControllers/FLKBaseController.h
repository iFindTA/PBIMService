//
//  FLKBaseController.h
//  FLKSecretSessionPro
//
//  Created by nanhu on 2016/11/10.
//  Copyright © 2016年 nanhu. All rights reserved.
//

/**
 FLK Base Classes
 *
 *  Dependency:
 *  <PBKits>
 *  <PBMediator>
 *  <WZLBadge>
 *  <SVProgressHUD>
 *  -- <SAMKeychain>:need for subclass
 *  -- <Masonry>:no nedeed, but can install previously for user
 *
 */
#import <UIKit/UIKit.h>
#import "FLKConstanits.h"
#import <PBKits/PBKits.h>
#import <PBMediator/PBMediator.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface FLKBaseController : UIViewController

NS_ASSUME_NONNULL_BEGIN

/**
 indicate self wether initialized, default is no
 */
@property (nonatomic, assign, readonly) BOOL wetherInited;

/**
 indicate wether self should response on other button touch event
 */
@property (nonatomic, assign) BOOL busy;

/**
 the custom navigationBar
 */
@property (nonatomic, strong, readonly) UINavigationBar *navigationBar;

/**
 end input mode
 */
- (void)endEditingMode;

#pragma mark -- navigationBar item

/**
 hidden custom navigationBar, move bar outof screen to headtop!
 */
- (void)hiddenNavigationBar;

/**
 navigationBar item

 @return the bar item
 */
- (UIBarButtonItem *)barSpacer;

/**
 generate navigationBar back item

 @param backTitle title for item
 @return the bar item
 */
- (UIBarButtonItem *)backBarButtonItem:(NSString * _Nullable)backTitle;

/**
 generate navigationBar back item

 @param backTitle title for item
 @param img : title image, default is back
 @return : bar item
 */
- (UIBarButtonItem *)backBarButtonItem:(NSString * _Nullable)backTitle withIcon:(NSString * _Nullable)img;

/**
 *  @brief generate custom barItem: default::color:FFFFFF/size:31
 *
 *  @param icon     iconfont's name
 *  @param target   iconfont's target
 *  @param selector iconfont's selector
 *
 *  @return the bar item
 */
- (UIBarButtonItem *)barWithIcon:(NSString *)icon withTarget:(nullable id)target withSelector:(nullable SEL)selector;

/**
 *  @brief generate custom barItem: default::size:31
 *
 *  @param icon  iconfont's name
 *  @param color bar's front color
 *  @param target   iconfont's target
 *  @param selector iconfont's selector
 *
 *  @return the bar item
 */
- (UIBarButtonItem *)barWithIcon:(NSString *)icon withColor:(UIColor *)color withTarget:(nullable id)target withSelector:(nullable SEL)selector;

/**
 *  @brief generate custom barItem: default::size:31
 *
 *  @param icon     the icon image
 *  @param target   bar's target
 *  @param selector bar's selector
 *
 *  @return the bar item
 */
- (UIBarButtonItem *)barWithImage:(UIImage *)icon withTarget:(nullable id)target withSelector:(nullable SEL)selector;

/**
 *  @brief generate custom barItem: default::size:31
 *
 *  @param icon     the icon image
 *  @param color    the icon image's tintColor, default is whiteColor
 *  @param target   bar's target
 *
 *  @param selector bar's selector
 *
 *  @return the bar item
 */
- (UIBarButtonItem *)barWithImage:(UIImage *)icon withColor:(nullable UIColor *)color withTarget:(nullable id)target withSelector:(nullable SEL)selector;

/**
 default pop stack or dismiss event
 */
- (void)defaultGoBackStack;

#pragma mark -- user interface jump hirenic

/**
 make the navigation stack back to the class

 @param aClass the class
 */
- (void)backStack2Class:(Class)aClass;

/**
 replace self by the class in current navigation stacks

 @param aClass the class to show
 */
- (void)replaceStack4Class:(Class)aClass;

/**
 replace self by the instance in current navigation stacks

 @param aInstance the class's instance
 */
- (void)replaceStack4Instance:(UIViewController *)aInstance;

#pragma mark -- handle networking error

/**
 resume one selector while the selector need usr's authorization, and usr authorization successfully!
 */
- (void)resumeCMDWhileAfterUsrAuthorizeSuccess NS_REQUIRES_SUPER;

/**
 handle the error while network activity

 @param error the error
 */
- (void)handleNetworkingActivityError:(NSError *)error;

@end

#pragma mark -- check viewController's navigationController wether nil or not

FOUNDATION_EXTERN void checkNavigationStack(UIViewController *wk);

NS_ASSUME_NONNULL_END
