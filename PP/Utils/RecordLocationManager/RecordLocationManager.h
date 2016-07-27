//
//  RecordLocationManager.h
//  PP
//
//  Created by Nguyen Xuan Tho on 7/27/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordLocationManager : NSObject

+ (instancetype)sharedInstance;

+ (BOOL)isLocationSeviceEnabled;

@property (strong, nonatomic) NSMutableArray *locationDatas;
@property (nonatomic) BOOL isRecordingData;

- (void)startLocationServiceAndRecordLocation;

- (NSString *)nameOfCSVFile;

@end
