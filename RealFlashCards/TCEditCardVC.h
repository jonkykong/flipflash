//
//  TCEditCardVC.h
//  Real Flash Cards
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCDeck.h"
#import "TCCard.h"

@interface TCEditCardVC : UIViewController

@property (nonatomic, strong) TCDeck *deck;
@property (nonatomic, strong) TCCard *card;

@end
