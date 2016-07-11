/*

 File: LeValueAlarmService.m
 
 Abstract: Value Alarm Service Code - Connect to a peripheral 
 get notified when the temperature changes and goes past settable
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



#import "LeValueAlarmService.h"
#import "LeDiscovery.h"


NSString *kK472ServiceUUIDString = @"DEC879E0-F914-11E4-9AC1-0002A5D5C51B";
NSString *kCustomServiceNotifyCharacteristicUUIDString = @"21A2BBE0-F915-11E4-A9FC-0002A5D5C51B";
NSString *kCustomServiceWriteCharacteristicUUIDString = @"0E653260-F915-11E4-96C7-0002A5D5C51B";

NSString *kAlarmServiceEnteredBackgroundNotification = @"kAlarmServiceEnteredBackgroundNotification";
NSString *kAlarmServiceEnteredForegroundNotification = @"kAlarmServiceEnteredForegroundNotification";

@interface LeValueAlarmService() <CBPeripheralDelegate> {
@private
    CBPeripheral		*servicePeripheral;
    
    CBService			*customDataService;
    
    CBCharacteristic    *customNotifyCharacteristic;
    CBCharacteristic	*CustomWriteCharacteristic;
    
    CBUUID              *customWriteUUID;
    CBUUID              *customServiceNotifyUUID;

    id<LeValueAlarmProtocol>	peripheralDelegate;
    BOOL notification_received;
    int16_t current_request_tag;
}
@end



@implementation LeValueAlarmService


@synthesize peripheral = servicePeripheral;


#pragma mark -
#pragma mark Init
/****************************************************************************/
/*								Init										*/
/****************************************************************************/
- (id) initWithPeripheral:(CBPeripheral *)peripheral controller:(id<LeValueAlarmProtocol>)controller
{
    self = [super init];
    if (self) {
        servicePeripheral = peripheral ;
        [servicePeripheral setDelegate:self];
		peripheralDelegate = controller;
        
        customWriteUUID	= [CBUUID UUIDWithString:kCustomServiceWriteCharacteristicUUIDString] ;
        customServiceNotifyUUID	= [CBUUID UUIDWithString:kCustomServiceNotifyCharacteristicUUIDString] ;
	}
    return self;
}


- (void) dealloc {
	if (servicePeripheral) {
		[servicePeripheral setDelegate:[LeDiscovery sharedInstance]];

		servicePeripheral = nil;
        

    }
    //[super dealloc];
}


- (void) reset
{
	if (servicePeripheral) {
		//[servicePeripheral release];
		servicePeripheral = nil;
	}
}



#pragma mark -
#pragma mark Service interaction
/****************************************************************************/
/*							Service Interactions							*/
/****************************************************************************/
- (void) start
{
	CBUUID	*serviceUUID	= [CBUUID UUIDWithString:kK472ServiceUUIDString];
	NSArray	*serviceArray	= [NSArray arrayWithObjects:serviceUUID, nil];

    [servicePeripheral discoverServices:serviceArray];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog( @"didDiscoverServices" );
	NSArray		*services	= nil;
	NSArray		*uuids	= [NSArray arrayWithObjects:customServiceNotifyUUID, 
								   customWriteUUID, 
								   nil];

	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong Peripheral.\n");
		return ;
	}
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
		return ;
	}

	services = [peripheral services];
	if (!services || ![services count]) {
        NSLog( @"Exit because services list is empty" );

		return ;
	}

	customDataService = nil;
    
	for (CBService *service in services) {
		if ([[service UUID] isEqual:[CBUUID UUIDWithString:kK472ServiceUUIDString]]) {
			customDataService = service;
			break;
		}
	}

	if (customDataService) {
        NSLog( @"Start discovering characteristics of customDataService" );
		[peripheral discoverCharacteristics:uuids forService:customDataService];
	}
}


- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
{
    NSLog(@"didDiscoverCharacteristicsForService");
	NSArray		*characteristics	= [service characteristics];
	CBCharacteristic *characteristic;
    NSLog(@"number of characteristics = %d", characteristics.count);

	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong Peripheral.\n");
		return ;
	}
	
	if (service != customDataService) {
		NSLog(@"Wrong Service.\n");
		return ;
	}
    
    if (error != nil) {
		NSLog(@"Error %@\n", error);
		return ;
	}
    BOOL all_necessary_chars_were_found = FALSE;
	for (characteristic in characteristics) {
        NSLog(@"discovered characteristic %@", [characteristic UUID]);
        
		if ([[characteristic UUID] isEqual:customWriteUUID]) { 
            NSLog(@"Discovered Custom Write Characteristic");
            CustomWriteCharacteristic = characteristic ;
		}
        else if ([[characteristic UUID] isEqual:customServiceNotifyUUID]) { 
            NSLog(@"Discovered Custom Notify Characteristic");
			customNotifyCharacteristic = characteristic ;
			//[peripheral readValueForCharacteristic:customNotifyCharacteristic];
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
            all_necessary_chars_were_found = TRUE;
		} 
	}
    if( all_necessary_chars_were_found == TRUE)
    [peripheralDelegate BLEServiceDidFoundCustomCharacteristic:self];
}

