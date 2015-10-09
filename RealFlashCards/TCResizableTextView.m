//
//  TCResizableTextView.m
//  FlipFlash
//
//  Created by Jon Kent on 10/8/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

#import "TCResizableTextView.h"

@implementation TCResizableTextView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateConstraints {
    for(NSLayoutConstraint *constraint in self.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            constraint.constant = super.contentSize.height + super.contentOffset.y;
            break;
        }
    }
    
    [super updateConstraints];
}

- (CGSize)contentSize
{
    [self setNeedsUpdateConstraints];
    
    return [super contentSize];
}

- (CGPoint)contentOffset
{
    [self setNeedsUpdateConstraints];
    
    return [super contentOffset];
}

- (void)textDidChange {
    self.textAlignment = NSTextAlignmentCenter;
}

@end
