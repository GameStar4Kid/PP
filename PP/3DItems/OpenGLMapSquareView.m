//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by Ray Wenderlich on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenGLMapSquareView.h"
#include <math.h>
#import "CC3GLMatrix.h"
#import <OpenGLES/ES1/gl.h>

@interface OpenGLMapSquareView() {
    BOOL isRendering;
    BOOL isMoving;
}
@property Boolean mShouldLoadTexture;
@property float mAngle;
@property float mVAngle;
@property float mX;
@property float mY;
@property float mPreviousX;
@property float mPreviousY;
@property (strong, nonatomic) NSMutableArray *mDataRows;
@property (strong, nonatomic) Locator *mCenterPoint;
@property (strong, nonatomic) MapLocator *mMarkerPoint;
@property float mHighest;
@property float mLowest;
@property float mLatUnit;
@end

@implementation OpenGLMapSquareView

#define TEX_COORD_MAX   1
const float TOUCH_SCALE_FACTOR = 180.0f / 640;

const Vertex Vertices1[] = {
    // Front
    {{-1.0f, 1.0f, 0.0f}, {1, 0, 0, 1}, {0, 0}},                            // -1  1 0 / 0,0 / Top Left
    {{-1.0f, -1.0f, 0.0f}, {0, 1, 0, 1}, {0.0f, TEX_COORD_MAX}},            // -1 -1 0 / 0,0 / Bottom Left
    {{1.0f, -1.0f, 0.0f}, {0, 0, 1, 1}, {TEX_COORD_MAX, TEX_COORD_MAX}},    //  1 -1 0 / 0,0 / Bottom Right
    {{1.0f, 1.0f, 0.0f}, {0, 0, 0, 1}, {TEX_COORD_MAX, 0}},                 //  1  1 0 / 0,0 / Top Right
};

const GLubyte Indices1[] = {0, 1, 2, 0, 2, 3 };

const GLfloat textureCoordinates[] = { 0.0f, 0.0f, //
    0.0f, 1.0f, //
    1.0f, 1.0f, //
    1.0f, 0.0f, //
};

