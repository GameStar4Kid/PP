//
//  GPSSettingViewController.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/14/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "GPSSettingViewController.h"
#import "CommonMethods.h"
#import "SettingUtils.h"

typedef NS_ENUM(NSUInteger, InputLabel) {
    InputLabel_SavePeriod = 1,
    InputLabel_AccuracyFilter,
    InputLabel_DistanceFilter
};

static CGFloat const kHeightOfLabel = 21.0;
static NSUInteger const kNumberOfComponents = 1;

@interface GPSSettingViewController ()<UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *lblSavePeriod;
@property (weak, nonatomic) IBOutlet UILabel *lblAccuracyFilter;
@property (weak, nonatomic) IBOutlet UILabel *lblDistanceFilter;
@property (weak, nonatomic) IBOutlet UILabel *lblSavePeriodValue;
@property (weak, nonatomic) IBOutlet UILabel *lblAccuracyFilterValue;
@property (weak, nonatomic) IBOutlet UILabel *lblDistanceFilterValue;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIView *inputView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidthOfSavePeriodLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidthOfAccuracyFilterLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidthOfDistanceFilterLabel;

@property (nonatomic) InputLabel currentInputLabel;

@end

@implementation GPSSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self updateView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods

- (void)setUpView {
    self.title = NSLocalizedString(@"PositionInfo.GPSSetting", nil);
    self.lblSavePeriod.text = NSLocalizedString(@"Save period", nil);
    self.lblAccuracyFilter.text = NSLocalizedString(@"Accuracy filter", nil);
    self.lblDistanceFilter.text = NSLocalizedString(@"Distance filter", nil);
    
    NSString *periodSave = [SettingUtils sharedInstance].savePeriod;
    if (periodSave.length > 0) {
        self.lblSavePeriodValue.text = periodSave;
    } else {
        self.lblSavePeriodValue.text = GPS_SAVE_PERIOD_LONG_24H;
        [[SettingUtils sharedInstance] setSavePeriod:self.lblSavePeriodValue.text];
    }
    NSString *accuracyFilter = [SettingUtils sharedInstance].accurracyFilter;
    if (accuracyFilter.length > 0) {
        self.lblAccuracyFilterValue.text = accuracyFilter;
    } else {
        self.lblAccuracyFilterValue.text = GPS_ACCURACY_FILTER_10M;
        [[SettingUtils sharedInstance] setAccurracyFilter:self.lblAccuracyFilterValue.text];
    }
    NSString *distanceFilter = [SettingUtils sharedInstance].distanceFilter;
    if (distanceFilter.length > 0) {
        self.lblDistanceFilterValue.text = distanceFilter;
    } else {
        self.lblDistanceFilterValue.text = GPS_DISTANCE_FILTER_5M;
        [[SettingUtils sharedInstance] setDistanceFilter:self.lblDistanceFilterValue.text];
    }
    
    self.pickerView.hidden = YES;
    [self.btnClose setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    self.btnClose.hidden = YES;
    
    self.inputView.layer.borderWidth = 2.0;
    self.inputView.layer.masksToBounds = YES;
    
    UITapGestureRecognizer *savePeriodGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAtSavePeriodLabel:)];
    [self.lblSavePeriod addGestureRecognizer:savePeriodGesture];
    
    UITapGestureRecognizer *accuracyFilterGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAtAccuracyFilterLabel:)];
    [self.lblAccuracyFilter addGestureRecognizer:accuracyFilterGesture];
    
    UITapGestureRecognizer *distanceFilterGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAtDistanceFilterLabel:)];
    [self.lblDistanceFilter addGestureRecognizer:distanceFilterGesture];
}

- (void)updateView {
    self.constraintWidthOfSavePeriodLabel.constant = [CommonMethods widthOfLabel:self.lblSavePeriod andHeightOfLabel:kHeightOfLabel];
    self.constraintWidthOfAccuracyFilterLabel.constant = [CommonMethods widthOfLabel:self.lblAccuracyFilter andHeightOfLabel:kHeightOfLabel];
    self.constraintWidthOfDistanceFilterLabel.constant = [CommonMethods widthOfLabel:self.lblDistanceFilter andHeightOfLabel:kHeightOfLabel];
}

- (void)reloadPickerWithInputLabel:(InputLabel)currentInputLabel {
    self.currentInputLabel = currentInputLabel;
    [self.pickerView reloadAllComponents];
    NSArray *data = [self dataForPicker];
    NSString *value = @"";
    switch (self.currentInputLabel) {
        case InputLabel_SavePeriod:
            value = [SettingUtils sharedInstance].savePeriod;
            break;
        case InputLabel_AccuracyFilter:
            value = [SettingUtils sharedInstance].accurracyFilter;
            break;
        case InputLabel_DistanceFilter:
            value = [SettingUtils sharedInstance].distanceFilter;
            break;
            
        default:
            break;
    }
    if (value.length > 0) {
        [self.pickerView selectRow:[data indexOfObject:value] inComponent:0 animated:YES];
    }
    self.pickerView.hidden = NO;
    self.btnClose.hidden = NO;
}

- (NSArray *)dataForPicker {
    NSArray *data = nil;
    switch (self.currentInputLabel) {
        case InputLabel_SavePeriod:
            data = @[GPS_SAVE_PERIOD_LONG_24H,
                     GPS_SAVE_PERIOD_SHORT_15M,
                     GPS_SAVE_PERIOD_SHORT_30M,
                     GPS_SAVE_PERIOD_SHORT_1H];
            break;
        case InputLabel_AccuracyFilter:
            data = @[GPS_ACCURACY_FILTER_10M,
                     GPS_ACCURACY_FILTER_100M];
            break;
        case InputLabel_DistanceFilter:
            data = @[GPS_DISTANCE_FILTER_5M,
                     GPS_DISTANCE_FILTER_10M,
                     GPS_DISTANCE_FILTER_50M,
                     GPS_DISTANCE_FILTER_100M,
                     GPS_DISTANCE_FILTER_500M];
            break;
            
        default:
            break;
    }
    return data;
}

#pragma mark - Action Methods

- (void)tappedAtSavePeriodLabel:(id)sender {
    [self reloadPickerWithInputLabel:InputLabel_SavePeriod];
}

- (void)tappedAtAccuracyFilterLabel:(id)sender {
    [self reloadPickerWithInputLabel:InputLabel_AccuracyFilter];
}

- (void)tappedAtDistanceFilterLabel:(id)sender {
    [self reloadPickerWithInputLabel:InputLabel_DistanceFilter];
}

- (IBAction)tappedAtCloseButton:(id)sender {
    self.pickerView.hidden = YES;
    self.btnClose.hidden = YES;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return kNumberOfComponents;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSArray *data = [self dataForPicker];
    
    return data.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *data = [self dataForPicker];
    
    return data[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSArray *data = [self dataForPicker];
    switch (self.currentInputLabel) {
        case InputLabel_SavePeriod:
            self.lblSavePeriodValue.text = data[row];
            [[SettingUtils sharedInstance] setSavePeriod:data[row]];
            break;
        case InputLabel_AccuracyFilter:
            self.lblAccuracyFilterValue.text = data[row];
            [[SettingUtils sharedInstance] setAccurracyFilter:data[row]];
            break;
        case InputLabel_DistanceFilter:
            self.lblDistanceFilterValue.text = data[row];
            [[SettingUtils sharedInstance] setDistanceFilter:data[row]];
            break;
            
        default:
            break;
    }
}

@end
