//
//  Map2DViewController.m
//  PP
//
//  Created by Duong Quoc Thang on 7/21/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "Map2DViewController.h"
@import GoogleMaps;

@implementation Map2DViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"Map2D View", nil);
}

- (void)viewDidLoad {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                            longitude:151.20
                                                                 zoom:6];
    GoogleMap2DView *mapView = [GoogleMap2DView mapWithFrame:CGRectZero camera:camera];
    mapView.myLocationEnabled = YES;
    self.map2DView = mapView;
    self.map2DView.delegate = self;
    
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(-33.86, 151.20);
    marker.title = @"Sydney";
    marker.snippet = @"Australia";
    marker.map = mapView;
    
//    //Controls whether the My Location dot and accuracy circle is enabled.
//    
//    self.map2DView.myLocationEnabled = YES;
//    
//    //Controls the type of map tiles that should be displayed.
//    
//    self.map2DView.mapType = kGMSTypeNormal;
//    
//    //Shows the compass button on the map
//    
//    self.map2DView.settings.compassButton = YES;
//    
//    //Shows the my location button on the map
//    
//    self.map2DView.settings.myLocationButton = YES;
//    
//    //Sets the view controller to be the GMSMapView delegate
//    
//    self.map2DView.delegate = self;
}


@end
