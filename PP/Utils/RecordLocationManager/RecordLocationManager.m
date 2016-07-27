//
//  RecordLocationManager.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/27/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "RecordLocationManager.h"
#import "CommonMethods.h"
#import "LocationModel.h"

@import CoreLocation;

static NSUInteger const kMaxNumberOfRows = 50;
static NSString *kSignForLineHasNewLocation = @"o";
static NSString *kSignForLineHasNotNewLocation = @"x";
static NSString *kDateFormatForFileName = @"yyyy_MM_dd_HH_mm_ss";
static NSString *kDateFormatForRecordInCSVFile = @"yyyy/MM/dd HH:mm:ss";
static NSString *kDocumentsFolder = @"Documents";
static NSString *kFolderNameHoldAllOfCSVFile = @"CSVFolder";

@interface RecordLocationManager ()<CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSTimer *intervalTimer;
@property (strong, nonatomic) NSTimer *maxRecordTimer;
@property (strong, nonatomic) NSTimer *retryTimer;
@property (strong, nonatomic) NSString *pathFile;
@property (strong, nonatomic) LocationModel *latestLocation;
@property (nonatomic) BOOL hasErrorLine;

@end

@implementation RecordLocationManager

+ (instancetype)sharedInstance {
    static RecordLocationManager *sharedInstnace = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstnace = [[RecordLocationManager alloc] initPrivate];
    });
    
    return sharedInstnace;
}

+ (BOOL)isLocationSeviceEnabled {
    
    return [CLLocationManager locationServicesEnabled];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    
    return self;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations[0];
    self.latestLocation = [[LocationModel alloc] initWithLatitude:location.coordinate.latitude andLongitude:location.coordinate.longitude];
    GPSSavePeriodType type = [[SettingUtils sharedInstance] savePeriodFromSetting];
    if (type == GPSSavePeriodType_Long24h) {
        if (self.retryTimer) {
            [self stopRetringGetNewLocation:NO];
        }
        if (self.intervalTimer) {
            [self stopUpdatingNewLocation];
        } else {
            [self stopUpdatingLocationService];
        }
    } else {
        [self stopUpdatingNewLocation];
    }
    [self saveDataToFileCSVWithLocation:location];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    GPSSavePeriodType type = [[SettingUtils sharedInstance] savePeriodFromSetting];
    if (type == GPSSavePeriodType_Long24h) {
        [self stopUpdatingLocationService];
        [self startUpdatingLocationService];
        if (!self.retryTimer ) {
            self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(stopRetringGetNewLocation:) userInfo:nil repeats:NO];
        }
    } else {
        [self stopUpdatingNewLocation];
        [self saveDataToFileCSVWithLocation:nil];
    }
}

#pragma mark - Private Methods

- (void)startLocationServiceAndRecordLocation {
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = [self accuracyFilterFromSetting];
    self.locationManager.distanceFilter = [self distanceFilterFromSetting];
    GPSSavePeriodType type = [[SettingUtils sharedInstance] savePeriodFromSetting];
    NSInteger maxRecord = 0;
    switch (type) {
        case GPSSavePeriodType_Long24h:
            maxRecord = 24 * 60 * 60 + 30;
            break;
        case GPSSavePeriodType_Short15m:
            maxRecord = 15 * 60;
            break;
        case GPSSavePeriodType_Short30m:
            maxRecord = 30 * 60;
            break;
        case GPSSavePeriodType_Short1h:
            maxRecord = 60 * 60;
            break;
            
        default:
            break;
    }
    self.maxRecordTimer = [NSTimer scheduledTimerWithTimeInterval:maxRecord
                                                           target:self
                                                         selector:@selector(willStopRecordingData)
                                                         userInfo:nil
                                                          repeats:NO];
    self.isRecordingData = YES;
    NSString *fileName = [CommonMethods stringFromDate:[NSDate date] andFormat:kDateFormatForFileName];
    NSString *header = [NSString stringWithFormat:@"取得状況, 日時, 緯度, 経度\n"];
    [self createFileCSVWith:fileName andContent:header];
    if (self.locationDatas) {
        [self.locationDatas removeAllObjects];
    } else {
        self.locationDatas = [[NSMutableArray alloc] init];
    }
    [self.locationManager startUpdatingLocation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willStopRecordingData:) name:NOTIFICATION_FOR_STOPPING_RECORDING_LOCATION_BY_POSITION_VIEW_CONTROLLER object:nil];
}

