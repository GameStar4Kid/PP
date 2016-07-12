//
//  BLEItem.m
//  PP
//
//  Created by Nguyen Tran on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "BLEItem.h"

@implementation BLEItem

- (id)initWithName:(NSString*)name UDID:(NSString*)UDID
{
    if(self=[super init])
    {
        self.name=name;
        self.UDID=UDID;
    }
    return self;
}
@end
