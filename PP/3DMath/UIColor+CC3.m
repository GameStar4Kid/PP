//
//  UIColor+CC3.m
//  PP
//
//  Created by Duong Quoc Thang on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "UIColor+CC3.h"

@implementation UIColor (CC3)

-(ccColor4F) asCCColor4F {
    ccColor4F rgba = kCCC4FWhite;  // initialize to white
    
    CGColorRef cgColor= self.CGColor;
    size_t componentCount = CGColorGetNumberOfComponents(cgColor);
    const CGFloat* colorComponents = CGColorGetComponents(cgColor);
    switch(componentCount) {
        case 4:			// RGB + alpha: set alpha then fall through to RGB
            rgba.a = colorComponents[3];
        case 3:			// RGB: alpha already set
            rgba.r = colorComponents[0];
            rgba.g = colorComponents[1];
            rgba.b = colorComponents[2];
            break;
        case 2:			// gray scale + alpha: set alpha then fall through to gray scale
            rgba.a = colorComponents[1];
        case 1:		// gray scale: alpha already set
            rgba.r = colorComponents[0];
            rgba.g = colorComponents[0];
            rgba.b = colorComponents[0];
            break;
        default:	// if all else fails, return white which is already set
            break;
    }
    return rgba;
}

+(UIColor*) colorWithCCColor4F: (ccColor4F) rgba {
    return [UIColor colorWithRed: rgba.r green: rgba.g blue: rgba.b alpha: rgba.a];
}

@end
