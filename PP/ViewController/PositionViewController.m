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
@property (strong, nonatomic) NSTimer *intervalTimer;
@property (strong, nonatomic) NSTimer *maxRecordTimer;
@property (strong, nonatomic) NSTimer *retryTimer;
@property (strong, nonatomic) NSString *pathFile;
@property (strong, nonatomic) NSMutableArray *locationDatas;
@property (nonatomic) BOOL isRetringGetLocation;

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
    self.locationDatas = [[NSMutableArray alloc] init];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopRecordData];
}

#pragma mark TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.locationDatas count];
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
    LocationModel *model = [self.locationDatas objectAtIndex:indexPath.row];
    NSString *status = @"取得成功";
    if (!model.isSuccess) {
        status = @"取得失敗";
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %0.3f-%0.3f", status, [self stringFromDate:model.date andFormat:@"yyyy/MM/dd HH:mm" ], model.latitude, model.longitude];
    
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
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    self.locationManager.delegate = self;
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    self.locationManager.desiredAccuracy = [self accuracyFilterFromSetting];
    self.locationManager.distanceFilter = [self distanceFilterFromSetting];
    GPSSavePeriodType type = [self savePeriodFromSetting];
    NSInteger maxRecord = 0;
    switch (type) {
        case GPSSavePeriodType_Long24h:
            maxRecord = 24 * 60 * 60;
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
                                                         selector:@selector(stopRecordData)
                                                         userInfo:nil
                                                          repeats:NO];
    self.btnStart.enabled = NO;
    self.pathFile = [self pathToFileCSV];
    self.lblRecordStartTime.text = [self stringFromDate:[NSDate date] andFormat:@"yyyy_MM_dd_HH_mm_ss"];
    [self.locationDatas removeAllObjects];
    [self.locationManager startUpdatingLocation];
}

- (IBAction)tappedAtStopButton:(id)sender {
    [self stopRecordData];
    self.btnStart.enabled = YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations[0];
    GPSSavePeriodType type = [self savePeriodFromSetting];
    if (type == GPSSavePeriodType_Long24h) {
        if (self.isRetringGetLocation) {
            [self stopRetringGetLocation];
        } else {
            [self stopGetingNewLocation];
        }
    } else {
        [self stopGetingNewLocation];
    }
    [self saveDataToFileCSVWithLocation:location];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    GPSSavePeriodType type = [self savePeriodFromSetting];
    if (type == GPSSavePeriodType_Long24h) {
        if (!self.isRetringGetLocation) {
            [self stopGetingNewLocation];
            self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(stopRetringGetLocation) userInfo:nil repeats:NO];
            self.isRetringGetLocation = YES;
        } else {
            [self stopUpdatingLocationService];
        }
        [self startUpdatingLocationService];
    } else {
        [self stopGetingNewLocation];
        [self saveDataToFileCSVWithLocation:nil];
    }
}

- (void)saveDataToFileCSVWithLocation:(CLLocation *)location {
    //1. Add location to data list
    LocationModel *model = [[LocationModel alloc] init];
    NSString *status = @"";
    if (location) {
        model.isSuccess = YES;
        model.date = location.timestamp;
        model.latitude = location.coordinate.latitude;
        model.longitude = location.coordinate.longitude;
        status = @"o";
    } else {
        model.isSuccess = NO;
        model.date = [NSDate date];
        LocationModel *latestLocation = [[LocationModel alloc] init];
        if (self.locationDatas.count > 0) {
            latestLocation = self.locationDatas[0];
        }
        model.latitude = latestLocation.latitude;
        model.longitude = latestLocation.longitude;
        status = @"x";
    }
    if (self.locationDatas.count >= kMaxNumberOfRows) {
        [self.locationDatas removeLastObject];
    }
    [self.locationDatas addObject:model];
    
    //2. Save location to file csv
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.pathFile]) {
        NSString *contentString = [NSString stringWithFormat:@"取得状況, 日時, 緯度, 経度\n"];
        [[NSFileManager defaultManager] createFileAtPath:self.pathFile contents:[contentString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    LocationModel *latestLocation = [self.locationDatas lastObject];
    NSString *writeString = [NSString stringWithFormat:@"%@, %@, %0.3f, %0.3f\n", status, [self stringFromDate:latestLocation.date andFormat:@"yyyy/MM/dd HH:mm:ss"], latestLocation.latitude, latestLocation.longitude];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:self.pathFile];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    //position handle cursor to the end of file
    [handle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //3. Reload data on the tableview
    if (self.locationDatas.count > 1) {
       [self.locationDatas sortUsingComparator:^NSComparisonResult(LocationModel  *obj1, LocationModel  *obj2) {
           return [obj2.date compare:obj1.date];
       }];
    }
    [self.tableView reloadData];
    
    //4. Continue updating new location
    GPSSavePeriodType type = [self savePeriodFromSetting];
    NSInteger interval = 1;
    if (type == GPSSavePeriodType_Long24h) {
        interval = 90;
    }
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(startUpdatingLocationService)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (NSString *)pathToFileCSV {
    NSString *savePeriod = [SettingUtils sharedInstance].savePeriod;
    if (savePeriod.length == 0) {
        savePeriod = GPS_SAVE_PERIOD_LONG_24H;
    }
    NSString *fileName = [NSString stringWithFormat:@"%@.csv", [self stringFromDate:[NSDate date] andFormat:@"yyyy_MM_dd_HH_mm_ss"]];
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *pathToCSVFolder = [documentsDirectory stringByAppendingPathComponent:@"CSVFolder"];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:pathToCSVFolder withIntermediateDirectories:NO attributes:nil error:&error];
    
    NSString *path = [pathToCSVFolder stringByAppendingPathComponent:fileName];
    
    return path;
}

- (NSString *)stringFromDate:(NSDate *)date andFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    NSString *string =[formatter stringFromDate:date];
    
    return string;
}

- (void)stopRetringGetLocation {
    self.isRetringGetLocation = NO;
    [self stopUpdatingLocationService];
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    [self saveDataToFileCSVWithLocation:nil];
}

- (void)startUpdatingLocationService {
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocationService {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

- (void)stopGetingNewLocation {
    [self stopUpdatingLocationService];
    [self.intervalTimer invalidate];
    self.intervalTimer = nil;
}

- (void)stopRecordData {
    [self stopGetingNewLocation];
    [self.maxRecordTimer invalidate];
    self.maxRecordTimer = nil;
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
