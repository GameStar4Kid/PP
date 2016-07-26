//
//  PositionViewController.m
//  PP
//
//  Created by Nguyen Tran on 7/8/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "PositionViewController.h"
#import "GPSSettingViewController.h"
#import "SettingUtils.h"
#import "LocationModel.h"
#import <UIAlertView+Blocks.h>

@import CoreLocation;

static NSUInteger const kMaxNumberOfRows = 50;

@interface PositionViewController ()<CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnGPSSetting;
@property (weak, nonatomic) IBOutlet UILabel *lblIntervalValue;
@property (weak, nonatomic) IBOutlet UILabel *lblMaxRecordTime;
@property (weak, nonatomic) IBOutlet UILabel *lblRecordStartTime;

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation PositionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[_btnStart layer] setBorderWidth:2.0f];
    [[_btnStart layer] setBorderColor:[UIColor blackColor].CGColor];
    [[_btnStop layer] setBorderWidth:2.0f];
    [[_btnStop layer] setBorderColor:[UIColor blackColor].CGColor];
    [[_btnGPSSetting layer] setBorderWidth:2.0f];
    [[_btnGPSSetting layer] setBorderColor:[UIColor blackColor].CGColor];
    if ([[SettingUtils sharedInstance].maxRecordTimer isValid]) {
        self.btnStart.enabled = NO;
        self.btnStop.enabled = YES;
    } else {
        self.btnStop.enabled = NO;
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"PositionInfo Dashboard", nil);
    GPSSavePeriodType type = [self savePeriodFromSetting];
    NSString *maxRecordTime = @"24H";
    NSString *interval = @"1 second";
    switch (type) {
        case GPSSavePeriodType_Long24h:
            interval = @"2 minutes";
            break;
        case GPSSavePeriodType_Short15m:
            maxRecordTime = @"15M";
            break;
        case GPSSavePeriodType_Short30m:
            maxRecordTime = @"30M";
            break;
        case GPSSavePeriodType_Short1h:
            maxRecordTime = @"1H";
            break;
            
        default:
            break;
    }
    self.lblIntervalValue.text = interval;
    self.lblMaxRecordTime.text = maxRecordTime;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[SettingUtils sharedInstance].locationDatas count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableView.frame.size.height/6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StaticCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StaticCell"];
        //        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        //        cell.backgroundColor=[UIColor yellowColor];
    }
    LocationModel *model = [[SettingUtils sharedInstance].locationDatas objectAtIndex:indexPath.row];
    NSString *status = @"取得成功";
    if (!model.isSuccess) {
        status = @"取得失敗";
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %0.3f-%0.3f", status, [self stringFromDate:model.date andFormat:@"yyyy/MM/dd HH:mm" ], model.latitude, model.longitude];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

#pragma mark - Action Methods

- (IBAction)tappedAtGPSSettingButton:(id)sender {
    GPSSettingViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GPSSettingViewController"];
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)tappedAtStartButton:(id)sender {
    if ([CLLocationManager locationServicesEnabled]) {
        if (nil == self.locationManager) {
            self.locationManager = [[CLLocationManager alloc] init];
        }
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = [self accuracyFilterFromSetting];
        self.locationManager.distanceFilter = [self distanceFilterFromSetting];
        GPSSavePeriodType type = [self savePeriodFromSetting];
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
        [SettingUtils sharedInstance].maxRecordTimer = [NSTimer scheduledTimerWithTimeInterval:maxRecord
                                                               target:self
                                                             selector:@selector(stopRecordData)
                                                             userInfo:nil
                                                              repeats:NO];
        self.btnStart.enabled = NO;
        self.btnStop.enabled = YES;
        NSString *fileName = [self stringFromDate:[NSDate date] andFormat:@"yyyy_MM_dd_HH_mm_ss"];
        NSString *header = [NSString stringWithFormat:@"取得状況, 日時, 緯度, 経度\n"];
        [self createFileCSVWith:fileName andContent:header];
        self.lblRecordStartTime.text = fileName;
        if ([SettingUtils sharedInstance].locationDatas) {
            [[SettingUtils sharedInstance].locationDatas removeAllObjects];
        } else {
            [SettingUtils sharedInstance].locationDatas = [[NSMutableArray alloc] init];
        }
        [self.locationManager startUpdatingLocation];
    } else {
        [UIAlertView showWithTitle:@"Warning!"
                           message:@"Location service was disabled."
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil
                          tapBlock:nil];
    }
}

- (IBAction)tappedAtStopButton:(id)sender {
    [self stopRecordData];
    self.btnStart.enabled = YES;
    self.btnStop.enabled = NO;
    if ([SettingUtils sharedInstance].retryTimer) {
        [[SettingUtils sharedInstance].retryTimer invalidate];
        [SettingUtils sharedInstance].retryTimer = nil;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations[0];
    [SettingUtils sharedInstance].latestLocation = [[LocationModel alloc] initWithLatitude:location.coordinate.latitude andLongitude:location.coordinate.longitude];
    GPSSavePeriodType type = [self savePeriodFromSetting];
    if (type == GPSSavePeriodType_Long24h) {
        if ([SettingUtils sharedInstance].retryTimer) {
            [self stopRetringGetNewLocation:NO];
        }
        if ([SettingUtils sharedInstance].intervalTimer) {
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
    GPSSavePeriodType type = [self savePeriodFromSetting];
    if (type == GPSSavePeriodType_Long24h) {
        [self stopUpdatingLocationService];
        [self startUpdatingLocationService];
        if (![SettingUtils sharedInstance].retryTimer ) {
            [SettingUtils sharedInstance].retryTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(stopRetringGetNewLocation:) userInfo:nil repeats:NO];
        }
    } else {
        [self stopUpdatingNewLocation];
        [self saveDataToFileCSVWithLocation:nil];
    }
}

#pragma mark - Private Methods

- (void)saveDataToFileCSVWithLocation:(CLLocation *)location {
    //1. Add location to data list
    LocationModel *model = [[LocationModel alloc] init];
    model.date = [NSDate date];
    NSString *status = @"";
    if (location) {
        model.isSuccess = YES;
        model.latitude = location.coordinate.latitude;
        model.longitude = location.coordinate.longitude;
        status = @"o";
        for (int i = 0; i < [SettingUtils sharedInstance].locationDatas.count; i++) {
            LocationModel *locationObj = [SettingUtils sharedInstance].locationDatas[i];
            if (locationObj.isSuccess) {
                break;
            } else {
                locationObj.latitude = model.latitude;
                locationObj.longitude = model.longitude;
                [SettingUtils sharedInstance].locationDatas[i] = locationObj;
                locationObj = nil;
            }
        }
    } else {
        model.isSuccess = NO;
        if ([SettingUtils sharedInstance].latestLocation) {
            model.latitude = [SettingUtils sharedInstance].latestLocation.latitude;
            model.longitude = [SettingUtils sharedInstance].latestLocation.longitude;
        } else {
            model.latitude = CGFLOAT_MIN;
            model.longitude = CGFLOAT_MIN;
            [SettingUtils sharedInstance].hasErrorLine = YES;
        }
        status = @"x";
    }
    if ([SettingUtils sharedInstance].locationDatas.count >= kMaxNumberOfRows) {
        [[SettingUtils sharedInstance].locationDatas removeLastObject];
    }
    [[SettingUtils sharedInstance].locationDatas addObject:model];
    
    //2. Update to the line error in file csv
    if ([SettingUtils sharedInstance].hasErrorLine && location != nil) {
        NSString *content = [NSString stringWithContentsOfFile:[SettingUtils sharedInstance].pathFile encoding:NSUTF8StringEncoding error:nil];
        NSArray *listRows = [content componentsSeparatedByString:@"\n"];
        NSMutableArray *listLocations = [NSMutableArray arrayWithArray:listRows];
        [listLocations removeLastObject];
        for (NSInteger i = listLocations.count - 1; i > 0; i--) {
            NSString *dataInRow = listLocations[i];
            NSArray *row = [dataInRow componentsSeparatedByString:@","];
            NSMutableArray *rowDetail = [NSMutableArray arrayWithArray:row];
            NSString *statusOfRow = rowDetail[0];
            if ([statusOfRow isEqualToString:@"o"]) {
                
                break;
            } else {
                rowDetail[2] = [NSString stringWithFormat:@" %0.3f", model.latitude];
                rowDetail[3] = [NSString stringWithFormat:@" %0.3f", model.longitude];
                NSString *dataInRowEdited = @"";
                for (int j = 0; j < rowDetail.count; j++) {
                    dataInRowEdited = [dataInRowEdited stringByAppendingFormat:@"%@,", rowDetail[j]];
                }
                listLocations[i] = dataInRowEdited;
            }
        }
        NSError *removeFileError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[SettingUtils sharedInstance].pathFile error:&removeFileError];
        if (removeFileError) {
            
        } else {
            NSString *newContent = @"";
            for (NSString *string in listLocations) {
                newContent = [newContent stringByAppendingFormat:@"%@\n", string];
            }
            [self createFileCSVWith:self.lblRecordStartTime.text andContent:newContent];
        }
    }
    
    //3. Save location to file csv
    NSString *writeString = [NSString stringWithFormat:@"%@, %@, %0.3f, %0.3f\n", status, [self stringFromDate:model.date andFormat:@"yyyy/MM/dd HH:mm:ss"], model.latitude, model.longitude];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:[SettingUtils sharedInstance].pathFile];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //4. Reload data on the tableview
    if ([SettingUtils sharedInstance].locationDatas.count > 1) {
       [[SettingUtils sharedInstance].locationDatas sortUsingComparator:^NSComparisonResult(LocationModel  *obj1, LocationModel  *obj2) {
           return [obj2.date compare:obj1.date];
       }];
    }
    [self.tableView reloadData];
    
    //5. Continue updating new location
    GPSSavePeriodType type = [self savePeriodFromSetting];
    NSInteger interval = 1;
    if (type == GPSSavePeriodType_Long24h) {
        interval = 120;
    }
    [SettingUtils sharedInstance].intervalTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(startUpdatingLocationService)
                                                        userInfo:nil
                                                         repeats:NO];
    NSLog(@"----Continue to save data");
}

