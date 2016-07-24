//
//  OpenGLViewController.h
//  PP
//
//  Created by Duong Quoc Thang on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "OpenGLMapSquareView.h"

@class Locator;

@interface OpenGLViewController : UIViewController
@property (strong, nonatomic) IBOutlet OpenGLMapSquareView *glView;
@property (nonatomic) UIDeviceOrientation currentDeviceOrientation;
@property (strong, nonatomic) NSMutableArray *dataRows;
@property (strong, nonatomic) Locator *centerPoint;
@property (strong, nonatomic) MapLocator *markerPoint;
@end