typedef struct {
    float lat;
    float lng;
    float alt; // New
} Position;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    glFlush();
    if ([EAGLContext currentContext] != nil) {
        [EAGLContext setCurrentContext:nil];
    }
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);        
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];    
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)setupFrameBuffer {    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);   
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);    
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];    
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileFragmentShader:(NSString *)fragmentName {
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentName withType:GL_FRAGMENT_SHADER];
    
    // 2
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShader);
    glAttachShader(_programHandle, fragmentShader);
    glLinkProgram(_programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(_programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(_programHandle, "Position");
    _colorSlot = glGetAttribLocation(_programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(_programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(_programHandle, "Modelview");
    
    _texCoordSlot = glGetAttribLocation(_programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(_programHandle, "Texture");

}

- (void)compileShaders {
    
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"MapFragment" withType:GL_FRAGMENT_SHADER];
    
    // 2
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShader);
    glAttachShader(_programHandle, fragmentShader);
    glLinkProgram(_programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(_programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(_programHandle, "Position");
    _colorSlot = glGetAttribLocation(_programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(_programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(_programHandle, "Modelview");
    
    _texCoordSlot = glGetAttribLocation(_programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(_programHandle, "Texture");
}
// For vertices of triangle
- (void)setupVBO_Index {
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices1), Vertices1, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices1), Indices1, GL_STATIC_DRAW);

}
// For vertices of line
- (void)setupVBOInfo:(Vertex*)vertexData {
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * [self.mDataRows count], vertexData, GL_STATIC_DRAW);
}

- (void)render:(CADisplayLink*)displayLink {
    if(!isMoving)
    {
       if(isRendering)return;
    }
    isRendering=YES;
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Enable Smooth Shading, default not really needed.
    glShadeModel(GL_SMOOTH);
    // Depth buffer setup.
    glClearDepthf(1.0f);
    // Enables depth testing.
    glEnable(GL_DEPTH_TEST);
    // The type of depth testing to do.
    glDepthFunc(GL_LEQUAL);
    // Really nice perspective calculations.
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    // Map
    [self setupVBO_Index];
    [self compileShaders];
    
    float aspect = fabs(self.frame.size.width / self.frame.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 0.01f, 100.0f);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projectionMatrix.m);

    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mVAngle), 1, 0, 0);
    
    // Rotate via z axis
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mAngle), 0, 0, 1);
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));    
    
    // 3
    if (_mapTexture == 0) {
        NSArray       *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString  *documentsDirectory = [paths objectAtIndex:0];
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"map.png"];
        //_mapTexture = [self setupTexture:@"staticmap2.png"];
        _mapTexture = [self setupTexture:filePath];
    }
    
    if (_mShouldLoadTexture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _mapTexture);
    }
    // Shader
    glUniform1i(_textureUniform, 0);    // Call SimpleFragment & SimpleVertex
    // Draw
    glDrawElements(GL_TRIANGLES, sizeof(Indices1)/sizeof(Indices1[0]), GL_UNSIGNED_BYTE, 0);
    
    // Blueroute
    // 1
    [self setupVBOInfo:verticesBR];
    [self compileFragmentShader:@"RouteFragment"];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projectionMatrix.m);
    
    // 2
    modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mVAngle), 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mAngle), 0, 0, 1);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    // 3
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));
    
    // 4
    glLineWidth(5.0f);
    glDrawArrays(GL_LINE_STRIP, 0, [self.mDataRows count]);
    
    
    // RedRoute
    // 1
    [self setupVBOInfo:verticesRR];
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    // 3
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));
    
    // 4
    glLineWidth(5.0f);
    glDrawArrays(GL_LINE_STRIP, 0, [self.mDataRows count]);
    
    
    // Compass
    glViewport(0, self.frame.size.height-100, 100, 100);
    [self setupVBO_Index];
    [self compileShaders];
    
    aspect = 1.0f;
    projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 0.01f, 100.0f);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projectionMatrix.m);
    
    
    modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    
    // Rotate via z axis
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mAngle), 0, 0, 1);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));
    
    // 3
    if (_compassTexture == 0) {
        _compassTexture = [self setupTexture:@"compass_.png"];
    }
    
    if (_mShouldLoadTexture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _compassTexture);
    }
    // Shader
    glUniform1i(_textureUniform, 0);    // Call SimpleFragment & SimpleVertex
    // Draw
    glDrawElements(GL_TRIANGLES, sizeof(Indices1)/sizeof(Indices1[0]), GL_UNSIGNED_BYTE, 0);
    
    
    // Pin
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projectionMatrix.m);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    if (_pinTexture == 0) {
        _pinTexture = [self setupTexture:@"map_marker_icon.png"];
    }
    if (_mShouldLoadTexture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _pinTexture);
    }
    
    glUniform1i(_textureUniform, 0);    // Call SimpleFragment & SimpleVertex
    
    modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    // Rotate via z axis
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mVAngle), 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mAngle), 0, 0, 1);
    //    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(90), 1, 0, 0);
    GLfloat markerLng = [self toBaseCoordinate:self.mCenterPoint.m_centerLng Unit:self.mLatUnit Val:self.mMarkerPoint.m_lng];
    GLfloat markerLat = [self toBaseCoordinate:self.mCenterPoint.m_centerLat Unit:self.mLatUnit Val:self.mMarkerPoint.m_lat] *
    [self calculateModifier:self.mCenterPoint.m_centerLat];
    GLfloat markerAlt = [self convertAlt:self.mHighest Lowest:self.mLowest Alt:self.mMarkerPoint.m_alt];
    
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, markerLng, markerLat, markerAlt);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.1f, 0.1f, 0.0f);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 1.0f, 0.0f);
    // Shader
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    // Draw
    glDrawElements(GL_TRIANGLES, sizeof(Indices1)/sizeof(Indices1[0]), GL_UNSIGNED_BYTE, 0);
    glDisable(GL_BLEND);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (GLuint)setupTexture:(NSString *)fileName {
    
    // 1
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4
    GLuint texId;
    glGenTextures(1, &texId);
    glBindTexture(GL_TEXTURE_2D, texId);
    
    // Create Nearest Filtered Texture
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // Different possible texture parameters, e.g. GL10.GL_CLAMP_TO_EDGE
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    // Enable flag by true
    self.mShouldLoadTexture = true;
    
    free(spriteData);        
    return texId;
}

