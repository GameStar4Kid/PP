//
//  BLEHelper.m
//  PP
//
//  Created by Nguyen Tran on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "BLEHelper.h"
#import <CoreLocation/CoreLocation.h>
#define SYNC_TYPE_MANUAL 0
#define SYNC_TYPE_AUTO 1
#define AUTOMATIC_TIME_SYNC_PERIOD_SECONDS 86400.0 // 24 hours
#define ALLOWED_24H_SYNC_AFTER_TIME  300 // 5 minutes
#define ALLOWED_24H_SYNC_BEFORE_TIME 120 // 2 minutes
typedef enum WATCH_MODEL
{
    MODEL_S830 = 0,
    MODEL_S810,
    MODEL_MAX
} E_WATCH_MODEL ;
#define BLE_SCAN_TIME_OUT_SECONDS 30.0
#define BLE_SCAN_TIME_OUT_SECONDS_AUTOMATIC_TIME_SYNC 600.0
@interface BLEHelper()<LeValueAlarmProtocol>
{
    LeDiscovery* my_BLE_discovery;
    uint8_t current_sync_type ;
    NSString* current_watch_device_UUID;
    CBPeripheral *current_considering_peripheral;
    BOOL syncing_in_progress;
    BOOL there_are_invalid_plans;
    BOOL sync_done;
    BOOL GPS_Failed;
    BOOL communication_ready_msg_received;
    BOOL bluetooth_state_enable;
    BOOL communication_stopped; // communication has been stopped from app side( by user, or error occurred )
    uint8_t receiving_message_command;
    uint16_t receiving_expected_length;
    uint16_t total_record_data_packs;
    uint16_t current_reading_data_pack;
    uint16_t data_chunk_begin_offset;
    uint16_t data_chunk_bytes_to_read;
    NSMutableData* receiving_message_data;
    NSMutableData* data_pack_altitude_entries;
    
    NSMutableArray* data_pack_summary_list;
    NSMutableArray* data_pack_outline_list;
    NSMutableArray* data_pack_altitude_record_list;
    uint8_t current_plan_writting_index;
    NSTimer *timeout_timer;
    NSTimer *ble_ready_timeout_timer;
    NSTimer *Check_24H_sync_timer;
}
@property (nonatomic, assign) int WatchModel_24H_Sync ;
@property (nonatomic, strong) CLLocation *m_currentLocation;
@end
__strong static BLEHelper* _sharedInstance = nil;
@implementation BLEHelper
+ (BLEHelper *)sharedInstance
{
    @synchronized(self)
    {
        if (nil == _sharedInstance)
        {
            _sharedInstance = [[BLEHelper alloc] init];
        }
    }
    return _sharedInstance;
}
-(void) start_ble_scan_background
{
    NSLog(@"start_ble_scan_background");
    if(syncing_in_progress==FALSE)
    {
        [self restart_ble_scan:TRUE];
    }
    [self Stop_Next_Sync_Time];
}

-(void) stop_ble_scan_for_foreground
{
    NSLog(@"stop_ble_scan_for_foreground");
    if(syncing_in_progress==FALSE)
    {
        [self stop_ble_scan];
        current_sync_type = SYNC_TYPE_MANUAL ;
    }
    [self Check_Next_Sync_Time];
    [self Start_Next_Sync_Time];
}
- (BOOL) get24hSyncValue:(E_WATCH_MODEL)model
{
    //TODO
    return true;
}
-(void) restart_ble_scan:(BOOL)loadViewFlg
{
    NSLog(@"----- restart_ble_scan -----");
    
    // Set Restore State
    bool lastTimeResdtoreState = my_BLE_discovery.ResdtoreState ;
    my_BLE_discovery.ResdtoreState = false;
    
    if(syncing_in_progress==FALSE)
    {
        UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
        if(applicationState != UIApplicationStateActive)
        {
            
            if(([self get24hSyncValue:MODEL_S830]==TRUE) ||
               ([self get24hSyncValue:MODEL_S830]==TRUE))
            {
                NSLog(@"----- applicationState != UIApplicationStateActive -----");
                communication_stopped = FALSE;
                sync_done = NO;
                receiving_message_command = 0;
                GPS_Failed = FALSE;
                current_sync_type = SYNC_TYPE_AUTO ;
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                NSLog( @"///// start_ble_scan 003 /////");
                [self start_ble_scan];
            }
            if((lastTimeResdtoreState == true) && (loadViewFlg == TRUE))
            {
                NSLog( @">>>>> Send prepareLoadViewNotification <<<<<");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"prepareLoadViewNotification" object:nil];
            }
        }
        else
        {
            [self Start_Next_Sync_Time];
        }
    }
}

