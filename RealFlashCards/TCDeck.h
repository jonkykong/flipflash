//
//  TCCardDeck.h
//  Real Flash Cards
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCDeck : NSObject

- (void)encodeForSending:(BOOL)isSending;
    
- (void)setTitle:(NSString *)title;
- (void)setCards:(NSMutableArray *)cards;
- (void)clearLatestScores;
- (void)setLatestCardIndex:(NSUInteger)index showFront:(BOOL)front;
- (void)incrementDeckCycles;
- (void)resetDeckCycles;

- (NSUInteger)deckCycles;
- (NSUInteger)latestCardIndex;
- (BOOL)latestCardShowFront;
- (NSString *)title;
- (NSMutableArray *)cards;
- (void)sortCardsByDifficulty;
- (void)shuffleCards;

@end
