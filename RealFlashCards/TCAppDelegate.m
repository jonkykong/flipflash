//
//  AppDelegate.m
//  testing swiping
//
//  Created by Jon Kent on 5/21/14.
//  Copyright (c) 2014 Jon Kent. All rights reserved.
//

#import "TCAppDelegate.h"
#import "TCDeckManager.h"
#import "TCDeck.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

NSString *const TCNewDeckFromFileNotification = @"TCNewDeckFromFileNotification";

@implementation TCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    #ifdef DEBUG
        [Fabric with:@[CrashlyticsKit]];
    #endif
    
    // http://stackoverflow.com/questions/26487170/xcode-6-x-ios-8-hides-status-bar-in-landscape-orientation
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [self updateAppAccent];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self updateAppAccent];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (url) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        if(data) {
            @try {
                TCDeck *deck = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [[TCDeckManager sharedManager] addDeck:deck];
                [[[UIAlertView alloc] initWithTitle:@"Deck Added" message:[NSString stringWithFormat:@"\"%@\" has been added to your decks.", deck.title] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                [[NSNotificationCenter defaultCenter] postNotificationName:TCNewDeckFromFileNotification object:deck userInfo:nil];
                return YES;
            }
            @catch (NSException *exception) {}
        }
    }
    [[[UIAlertView alloc] initWithTitle:@"Can't Add Deck" message:@"There was a problem with this deck preventing it from being added." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    return NO;
}

- (void)updateAppAccent {
    NSArray *colorArray = @[[UIColor colorWithRed:.8 green:0 blue:0 alpha:1], // red
                            [UIColor colorWithRed:1 green:.4 blue:0 alpha:1], // orange
                            [UIColor colorWithRed:.7 green:.7 blue:0 alpha:1], // yellow
                            [UIColor colorWithRed:0 green:.6 blue:0 alpha:1], // green
                            [UIColor colorWithRed:0 green:.8 blue:.8 alpha:1], // cyan
                            [UIColor colorWithRed:0 green:.4 blue:.8 alpha:1], // blue
                            [UIColor colorWithRed:.8 green:0 blue:.8 alpha:1]]; // pink
    
    NSCalendar* calender = [NSCalendar currentCalendar];
    NSDateComponents* component = [calender components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    UIColor *globalColor = colorArray[[component weekday] - 1]; // 1 = Sunday, 2 = Monday...
    
    [[UIView appearance] setTintColor:globalColor];
    UIImage *backButtonImage = [[UIImage imageNamed:@"Back Arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [[UINavigationBar appearance] setBackIndicatorImage:backButtonImage];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:backButtonImage];
}

@end