-(void) stop_ble_scan
{
    NSLog(@"stop_ble_scan");
    [self stop_timeout_timer];
    [my_BLE_discovery stopScanning];
}
-(void) start_timeout_timer:(double)timeout_seconds
{
    NSLog(@"_____ start_timeout_timer _____");
    [self stop_timeout_timer];
    NSLog(@"_____ Call NSTimer _____");
    timeout_timer = [NSTimer scheduledTimerWithTimeInterval:timeout_seconds target:self selector:@selector(ble_scan_time_out_check) userInfo:nil repeats:NO];
}

-(void) stop_timeout_timer
{
    NSLog(@"_____ 1.stop_timeout_timer _____");
    if(timeout_timer!=nil)
    {
        NSLog(@"_____ 2.stop_timeout_timer _____");
        [timeout_timer invalidate];
        timeout_timer = nil;
    }
}
-(void) stop_ready_timeout_timer
{
    NSLog(@"_____ 1.stop_ready_timeout_timer _____");
    if(ble_ready_timeout_timer!=nil)
    {
        NSLog(@"_____ 2.stop_ready_timeout_timer _____");
        [ble_ready_timeout_timer invalidate];
        ble_ready_timeout_timer = nil;
    }
}

-(void) start_ble_scan
{
    NSLog(@"----- Called start_ble_scan -----");
    // ----- 2016.02.25 -----
    self.WatchModel_24H_Sync = MODEL_MAX ;
    [self stop_timeout_timer];
    _currentlyDisplayingService = nil;
    _connectedServices = [NSMutableArray new];
    [my_BLE_discovery setDiscoveryDelegate:self];
    [my_BLE_discovery setPeripheralDelegate:self];
    [my_BLE_discovery startScanningForUUIDString:kK472ServiceUUIDString];
    communication_ready_msg_received = FALSE;
    
    double scan_time_out_interval = BLE_SCAN_TIME_OUT_SECONDS;
    
    if(current_sync_type == SYNC_TYPE_MANUAL)
    {
        NSLog(@"scan_time_out_interval = %f", scan_time_out_interval);
        [self start_timeout_timer:scan_time_out_interval];
    }
    else
    {
        NSLog(@"----- scan timer not start(SYNC_TYPE_AUTO) -----");
    }
}

-(void) ble_scan_time_out_check
{
    NSLog(@"***** ble_scan_time_out_check");
    if( communication_stopped == FALSE && _currentlyDisplayingService == nil)
    {
        NSLog(@"BLE Scan timed out --> No device could be found");
        [self stop_ble_scan];
        syncing_in_progress = FALSE;
        if(current_sync_type == SYNC_TYPE_MANUAL )
        {
//            [self close_progress_dialog];
//            [self show_ble_scan_failed_dialog];
        }
        else
        {
            //automatic time sync
            [self skip_and_delay_to_next_automatic_sync];
        }
    }
    [self stop_timeout_timer];
}

- (void) discoveryServiceDisconnected
{
    NSLog(@"----- discoveryServiceDisconnected -----");
    [timeout_timer invalidate];
    timeout_timer = nil;
    if(current_sync_type == SYNC_TYPE_MANUAL && syncing_in_progress == TRUE )
    {
        //[self close_progress_dialog];
    }
    if( communication_stopped == FALSE && sync_done == FALSE )
    {
        NSLog(@"ERROR: unexpected disconect from watch");
        
        if(current_sync_type == SYNC_TYPE_AUTO )
        {
            [self skip_and_delay_to_next_automatic_sync];
        }
        
        if(current_sync_type == SYNC_TYPE_MANUAL )
        {
//            [self BLE_communication_error:@"ERROR: unexpected disconect from watch"];
        }
    }
    self.WatchModel_24H_Sync = MODEL_MAX;
   	syncing_in_progress = FALSE;	
    
}
- (void) Check_Next_Sync_Time
{
    if( syncing_in_progress == FALSE )
    {
        //TODO
        // update time for next sync
    }
}

