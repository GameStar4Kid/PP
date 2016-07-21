//
//  LocationModel.h
//  PP
//
//  Created by Nguyen Xuan Tho on 7/20/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationModel : NSObject

@property (nonatomic) BOOL isSuccess;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@end
