/*
 
 File: LeValueAlarmService.h
 
 Abstract: Value Alarm Service Header - Connect to a peripheral 
 and get notified when the temperature changes and goes past settable
 maximum and minimum temperatures.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */


#import <UIKit/UIKit.h>
#import <Availability.h>

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define BLE_MSG_SIZE_INDEX 0
#define BLE_APP_COMMAND_INDEX 2
#define BLE_MSG_HEADER_SIZE 4
#define BLE_MAX_CHUNK_SIZE 20 // bytes
#define BLE_MAX_NUMBER_OF_PLAN 7

#define BLE_RESULT_OK 1
#define BLE_RESULT_FAIL 0



#define BLE_APP_COMMAND_DATA_SUMMARY 0x43
#define BLE_APP_COMMAND_DATA_OUTLINE 0x44
#define BLE_APP_COMMAND_DATA_CHUNK 0x45
#define BLE_APP_COMMAND_DATA_UPLOADED 0x46

#define BLE_APP_COMMAND_BASIC_TIME_WRITE 0x10
#define BLE_APP_COMMAND_BASIC_SETTING_WRITE 0x13
#define BLE_APP_COMMAND_UNIT_SETTING_WRITE 0x15
#define BLE_APP_COMMAND_PERSONAL_SETTING_WRITE 0x17
#define BLE_APP_COMMAND_ALARM_SETTING_WRITE 0x19
#define BLE_APP_COMMAND_WORLD_TIME_ZONE_WRITE 0x1C
#define BLE_APP_COMMAND_PLAN_WRITE 0x40

#define BLE_APP_COMMAND_READY_FOR_COMMUNICATION 0x21


// Data struct used for parsing climbing record outline info from outline response message (AP_CMD 0x44)
// Data size: 56 bytes (BLE Format v3.17)
typedef	struct
{
	//plan serial year month day hour minute second ( 7 bytes )
	uint16_t plan_year ;
	uint8_t plan_month;
	uint8_t plan_day;
	uint8_t plan_hour;
	uint8_t plan_minute;
	uint8_t plan_second;
	uint8_t measurement_minute;	//measurement time minute
	uint8_t measurement_hour;	//measurement time hour
	uint8_t start_second;	//start time second
	uint8_t start_minute;	//start time minute
	uint8_t start_hour;	//start time hour
	uint8_t start_date;	//start time date
	uint8_t start_month;	//start time month
	uint16_t start_year;	//start year (2 bytes)
	int16_t beginning_altitude;	//beginning altitude 2 bytes
	uint8_t ending_minute;	//ending minute
	uint8_t ending_hour;	//ending hour
	int16_t ending_altitude;	//ending altitude 2 bytes
	uint8_t highest_altitude_reached_minute;	//Highest altitude reached minute
	uint8_t highest_altitude_reached_hour;	//Highest altitude reached hour
	int16_t highest_altitude_measured;	//Highest altitude measured 2 bytes
	uint8_t lowest_altitude_reached_minute;	//lowest altitude reached minute
	uint8_t lowest_altitude_reached_hour;	//lowest altitude reached hour
	int16_t lowest_altitude_measured;	//lowest altitude measured 2 bytes
	uint16_t avergage_ascent_speed;	//Average ascent speed (m/h) 2 bytes
	int16_t avergage_descent_speed;	//Average descent speed (m/h) 2 bytes
	uint16_t consumption_energy;	//S830:Consumption energy (kcal) 2 bytes
									//S810:acumulated_ascent_height for energy calculation
	uint16_t consumption_energy_unused;	//S830:Consumption energy (kcal) 2 bytes
										//S810:acumulated_descent_height for energy calculation
	uint16_t acumulated_ascent_height;	//acumulated ascent height (m) 2 bytes
	uint16_t acumulated_descent_height;	//acumulated descent height (m) 2 bytes
	uint16_t total_number_of_altitude_data;
	uint32_t walking_time_total_seconds;
	uint32_t walking_time_up_and_down_seconds;
	uint32_t walking_time_flat_seconds;
} CLIMB_RECORD_OUTLINE_DATA_t;

/****************************************************************************/
/*						Service Characteristics								*/
/****************************************************************************/
extern NSString *kK472ServiceUUIDString;                 // DEADF154-0000-0000-0000-0000DEADF154     Service UUID
extern NSString *kCurrentValueCharacteristicUUIDString;   // CCCCFFFF-DEAD-F154-1319-740381000000     Current Value Characteristic
extern NSString *kMinimumValueCharacteristicUUIDString;   // C0C0C0C0-DEAD-F154-1319-740381000000     Minimum Value Characteristic
extern NSString *kMaximumValueCharacteristicUUIDString;   // EDEDEDED-DEAD-F154-1319-740381000000     Maximum Value Characteristic
extern NSString *kAlarmCharacteristicUUIDString;                // AAAAAAAA-DEAD-F154-1319-740381000000     Alarm Characteristic

extern NSString *kAlarmServiceEnteredBackgroundNotification;
extern NSString *kAlarmServiceEnteredForegroundNotification;

/****************************************************************************/
/*								Protocol									*/
/****************************************************************************/
@class LeValueAlarmService;

typedef enum {
    kAlarmHigh  = 0,
    kAlarmLow   = 1,
} AlarmType;

@protocol LeValueAlarmProtocol<NSObject>
- (void) BLEService:(LeValueAlarmService*)service didSoundAlarmOfType:(AlarmType)alarm;
- (void) BLEServiceDidStopAlarm:(LeValueAlarmService*)service;
- (void) BLEServiceNotificationReceived:(NSData*)data;
- (void) BLEServiceNotificationTimeout;
- (void) BLEServiceDidChangeStatus:(LeValueAlarmService*)service;
- (void) BLEServiceDidFoundCustomCharacteristic:(LeValueAlarmService*)service;
- (void) BLEServiceDidReset;
@end


/****************************************************************************/
/*						Value Alarm service.                          */
/****************************************************************************/
@interface LeValueAlarmService : NSObject

- (id) initWithPeripheral:(CBPeripheral *)peripheral controller:(id<LeValueAlarmProtocol>)controller;
- (void) reset;
- (void) start;

/* Querying Sensor */
@property (readonly) CGFloat temperature;
@property (readonly) CGFloat minimumValue;
@property (readonly) CGFloat maximumValue;

/* Set the alarm cutoffs */
- (void) writeMessageToCustomWriteCharacteristic:(NSString*)hex_string;
- (void) writeMessageToCustomWriteCharacteristic_raw:(NSData*)data;
- (void) do_notification_subscribing;

/* Behave properly when heading into and out of the background */
- (void)enteredBackground;
- (void)enteredForeground;

@property (readonly) CBPeripheral *peripheral;
@end
