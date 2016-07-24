//
//  Map2DViewController.h
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleMap2DView.h"

@interface Locator : NSObject
@property GLfloat m_centerLat;
@property GLfloat m_centerLng;
@property GLfloat m_zoom;
@end

@interface MapLocator : NSObject
@property (strong, nonatomic) NSString *m_date;
@property (strong, nonatomic) NSString *m_time;
@property GLint m_status;
@property GLfloat m_lat;
@property GLfloat m_lng;
@property GLfloat m_alt;
@property GLint m_now;
@end

@interface Map2DViewController : UIViewController <GMSMapViewDelegate>
@property (weak, nonatomic) IBOutlet GMSMapView *map2DView;
@property (strong, nonatomic) NSMutableArray *dataRows;
@property (weak, nonatomic) IBOutlet UIButton *btn3D;
@property (strong, nonatomic) MapLocator *markerPoint;
@property BOOL isMarkerActive;
@end
