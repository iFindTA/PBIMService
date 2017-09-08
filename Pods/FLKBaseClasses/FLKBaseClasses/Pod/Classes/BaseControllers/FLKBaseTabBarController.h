//
//  FLKBaseTabBarController.h
//  FLKBaseClasses
//
//  Created by nanhu on 2016/11/16.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLKConstanits.h"
#import <PBKits/PBKits.h>
#import <WZLBadge/WZLBadgeImport.h>

NS_ASSUME_NONNULL_BEGIN


/**
 root tabBar Controller
 *
 *  Dependency:
 *
 *  -----------------pod libs---------------------
 *  <WZLBadge>
 *
 */
@interface FLKBaseTabBarController : UITabBarController

/**
 generate tabBar Controller

 @param cls the root controllers for per tab
 @return the instance
 */
- (id)initWithRootClasses:(NSArray <Class>*)cls;

/**
 update badge value for index

 @param style badge stayle
 @param num badge value
 @param index tabBar index
 */
- (void)updateBadgeStyle:(WBadgeStyle)style value:(NSUInteger)num atIndex:(NSUInteger)index;

/**
 clear badge value for index

 @param index tabBar index
 */
- (void)clearBadgeAtIndex:(NSUInteger)index;

NS_ASSUME_NONNULL_END

@end
