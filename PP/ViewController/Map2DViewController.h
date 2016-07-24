//
//  Map2DViewController.h
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleMap2DView.h"

@interface Map2DViewController : UIViewController <GMSMapViewDelegate>
@property (weak, nonatomic) IBOutlet GMSMapView *map2DView;
@property (strong, nonatomic) NSMutableArray *dataRows;
@property (weak, nonatomic) IBOutlet UIButton *btn3D;
@property BOOL isMarkerActive;
@end
