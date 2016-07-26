//
//  Height2DView.h
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES1/gl.h>

@interface Height2DView : GLKView<GLKViewDelegate>
@property GLfloat x;
@end
