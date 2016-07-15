//
//  SettingUtils.h
//  PP
//
//  Created by Nguyen Tran on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface SettingUtils : NSObject

+ (SettingUtils *)sharedInstance;
@property(nonatomic,strong) NSString* deviceUDID;
@property(nonatomic,strong) NSString* deviceName;
@property (nonatomic, strong) NSString *savePeriod;
@property (nonatomic, strong) NSString *accurracyFilter;
@property (nonatomic, strong) NSString *distanceFilter;
- (void)saveDataWhenTerminate;
@end
