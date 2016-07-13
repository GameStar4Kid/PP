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
}
- (void)viewWillAppear:(BOOL)animated
{   
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.title = NSLocalizedString(@"OpenGL ES View", nil);
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.glView = [[OpenGLMapSquareView alloc] initWithFrame:screenBounds];
    [self.view addSubview:self.glView];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