- (void)createFileCSVWith:(NSString *)name andContent:(NSString *)content{
    NSString *savePeriod = [SettingUtils sharedInstance].savePeriod;
    if (savePeriod.length == 0) {
        savePeriod = GPS_SAVE_PERIOD_LONG_24H;
    }
    NSString *fileName = [NSString stringWithFormat:@"%@.csv", name];
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *pathToCSVFolder = [documentsDirectory stringByAppendingPathComponent:@"CSVFolder"];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:pathToCSVFolder withIntermediateDirectories:NO attributes:nil error:&error];
    
    [SettingUtils sharedInstance].pathFile = [pathToCSVFolder stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[SettingUtils sharedInstance].pathFile]) {
        [[NSFileManager defaultManager] createFileAtPath:[SettingUtils sharedInstance].pathFile contents:[content dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    [SettingUtils sharedInstance].hasErrorLine = NO;
}

- (NSString *)stringFromDate:(NSDate *)date andFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    NSString *string =[formatter stringFromDate:date];
    
    return string;
}

- (void)stopRetringGetNewLocation:(BOOL)isSave {
    [self stopUpdatingLocationService];
    [[SettingUtils sharedInstance].retryTimer invalidate];
    [SettingUtils sharedInstance].retryTimer = nil;
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
    if ([SettingUtils sharedInstance].intervalTimer) {
        [[SettingUtils sharedInstance].intervalTimer invalidate];
        [SettingUtils sharedInstance].intervalTimer = nil;
    }
}

- (void)stopRecordData {
    [self stopUpdatingNewLocation];
    [[SettingUtils sharedInstance].maxRecordTimer invalidate];
    [SettingUtils sharedInstance].maxRecordTimer = nil;
    [SettingUtils sharedInstance].latestLocation = nil;
    [SettingUtils sharedInstance].pathFile = nil;
    [SettingUtils sharedInstance].hasErrorLine = NO;
    self.lblRecordStartTime.text = @"ログ名";
}

- (GPSSavePeriodType)savePeriodFromSetting {
    NSString *savePeriod = [SettingUtils sharedInstance].savePeriod;
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

@end
