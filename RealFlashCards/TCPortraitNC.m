//
//  TCPortraitNC.m
//  FlipFlash
//
//  Created by Jon Kent on 3/23/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCPortraitNC.h"

@interface TCPortraitNC ()

@end

@implementation TCPortraitNC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self updateColors];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)updateColors {
    self.navigationBar.barTintColor = [UIView appearance].tintColor;
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.barStyle = UIBarStyleBlack;
    NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithDictionary:self.navigationBar.titleTextAttributes];
    [titleAttributes addEntriesFromDictionary:@{NSForegroundColorAttributeName : [UIColor groupTableViewBackgroundColor]}];
    self.navigationBar.titleTextAttributes = titleAttributes;
    self.toolbar.barTintColor = [UIView appearance].tintColor;
    self.toolbar.tintColor = [UIColor whiteColor];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
