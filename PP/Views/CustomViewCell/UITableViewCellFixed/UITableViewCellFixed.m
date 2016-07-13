//
//  UITableViewCellFixed.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/13/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "UITableViewCellFixed.h"

static CGFloat const kPaddingLeft = 31.0;

@implementation UITableViewCellFixed

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(kPaddingLeft,
                                      0,
                                      self.contentView.bounds.size.width - kPaddingLeft,
                                      self.contentView.bounds.size.height);
}

@end
