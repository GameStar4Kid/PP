//
//  Map2DViewController.m
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "Map2DViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "OpenGLViewController.h"
#import <OpenGLES/ES1/gl.h>

@implementation Locator
@end

@implementation MapLocator
@end

@implementation Map2DViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"Map2D View", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.x = -1;
    
    // Disable 3D button firstly
    [_btn3D setEnabled:FALSE];
    
    // Read data file
    self.dataRows = [self read3DData];
    
    if (self.dataRows == nil || (self.dataRows != nil && [self.dataRows count] == 0)) {
        return;
    }
    
    // Keep height data
    [self getHeightData];
    self.numberOfData = [self.dataRows count];
    
    // Display map at first locator
    Locator *centerLocator = [self getCenterLocator];
    CLLocationCoordinate2D centerPosition = CLLocationCoordinate2DMake(centerLocator.m_centerLat, centerLocator.m_centerLng);
    self.map2DView.delegate = self;

    // Create path for polyline
    GMSMutablePath *path = [GMSMutablePath path];
    for (int i = 0; i < [_dataRows count]; i++) {
        [path addCoordinate:CLLocationCoordinate2DMake(((MapLocator*)([_dataRows objectAtIndex:i])).m_lat, ((MapLocator*)([_dataRows objectAtIndex:i])).m_lng)];
    }
    
    // Create polyline
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    [polyline setStrokeWidth:2.0f];
    [polyline setStrokeColor:[UIColor blueColor]];
    [polyline setMap:self.map2DView];
    
    
    // Create marker
    [self setMarkerPoint:[self.dataRows objectAtIndex:0]];
    self.marker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(self.markerPoint.m_lat, self.markerPoint.m_lng)];
    [self.marker setMap:self.map2DView];
    
    // Move camera to center position
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:centerPosition zoom:centerLocator.m_zoom-1];
    [self.map2DView setCamera:camera];
    
    // Get 2D Image from Google URL
    NSString *imageUrlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/staticmap?center=%f,%f&zoom=%d&size=%dx%d&format=%@&key=%@", centerLocator.m_centerLat, centerLocator.m_centerLng, (int)centerLocator.m_zoom-1, MAP_WIDTH, MAP_HEIGHT, MAP_STYLE, GoogleAPIKey];

    //download the file in a seperate thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Downloading Started");
        NSString *urlToDownload = imageUrlStr;
        NSURL  *url = [NSURL URLWithString:urlToDownload];
        NSData *urlData = [NSData dataWithContentsOfURL:url];
        if ( urlData )
        {
            NSArray       *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"map.png"];
            
            //saving is done on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [urlData writeToFile:filePath atomically:YES];
                NSLog(@"File Saved !");
                
                // Enable 3D button
                [_btn3D setEnabled:TRUE];
            });
        }
        
    });
    
    glFlush();
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!self.context)
    {
        NSLog(@"Failed to create ES context");
    }
    GLKView *view = (GLKView *)self.mapHeight2DView;
    view.context = self.context;                      //3
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.context];
    self.mapHeight2DView.delegate = self;
    [self setupDisplayLink];
}

- (NSMutableArray *)read3DData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *filePath =  [documentsDirectory stringByAppendingPathComponent:@"logtestdata_2sec.csv"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSString *myPathInfo = [[NSBundle mainBundle] pathForResource:@"logtestdata_2sec" ofType:@"csv"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager copyItemAtPath:myPathInfo toPath:filePath error:NULL];
    }
    
    //Load from File
    NSError *error;
    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];

    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    NSLog(@"contents: %@", fileContents);
    
    // Separate content by lines
    // Declare empty data array
    NSMutableArray *dataRows = [[NSMutableArray alloc] init];
    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    
    // Remove empty data array
    for (int i = 0; i < [listArray count]; i++) {
        // Remove the blank line and the first row
        if (!(([listArray[i] length]) <= 7) && i != 0) {
            NSArray *items = [listArray[i] componentsSeparatedByString:@","];
            
            // Create new MapLocator object
            MapLocator *locator = [[MapLocator alloc] init];
            [locator setM_date:items[0]];
            [locator setM_time:items[1]];
            [locator setM_status:[items[2] intValue]];
            [locator setM_lat:[items[3] floatValue]];
            [locator setM_lng:[items[4] floatValue]];
            [locator setM_alt:[items[5] floatValue]];
            [locator setM_now:[items[6] intValue]];
            
            [dataRows addObject:locator];
        }
    }
    
    // Keep data into MapLocator object
    for (MapLocator *locator in dataRows) {
        NSLog(@"%@\t%f\t%f\t%f\n", locator.m_time, locator.m_lat, locator.m_lng, locator.m_alt);
    }
    
    NSLog(@"items = %lu\n", (unsigned long)[dataRows count]);
    
    return dataRows;
}