- (void)setupRoute {
    float biggestLat = -200;
    float smallestLat = 200;
    float biggestLng = -200;
    float smallestLng = 200;
    self.mLowest = 9999;
    self.mHighest = 0;
    int lengthOfArray = [self.mDataRows count];
    
    for (int i = 0; i < lengthOfArray; i++) {
        // Latitude
        biggestLat = (((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lat > biggestLat) ? ((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lat : biggestLat;
        smallestLat = (((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lat < smallestLat) ? ((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lat : smallestLat;
        
        // Longitude
        biggestLng = (((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lng > biggestLng) ? ((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lng : biggestLng;
        smallestLng = (((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lng < smallestLng) ? ((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lng : smallestLng;
        
        // Altitude
        self.mHighest = (((MapLocator*)[self.mDataRows objectAtIndex:i]).m_alt > self.mHighest) ? ((MapLocator*)[self.mDataRows objectAtIndex:i]).m_alt : self.mHighest;
        self.mLowest = (((MapLocator*)[self.mDataRows objectAtIndex:i]).m_alt < self.mLowest) ? ((MapLocator*)[self.mDataRows objectAtIndex:i]).m_alt : self.mLowest;
    }

    float round = 360;
    float latPerPixel = round/pow(2, self.mCenterPoint.m_zoom)/512;
    self.mLatUnit = latPerPixel * 256;
    
    // Allocate memory for vertices
    verticesBR = (Vertex *)malloc(sizeof(Vertex) * lengthOfArray);
    verticesRR = (Vertex *)malloc(sizeof(Vertex) * lengthOfArray);
    for(int i = 0; i < lengthOfArray; i ++){
        // Blue route
        verticesBR[i].Position[0] = [self toBaseCoordinate:self.mCenterPoint.m_centerLng Unit:self.mLatUnit Val:((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lng];
        verticesBR[i].Position[1] = [self toBaseCoordinate:self.mCenterPoint.m_centerLat Unit:self.mLatUnit Val:((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lat] *
        [self calculateModifier:self.mCenterPoint.m_centerLat];
        verticesBR[i].Position[2] = 0.0001;
        verticesBR[i].Color[0] = 0;
        verticesBR[i].Color[1] = 0;
        verticesBR[i].Color[2] = 1;
        verticesBR[i].Color[3] = 1;
        
        // Red route
        verticesRR[i].Position[0] = [self toBaseCoordinate:self.mCenterPoint.m_centerLng Unit:self.mLatUnit Val:((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lng];
        verticesRR[i].Position[1] = [self toBaseCoordinate:self.mCenterPoint.m_centerLat Unit:self.mLatUnit Val:((MapLocator*)[self.mDataRows objectAtIndex:i]).m_lat] *
        [self calculateModifier:self.mCenterPoint.m_centerLat];
        verticesRR[i].Position[2] = [self convertAlt:self.mHighest Lowest:self.mLowest Alt:((MapLocator*)[self.mDataRows objectAtIndex:i]).m_alt];
        verticesRR[i].Color[0] = 1;
        verticesRR[i].Color[1] = 0;
        verticesRR[i].Color[2] = 0;
        verticesRR[i].Color[3] = 1;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (float)latRad:(float) lat{
    float sin = sinf(lat * M_PI / 180);
    float radX2 = log((1 + sin) / (1 - sin)) / 2;
    return fmaxf(fminf(radX2, M_PI), -M_PI) / 2;
}

- (float)zoom:(float)mapPx WorldPx:(float)worldPx Fraction:(float)fraction {
    return floorf(log(mapPx / worldPx / fraction) / 0.693);
}

- (float)toBaseCoordinate:(float)center Unit:(float)unit Val:(float)x {
    return (float)((x-center)/unit/2);
}

- (float)convertAlt:(float)highest Lowest:(float)lowest Alt:(float)alt {
    return (float)((alt-lowest)/(highest-lowest));
}

- (float)calculateModifier:(float)lat{
    float modifier = 0.01682 * lat + 0.629396;
    if(modifier < 1){
        modifier = 1.0;
    }
    return modifier;
}

- (void)dealloc
{
    if (verticesBR != nil) {
        free(verticesBR);
    }
    
    if (verticesRR != nil) {
        free(verticesRR);
    }
    _context = nil;
}

- (void)initParams {
    self.mShouldLoadTexture = false;
    self.mVAngle = -50.0f;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    isMoving=YES;
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    self.mX = touchLocation.x;
    self.mY = touchLocation.y;
    
    self.mPreviousX = (self.mPreviousX != self.mX) ? self.mX : self.mPreviousX;
    self.mPreviousY = (self.mPreviousY != self.mY) ? self.mY : self.mPreviousY;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    isMoving=NO;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    self.mX = touchLocation.x;
    self.mY = touchLocation.y;
    
    float dx = self.mX - self.mPreviousX;
    float dy = self.mY - self.mPreviousY;
    int height = self.frame.size.height;
    
    // reverse direction of rotation above the mid-line
    if (self.mY > height / 2) {
        dx = dx * -1 ;
    }
    
    float newAngle = self.mAngle +
    ((-dx) * TOUCH_SCALE_FACTOR);
    [self setMAngle:newAngle];
    
    float newVAngle = self.mVAngle +
    (dy) * TOUCH_SCALE_FACTOR;
    if(newVAngle < -89){
        newVAngle = -89;
    }
    if(newVAngle > 0){
        newVAngle = 0;
    }
    [self setMVAngle:newVAngle];
    
    NSLog(@"TOUCH MOVE: X:%f Y:%f\nPreviousX:%f PreviousY:%f\nDx:%f Dy:%f\nScreenHeight:%d Dx(New):%f\nNewAngle:%f NewVAngle:%f", self.mX, self.mY, self.mPreviousX, self.mPreviousY, dx, dy, height, dx, newAngle, newVAngle);
    
    self.mPreviousX = (self.mPreviousX != self.mX) ? self.mX : self.mPreviousX;
    self.mPreviousY = (self.mPreviousY != self.mY) ? self.mY : self.mPreviousY;
}

- (void)initData:(NSMutableArray *)pDataRows CenterPoint:(Locator *)pCenterPoint MarkerPoint:(MapLocator *)pMarkerPoint {
    [self initParams];
    [self setMDataRows:pDataRows];
    [self setMCenterPoint:pCenterPoint];
    [self setMMarkerPoint:pMarkerPoint];
    [self setupLayer];
    [self setupContext];
    [self setupDepthBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupRoute];
    [self setupDisplayLink];
}
@end
