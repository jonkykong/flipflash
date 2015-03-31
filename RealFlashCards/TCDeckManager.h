//
//  TCDeckManager.h
//  Real Flash Cards
//
//  Created by Jon Kent on 3/26/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCDeck;

@interface TCDeckManager : NSObject

+ (TCDeckManager *)sharedManager;
- (NSArray *)decks;
- (void)addDeck:(TCDeck *)deck;
- (void)removeDeck:(TCDeck *)deck;
- (void)saveDecks;

@end
