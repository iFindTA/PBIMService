//
//  FLKIndicatorButton.h
//  FLKBaseClasses
//
//  Created by nanhu on 2016/11/15.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 custom button in order to add one state: activity indicator for event, such as:network
 */
@interface FLKIndicatorButton : UIButton

/**
 query current busy state
 */
@property (nonatomic, assign, readonly, getter=wetherBusy) BOOL busyState;

/**
 change current busy state

 @param act wether animate
 */
- (void)makeActivity:(BOOL)act;

@end
