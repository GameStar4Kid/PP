//
//  Height2DView.m
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "Height2DView.h"

@implementation Height2DView

- (id)init {
    self = [super init];
    if (self) {
        self.x = -1;
    }
    return self;
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
}
@end
