//
//  TCCardDeck.m
//  Real Flash Cards
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCDeck.h"
#import "TCCard.h"

@interface TCDeck ()
@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, assign) BOOL sending;
@end

@implementation TCDeck

@synthesize data;
@synthesize sending;

static const NSString *kTCCardDataArrayTitle = @"title";
static const NSString *kTCCardDataArrayCards = @"cards";
static const NSString *kTCCardDataArrayLatestCardIndex = @"latestCardIndex";
static const NSString *kTCCardDataArrayLatestCardShowFront = @"latestCardShowFront";
static const NSString *kTCCardDataArrayDeckCycles = @"deckCycles";
static const NSString *kTCCardDataArray = @"data";

- (instancetype)init
{
    self = [super init];
    if (self) {
        data = [NSMutableDictionary dictionary];
        self.cards = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [[[self class] alloc] init];
    if (self) {
        data = [coder decodeObjectForKey:(NSString *)kTCCardDataArray];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if(sending) {
        for(TCCard *card in self.cards) {
            [card encodeForSending:YES];
        }
    }
    
    [coder encodeObject:data forKey:(NSString *)kTCCardDataArray];
    
    if(sending) {
        for(TCCard *card in self.cards) {
            [card encodeForSending:NO];
        }
    }
}

- (void)encodeForSending:(BOOL)isSending {
    self.sending = isSending;
}

- (void)setTitle:(NSString *)title {
    [data setValue:title forKey:(NSString *)kTCCardDataArrayTitle];
}

- (void)setCards:(NSMutableArray *)cards {
    [data setValue:cards forKey:(NSString *)kTCCardDataArrayCards];
}

- (void)setLatestCardIndex:(NSUInteger)index showFront:(BOOL)front {
    NSNumber *number = [NSNumber numberWithInteger:index];
    [data setValue:number forKey:(NSString *)kTCCardDataArrayLatestCardIndex];
    number = [NSNumber numberWithBool:front];
    [data setValue:number forKey:(NSString *)kTCCardDataArrayLatestCardShowFront];
}

- (void)incrementDeckCycles {
    NSNumber *number = [NSNumber numberWithInteger:[self deckCycles] + 1];
    [data setValue:number forKey:(NSString *)kTCCardDataArrayDeckCycles];
    for(TCCard *card in self.cards) {
        [card resetLatestScore];
    }
}

- (void)resetDeckCycles {
    [data setValue:@0 forKey:(NSString *)kTCCardDataArrayDeckCycles];
}

- (NSString *)title {
    return [data objectForKey:kTCCardDataArrayTitle];
}

- (NSMutableArray *)cards {
    return [data objectForKey:kTCCardDataArrayCards];
}

- (NSUInteger)latestCardIndex {
    NSNumber *number = [data objectForKey:kTCCardDataArrayLatestCardIndex];
    return number.integerValue;
}

- (BOOL)latestCardShowFront {
    NSNumber *number = [data objectForKey:kTCCardDataArrayLatestCardShowFront];
    if(!number) return YES;
    return number.boolValue;
}

- (NSUInteger)deckCycles {
    NSNumber *number = [data objectForKey:kTCCardDataArrayDeckCycles];
    return number.integerValue;
}

- (void)clearLatestScores {
    for(TCCard *card in self.cards) {
        [card resetLatestScore];
    }
}

- (void)sortCardsByDifficulty {
    NSMutableArray *copyOfCards = [self.cards mutableCopy];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"scoredNet" ascending:YES];
    [copyOfCards sortUsingDescriptors:@[ sortDescriptor ]];
    self.cards = copyOfCards;
    [self setLatestCardIndex:0 showFront:YES];
}

- (void)shuffleCards {
    NSMutableArray *copyOfCards = [self.cards mutableCopy];
    
    for(NSUInteger i = [self.cards count]; i > 1; i--) {
        NSUInteger j = arc4random_uniform((unsigned int)i);
        [copyOfCards exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }
    
    self.cards = copyOfCards;
    [self setLatestCardIndex:0 showFront:YES];
}

- (id)copyWithZone:(NSZone *)zone
{
    TCDeck *deck = [[TCDeck alloc] init];
    deck.title = self.title;
    
    for(TCCard *card in self.cards) {
        TCCard *newCard = [[TCCard alloc] init];
        newCard.frontText = card.frontText;
        newCard.backText = card.backText;
        newCard.frontImage = card.frontImage;
        newCard.backImage = card.backImage;
        [deck.cards addObject:newCard];
    }
    
    return deck;
}

@end
