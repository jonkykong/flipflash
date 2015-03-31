//
//  TCCardData.h
//  testing swiping
//
//  Created by Jon Kent on 3/19/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCCard : NSObject

- (void)encodeForSending:(BOOL)sending;

- (void)setFrontText:(NSString *)frontText;
- (void)setFrontImage:(UIImage *)frontImage;
- (void)setBackText:(NSString *)backText;
- (void)setBackImage:(UIImage *)backImage;
- (void)incrementScoreRight;
- (void)incrementScoreWrong;
- (void)resetScores;
- (void)resetLatestScore;

- (NSString *)frontText;
- (UIImage *)frontImage;
- (NSString *)backText;
- (UIImage *)backImage;
- (void)frontImageWithCompletion:(void (^)(UIImage* image))completion;
- (void)backImageWithCompletion:(void (^)(UIImage* image))completion;
- (NSUInteger)scoredRight;
- (NSUInteger)scoredWrong;
- (NSInteger)scoredNet;
- (NSUInteger)scoredTotal;
- (NSInteger)scoredLatest;

@end
