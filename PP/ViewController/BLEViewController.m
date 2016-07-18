//
//  BLEViewController.m
//  PP
//
//  Created by Nguyen Tran on 7/8/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "BLEViewController.h"
#import "BLEItem.h"
#import "BLEHelper.h"
@interface BLEDeviceCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblTitleName;
@property (weak, nonatomic) IBOutlet UILabel *lblTitleUDID;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailName;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailUDID;

@end
@implementation BLEDeviceCell
@end
@interface BLESettingCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblTitleSetting;
@property (weak, nonatomic) IBOutlet UILabel *lblDetailSetting;
@end
@implementation BLESettingCell
@end
@interface BLEViewController ()

@end

@implementation BLEViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDevicesList) name:NOTIFICATION_BLE_CONNECT_SUCCESS object:nil];
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"BLE Dashboard", nil);
//    [[BLEHelper sharedInstance] start_watch_app_synchronization];
    [self loadDevicesList];
    
}
- (void) loadDevicesList
{
    NSMutableArray*    list = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray*arr = [BLEHelper sharedInstance].connectedServices;
    for (LeValueAlarmService* service in arr)
    {
        BLEItem*item = [[BLEItem alloc] initWithName:service.peripheral.name UDID:service.peripheral.identifier.UUIDString];
        [list addObject:item];
    }
    if(list.count==0 && [SettingUtils sharedInstance].deviceUDID.length>0)
    {
        NSString*name = [SettingUtils sharedInstance].deviceName;
        NSString*udid = [SettingUtils sharedInstance].deviceUDID;
        BLEItem*item = [[BLEItem alloc] initWithName:name UDID:udid];
        [list addObject:item];
    }
    if(list.count==0)
    {
        BLEItem*item = [[BLEItem alloc] initWithName:@"...." UDID:@"...."];
        [list addObject:item];
    }
    self.dataList=list;
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark TableView Methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section==0)
        return _dataList.count*2;
    else
    {
        return 2;
    }
}
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section==0)
    {
//        return (_dataList.count>0)?NSLocalizedString(@"BLE Title Section 1", ):@"";
        return NSLocalizedString(@"BLE Title Section 1", );
    }
    else
    {
        return NSLocalizedString(@"BLE Title Section 2", );
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if(indexPath.section==0&&_dataList.count==0)
//    {
//        return 0;
//    }
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"staticCell"];
    if (!cell) {
        cell = [[BLESettingCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"staticCell"];
    }
    [self configureCell:indexPath cell:cell];
    return cell;
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor grayColor];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}
- (void)configureCell:(NSIndexPath*)indexPath cell:(UITableViewCell*)cell
{
    if(indexPath.section==0)
    {
        int row = roundf(indexPath.row/2);
        BLEItem*item = _dataList[row];
        if(indexPath.row==0)
        {
            cell.textLabel.text=NSLocalizedString(@"BLE.Section1.Title1", nil );
            cell.detailTextLabel.text= item.name;
        }
        else
        {
            cell.textLabel.text=NSLocalizedString(@"BLE.Section1.Title2", nil );
            cell.detailTextLabel.text= item.UDID;
            cell.detailTextLabel.adjustsFontSizeToFitWidth=YES;
        }
    }
    else
    {
        if(indexPath.row==0)
        {
            cell.textLabel.text=NSLocalizedString(@"BLE.Section2.Title1", nil );
            cell.detailTextLabel.text= @"....";
        }
        else
        {
            cell.textLabel.text=NSLocalizedString(@"BLE.Section2.Title2", nil );
            cell.detailTextLabel.text= [SettingUtils sharedInstance].lastSync;
            cell.detailTextLabel.adjustsFontSizeToFitWidth=YES;
        }
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end
