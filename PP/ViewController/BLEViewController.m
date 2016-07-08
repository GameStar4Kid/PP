//
//  BLEViewController.m
//  PP
//
//  Created by Nguyen Tran on 7/8/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "BLEViewController.h"

@interface BLEViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

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
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
