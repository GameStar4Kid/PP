//
//  LocationModel.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/20/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "LocationModel.h"

@implementation LocationModel

- (instancetype)initWithLatitude:(double)latitude andLongitude:(double)longitude {
    self = [super init];
    if (self) {
        self.latitude = latitude;
        self.longitude = longitude;
    }
    
    return self;
}

@end
