//
//  UINavigationController+iOSAutorotation.m
//  PP
//
//  Created by Duong Quoc Thang on 7/20/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "UINavigationController+iOSAutorotation.h"

@implementation UINavigationController (iOSAutorotation)

-(BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

@end
