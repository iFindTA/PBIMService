//
//  FLKBaseCell.m
//  FLKBaseClasses
//
//  Created by nanhu on 2016/12/2.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKBaseCell.h"

@implementation FLKBaseCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self __initSetupBaseProperties];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self __initSetupBaseProperties];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)__initSetupBaseProperties {
    self.contentView.backgroundColor = [UIColor whiteColor];
}

@end
