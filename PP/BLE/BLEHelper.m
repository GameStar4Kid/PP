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
#define K472_DEVICE_NAME_FIRST_4_CHARS @"S830"
#define K474_DEVICE_NAME_FIRST_4_CHARS @"S810"
typedef enum WATCH_MODEL
{
    MODEL_S830 = 0,
    MODEL_S810,
    MODEL_MAX
} E_WATCH_MODEL ;
#define BLE_SCAN_TIME_OUT_SECONDS 30.0
#define BLE_SCAN_TIME_OUT_SECONDS_AUTOMATIC_TIME_SYNC 600.0
@interface BLEHelper()<LeValueAlarmProtocol,CLLocationManagerDelegate,LeDiscoveryDelegate>
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
    NSDate* Sync_Date;
}
@property (nonatomic, assign) int WatchModel_24H_Sync ;
@property (nonatomic, strong) CLLocation *m_currentLocation;
@property (nonatomic , strong) CLLocationManager *locationManager;
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
- (id)init
{
    if(self=[super init])
    {
        my_BLE_discovery = [[LeDiscovery alloc] init];
        [my_BLE_discovery setDiscoveryDelegate:self];
        [my_BLE_discovery setPeripheralDelegate:self];
        _connectedServices = [NSMutableArray new];
    }
    return self;
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
            [self start_watch_app_synchronization_foreground];
        }
        else
        {
            //automatic time sync
            [self skip_and_delay_to_next_automatic_sync];
        }
    }
    [self stop_timeout_timer];
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
    
