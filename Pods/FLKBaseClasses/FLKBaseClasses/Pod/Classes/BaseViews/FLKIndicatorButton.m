//
//  FLKIndicatorButton.m
//  FLKBaseClasses
//
//  Created by nanhu on 2016/11/15.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKIndicatorButton.h"

@interface FLKIndicatorButton ()

@property (nonatomic, assign, readwrite) BOOL busyState;

@property (nonatomic, strong) UIColor *originFontColor;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation FLKIndicatorButton

- (void)makeActivity:(BOOL)act {
    if (act == self.busyState) {
        return;
    }
    
    if (act) {
        [self.indicator startAnimating];
    } else {
        [self.indicator stopAnimating];
    }
    self.imageView.layer.opacity = act?0:1;
    UIColor *mColor = [self.originFontColor colorWithAlphaComponent:act?0:1];
    [self setTitleColor:mColor forState:UIControlStateNormal];
    self.busyState = act;
}

#pragma mark -- getter
- (BOOL)wetherBusy {
    return _busyState;
}

- (UIActivityIndicatorView *)indicator {
    if (!_indicator) {
        self.originFontColor = self.titleLabel.textColor;
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.hidesWhenStopped = true;
        _indicator.translatesAutoresizingMaskIntoConstraints = false;
        [self addSubview:_indicator];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_indicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_indicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    }
    return _indicator;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