- (void)getHeightData {
    self.vertexData = (GLfloat*)malloc(sizeof(GLfloat) * [self.dataRows count] * 6);
    
    GLfloat highest = 0;
    for(int i = 0; i < [self.dataRows count]; i ++){
        if(((MapLocator*)([self.dataRows objectAtIndex:i])).m_alt > highest){
            highest = ((MapLocator*)([self.dataRows objectAtIndex:i])).m_alt;
        }
    }
    
    for(int i = 0; i < [self.dataRows count]; i ++){
        self.vertexData[i*6] = (float)(i*2.0/[self.dataRows count])-1;
        self.vertexData[i*6+1] = (float)(((MapLocator*)([self.dataRows objectAtIndex:i])).m_alt/highest);
        self.vertexData[i*6+2] = 0;
        self.vertexData[i*6+3] = (float)(i*2.0/[self.dataRows count])-1;
        self.vertexData[i*6+4] = 0;
        self.vertexData[i*6+5] = 0;
    }
}

- (Locator*)getCenterLocator {
    Locator *centerLocator;
    double biggestLat = 0;
    double smallestLat = 9999;
    double biggestLng = 0;
    double smallestLng = 999;
    double lowest = 9999;
    double highest = 0;
    for (MapLocator *locator in self.dataRows) {
        if (locator.m_lat > biggestLat) {
            biggestLat = locator.m_lat;
        }
        if (locator.m_lat < smallestLat) {
            smallestLat = locator.m_lat;
        }
        if (locator.m_lng > biggestLng) {
            biggestLng = locator.m_lng;
        }
        if (locator.m_lng < smallestLng) {
            smallestLng = locator.m_lng;
        }
        if(locator.m_alt > highest){
            highest = locator.m_alt;
        }
        if(locator.m_alt < lowest){
            lowest = locator.m_alt;
        }
    }

    float latFraction = ([self latRad:biggestLat] - [self latRad:smallestLat]) / M_PI;
    
    float lngDiff = biggestLng - smallestLng;
    float lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360;
    
    float latZoom = [self zoom:512 WorldPx:256 Fraction:latFraction];
    float lngZoom = [self zoom:512 WorldPx:256 Fraction:lngFraction];
    
    float zoom = fminf(latZoom, lngZoom);
    zoom = fminf(zoom, 21);
    
    float centerLat = (biggestLat + smallestLat) / 2;
    float centerLng = (biggestLng + smallestLng) / 2;
    
    centerLocator = [[Locator alloc] init];
    [centerLocator setM_centerLat:centerLat];
    [centerLocator setM_centerLng:centerLng];
    [centerLocator setM_zoom:zoom];
    
    return centerLocator;
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

- (BOOL)shouldAutorotate {
    return NO;
}

- (IBAction)open3DView:(id)sender {
    // Open 3D form
    OpenGLViewController *glView = [[OpenGLViewController alloc] init];
    [glView setDataRows:self.dataRows];
    [glView setCenterPoint:[self getCenterLocator]];
    [glView setMarkerPoint:self.markerPoint];
    // Adds the above view controller to the stack and pushes it into view
    [self.navigationController pushViewController:glView animated:YES];
}

- (void)setupDisplayLink {
//    // drawFrame is the render trigger function
//    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame)];
//    // with the frameInterval 0 = max speed , 100 = slow
//    self.displayLink.frameInterval = 2;
//    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)drawFrame
{
    // notify that we want to update the context
    [self.mapHeight2DView setNeedsDisplay];
}

- (void)glkViewControllerUpdate:(GLKViewController *)controller {
    // Do nothing
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glPushMatrix();
    // Create View
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Enable Smooth Shading, default not really needed.
    glShadeModel(GL_FLAT);
    // Depth buffer setup.
    glClearDepthf(1.0f);
    // Enables depth testing.
    glDisable(GL_DEPTH_TEST);
    // The type of depth testing to do.
    glDepthFunc(GL_LEQUAL);
    // Really nice perspective calculations.
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

    // Select the projection matrix
    glMatrixMode(GL_PROJECTION);
    // Reset the projection matrix
    glLoadIdentity();
    // Calculate the aspect ratio of the window
    glOrthof(-1, 1, 0, 1, 1.0f, 100);
    // Select the modelview matrix
    glMatrixMode(GL_MODELVIEW);
    // Reset the modelview matrix
    glLoadIdentity();
    gluLookAt(0.0f, 0.0f, 3.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);

    // Height Data
    glPushMatrix();
    // Counter-clockwise winding.
    glFrontFace(GL_CCW);
    // Enable face culling.
    glEnable(GL_CULL_FACE);
    // What faces to remove with the face culling.
    glCullFace(GL_BACK);
    
    // Enabled the vertices buffer for writing and to be used during
    // rendering.
    glEnableClientState(GL_VERTEX_ARRAY);
    // Specifies the location and data format of an array of vertex
    // coordinates to use when rendering.
    glVertexPointer(3, GL_FLOAT, 0, self.vertexData);
    glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, [self.dataRows count]*2);
    
    // Disable the vertices buffer.
    glDisableClientState(GL_VERTEX_ARRAY);
    // Disable face culling.
    glDisable(GL_CULL_FACE);
    glPopMatrix();
    
    
    // WhiteLine
    GLfloat vertices[] = { self.x, 1, 0, self.x, 0, 0 };
    glPushMatrix();
    // Counter-clockwise winding.
    glFrontFace(GL_CCW);
    // Enable face culling.
    glEnable(GL_CULL_FACE);
    // What faces to remove with the face culling.
    glCullFace(GL_BACK);
    
    // Enabled the vertices buffer for writing and to be used during
    // rendering.
    glEnableClientState(GL_VERTEX_ARRAY);
    // Specifies the location and data format of an array of vertex
    // coordinates to use when rendering.
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glLineWidth(2.0f);
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    glDrawArrays(GL_LINES, 0, 2);
    
    // Disable the vertices buffer.
    glDisableClientState(GL_VERTEX_ARRAY);
    // Disable face culling.
    glDisable(GL_CULL_FACE);
    glPopMatrix();
    
    glPopMatrix();
}

- (void)dealloc {
    if (self.vertexData != nil) {
        free(self.vertexData);
    }
}

void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
               GLfloat centerx, GLfloat centery, GLfloat centerz,
               GLfloat upx, GLfloat upy, GLfloat upz)
{
    GLfloat m[16];
    GLfloat x[3], y[3], z[3];
    GLfloat mag;
    
    /* Make rotation matrix */
    
    /* Z vector */
    z[0] = eyex - centerx;
    z[1] = eyey - centery;
    z[2] = eyez - centerz;
    mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
    if (mag) {          /* mpichler, 19950515 */
        z[0] /= mag;
        z[1] /= mag;
        z[2] /= mag;
    }
    
    /* Y vector */
    y[0] = upx;
    y[1] = upy;
    y[2] = upz;
    
    /* X vector = Y cross Z */
    x[0] = y[1] * z[2] - y[2] * z[1];
    x[1] = -y[0] * z[2] + y[2] * z[0];
    x[2] = y[0] * z[1] - y[1] * z[0];
    
    /* Recompute Y = Z cross X */
    y[0] = z[1] * x[2] - z[2] * x[1];
    y[1] = -z[0] * x[2] + z[2] * x[0];
    y[2] = z[0] * x[1] - z[1] * x[0];
    
    /* mpichler, 19950515 */
    /* cross product gives area of parallelogram, which is < 1.0 for
     * non-perpendicular unit-length vectors; so normalize x, y here
     */
    
    mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    if (mag) {
        x[0] /= mag;
        x[1] /= mag;
        x[2] /= mag;
    }
    
    mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
    if (mag) {
        y[0] /= mag;
        y[1] /= mag;
        y[2] /= mag;
    }
    
#define M(row,col)  m[col*4+row]
    M(0, 0) = x[0];
    M(0, 1) = x[1];
    M(0, 2) = x[2];
    M(0, 3) = 0.0;
    M(1, 0) = y[0];
    M(1, 1) = y[1];
    M(1, 2) = y[2];
    M(1, 3) = 0.0;
    M(2, 0) = z[0];
    M(2, 1) = z[1];
    M(2, 2) = z[2];
    M(2, 3) = 0.0;
    M(3, 0) = 0.0;
    M(3, 1) = 0.0;
    M(3, 2) = 0.0;
    M(3, 3) = 1.0;
#undef M
    glMultMatrixf(m);
    
    /* Translate Eye to Origin */
    glTranslatef(-eyex, -eyey, -eyez);
    
}

- (void)setMarkerNewPos:(CGFloat)pXPos {
    int markerXPos = (int)floorf((pXPos + 1) * [self.dataRows count] / 2 );
    if(markerXPos < 0){
        markerXPos = 0;
    }
    if(markerXPos >= [self.dataRows count]){
        markerXPos = [self.dataRows count] - 1;
    }
    [self setMarkerPoint:[self.dataRows objectAtIndex:markerXPos]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.mapHeight2DView];
    self.x = touchLocation.x/self.mapHeight2DView.bounds.size.width * 2 - 1;
    [self drawFrame];
    [self updateMarker];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.mapHeight2DView];
    self.x = touchLocation.x/self.mapHeight2DView.bounds.size.width * 2 - 1;
    [self drawFrame];
    [self updateMarker];
}

- (void)updateMarker {
    [self setMarkerNewPos:self.x];
    if (self.marker == nil) {
        [self.marker setMap:nil];
        self.marker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(self.markerPoint.m_lat, self.markerPoint.m_lng)];
        self.marker.map = self.map2DView;
    } else {
        self.marker.position = CLLocationCoordinate2DMake(self.markerPoint.m_lat, self.markerPoint.m_lng);
    }
}
@end
