//
//  TCEditDeckVC.h
//  Real Flash Cards
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCDeck.h"

@class TCEditDeckVC;
@protocol TCEditDeckVCDelegate <NSObject>

- (void)editDeckVC:(TCEditDeckVC *)editDeckVC didFinishWithDeck:(TCDeck *)deck;

@end

@interface TCEditDeckVC : UITableViewController

@property (nonatomic, strong) TCDeck *deck;
@property (nonatomic, assign) BOOL isNewDeck;
@property (nonatomic, weak) id<TCEditDeckVCDelegate> delegate;

@end