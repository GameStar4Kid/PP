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
#import "RecordLocationManager.h"
#import <UIAlertView+Blocks.h>
#import "CommonMethods.h"

@interface PositionViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnGPSSetting;
@property (weak, nonatomic) IBOutlet UILabel *lblIntervalValue;
@property (weak, nonatomic) IBOutlet UILabel *lblMaxRecordTime;
@property (weak, nonatomic) IBOutlet UILabel *lblRecordStartTime;

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
    if ([[RecordLocationManager sharedInstance] isRecordingData]) {
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
    GPSSavePeriodType type = [[SettingUtils sharedInstance] savePeriodFromSetting];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willReloadDataOnTheTableView:)
                                                 name:NOTIFICATION_FOR_RELOADING_DATA_ON_THE_TABLEVIEW
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didStopRecordingLocation:)
                                                 name:NOTIFICATION_FOR_STOPPING_RECORDING_LOCATION_BY_RECORD_LOCATION_MANAGER
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FOR_STOPPING_RECORDING_LOCATION_BY_RECORD_LOCATION_MANAGER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FOR_RELOADING_DATA_ON_THE_TABLEVIEW object:nil];
}

#pragma mark TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[RecordLocationManager sharedInstance].locationDatas count];
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
    LocationModel *model = [[[RecordLocationManager sharedInstance] locationDatas] objectAtIndex:indexPath.row];
    NSString *status = @"取得成功";
    if (!model.isSuccess) {
        status = @"取得失敗";
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %0.8f-%0.8f", status, [CommonMethods stringFromDate:model.date andFormat:@"yyyy/MM/dd HH:mm" ], model.latitude, model.longitude];
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
    if ([RecordLocationManager isLocationSeviceEnabled]) {
        [[RecordLocationManager sharedInstance] startLocationServiceAndRecordLocation];
        self.btnStart.enabled = NO;
        self.btnStop.enabled = YES;
        self.lblRecordStartTime.text = [[RecordLocationManager sharedInstance] nameOfCSVFile];
    } else {
        [UIAlertView showWithTitle:@"Warning!"
                           message:@"Location service was disabled."
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil
                          tapBlock:nil];
    }
}

- (IBAction)tappedAtStopButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FOR_STOPPING_RECORDING_LOCATION_BY_POSITION_VIEW_CONTROLLER
                                                        object:nil
                                                      userInfo:nil];
    [self updateUIWhenStopRecording];
}

#pragma mark - Private Methods 

- (void)willReloadDataOnTheTableView:(NSNotification *)noti {
    [self.tableView reloadData];
}

- (void)didStopRecordingLocation:(NSNotification *)noti {
    [self updateUIWhenStopRecording];
}

- (void)updateUIWhenStopRecording {
    self.btnStart.enabled = YES;
    self.btnStop.enabled = NO;
    self.lblRecordStartTime.text = @"ログ名";
}

@end
