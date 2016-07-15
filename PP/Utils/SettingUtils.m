//
//  SettingUtils.m
//  PP
//
//  Created by Nguyen Tran on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "SettingUtils.h"
@interface SettingUtils()
{
}
@end
__strong static SettingUtils* _sharedInstance = nil;
@implementation SettingUtils
+ (SettingUtils *)sharedInstance
{
    @synchronized(self)
    {
        if (nil == _sharedInstance)
        {
            _sharedInstance = [[SettingUtils alloc] init];
        }
    }
    return _sharedInstance;
}
- (id)init
{
    if(self=[super init])
    {
        [self loadData];
    }
    return self;
}
- (void)saveDataWhenTerminate
{
    [[NSUserDefaults standardUserDefaults] setObject:_deviceUDID forKey:@"deviceUDID"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"deviceName"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"GPSSetting_SavePeriod"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"GPSSetting_AccuracyFilter"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"GPSSetting_DistanceFilter"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)loadData
{
    _deviceName = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceName"];
    _deviceUDID = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceUDID"];
    _savePeriod = [[NSUserDefaults standardUserDefaults] stringForKey:@"GPSSetting_SavePeriod"];
    _accurracyFilter = [[NSUserDefaults standardUserDefaults] stringForKey:@"GPSSetting_AccuracyFilter"];
    _distanceFilter = [[NSUserDefaults standardUserDefaults] stringForKey:@"GPSSetting_DistanceFilter"];
}
@end
