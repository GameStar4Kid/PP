//
//  BLEItem.h
//  PP
//
//  Created by Nguyen Tran on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEItem : NSObject
@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSString* UDID;
- (id)initWithName:(NSString*)name UDID:(NSString*)UDID;
@end
