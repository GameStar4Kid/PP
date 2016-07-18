//
//  OpenGLViewController.h
//  PP
//
//  Created by Duong Quoc Thang on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>
//#include "OpenGLView.h"
#include "OpenGLMapSquareView.h"

@interface OpenGLViewController : UIViewController
//@property (strong, nonatomic) IBOutlet OpenGLView *glView;
@property (strong, nonatomic) IBOutlet OpenGLMapSquareView *glView;
//@property (strong, nonatomic) IBOutlet OpenGLCompassView *glCompassView;
@end
