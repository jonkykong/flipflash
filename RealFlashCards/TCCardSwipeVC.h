//
//  ViewController.h
//  testing swiping
//
//  Created by Jon Kent on 5/21/14.
//  Copyright (c) 2014 Jon Kent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCDeck.h"

typedef NS_ENUM(NSInteger, TCCardRevealMode) {
    TCCardRevealFront = 0,
    TCCardRevealBack,
    TCCardRevealRandom
};

@interface TCCardSwipeVC : UIViewController

@property (nonatomic, strong) TCDeck *deck;
@property (nonatomic, assign) BOOL preview;
@property (assign, nonatomic) TCCardRevealMode cardRevealMode;

@end
