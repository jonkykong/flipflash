//
//  TCCardDeck.h
//  FlipFlash
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCDeck : NSObject<NSCopying, NSCoding> 

@property (nonatomic, readonly) NSUInteger deckCycles;
@property (nonatomic, readonly) NSUInteger latestCardIndex;
@property (nonatomic, readonly) BOOL latestCardShowFront;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSMutableArray *cards;

- (void)encodeForSending:(BOOL)isSending;
- (void)clearLatestScores;
- (void)setLatestCardIndex:(NSUInteger)index showFront:(BOOL)front;
- (void)incrementDeckCycles;
- (void)resetDeckCycles;
- (void)sortCardsByDifficulty;
- (void)shuffleCards;

@end
