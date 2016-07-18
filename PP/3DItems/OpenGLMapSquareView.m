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
    
}

@property Boolean mShouldLoadTexture;

@end

@implementation OpenGLMapSquareView

#define TEX_COORD_MAX   1
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


//        positionList.add(new Position(11.938604, 108.441754, 1491));
//        positionList.add(new Position(11.939946, 108.446161, 1481));
//        positionList.add(new Position(11.936598, 108.446848, 1485));
//        positionList.add(new Position(11.935789, 108.446054, 1480));
//        positionList.add(new Position(11.935926, 108.445614, 1482));
//        positionList.add(new Position(11.937584, 108.445131, 1486));
//        positionList.add(new Position(11.938613, 108.441794, 1491));
Position route[] = {{11.938604, 108.441754, 1491},
                {11.939946, 108.446161, 1481},
                {11.936598, 108.446848, 1485},
                {11.935789, 108.446054, 1480},
                {11.935926, 108.445614, 1482},
                {11.937584, 108.445131, 1486},
                {11.938613, 108.441794, 1491}
};

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {   
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
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentName withType:GL_FRAGMENT_SHADER];
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
    glEnableVertexAttribArray(_programHandle);
    glEnableVertexAttribArray(_programHandle);
    
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
}

- (void)render:(CADisplayLink*)displayLink {
    [self setupVBO_Index];
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);        
    
    float aspect = fabs(self.frame.size.width / self.frame.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 0.01f, 100.0f);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projectionMatrix.m);

    // Map
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(45.0f), -1, 0, 0);
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));    
    
    if (_mapTexture == 0) {
        _mapTexture = [self setupTexture:@"staticmap2.png"];
    }
    
    if (_mShouldLoadTexture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _mapTexture);
    }
    // Shader
    glUniform1i(_textureUniform, 0);    // Call SimpleFragment & SimpleVertex
    // Draw
    glDrawElements(GL_TRIANGLES, sizeof(Indices1)/sizeof(Indices1[0]), GL_UNSIGNED_BYTE, 0);
    
    
    // Pin
    if (_pinTexture == 0) {
        _pinTexture = [self setupTexture:@"map_marker_icon.png"];
    }
    if (_mShouldLoadTexture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _pinTexture);
    }
    
    glUniform1i(_textureUniform, 0);    // Call SimpleFragment & SimpleVertex
    
    modelViewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.1f, 0.1f, 0.0f);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 1.0f, 0.0f);
    // Shader
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelViewMatrix.m);
    // Draw
    glDrawElements(GL_TRIANGLES, sizeof(Indices1)/sizeof(Indices1[0]), GL_UNSIGNED_BYTE, 0);
    
    
    // Blueroute
    [self setupVBOInfo:verticesBR];
    [self compileFragmentShader:@"RouteFragment"];
    // Draw
    glDrawElements(GL_LINE_STRIP, sizeof(verticesBR)/sizeof(verticesBR[0]), GL_UNSIGNED_BYTE, 0);
    
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
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
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
    float lowest = 9999;
    float highest = 0;
    int lengthOfArray = sizeof(route) / sizeof(route[0]);
    for (int i = 0; i < lengthOfArray; i++) {
        // Latitude
        biggestLat = (route[i].lat > biggestLat) ? route[i].lat : biggestLat;
        smallestLat = (route[i].lat < smallestLat) ? route[i].lat : smallestLat;
        // Longitude
        biggestLng = (route[i].lng > biggestLng) ? route[i].lng : biggestLng;
        smallestLng = (route[i].lng < smallestLng) ? route[i].lng : smallestLng;
        // Altitude
        highest = (route[i].alt > highest) ? route[i].alt : highest;
        lowest = (route[i].alt < lowest) ? route[i].alt : lowest;
    }
    
    float latFraction = [self latRad:biggestLat] - [self latRad:smallestLat] / M_PI;
    
    float lngDiff = biggestLng - smallestLng;
    float lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360;
    
    float latZoom = [self zoom:512 WorldPx:256 Fraction:latFraction];
    float lngZoom = [self zoom:512 WorldPx:256 Fraction:lngFraction];
    
    float zoom = fminf(latZoom, lngZoom);
    zoom = fminf(zoom, 21);
    
    float centerLat = (biggestLat + smallestLat) / 2;
    float centerLng = (biggestLng + smallestLng) / 2;
    
    float round = 360;
    float latPerPixel = round/pow(2, zoom)/512;
    float latUnit = latPerPixel * 256;
    verticesBR = malloc(sizeof(Vertex) * lengthOfArray);
    for(int i = 0; i < lengthOfArray; i ++){
        verticesBR[i].Position[0] = [self toBaseCoordinate:centerLng Unit:latUnit Val:route[i].lng];
        verticesBR[i].Position[1] = [self toBaseCoordinate:centerLat Unit:latUnit Val:route[i].lat] *
        [self calculateModifier:centerLat];
        verticesBR[i].Position[2] = 0;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
        [self setupLayer];        
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];        
        [self setupFrameBuffer];
        [self setupRoute];
        [self compileShaders];
        [self setupDisplayLink];
    }
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
    _context = nil;
}

- (void)initParams {
    self.mShouldLoadTexture = false;
}
@end