- (void) do_notification_subscribing
{
    NSLog(@"LeValueAlarmService do_notification_subscribing");
    [servicePeripheral setNotifyValue:YES forCharacteristic:customNotifyCharacteristic];
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

#pragma mark -
#pragma mark Characteristics interaction
/****************************************************************************/
/*						Characteristics Interactions						*/
/****************************************************************************/
- (void) writeMessageToCustomWriteCharacteristic:(NSString*)hex_string;
{
    NSData  *data	= nil;
    data =[self dataFromHexString:hex_string];
    [self writeMessageToCustomWriteCharacteristic_raw:data];
    notification_received = TRUE;
}

- (void) writeMessageToCustomWriteCharacteristic_raw:(NSData*)data;
{   
    if (!servicePeripheral) {
        NSLog(@"Not connected to a peripheral");
        return ;
    }

    if (!CustomWriteCharacteristic) {
        NSLog(@"There is no valid CustomWriteCharacteristic");
        return;
    }
    NSLog(@"writeMessageToCustomWriteCharacteristic");

    NSData* chunk_bytes;

    uint16_t start_index = 0;
    uint16_t chunk_size = 0;
    //[NSThread sleepForTimeInterval: 0.5];
    current_request_tag++;
    int16_t request_tag = current_request_tag;
    notification_received = FALSE;
    while( start_index < data.length )
    {
        chunk_size = BLE_MAX_CHUNK_SIZE;
        chunk_size = MIN( chunk_size, data.length - start_index );
        chunk_bytes = [data subdataWithRange:NSMakeRange( start_index, chunk_size )];
        //NSLog(@"chunk_bytes = %@", chunk_bytes);
        [servicePeripheral writeValue:chunk_bytes forCharacteristic:CustomWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        //[self performSelector:@selector(writeCustomData:) withObject:chunk_bytes afterDelay:1.0];
        start_index += chunk_size;
    }
    [self performSelector:@selector(notificationReceiveTimeout:) withObject:[NSNumber numberWithInt:request_tag] afterDelay:10.0];
}

- (void) notificationReceiveTimeout:(NSNumber*)request_tag
{
    if( notification_received == FALSE && [request_tag intValue] == current_request_tag )
    {
        NSLog(@"LeValueAlarmService Notifications Receiving Timeout");
        [peripheralDelegate BLEServiceNotificationTimeout];
    }
}

- (void) writeCustomData:(NSData*) data
{
   [servicePeripheral writeValue:data forCharacteristic:CustomWriteCharacteristic type:CBCharacteristicWriteWithResponse];
}


- (void)enteredBackground
{
    // Find the fishtank service
    for (CBService *service in [servicePeripheral services]) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kK472ServiceUUIDString]]) {
            
            for (CBCharacteristic *characteristic in [service characteristics]) {
                if ( [[characteristic UUID] isEqual:[CBUUID UUIDWithString:kCustomServiceNotifyCharacteristicUUIDString]] ) {
                    
                    // And STOP getting notifications from it
                    [servicePeripheral setNotifyValue:NO forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)enteredForeground
{
    // Find the fishtank service
    for (CBService *service in [servicePeripheral services]) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kK472ServiceUUIDString]]) {
            
            for (CBCharacteristic *characteristic in [service characteristics]) {
                if ( [[characteristic UUID] isEqual:[CBUUID UUIDWithString:kCustomServiceNotifyCharacteristicUUIDString]] ) {
                    
                    // And START getting notifications from it
                    [servicePeripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{  
    NSLog(@"LeValueAlarmService didUpdateValueForCharacteristic ");

	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong peripheral\n");
		return ;
	}

    if ([error code] != 0) {
		NSLog(@"Error %@\n", error);
		return ;
	}

    if ([[characteristic UUID] isEqual:customServiceNotifyUUID]) {
        //NSLog(@"value = %@", [characteristic value]);
        notification_received = TRUE; // must have, or "Timeout" will be always fired
        [peripheralDelegate BLEServiceNotificationReceived:[characteristic value]];
        return;
    }
    else
    {
        NSLog(@"This notification is not from custom notify char\n");
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"LeValueAlarmService didWriteValueForCharacteristic");
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    //[peripheral readValueForCharacteristic:characteristic];
}
@end
