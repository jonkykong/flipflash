//
//  TCCardData.h
//  testing swiping
//
//  Created by Jon Kent on 3/19/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCCard : NSObject<NSCoding> 

@property (nonatomic, copy) NSString *frontText;
@property (nonatomic, strong) UIImage *frontImage;
@property (nonatomic, copy) NSString *backText;
@property (nonatomic, strong) UIImage *backImage;
@property (nonatomic, readonly) NSUInteger scoredRight;
@property (nonatomic, readonly) NSUInteger scoredWrong;
@property (nonatomic, readonly) NSInteger scoredNet;
@property (nonatomic, readonly) NSUInteger scoredTotal;
@property (nonatomic, readonly) NSInteger scoredLatest;

- (void)encodeForSending:(BOOL)sending;
- (void)incrementScoreRight;
- (void)incrementScoreWrong;
- (void)resetScores;
- (void)resetLatestScore;
- (void)frontImageWithCompletion:(void (^)(UIImage* image))completion;
- (void)backImageWithCompletion:(void (^)(UIImage* image))completion;

@end
