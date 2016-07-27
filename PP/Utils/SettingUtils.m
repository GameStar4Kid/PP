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
        self.dateFormatter = [[NSDateFormatter alloc] init];
    }
    return self;
}
- (void)setDeviceName:(NSString *)deviceName
{
    _deviceName=deviceName;
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"deviceName"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"GPSSetting_SavePeriod"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"GPSSetting_AccuracyFilter"];
    [[NSUserDefaults standardUserDefaults] setObject:_deviceName forKey:@"GPSSetting_DistanceFilter"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setDeviceUDID:(NSString *)deviceUDID
{
    _deviceUDID = deviceUDID;
    [[NSUserDefaults standardUserDefaults] setObject:_deviceUDID forKey:@"deviceUDID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setLastSync:(NSString *)lastSync
{
    _lastSync = lastSync;
    [[NSUserDefaults standardUserDefaults] setObject:_lastSync forKey:@"lastSync"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setSavePeriod:(NSString *)savePeriod
{
    _savePeriod = savePeriod;
    [[NSUserDefaults standardUserDefaults] setObject:_lastSync forKey:@"savePeriod"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setAccurracyFilter:(NSString *)accurracyFilter
{
    _accurracyFilter = accurracyFilter;
    [[NSUserDefaults standardUserDefaults] setObject:_lastSync forKey:@"accurracyFilter"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setDistanceFilter:(NSString *)distanceFilter
{
    _distanceFilter = distanceFilter;
    [[NSUserDefaults standardUserDefaults] setObject:_lastSync forKey:@"distanceFilter"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)loadData
{
    _deviceName = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceName"];
    _deviceUDID = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceUDID"];
    _savePeriod = [[NSUserDefaults standardUserDefaults] stringForKey:@"savePeriod"];
    _accurracyFilter = [[NSUserDefaults standardUserDefaults] stringForKey:@"accurracyFilter"];
    _distanceFilter = [[NSUserDefaults standardUserDefaults] stringForKey:@"distanceFilter"];
    _lastSync = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastSync"];
}

- (GPSSavePeriodType)savePeriodFromSetting {
    NSString *savePeriod = self.savePeriod;
    GPSSavePeriodType type = GPSSavePeriodType_Long24h;
    
    if ([savePeriod isEqualToString:GPS_SAVE_PERIOD_SHORT_15M]) {
        type = GPSSavePeriodType_Short15m;
    } else if ([savePeriod isEqualToString:GPS_SAVE_PERIOD_SHORT_30M]) {
        type = GPSSavePeriodType_Short30m;
    } else if ([savePeriod isEqualToString:GPS_SAVE_PERIOD_SHORT_1H]) {
        type = GPSSavePeriodType_Short1h;
    }
    
    return type;
}

@end
