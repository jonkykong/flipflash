//
//  TCDeckManager.h
//  FlipFlash
//
//  Created by Jon Kent on 3/26/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCDeck;

@interface TCDeckManager : NSObject

@property (nonatomic, readonly, copy) NSArray *decks;

+ (TCDeckManager *)sharedManager;
- (void)addDeck:(TCDeck *)deck;
- (void)removeDeck:(TCDeck *)deck;
- (void)saveDecks;

@end
