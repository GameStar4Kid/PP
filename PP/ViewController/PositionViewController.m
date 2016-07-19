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

@import CoreLocation;

@interface PositionViewController ()<CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnGPSSetting;
@property (weak, nonatomic) IBOutlet UILabel *lblIntervalValue;
@property (weak, nonatomic) IBOutlet UILabel *lblMaxRecordTime;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSTimer *intervalTimer;
@property (strong, nonatomic) NSTimer *maxRecordTimer;
@property (strong, nonatomic) CLLocation *latestLocation;
@property (strong, nonatomic) NSString *pathFile;

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
    self.tableView.scrollEnabled=NO;
    
//    if ([SettingUtils sharedInstance].isRecordLocationProcessing) {
//        self.btnStart.enabled = NO;
//    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"PositionInfo Dashboard", nil);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self tappedAtStopButton:nil];
}

#pragma mark TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
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
    cell.textLabel.text=@"取得成功 yyyy/mm/dd hh:mm 座標";
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
        self.locationManager.delegate = self;
    }
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
                                                         selector:@selector(stopLocationService)
                                                         userInfo:nil
                                                          repeats:NO];
    self.btnStart.enabled = NO;
    self.pathFile = [self pathToFileCSV];
    [self.locationManager startUpdatingLocation];
}

- (IBAction)tappedAtStopButton:(id)sender {
    [self stopLocationService];
    [self.maxRecordTimer invalidate];
    self.maxRecordTimer = nil;
    self.btnStart.enabled = YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    self.latestLocation = locations[0];
    [self saveDataToFileCSVWithError:NO];
    [self stopLocationService];
    [self startNewLocationService];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self saveDataToFileCSVWithError:YES];
    [self stopLocationService];
    [self startNewLocationService];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
    }
}

- (void)saveDataToFileCSVWithError:(BOOL)isError {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.pathFile]) {
        NSString *contentString = [NSString stringWithFormat:@"取得状況, 日時, 緯度, 経度\n"];
        [[NSFileManager defaultManager] createFileAtPath:self.pathFile contents:[contentString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    NSString *status = @"o";
    if (isError) {
        status = @"x";
    }
    NSString *writeString = [NSString stringWithFormat:@"%@, %@, %0.3f, %0.3f\n", status, [self stringFromDate:self.latestLocation.timestamp andFormat:@"yyyy/MM/dd HH:mm:ss"], self.latestLocation.coordinate.latitude, self.latestLocation.coordinate.longitude];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:self.pathFile];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    //position handle cursor to the end of file
    [handle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)pathToFileCSV {
    NSString *savePeriod = [SettingUtils sharedInstance].savePeriod;
    if (savePeriod.length == 0) {
        savePeriod = GPS_SAVE_PERIOD_LONG_24H;
    }
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.csv", [self stringFromDate:[NSDate date] andFormat:@"yyyy_MM_dd_HH_mm_ss"], savePeriod];
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    return path;
}

- (NSString *)stringFromDate:(NSDate *)date andFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    NSString *string =[formatter stringFromDate:date];
    
    return string;
}

- (void)startNewLocationService {
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

- (void)startUpdatingLocationService {
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocationService {
    [self.intervalTimer invalidate];
    self.intervalTimer = nil;
    [self.locationManager stopUpdatingLocation];
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
