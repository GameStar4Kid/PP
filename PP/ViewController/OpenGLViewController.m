//
//  OpenGLViewController.m
//  PP
//
//  Created by Duong Quoc Thang on 7/11/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "OpenGLViewController.h"

@implementation OpenGLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)viewWillAppear:(BOOL)animated
{   
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES];
    self.navigationItem.title = NSLocalizedString(@"OpenGL ES View", nil);
    
    // Do what you want here
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.glView = [[OpenGLMapSquareView alloc] initWithFrame:screenBounds];
    [self.glView initData:self.dataRows CenterPoint:self.centerPoint MarkerPoint:self.markerPoint];
    [self.view addSubview:self.glView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    if ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight ||
         [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ) {
        return YES;
    }
    else {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape; // or however you want to rotate
}
@end