- (void)saveDataToFileCSVWithLocation:(CLLocation *)location {
    //1. Add location to data list
    LocationModel *model = [[LocationModel alloc] init];
    model.date = [NSDate date];
    NSString *status = @"";
    if (location) {
        model.isSuccess = YES;
        model.latitude = location.coordinate.latitude;
        model.longitude = location.coordinate.longitude;
        status = kSignForLineHasNewLocation;
        for (int i = 0; i < self.locationDatas.count; i++) {
            LocationModel *locationObj = self.locationDatas[i];
            if (locationObj.isSuccess) {
                break;
            } else {
                locationObj.latitude = model.latitude;
                locationObj.longitude = model.longitude;
                self.locationDatas[i] = locationObj;
                locationObj = nil;
            }
        }
    } else {
        model.isSuccess = NO;
        if (self.latestLocation) {
            model.latitude = self.latestLocation.latitude;
            model.longitude = self.latestLocation.longitude;
        } else {
            model.latitude = CGFLOAT_MIN;
            model.longitude = CGFLOAT_MIN;
            self.hasErrorLine = YES;
        }
        status = kSignForLineHasNotNewLocation;
    }
    if (self.locationDatas.count >= kMaxNumberOfRows) {
        [self.locationDatas removeLastObject];
    }
    [self.locationDatas addObject:model];
    
    //2. Update to the line error in file csv
    if (self.hasErrorLine && location != nil) {
        NSString *content = [NSString stringWithContentsOfFile:self.pathFile encoding:NSUTF8StringEncoding error:nil];
        NSArray *listRows = [content componentsSeparatedByString:@"\n"];
        NSMutableArray *listLocations = [NSMutableArray arrayWithArray:listRows];
        [listLocations removeLastObject];
        for (NSInteger i = listLocations.count - 1; i > 0; i--) {
            NSString *dataInRow = listLocations[i];
            NSArray *row = [dataInRow componentsSeparatedByString:@","];
            NSMutableArray *rowDetail = [NSMutableArray arrayWithArray:row];
            NSString *statusOfRow = rowDetail[0];
            if ([statusOfRow isEqualToString:kSignForLineHasNewLocation]) {
                
                break;
            } else {
                rowDetail[2] = [NSString stringWithFormat:@" %0.8f", model.latitude];
                rowDetail[3] = [NSString stringWithFormat:@" %0.8f", model.longitude];
                NSString *dataInRowEdited = @"";
                for (int j = 0; j < rowDetail.count; j++) {
                    dataInRowEdited = [dataInRowEdited stringByAppendingFormat:@"%@,", rowDetail[j]];
                }
                listLocations[i] = dataInRowEdited;
            }
        }
        NSError *removeFileError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.pathFile error:&removeFileError];
        if (removeFileError) {
            
        } else {
            NSString *newContent = @"";
            for (NSString *string in listLocations) {
                newContent = [newContent stringByAppendingFormat:@"%@\n", string];
            }
            [self createFileCSVWith:[self nameOfCSVFile] andContent:newContent];
        }
    }
    
    //3. Save location to file csv
    NSString *writeString = [NSString stringWithFormat:@"%@, %@, %0.8f, %0.8f\n", status, [CommonMethods stringFromDate:model.date andFormat:kDateFormatForRecordInCSVFile], model.latitude, model.longitude];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:self.pathFile];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //4. Reload data on the tableview
    if (self.locationDatas.count > 1) {
        [self.locationDatas sortUsingComparator:^NSComparisonResult(LocationModel *obj1, LocationModel *obj2) {
            return [obj2.date compare:obj1.date];
        }];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FOR_RELOADING_DATA_ON_THE_TABLEVIEW
                                                        object:nil
                                                      userInfo:nil];
    
    //5. Continue updating new location
    GPSSavePeriodType type = [[SettingUtils sharedInstance] savePeriodFromSetting];
    NSInteger interval = 1;
    if (type == GPSSavePeriodType_Long24h) {
        interval = 120;
    }
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(startUpdatingLocationService)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)createFileCSVWith:(NSString *)name andContent:(NSString *)content{
    NSString *fileName = [NSString stringWithFormat:@"%@.csv", name];
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:kDocumentsFolder];
    NSString *pathToCSVFolder = [documentsDirectory stringByAppendingPathComponent:kFolderNameHoldAllOfCSVFile];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:pathToCSVFolder withIntermediateDirectories:NO attributes:nil error:&error];
    
    self.pathFile = [pathToCSVFolder stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.pathFile]) {
        [[NSFileManager defaultManager] createFileAtPath:self.pathFile contents:[content dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    self.hasErrorLine = NO;
}

- (void)stopRetringGetNewLocation:(BOOL)isSave {
    [self stopUpdatingLocationService];
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    if (isSave) {
        [self saveDataToFileCSVWithLocation:nil];
    }
}

- (void)startUpdatingLocationService {
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocationService {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

- (void)stopUpdatingNewLocation {
    [self stopUpdatingLocationService];
    if (self.intervalTimer) {
        [self.intervalTimer invalidate];
        self.intervalTimer = nil;
    }
}

- (void)willStopRecordingData {
    [self stopRecordingData];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FOR_STOPPING_RECORDING_LOCATION_BY_RECORD_LOCATION_MANAGER object:nil userInfo:nil];
}

- (void)stopRecordingData {
    [self stopUpdatingNewLocation];
    [self.maxRecordTimer invalidate];
    self.maxRecordTimer = nil;
    self.latestLocation = nil;
    self.pathFile = nil;
    self.hasErrorLine = NO;
    self.isRecordingData = NO;
}

- (void)willStopRecordingData:(NSNotification *)noti {
    [self stopRecordingData];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FOR_STOPPING_RECORDING_LOCATION_BY_POSITION_VIEW_CONTROLLER object:nil];
}

- (CLLocationAccuracy)accuracyFilterFromSetting {
    NSString *accuracyFilter = [SettingUtils sharedInstance].accurracyFilter;
    
    if ([accuracyFilter isEqualToString:GPS_ACCURACY_FILTER_100M]) {
        
        return kCLLocationAccuracyHundredMeters;
    }
    
    return kCLLocationAccuracyNearestTenMeters;
}

- (NSUInteger)distanceFilterFromSetting {
    NSString *string = [SettingUtils sharedInstance].distanceFilter;
    NSUInteger distanceFilter = 5;
    if ([string isEqualToString:GPS_DISTANCE_FILTER_10M]) {
        
        distanceFilter = 10;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_50M]) {
        
        distanceFilter = 50;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_100M]) {
        
        distanceFilter = 100;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_500M]) {
        
        distanceFilter = 500;
    }
    
    return distanceFilter;
}

- (NSString *)nameOfCSVFile {
    if (self.pathFile.length > 0) {
        return [[self.pathFile lastPathComponent] stringByDeletingPathExtension];
    }
    
    return @"";
}

@end
