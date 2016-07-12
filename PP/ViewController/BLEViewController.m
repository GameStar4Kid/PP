//
//  BLEViewController.m
//  PP
//
//  Created by Nguyen Tran on 7/8/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "BLEViewController.h"
#import "BLEItem.h"
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
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"BLE Dashboard", nil);
    //test
    _dataList = [NSMutableArray arrayWithCapacity:0];
    BLEItem*item = [[BLEItem alloc] initWithName:@"S830" UDID:@"1234123123123"];
    [_dataList addObject:item];
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark TableView Methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section==0)
        return _dataList.count;
    else
    {
        return 1;
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
        return (_dataList.count>0)?NSLocalizedString(@"BLE Title Section 1", ):@"";
    }
    else
    {
        return NSLocalizedString(@"BLE Title Section 2", );
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0&&_dataList.count==0)
    {
        return 0;
    }
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0)
    {
        BLEDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deviceCell"];
        if (!cell) {
            cell = [[BLEDeviceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"deviceCell"];
            //        cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //        cell.backgroundColor=[UIColor yellowColor];
        }
        cell.lblTitleName.text= NSLocalizedString(@"BLE.Section1.Title1", nil);
        cell.lblTitleUDID.text= NSLocalizedString(@"BLE.Section1.Title2", nil);
        BLEItem*item = _dataList[indexPath.row];
        cell.lblDetailName.text=item.name;
        cell.lblDetailUDID.text=item.UDID;
        return cell;
    }
    else
    {
        BLESettingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingCell"];
        if (!cell) {
            cell = [[BLESettingCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingCell"];
            //        cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //        cell.backgroundColor=[UIColor yellowColor];
        }
        cell.lblTitleSetting.text= NSLocalizedString(@"BLE.Section2.Title1", nil );
        cell.lblDetailSetting.text= @"ABV";
        return cell;
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
