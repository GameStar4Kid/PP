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
    // Do any additional setup after loading the view.
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
    // Create the location manager if this object does not
    // already have one.
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    self.locationManager.desiredAccuracy = [self accuracyFilterSetting];
    
    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = [self distanceFilterFromSetting]; // meters
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (IBAction)tappedAtStopButton:(id)sender {
    [self.locationManager stopUpdatingLocation];
}

- (CLLocationAccuracy)accuracyFilterSetting {
    NSString *accuracyFilter = [SettingUtils sharedInstance].accurracyFilter;
    
    if ([accuracyFilter isEqualToString:GPS_ACCURACY_FILTER_10M]) {
        
        return kCLLocationAccuracyNearestTenMeters;
    } else if ([accuracyFilter isEqualToString:GPS_ACCURACY_FILTER_100M]) {
        
        return kCLLocationAccuracyHundredMeters;
    }
    
    return kCLLocationAccuracyNearestTenMeters;
}

- (NSUInteger)distanceFilterFromSetting {
    NSString *string = [SettingUtils sharedInstance].distanceFilter;
    NSUInteger distanceFilter = 0;
    if ([string isEqualToString:GPS_DISTANCE_FILTER_5M]) {
        
        distanceFilter = 5;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_10M]) {
        
        distanceFilter = 10;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_50M]) {
        
        distanceFilter = 50;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_100M]) {
        
        distanceFilter = 100;
    } else if ([string isEqualToString:GPS_DISTANCE_FILTER_500M]) {
        
        distanceFilter = 500;
    } else {
        
        distanceFilter = 5;
    }
    
    return distanceFilter;
}

@end
