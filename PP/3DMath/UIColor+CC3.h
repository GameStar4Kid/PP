//
//  UIColor+CC3.h
//  PP
//
//  Created by Duong Quoc Thang on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "CC3Foundation.h"

@interface UIColor (CC3)

/** Returns a transparent ccColor4F struct containing the RGBA values for this color. */
-(ccColor4F) asCCColor4F;

/** Returns an autoreleased UIColor instance created from the RGBA values in the specified ccColor4F. */
+(UIColor*) colorWithCCColor4F: (ccColor4F) rgba;

@end
