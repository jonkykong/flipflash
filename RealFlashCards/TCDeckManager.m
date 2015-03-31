//
//  TCDeckManager.m
//  Real Flash Cards
//
//  Created by Jon Kent on 3/26/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCDeckManager.h"
#import "TCDeck.h"
#import "TCCard.h"

@interface TCDeckManager ()
@property (nonatomic, strong) NSMutableArray *decks;
@property (nonatomic, strong) NSOperationQueue *saveToDiskQueue;
@end

@implementation TCDeckManager

@synthesize decks;
@synthesize saveToDiskQueue;

static TCDeckManager *sharedManager;
static const NSString *kTCDecks = @"decks";

#pragma mark - Singleton
+ (TCDeckManager *)sharedManager{
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        sharedManager = [[TCDeckManager alloc] init];
        
        sharedManager.saveToDiskQueue = [NSOperationQueue new];
        sharedManager.saveToDiskQueue.name = @"saveToDiskQueue";
        sharedManager.saveToDiskQueue.maxConcurrentOperationCount = 1;
        
        NSData *decksData = [[NSUserDefaults standardUserDefaults] objectForKey:(NSString *)kTCDecks];
        if(decksData) {
            sharedManager.decks = [NSKeyedUnarchiver unarchiveObjectWithData:decksData];
        } else {
            TCDeck *tutorialDeck = [[TCDeck alloc] init];
            tutorialDeck.title = @"Tutorial Deck (swipe left to delete)";
            for(NSUInteger i = 0; i < 8; i++) {
                TCCard *card = [[TCCard alloc] init];
                switch (i) {
                    case 0: card.frontText = @"Swipe right when you know a card →"; break;
                    case 1: card.frontText = @"← Swipe left when you don't"; break;
                    case 2: card.frontText = @"Tap a card to flip it over"; card.backText = @"That's it!"; break;
                    case 3: card.frontText = @"Hold your phone sideways to make the cards larger..."; break;
                    case 4: card.frontText = @"...or pinch to zoom in even more!"; break;
                    case 5: card.frontText = @"Add photos to cards from your camera"; card.frontImage = [UIImage imageNamed:@"math.jpg"]; break;
                    case 6: card.frontText = @"Send decks you create to your friends"; break;
                    case 7: card.frontText = @"Tap ☰ in the top-right corner to see more options"; break;
                }
                [tutorialDeck.cards addObject:card];
            }
            
            sharedManager.decks = [NSMutableArray arrayWithObject:tutorialDeck];
            [sharedManager saveDecks];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:sharedManager selector:@selector(synchronize) name:UIApplicationWillResignActiveNotification object:nil];
    });
    
    return sharedManager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)decks {
    return decks;
}

- (void)addDeck:(TCDeck *)deck {
    if(!deck) return;
    
    if(![decks containsObject:deck]) {
        [decks addObject:deck];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [decks sortUsingDescriptors:@[ sortDescriptor ]];
    }
    [self saveDecks];
}

- (void)removeDeck:(TCDeck *)deck {
    [decks removeObject:deck];
}

- (void)saveDecks {
    [saveToDiskQueue addOperationWithBlock:^{
        NSMutableArray *decksToSave = [NSMutableArray arrayWithArray:decks];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *deckData = [NSKeyedArchiver archivedDataWithRootObject:decksToSave];
        [userDefaults setValue:deckData forKey:(NSString *)kTCDecks];
        [userDefaults synchronize];
    }];
}

- (void)synchronize {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
}

@end
