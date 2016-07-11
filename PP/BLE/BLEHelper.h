//
//  BLEHelper.h
//  PP
//
//  Created by Nguyen Tran on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeDiscovery.h"
@interface BLEHelper : NSObject
@property (retain, nonatomic) LeValueAlarmService *currentlyDisplayingService;
@property (retain, nonatomic) NSMutableArray            *connectedServices;

+ (BLEHelper *)sharedInstance;

-(void) check_and_set_a_timer_for_next_sync;
-(void) start_ble_scan;
-(void) start_ble_scan_background;
-(void) stop_ble_scan_for_foreground;
-(void) restart_ble_scan:(BOOL)loadViewFlg;
-(void) do_automatic_24H_time_syncing;
@end
