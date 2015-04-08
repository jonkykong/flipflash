//
//  DraggableView.h
//  testing swiping
//
//  Created by Jon Kent on 5/21/14.
//  Copyright (c) 2014 Jon Kent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OverlayView.h"

@protocol TCCardViewDelegate <NSObject>

- (void)cardSwipedLeft:(UIView *)card;
- (void)cardSwipedRight:(UIView *)card;
- (void)cardFlipped:(BOOL)showFront;

@end

@class TCCard;

@interface TCCardView : UIView

@property (nonatomic,assign) BOOL showFront;
@property (weak) id <TCCardViewDelegate> delegate;

- (void)setCardData:(TCCard *)setCardData;
- (void)setCardDataAsync:(TCCard *)setCardData completion:(void (^)(void))completion;
- (void)leftClickAction;
- (void)rightClickAction;

@end
