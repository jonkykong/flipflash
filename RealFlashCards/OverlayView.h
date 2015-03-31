//
//  OverlayView.h
//  testing swiping
//
//  Created by Jon Kent on 5/22/14.
//  Copyright (c) 2014 Jon Kent. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger , GGOverlayViewMode) {
    GGOverlayViewModeLeft,
    GGOverlayViewModeRight
};

@interface OverlayView : UIView

@property (nonatomic) GGOverlayViewMode mode;
@property (nonatomic, strong) UIImageView *imageView;

@end
