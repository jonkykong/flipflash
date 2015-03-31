//
//  TCCardSwipeNC.h
//  Real Flash Cards
//
//  Created by Jon Kent on 3/25/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TCDeck;

@interface TCCardSwipeNC : UINavigationController

@property (nonatomic, strong) TCDeck *deck;
@property (nonatomic, assign) BOOL preview;

@end
