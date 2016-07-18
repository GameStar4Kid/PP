//
//  Enums.h
//  PP
//
//  Created by Nguyen Xuan Tho on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

typedef NS_ENUM(NSInteger, DataCellType) {
    DataCellType_Sun,
    DataCellType_Moon,
    DataCellType_Age,
    DataCellType_MeteorologicalData,
    DataCellType_WeatherAlert
};

typedef NS_ENUM(NSUInteger, GPSSavePeriodType) {
    GPSSavePeriodType_Long24h,
    GPSSavePeriodType_Short15m,
    GPSSavePeriodType_Short30m,
    GPSSavePeriodType_Short1h
};

typedef NS_ENUM(NSUInteger, GPSAccuracyFilterType) {
    GPSAccuracyFilterType_10m,
    GPSAccuracyFilterType_100m
};

typedef NS_ENUM(NSUInteger, GPSDistanceFilterType) {
    GPSDistanceFilterType_5m,
    GPSDistanceFilterType_10m,
    GPSDistanceFilterType_50m,
    GPSDistanceFilterType_100m,
    GPSDistanceFilterType_500m,
};