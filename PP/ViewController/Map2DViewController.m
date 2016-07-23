//
//  Map2DViewController.m
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "Map2DViewController.h"

@interface Locator : NSObject
@property GLfloat m_centerLat;
@property GLfloat m_centerLng;
@property GLfloat m_zoom;
@end

@implementation Locator
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
    
    // Read data file
    self.dataRows = [self read3DData];
    
    if (self.dataRows == nil || (self.dataRows != nil && [self.dataRows count] == 0)) {
        return;
    }
    
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
    MapLocator *firstLocator = [self.dataRows objectAtIndex:0];
    GMSMarker *marker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(firstLocator.m_lat, firstLocator.m_lng)];
    [marker setMap:self.map2DView];
    
    
    //    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(-33.8683, 151.2086);
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:centerPosition zoom:centerLocator.m_zoom-1];
    [self.map2DView setCamera:camera];
    
    // Get 2D Image from Google URL
    NSString *imageUrlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/staticmap?center=%f,%f&zoom=%f&size=%dx%d&format=%@&key=%@", centerLocator.m_centerLat, centerLocator.m_centerLng, centerLocator.m_zoom-1, MAP_WIDTH, MAP_HEIGHT, MAP_STYLE, GoogleAPIKey];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrlStr]];
//    AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"filename"];
//    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
//    
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"Successfully downloaded file to %@", path);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
//    
//    [operation start];

}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    CGPoint p;
    marker.icon=[UIImage imageNamed:@"selectedicon.png"];//selected marker
    
    for (int i=0; i<[_markerArray count]; i++)
    {
        [_markerArray[i] getValue:&p];
        GMSMarker *unselectedMarker= [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(p.x, p.y)];
        //check selected marker and unselected marker position
        if(unselectedMarker.position.latitude!=marker.position.latitude &&    unselectedMarker.position.longitude!=marker.position.longitude)
        {
            unselectedMarker.icon=[UIImage imageNamed:@"unselectedicon.png"];
        }
    }
    
    
    return NO;
}

- (NSMutableArray *)read3DData {
    // Declare empty data array
    NSMutableArray *dataRows = [[NSMutableArray alloc] init];
    
    // Read data file
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"logtestdata" ofType:@"csv"];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    NSLog(@"contents: %@", fileContents);
    
    // Separate content by lines
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
@end