- (void) Start_Next_Sync_Time
{
    NSLog(@"====== Start_Next_Sync_Time ======");
    [self Stop_Next_Sync_Time] ;
    NSLog(@"----- Timer Start -----");
    Check_24H_sync_timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(Check_Next_Sync_Time) userInfo:nil repeats:YES];
}

- (void) Stop_Next_Sync_Time
{
    if(Check_24H_sync_timer != nil )
    {
        NSLog(@"====== Stop_Next_Sync_Time ======");
        [Check_24H_sync_timer invalidate];
        Check_24H_sync_timer = nil ;
    }
    
}
-(void) skip_and_delay_to_next_automatic_sync
{
    NSLog(@"WatchMenuTableController skip_and_delay_to_next_automatic_sync");
    [self check_and_set_a_timer_for_next_sync];
}
-(void) check_and_set_a_timer_for_next_sync
{
    NSLog(@"WatchMenuTableController check_and_set_a_timer_for_next_sync");
    
    NSString* device_name = [[NSUserDefaults standardUserDefaults] stringForKey:@"last_used_model_name"];
    UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
    if(applicationState == UIApplicationStateBackground)
    {
        // called from willRestoreState
        if(my_BLE_discovery.ResdtoreState)
        {
            NSLog(@"======== Skip / my_BLE_discovery.ResdtoreState = true =====");
            return;
        }
    }
    
    
    NSLog(@"===== 1.check_auto_24H_sync_time =====");
    E_WATCH_MODEL watch_model;
    if(current_sync_type == SYNC_TYPE_AUTO)
    {
        if(self.WatchModel_24H_Sync == MODEL_MAX)
        {
            //TODO
            watch_model = MODEL_S830;
        }
    }
    [self check_auto_24H_sync_time:watch_model];
}
-(bool) check_auto_24H_sync_time: (int)Target_model
{
    NSLog(@"----- check_auto_24H_sync_time -----");
    bool result = false;
    //TODO
    NSDate* last_date = [NSDate date];
    NSDate* next_date = [NSDate date];
    
    //TODO
    E_WATCH_MODEL my_watch_model = MODEL_S830;
    E_WATCH_MODEL watch_model;
    NSLog(@"1.----- check_auto_24H_sync_time -----");
    if(Target_model != my_watch_model)
    {
        watch_model = Target_model ;
        //TODO
        last_date = [NSDate date];
        next_date = [NSDate date];
    }
    //value_of_time_sync_24H = [setting Get_24H_Sync_Value:watch_model ];
    //TODO
    BOOL value_of_time_sync_24H =true;
    if(last_date==nil)
    {
        NSLog(@"----- Skip.check_auto_24H_sync_time -----");
        return false ;
    }
    
    if(value_of_time_sync_24H == TRUE)
    {
        NSDate* current_date = [NSDate date];
        
        NSLog(@"last_time_sync_date = %@", last_date);
        NSLog(@"current_date        = %@", current_date);
        NSLog(@"next_date           = %@", next_date);
        NSTimeInterval last_secs = [current_date timeIntervalSinceDate:last_date];
        
        int i_last_secs = (int)last_secs;
        NSLog(@"----- 1.i_last_secs = %d sec=====",i_last_secs);
        if(i_last_secs <= 0)
        {
            return false;
        }
        
        int i_secs_work = i_last_secs / (int)AUTOMATIC_TIME_SYNC_PERIOD_SECONDS ;
        int i_secs_mod  = i_last_secs % (int)AUTOMATIC_TIME_SYNC_PERIOD_SECONDS ;
        NSLog(@"----- 2.i_last_secs / AUTOMATIC_TIME_SYNC_PERIOD_SECONDS = %d -----",i_secs_work);
        NSLog(@"----- 2.i_last_secs MOD AUTOMATIC_TIME_SYNC_PERIOD_SECONDS = %d sec-----",i_secs_mod);
        int sync_before_time = (int)AUTOMATIC_TIME_SYNC_PERIOD_SECONDS ;
        sync_before_time = sync_before_time - ALLOWED_24H_SYNC_BEFORE_TIME ;
        
        if(i_secs_work == 0)
        {
            if(i_secs_mod >= sync_before_time)
            {
                NSLog(@"---- (TRUE)current time > ALLOWED_24H_SYNC_BEFORE_TIME ----");
                result = true;
            }
        }
        else
        {
            if( (i_secs_mod >= sync_before_time) ||
               (i_secs_mod <= ALLOWED_24H_SYNC_AFTER_TIME) )
            {
                NSLog(@"---- (TRUE)ALLOWED_24H_SYNC_BEFORE_TIME < current time < ALLOWED_24H_SYNC_AFTER_TIME ----");
                result = true;
            }
        }
    }
    
    return result;
}
#pragma mark LeValueAlarmProtocol
/** Peripheral connected or disconnected */
- (void) BLEServiceDidChangeStatus:(LeValueAlarmService*)service
{
    if ( [[service peripheral] state] == CBPeripheralStateConnected ) {
        NSLog(@"Service (%@) connected", service.peripheral.name);
        if (![_connectedServices containsObject:service]) {
            [_connectedServices addObject:service];
        }
    }
    
    else {
        NSLog(@"Service (%@) disconnected", service.peripheral.name);
        if ([_connectedServices containsObject:service]) {
            [_connectedServices removeObject:service];
        }
    }
}


