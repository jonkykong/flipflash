//
//  TCCardSwipeNC.m
//  FlipFlash
//
//  Created by Jon Kent on 3/25/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCCardSwipeNC.h"
#import "TCCardSwipeVC.h"

@interface TCCardSwipeNC () <UINavigationControllerDelegate>

@property (nonatomic, assign) BOOL showPortrait;

@end

@implementation TCCardSwipeNC

@synthesize deck;
@synthesize showPortrait;
@synthesize preview;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self rotateToDeviceOrientation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateToDeviceOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rotateToDeviceOrientation {
    if(![self shouldAutorotate]) {
        return;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    TCCardSwipeVC *nextPage;
    if(UIDeviceOrientationIsLandscape(orientation)) {
        if(!showPortrait && self.topViewController) {
            return;
        }
        showPortrait = NO;
        nextPage = [storyboard instantiateViewControllerWithIdentifier:@"LandscapeSwipe"];
    } else if(UIDeviceOrientationIsPortrait(orientation) || !self.topViewController) {
        if(preview && self.topViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        if(showPortrait) {
            return;
        }
        showPortrait = YES;
        nextPage = [storyboard instantiateViewControllerWithIdentifier:@"PortraitSwipe"];
    } else {
        return;
    }
    
    nextPage.deck = deck;
    nextPage.preview = preview;
    TCCardSwipeVC *currentPage = (id)self.topViewController;
    nextPage.cardRevealMode = currentPage.cardRevealMode;
    if (!nextPage.view.window)
    {
        [self pushViewController:nextPage animated:NO];
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self setViewControllers:@[viewController] animated:NO];
}

- (BOOL)shouldAutorotate {
    if(!self.topViewController) {
        return YES;
    }
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if(!self.topViewController) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if(UIDeviceOrientationIsLandscape(orientation)) {
            return UIInterfaceOrientationMaskLandscape;
        }
        return UIInterfaceOrientationMaskPortrait;
    }
    if([self shouldAutorotate]) {
        return UIInterfaceOrientationMaskAll;
    }
    if(showPortrait) {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskLandscape;
}
@end
