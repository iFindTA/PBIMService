//
//  FLKBaseView.m
//  FLKBaseClasses
//
//  Created by nanhu on 2016/11/28.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKBaseView.h"

@interface FLKBaseView ()

@property (nonatomic, strong) UILabel *placeholder;

@property (nonatomic, assign) BOOL wetherShowPlaceholder;

@end

@implementation FLKBaseView

- (void)showPlaceholder:(BOOL)show withInfo:(NSString *)holder {
    if ((!show && self.placeholder.hidden)||(show && self.placeholder.hidden)) {
        return;
    }
    
    if (show) {
        holder = holder.length==0?@"暂无内容":holder;
        self.placeholder.text = holder;
        //[self adjustPlaceholder];
    } else {
        [self.placeholder removeFromSuperview];
        _placeholder = nil;
    }
    self.wetherShowPlaceholder = show;
}

- (void)adjustPlaceholder {
    
    NSLayoutConstraint *constraint_top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *constraint_bot = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *constraint_let = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    NSLayoutConstraint *constraint_rgh = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    [self.placeholder addConstraints:@[constraint_top, constraint_bot, constraint_let, constraint_rgh]];
}

#pragma mark -- getter

- (UILabel *)placeholder {
    if (!_placeholder) {
        UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
        label.font = [UIFont systemFontOfSize:17];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor grayColor];
        _placeholder = label;
    }
    
    return _placeholder;
}

#pragma mark -- layout subviews

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.wetherShowPlaceholder) {
        [self didTouchErrorPlaceholder];
    }
}

- (void)didTouchErrorPlaceholder {}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