/** Central Manager reset */
- (void) BLEServiceDidReset
{
    [_connectedServices removeAllObjects];
}

- (NSData *)dataFromHexString:(NSString *)string
{
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    int length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}
- (void) BLEServiceNotificationTimeout
{
    NSLog(@"WatchMenuTableController BLEServiceNotificationTimeout");
    if( _currentlyDisplayingService != nil && communication_stopped == FALSE)
    {
        NSLog(@"ERROR: Could not receive response from Watch");
    }
}

- (void) BLEServiceDidFoundCustomCharacteristic:(LeValueAlarmService*)service
{
    [self stop_ble_scan];
    
    NSLog(@"WatchMenuTableController BLEServiceDidFoundCustomCharacteristic");
    _currentlyDisplayingService = service;
    if(self.m_currentLocation != nil )
    {
        NSLog(@"m_currentLocation accquired --> start_watch_app_synchronization");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        [self start_watch_app_synchronization];
        
    }
    else
    {
        if( GPS_Failed == TRUE)
        {
            NSLog(@"GPS Failed --> start_watch_app_synchronization without location info");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            [self start_watch_app_synchronization];
        }
        else
        {
            NSLog(@"m_currentLocation not accquired yet");
        }
    }
}
- (void) BLEServiceNotificationReceived:(NSData*)data
{
    NSLog( @"\n\nWatchMenuTableController BLEServiceNotificationReceived data = %@ length = %ld", data, (unsigned long)data.length );
    
    if( communication_stopped || sync_done == YES )
    {
        NSLog(@"User tap canceled button or Already Synchronized --> return ");
        // No.166 addition .Check if device has been connected --> exit politely, to prevent watch from displaying ERR1
        if( _currentlyDisplayingService != nil )
        {
            NSLog(@"Device already connected --> send communication stop messsage..");
            [_currentlyDisplayingService writeMessageToCustomWriteCharacteristic:@"00 00 20 80"];
            [self restart_ble_scan:TRUE];
        }
        return;
    }
    
    const unsigned char* data_bytes = (const unsigned char*)[data bytes];
    
    uint8_t app_command = data_bytes[BLE_APP_COMMAND_INDEX] ;
    
    if( receiving_message_command != 0 ) // A message is waiting to be fullfilled
    {
        NSLog(@"Continue Receiving a message");
        if( data.length > receiving_expected_length - receiving_message_data.length  )
        {
            NSLog(@"BLE Message Error: Receiving a message chunk with size larger than expected");
            return;
        }
        NSLog(@"append message chunk");
        [receiving_message_data appendData:data];
        NSLog(@"received length = %ld", (unsigned long)receiving_message_data.length);
        NSLog(@"expected_length = %hu", receiving_expected_length);
        if( receiving_message_data.length  < receiving_expected_length  )
        {
            return;
        }
        NSLog(@"Full message received");
        app_command = receiving_message_command;
        receiving_message_command = 0; // turn off "long message receiving" mode
    }
    else
    {
        NSLog(@"Receiving a new message");
        
        receiving_message_data = [NSMutableData dataWithData:data];
        uint16_t msg_content_length = data_bytes[ BLE_MSG_SIZE_INDEX ];
        NSLog(@"msg content length = %hu", msg_content_length);
        
        if( data.length < msg_content_length + BLE_MSG_HEADER_SIZE )
        {
            NSLog(@"Wait for next parts of this message...");
            //setup for receiving a message larger than 20 bytes
            receiving_message_command = app_command;
            receiving_expected_length = msg_content_length + BLE_MSG_HEADER_SIZE;
            return; // wait for notification of next message chunk
        }
    }
    
    switch( app_command )
    {
        case BLE_APP_COMMAND_READY_FOR_COMMUNICATION:
        {
            NSLog(@"Communication Ready notification received... start data syncing..");
            communication_ready_msg_received = TRUE;
            [self stop_ready_timeout_timer];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
//            [self BLE_write_time_to_watch];
            break;
        }
        case BLE_APP_COMMAND_DATA_SUMMARY:
        {
//            [self BLE_process_record_data_summary_response:receiving_message_data];
            break;
        }
        case BLE_APP_COMMAND_DATA_OUTLINE:
        {
//            [self BLE_process_record_data_outline_response:receiving_message_data];
            break;
        }
        case BLE_APP_COMMAND_DATA_CHUNK:
        {
//            [self BLE_process_record_data_chunk_response:receiving_message_data];
            break;
        }
        case BLE_APP_COMMAND_DATA_UPLOADED:
        {
//            [self BLE_process_data_pack_set_uploaded_flag_response:data];
            break;
        }
        case BLE_APP_COMMAND_BASIC_SETTING_WRITE:
        {
//            [self BLE_process_basic_setting_write_response:data];
            break;
        }
        case BLE_APP_COMMAND_UNIT_SETTING_WRITE:
        {
//            [self BLE_process_unit_setting_write_response:data];
            break;
        }
        case BLE_APP_COMMAND_PERSONAL_SETTING_WRITE:
        {
//            [self BLE_process_personal_setting_write_response:data];
            break;
        }
        case BLE_APP_COMMAND_ALARM_SETTING_WRITE:
        {
//            [self BLE_process_alarm_setting_write_response:data];
            break;
        }
        case BLE_APP_COMMAND_WORLD_TIME_ZONE_WRITE:
        {
//            [self BLE_process_world_time_zone_write_response:data];
            break;
        }
        case BLE_APP_COMMAND_PLAN_WRITE:
        {
//            [self BLE_process_plan_write_response:data];
            break;
        }
        case BLE_APP_COMMAND_BASIC_TIME_WRITE:
        {
//            [self BLE_process_time_write_response:data];
            break;
        }
            
        default:
        {
            NSLog(@"Error: Invalid APP_COMMAND received ");
            NSLog(@"--> Show BLE Error Dialog");
            break;
        }													
    }
}
- (void) start_watch_app_synchronization
{
    if( communication_stopped || sync_done == YES )
    {
        NSLog(@"User tap canceled button or Already Synchronized --> return ");
        return;
    }
    if( communication_ready_msg_received == TRUE )
    {
        NSLog(@"----- communication_ready_msg_received == TRUE -----");
        return;
    }
    
    [_currentlyDisplayingService do_notification_subscribing];
    NSLog(@"_____ start ble_ready_timeout_timer Timer _____");
   	ble_ready_timeout_timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(ble_scan_time_out_check) userInfo:nil repeats:NO];
    
}
@end
