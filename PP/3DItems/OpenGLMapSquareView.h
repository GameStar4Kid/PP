//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by Ray Wenderlich on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Map2DViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

@class MapLocator;
@class Locator;

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2]; // New
} Vertex;

@interface OpenGLMapSquareView : UIView {
    UIImage* _image;
    NSOutputStream* _outputStream;
    Vertex* verticesBR;
    Vertex* verticesRR;
    GLuint _programHandle;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    float _currentRotation;
    
    GLuint _mapTexture;
    GLuint _pinTexture;
    GLuint _compassTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    // For BlueRoute
    GLuint _vertexBRBuffer;
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    GLuint _depthBuffer;
    GLint _viewportWidth;
    GLint _viewportHeight;
    GLuint _depthRenderBuffer;
}
- (void)initData:(NSMutableArray *)pDataRows CenterPoint:(Locator *)pCenterPoint MarkerPoint:(MapLocator *)pMarkerPoint;
@end