//    NSString* device_name = [[NSUserDefaults standardUserDefaults] stringForKey:@"last_used_model_name"];
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
- (LeValueAlarmService*) serviceForPeripheral:(CBPeripheral *)peripheral
{
    for (LeValueAlarmService *service in _connectedServices) {
        if ( [[service peripheral] isEqual:peripheral] ) {
            return service;
        }
    }
    
    return nil;
}
#pragma mark LeValueAlarmProtocol
- (void) BLEService:(LeValueAlarmService*)service didSoundAlarmOfType:(AlarmType)alarm
{
    
}
- (void) BLEServiceDidStopAlarm:(LeValueAlarmService*)service
{
    
}
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
    int length = (int)string.length;
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
            [SettingUtils sharedInstance].deviceUDID=_currentlyDisplayingService.peripheral.identifier.UUIDString;
            [SettingUtils sharedInstance].deviceName=_currentlyDisplayingService.peripheral.name;
            [[SettingUtils sharedInstance].dateFormatter setDateFormat:@"yyyy/MM/dd hh:mm:ss"];
            [SettingUtils sharedInstance].lastSync= [[SettingUtils sharedInstance].dateFormatter stringFromDate:[NSDate date]];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BLE_CONNECT_SUCCESS object:nil];
            NSLog(@"Communication Ready notification received... start data syncing..");
            communication_ready_msg_received = TRUE;
            [self stop_ready_timeout_timer];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
            [self BLE_write_time_to_watch];
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
            [self BLE_process_time_write_response:data];
            NSLog(@"Write time to watch success");
            
            //stop connect
            [self BLE_write_stop_connecting_to_watch];
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
- (void) BLE_write_time_to_watch
{
    NSLog(@"WatchMenuTableController BLE_write_time_to_watch");
    NSLog(@"Write Sync Time Message...");
    NSData *time_sync_message = [self generate_time_sync_message];
    NSLog(@"time_sync_message = %@", time_sync_message);
    [_currentlyDisplayingService writeMessageToCustomWriteCharacteristic_raw:time_sync_message];
}
-(void) BLE_write_stop_connecting_to_watch
{
    NSLog(@"Write Stop Communication Message");
    [_currentlyDisplayingService writeMessageToCustomWriteCharacteristic:@"00 00 20 80"];
    sync_done = YES;
    syncing_in_progress = FALSE;
    [self stop_timeout_timer];
//    [self check_and_set_a_timer_for_next_sync];
//    [self restart_ble_scan:TRUE];
    //TODO
    [self performSelector:@selector(start_watch_app_synchronization_foreground) withObject:nil afterDelay:10];
}
- (void) BLE_process_time_write_response:(NSData*)data
{
    const unsigned char* data_bytes = (const unsigned char*)[data bytes];
    NSDate* last_sync_date;
    //TODO
//    E_WATCH_MODEL watch_model = MODEL_S830 ;
    
    NSLog(@"WatchMenuTableController BLE_process_time_write_response data = %@", data);
    if( data_bytes[ data.length -1 ] == BLE_RESULT_OK )
    {
        last_sync_date = [NSDate date];
    }
    else
    {
        NSLog(@"Response Error: could not write time to watch");
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
- (void) start_watch_app_synchronization_foreground
{
    if(syncing_in_progress == TRUE )
    {
         if(_currentlyDisplayingService != nil)
         {
         	NSLog(@"Other syncing is in progress --> SKIP ");
         	return;
         }
        
    }
    
    syncing_in_progress = TRUE;
    current_sync_type = SYNC_TYPE_MANUAL;
    
    communication_stopped = FALSE;
    sync_done = NO;
    receiving_message_command = 0;
    NSLog( @"///// start_ble_scan 002 /////");
    [self start_ble_scan];
    current_considering_peripheral = nil;
    NSLog( @"sync_confirm_dialog_ok_tapped / startUpdateLocationInfo");
    [self startUpdateLocationInfo];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (self.m_currentLocation == nil)
    {
        self.m_currentLocation = [(CLLocation *)[locations lastObject] copy];
        
        
        NSLog(@"didUpdateToLocation: %@", self.m_currentLocation);
        
        NSLog(@"current longitude = %@",[NSString stringWithFormat:@"%.8f", self.m_currentLocation.coordinate.longitude]);
        NSLog(@"current latitude = %@",[NSString stringWithFormat:@"%.8f", self.m_currentLocation.coordinate.latitude]);
        
       	[_locationManager stopUpdatingLocation];
       	_locationManager.delegate = nil;
       	_locationManager = nil;
        NSLog(@"[locationManager stopUpdatingLocation]");
        
        if( _currentlyDisplayingService != nil )
        {
            NSLog(@"watch connected ---> start_watch_app_synchronization ");
            
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            [self start_watch_app_synchronization];
        }
        else
        {
            NSLog(@"watch not connected yet ");
        }
    }
}
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    if ([error code] == kCLErrorDenied) {
        //you had denied
    }
    [manager stopUpdatingLocation];
}
-(void)startUpdateLocationInfo
{
    
    NSLog( @"-----[startUpdateLocationInfo]-----");
    self.m_currentLocation = nil;
    
    GPS_Failed = FALSE;
    
    if(_locationManager==nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
    }
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    [_locationManager startUpdatingLocation];
    
}
#pragma mark LeDiscoveryDelegate
- (void) discoveryStatePoweredOff
{
    NSLog(@"WatchMenuTableController discoveryStatePoweredOff");
    bluetooth_state_enable = FALSE;
    
}

- (void) discoveryStatePoweredOn
{
    NSLog(@"WatchMenuTableController discoveryStatePoweredOn");
    
    bluetooth_state_enable = TRUE;
    if(my_BLE_discovery.ResdtoreState==false)
    {
        NSLog(@"----- Restart BLE scan -----");
        [self restart_ble_scan:FALSE];
    }
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
            _currentlyDisplayingService=nil;
        }
    }
    self.WatchModel_24H_Sync = MODEL_MAX;
   	syncing_in_progress = FALSE;
    
}
- (bool) check_auto_24H_sync_time
{
    return true;
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
- (void) discoveryDidRefresh
{
    NSLog(@"discoveryDidRefresh");
    
    if(my_BLE_discovery.ResdtoreState)
    {
        current_sync_type = SYNC_TYPE_AUTO ;
    }
    
    //	CBPeripheral	*peripheral;
    NSArray			*devices;
    devices = [my_BLE_discovery foundPeripherals];
    
    NSLog( @"Device Count = %ld", (unsigned long)devices.count);
    
    
    //TODO
    E_WATCH_MODEL watch_model = MODEL_S830;
    
    if( devices.count > 0 && _currentlyDisplayingService == nil )
    {
        for( CBPeripheral* peripheral in devices )
        {
            //peripheral = (CBPeripheral*)[devices objectAtIndex:0];
            NSLog( @"Device UUID = %@", peripheral.identifier.UUIDString );
            NSLog( @"Device name = %@", peripheral.name);
            
            //TODO
//            if(nil != [user_rejected_device_UUIDs_dictionary valueForKey:peripheral.identifier.UUIDString])
//            {
//                NSLog(@"This device UUID has been rejected by user..skip it..");
//                continue;
//            }
            
            NSString* first_4_chars_of_found_device_name = [peripheral.name substringToIndex:4];
            NSString* first_4_chars_of_targeted_model_name = K472_DEVICE_NAME_FIRST_4_CHARS;
//            NSString* first_4_chars_of_targeted_model_name1 = K474_DEVICE_NAME_FIRST_4_CHARS;
            
//            if( [app_controller.my_watch_model_name isEqualToString:@"K474"] )
//            {
                first_4_chars_of_targeted_model_name = K472_DEVICE_NAME_FIRST_4_CHARS;
//            }
            
            BOOL this_is_current_targeted_watch_model = [first_4_chars_of_found_device_name isEqualToString:first_4_chars_of_targeted_model_name];  // アプリで選択中の機種の機種名を比較した結果
//            BOOL this_is_current_targeted_watch_model1 = [first_4_chars_of_found_device_name isEqualToString:first_4_chars_of_targeted_model_name1];
            
            BOOL this_is_targeted_auto_sync_device_UUID = TRUE;
            BOOL this_is_user_selected_device_UUID = FALSE;
            
            if(current_sync_type == SYNC_TYPE_AUTO)
            {
                NSLog(@"This is an auto synchronization..checking for last_time_sync_24H_enabled_device_UUID");
                // 検出した時計の機種を取得する
//                watch_model = [ setting Check_Device_Name:first_4_chars_of_found_device_name ] ;
                //TODO
                watch_model = MODEL_S830;
                if(watch_model == MODEL_MAX)
                {
                    continue;
                }
                
                
                NSLog(@"===== 2.check_auto_24H_sync_time =====");
                if([self check_auto_24H_sync_time:watch_model] == true)
                {
                    // 前回同期した時計のUUIDを取得
//                    NSString* last_device_UUID = [ setting Get_last_24H_Sync_UUID:watch_model ] ;
                    //TODO
                    NSString* last_device_UUID = @"";
                    // 検出したデバイスとUUIDを比較した結果をセットする
                    this_is_targeted_auto_sync_device_UUID = [peripheral.identifier.UUIDString isEqualToString:last_device_UUID];
                    
                    this_is_current_targeted_watch_model = FALSE;
                    
                    // Check Device name and UUID
                    //                    if ( this_is_current_targeted_watch_model && this_is_targeted_auto_sync_device_UUID )
                    if ( this_is_targeted_auto_sync_device_UUID )
                    {
                        // 24時間時刻同期では前回同期したデバイスと同じUUIDであればモデルも同じはずなので
                        // 機種名のチェックをTRUEにする
                        this_is_current_targeted_watch_model = TRUE ;
                        // Start Location Data
                        NSLog( @"discoveryDidRefresh / startUpdateLocationInfo");
                        [self startUpdateLocationInfo];
                    }
                    else
                    {
                        continue;
                    }
                }
                else
                {
                    NSLog(@"----- 1.else restart ble scan -----");
                    [self stop_ble_scan];
                    [self restart_ble_scan:TRUE];
                    return;
                }
            }
            else
            {
                NSLog(@"This is an synchronization..checking for last_time_sync_24H_enabled_device_UUID");
                
                NSLog(@"----- watch_model = %d",watch_model);
                NSString* user_selected_device_UUID = [SettingUtils sharedInstance].deviceUDID ;
                //FIXME
//                NSString* user_selected_device_UUID =@"2A01EEB0-CD72-B5F0-A6BB-E88663EBFF91";
                NSLog(@"user_selected_device_UUID = %@", user_selected_device_UUID);
                
                if( !user_selected_device_UUID )
                {
                    NSLog(@"This is the first ---- device has been connected with Prospex app..");
                    this_is_user_selected_device_UUID = TRUE;
//                    [[SettingUtils sharedInstance] saveDataWhenTerminate];
                    //TODO
//                    [ setting Set_24H_Sync_UUID:watch_model :peripheral.identifier.UUIDString];
                    
                }
                else
                {
                    
                    this_is_user_selected_device_UUID = [peripheral.identifier.UUIDString isEqualToString:user_selected_device_UUID];
                    
                    if((this_is_current_targeted_watch_model== TRUE) && ( this_is_user_selected_device_UUID == FALSE ))
                    {
                        [self stop_ble_scan];
                        NSLog(@"--> Show new watch confirm dialog");
                        current_considering_peripheral = peripheral;
                        //TODO
                        [self performSelector:@selector(start_watch_app_synchronization_foreground) withObject:nil afterDelay:10];
                        return;
                    }
                    else
                    {
                        NSLog(@"This last user selected device UUID..check and do syncing with it..");
                        
                    }
                    
                }
            }
            
            // ===== UUIDや同期時刻のチェック後の接続するかどうかを判断する処理 =====
            if ( this_is_current_targeted_watch_model && this_is_targeted_auto_sync_device_UUID )
            {
                if ( [peripheral state] != CBPeripheralStateConnected ) {
                    NSLog(@"This is currently targeted watch model --> Connect to device");
                    [self stop_ble_scan];
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                    [my_BLE_discovery connectPeripheral:peripheral];
                    // 接続したデバイスの機種を保持する
                    self.WatchModel_24H_Sync = watch_model ;
                    current_watch_device_UUID = peripheral.identifier.UUIDString;
                }
                else {
                    NSLog(@"WatchMenuTableController set currentlyDisplayingService");
                    _currentlyDisplayingService = [self serviceForPeripheral:peripheral];
                }
                
                return ;
            }
            {
                NSLog(@"This device is not currently targeted device");
            }
        }
        
        if(current_sync_type == SYNC_TYPE_AUTO)
        {
            NSLog(@"----- 2. restart ble scan -----");
            [self stop_ble_scan];
            [self restart_ble_scan:TRUE];
            
        }
        
    }
    else
    {
        NSLog(@"There is no device");
    }
}

- (NSData*) generate_time_sync_message
{
    int16_t latitude_data = 0;
    int16_t longitude_data = 0;
    uint8_t gps_sync_enable = 0x00;
    
    if (self.m_currentLocation != nil)
    {
        NSLog(@"location_accquired = TRUE ");
        
        if( self.m_currentLocation.coordinate.latitude >= -65.0 && self.m_currentLocation.coordinate.latitude <= 65.0 )
        {
            NSLog(@"Location latitude is in valid range (-65 ~ 65). Enable location bit field ");
            gps_sync_enable = 0x01;
            latitude_data = self.m_currentLocation.coordinate.latitude * 100;
            longitude_data = self.m_currentLocation.coordinate.longitude * 100;
        }
        else
        {
            NSLog(@"Location latitude is out of range (-65 ~ 65). Disable location bit field  ");
        }
    }
    else
    {
        NSLog(@"location_accquired = FALSE . Disable location bit field ");
    }
    
    // ----- 2016.02.09 debug -----
    //	NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //	NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    // ----- 2016.02.09 debug -----
    NSDate *date = [NSDate date];
    Sync_Date = [NSDate date] ;
    NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:date];
    
    NSInteger year = [dateComponents year];
    NSInteger month = [dateComponents month];
    NSInteger day = [dateComponents day];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    
    long long millisecs = (long long)( fmod([[NSDate date] timeIntervalSince1970],1) * 1000.0);
    Byte sec_percents = millisecs/10;
    
    int16_t time_zone_offset = ([[NSTimeZone localTimeZone] secondsFromGMT] / 60.0);
    
    uint8_t dst_enable = 0x00;
    
    BOOL dst = [[calendar timeZone] isDaylightSavingTime];
    // debug
    double dst_offset_minutes = 60;
    // debug
    
    if (dst == YES)
    {
        dst_enable = 1;
        // debug
        dst_offset_minutes = ([[calendar timeZone] daylightSavingTimeOffset] / 60.0);
        NSLog(@"current dst_offset_minutes = %f", dst_offset_minutes);
        if (dst_offset_minutes == 0)
        {
            dst_offset_minutes = 60;
        }
        // debug
        // subtract for dst_offset_minutes according to Bug list No.303
        // only subtract when DST is enabled at current time - Bug list No.303
        time_zone_offset = time_zone_offset - dst_offset_minutes;
    }
    
    NSLog(@"current hour = %ld", (long)hour);
    NSLog(@"current minute = %ld", (long)minute);
    NSLog(@"current second = %ld", (long)second);
    NSLog(@"current second percents = %d", sec_percents);
    
    NSLog(@"current day = %ld", (long)day);
    NSLog(@"current month = %ld", (long)month);
    NSLog(@"current year = %ld", (long)year);
    
    NSLog(@"current longitude data = %hd", longitude_data);
    NSLog(@"current latitude data = %hd", latitude_data);
    NSLog(@"time_zone_offset = %hd", time_zone_offset);
    
    Byte byte[] = {0x19, 0x00, 0x10, 0x80,
        sec_percents,
        (uint8_t)(second),/*second*/
        (uint8_t)(minute),/*minute*/
        (uint8_t)(hour),/*hour*/
        (uint8_t)(day),/*day*/
        (uint8_t)(month),/*month*/
        (uint8_t)( (uint16_t)year ), /*year*/
        (uint8_t)( ((uint16_t)year)>>8 ), /*year>>8*/
        //0xAC, 0x0D, 0x4C, 0x36,
        (uint8_t)( latitude_data ), /*latitude*/
        (uint8_t)( latitude_data>>8 ), /*latitude*/
        (uint8_t)( longitude_data ), /*longitude*/
        (uint8_t)( longitude_data>>8 ), /*longitude*/
        (uint8_t)( time_zone_offset ), /*time different*/
        (uint8_t)( time_zone_offset>>8 ), /*time different*/
        // debug
        //    60, // DST offset
        (uint8_t)(dst_offset_minutes),	//DST offset
        // debug
        dst_enable, // currently DST enable status
        0x00,0x00,0x00,0x00, // time when DST will switch from OFF->ON
        0x00,0x00,0x00,0x00, // time when DST will switch from ON->OFF
        gps_sync_enable };
    
    NSData *time_sync_message = [[NSData alloc] initWithBytes:byte length:29];
    return time_sync_message;
}
@end
