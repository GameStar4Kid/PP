//
//  CommonMethods.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/14/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "CommonMethods.h"

@implementation CommonMethods

+ (CGFloat)widthOfLabel:(UILabel *)label andHeightOfLabel:(CGFloat)height {
    CGSize size = [label sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)];
    
    return size.width;
}

+ (NSString *)stringFromDate:(NSDate *)date andFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    NSString *string =[formatter stringFromDate:date];
    
    return string;
}

@end
