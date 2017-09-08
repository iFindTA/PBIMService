//
//  FLKBaseTabBarItem.m
//  FLKBaseClasses
//
//  Created by nanhujiaju on 2017/1/12.
//  Copyright © 2017年 nanhu. All rights reserved.
//

#import "FLKBaseTabBarItem.h"
#import "FLKConstanits.h"

@implementation FLKBaseTabBarItem

- (instancetype)init {
    self = [super init];
    if (self) {
        [self __initSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self __initSetup];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)selectedImage {
    self = [super initWithTitle:title image:image selectedImage:selectedImage];
    if (self) {
        [self __initSetup];
    }
    return self;
}

- (void)__initSetup {
    
    self.image = [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.selectedImage = [self.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIColor *iconTintColor = PBColorMake(PB_TABBAR_TINT_HEX);
    [self setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]} forState:UIControlStateNormal];
    [self setTitleTextAttributes:@{NSForegroundColorAttributeName:iconTintColor} forState:UIControlStateSelected];
}

@end
