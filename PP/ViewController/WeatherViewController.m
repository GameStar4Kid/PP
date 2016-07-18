//
//  WeatherViewController.m
//  PP
//
//  Created by Nguyen Tran on 7/8/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "WeatherViewController.h"
#import "WeatherInfoTableViewCell.h"
#import "SunOrMoonDataTableViewCell.h"
#import "UITableViewCellFixed.h"

static NSUInteger const kNumberOfSection = 5;
static NSUInteger const kNumberOfRowInSection = 1;
static CGFloat const kHeightOfHeaderTableView = 40.0;
static CGFloat const kHeightOfFooterTableView = 40.0;
static CGFloat const kHeightOfWeatherInfoCell = 44.0;
static CGFloat const kHeightOfSunOrMoonDataCell = 63.0;
static CGFloat const kHeightOfHeaderViewInSection = 40.0;
static CGFloat const kPaddingLeft = 10.0;
static CGFloat const kSpaceVertical = 5.0;
static CGFloat const kPaddingTop = 2.0;
static CGFloat const kHeightOfSeparatorView = 1.0;

@interface WeatherViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WeatherViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"Weather Dashboard", nil);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self setUpView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpView {
    UIView *headerTableView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       self.tableView.bounds.size.width,
                                                                       kHeightOfHeaderTableView)];
    UILabel *lblContent = [[UILabel alloc] initWithFrame:CGRectZero];
    [lblContent setText:NSLocalizedString(@"Position information acquisition time", nil)];
    CGSize size = [lblContent sizeThatFits:CGSizeMake(CGFLOAT_MAX, kHeightOfHeaderTableView)];
    [lblContent setFrame:CGRectMake(kPaddingLeft,
                                    0,
                                    size.width,
                                    kHeightOfHeaderTableView)];
    [headerTableView addSubview:lblContent];
    
    UILabel *lblValue = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(lblContent.frame) + kSpaceVertical,
                                                                  0,
                                                                  headerTableView.bounds.size.width - CGRectGetMaxX(lblContent.frame) - kSpaceVertical,
                                                                  kHeightOfFooterTableView)];
    lblValue.text = @"----/--/--   --";
    [headerTableView addSubview:lblValue];
    
    self.tableView.tableHeaderView = headerTableView;
    
    UIView *footerTableView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       self.tableView.bounds.size.width,
                                                                       kHeightOfFooterTableView)];
    
    UIButton *btnInfo = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnInfo setFrame:CGRectMake(kPaddingLeft,
                                 0,
                                 (footerTableView.bounds.size.width - kPaddingLeft * 2 - kSpaceVertical)/ 2,
                                 kHeightOfFooterTableView)];
    [btnInfo setTitle:NSLocalizedString(@"Weather information acquisition", nil) forState:UIControlStateNormal];
    [btnInfo setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnInfo addTarget:self action:@selector(tappedAtInfoButton:) forControlEvents:UIControlEventTouchUpInside];
    btnInfo.layer.borderWidth = 3.0;
    btnInfo.layer.masksToBounds = YES;
    [footerTableView addSubview:btnInfo];
    
    UIButton *btnBackground = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnBackground setFrame:CGRectMake(CGRectGetMaxX(btnInfo.frame) + kSpaceVertical,
                                       0,
                                       btnInfo.bounds.size.width,
                                       btnInfo.bounds.size.height)];
    [btnBackground setTitle:NSLocalizedString(@"Background", nil) forState:UIControlStateNormal];
    [btnBackground setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnBackground addTarget:self action:@selector(tappedAtBackgroundButton:) forControlEvents:UIControlEventTouchUpInside];
    btnBackground.layer.borderWidth = 3.0;
    btnBackground.layer.masksToBounds = YES;
    [footerTableView addSubview:btnBackground];
    
    self.tableView.tableFooterView = footerTableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return kNumberOfSection;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return kNumberOfRowInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kSunOrMoonDataCellIndentifier = @"SunOrMoonDataCell";
    static NSString *kWeatherInfoCellIndentifier = @"WeatherInfoCell";
    static NSString *kSystemCell = @"SystemCell";
    
    if (indexPath.section == DataCellType_Sun ||
        indexPath.section == DataCellType_Moon) {
        SunOrMoonDataTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSunOrMoonDataCellIndentifier];
        [cell loadDataForSunOrMoonCell:indexPath.section andRiseValue:@"--:--" andSetValue:@"--:--"];
        
        return cell;
    } else if (indexPath.section == DataCellType_WeatherAlert) {
        UITableViewCellFixed *cell = [tableView dequeueReusableCellWithIdentifier:kSystemCell];
        if (cell == nil) {
            cell = [[UITableViewCellFixed alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSystemCell];
        }
        cell.textLabel.text = NSLocalizedString(@"ON (no blinking at the time of rain detection)", nil);
        
        return cell; 
    } else {
        WeatherInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWeatherInfoCellIndentifier];
        [cell loadDataForWeatherInfoCell:indexPath.section andValue:@"--.-"];
        
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == DataCellType_Sun ||
        indexPath.section == DataCellType_Moon) {
        
        return kHeightOfSunOrMoonDataCell;
    }
    
    return kHeightOfWeatherInfoCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return kHeightOfHeaderViewInSection;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                            0,
                                                            tableView.bounds.size.width,
                                                            kHeightOfHeaderViewInSection)];
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(kPaddingLeft,
                                                                     0,
                                                                     view.bounds.size.width,
                                                                     kHeightOfSeparatorView)];
    separatorView.backgroundColor = [UIColor lightGrayColor];
    [view addSubview:separatorView];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(kPaddingLeft,
                                                             kPaddingTop,
                                                             view.bounds.size.width - kPaddingLeft,
                                                             view.bounds.size.height - kPaddingTop * 2)];
    switch (section) {
        case DataCellType_Sun:
            lbl.text = NSLocalizedString(@"Sunrise and sunset data", nil);
            break;
        case DataCellType_Moon:
            lbl.text = NSLocalizedString(@"De sunset data of the month", nil);
            break;
        case DataCellType_Age:
            lbl.text = NSLocalizedString(@"Age (noon)", nil);
            break;
        case DataCellType_MeteorologicalData:
            lbl.text = NSLocalizedString(@"Meteorological data", nil);
            break;
        case DataCellType_WeatherAlert:
            lbl.text = NSLocalizedString(@"Weather alert", nil);
            break;
            
        default:
            break;
    }
    [view addSubview:lbl];
    
    return view;
}

- (void)tappedAtInfoButton:(id)sender {
    
}

- (void)tappedAtBackgroundButton:(id)sender {
    
}

@end
