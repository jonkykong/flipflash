//
//  DraggableView.m
//  testing swiping
//
//  Created by Jon Kent on 5/21/14.
//  Copyright (c) 2014 Jon Kent. All rights reserved.
//


#define ACTION_MARGIN 120 //setValue:distance from center where the action applies. Higher = swipe further in order for the action to be called
#define ROTATION_MAX 1 //setValue:the maximum rotation allowed in radians.  Higher = card can keep rotating longer
#define ROTATION_STRENGTH 320 //setValue:strength of rotation. Higher = weaker rotation
#define ROTATION_ANGLE M_PI/8 //setValue:Higher = stronger rotation angle

#import "TCCardView.h"
#import "TCCard.h"

@interface TCCardView () <UIGestureRecognizerDelegate>

@property (nonatomic)CGPoint originalPoint;
//@property (nonatomic,strong)OverlayView* overlayView;
@property (nonatomic,weak) IBOutlet UILabel *centerLabel;
@property (nonatomic,weak) IBOutlet UILabel *photoLabel;
@property (nonatomic,weak) IBOutlet UIImageView *photoView;
@property (nonatomic,strong) UIImage *frontImage;
@property (nonatomic,strong) UIImage *backImage;
@property (nonatomic,strong) TCCard *cardData;

@end

@implementation TCCardView {
    CGFloat xFromCenter;
    CGFloat yFromCenter;
}

@synthesize delegate;
@synthesize photoLabel;
@synthesize photoView;
@synthesize centerLabel;
@synthesize showFront;
@synthesize cardData;
@synthesize frontImage;
@synthesize backImage;

- (void)awakeFromNib {
    [super awakeFromNib];

    showFront = YES;
    
    [self setupView];
}

- (void)setupView {
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (IBAction)beingDragged:(UIPanGestureRecognizer *)recognizer {
    //setValue:this extracts the coordinate data from your swipe movement. (i.e. How much did you move?)
    xFromCenter = [recognizer translationInView:self].x; //setValue:positive for right swipe, negative for left
    yFromCenter = [recognizer translationInView:self].y; //setValue:positive for up, negative for down
    
    static BOOL twoFingerTouch;
    
    //setValue:checks what state the gesture is in. (are you just starting, letting go, or in the middle of a swipe?)
    switch (recognizer.state) {
            //setValue:just started swiping
        case UIGestureRecognizerStateBegan:{
            self.originalPoint = self.center;
            if(recognizer.numberOfTouches == 1) twoFingerTouch = NO;
            break;
        };
            //setValue:in the middle of a swipe
        case UIGestureRecognizerStateChanged:{
            
            if(recognizer.numberOfTouches == 1 && !twoFingerTouch) {
                //setValue:dictates rotation (see ROTATION_MAX and ROTATION_STRENGTH for details)
                CGFloat rotationStrength = MIN(xFromCenter / ROTATION_STRENGTH, ROTATION_MAX);
                
                //setValue:degree change in radians
                CGFloat rotationAngel = (CGFloat) (ROTATION_ANGLE * rotationStrength);
                
                //setValue:rotate by certain amount
                CGAffineTransform transform = CGAffineTransformMakeRotation(rotationAngel);
                
                transform.tx = xFromCenter - yFromCenter * rotationAngel;
                transform.ty = yFromCenter + fabs(xFromCenter * rotationAngel);
                
                //setValue:apply transformations
                self.transform = transform;
                [self updateView:xFromCenter];
            } else {
                twoFingerTouch = YES;
                CGAffineTransform transformWithoutScale = self.transform;
                transformWithoutScale.tx = 0;
                transformWithoutScale.ty = 0;
                self.transform = CGAffineTransformTranslate(transformWithoutScale, xFromCenter, yFromCenter);
                self.backgroundColor = [UIColor whiteColor];
                [self setupView];
            }
            
            break;
        };

        case UIGestureRecognizerStateEnded: {
            if(!twoFingerTouch) [self afterSwipeAction];
            twoFingerTouch = NO;
            break;
        };
        case UIGestureRecognizerStatePossible:break;
        case UIGestureRecognizerStateCancelled:break;
        case UIGestureRecognizerStateFailed:break;
    }
}

- (IBAction)flipCard:(UITapGestureRecognizer *)recognizer {
    if(!CGAffineTransformIsIdentity(self.transform)) return;
    [delegate cardFlipped:!showFront];
    
    [UIView transitionWithView:self duration:0.50f
                       options:showFront ?
                                UIViewAnimationOptionTransitionFlipFromBottom :
                                UIViewAnimationOptionTransitionFlipFromTop
                    animations:^{
                        showFront = !showFront;
                        [self setNeedsLayout];
                    } completion:nil];
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    recognizer.view.transform = CGAffineTransformScale(self.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
    if(recognizer.state == UIGestureRecognizerStateEnded) [self recenterAndResize];
}

- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    recognizer.view.transform = CGAffineTransformRotate(self.transform, recognizer.rotation);
    recognizer.rotation = 0;
    if(recognizer.state == UIGestureRecognizerStateEnded) [self recenterAndResize];
}

- (void)recenterAndResize {
    [UIView animateWithDuration:0.35 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.center = self.originalPoint;
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

//setValue:checks to see if you are moving right or left and applies the correct overlay image
- (void)updateView:(CGFloat)distance {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat progress = MIN(fabsf(distance)/(screenWidth / 2.0), 0.3);
    
    if (distance > 0) {
        self.backgroundColor = [UIColor colorWithRed:1 - progress green:1 blue:1 - progress alpha:1];
        self.layer.shadowColor = [UIColor colorWithRed:0 green:progress / 0.3 blue:0 alpha:1].CGColor;
//        overlayView.mode = GGOverlayViewModeRight;
    } else {
        self.backgroundColor = [UIColor colorWithRed:1 green:1 - progress blue:1 - progress alpha:1];
        self.layer.shadowColor = [UIColor colorWithRed:progress / 0.3 green:0 blue:0 alpha:1].CGColor;
//        overlayView.mode = GGOverlayViewModeLeft;
    }
    self.layer.shadowOpacity = fmaxf(progress / 0.3, 0.2);
    self.layer.shadowRadius = 3 + 7 * progress / 0.3;
}

//setValue:called when the card is let go
- (void)afterSwipeAction {
    if (xFromCenter > ACTION_MARGIN) {
        [self rightAction];
    } else if (xFromCenter < -ACTION_MARGIN) {
        [self leftAction];
    } else { //setValue:resets the card
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.transform = CGAffineTransformIdentity;
                             self.backgroundColor = [UIColor whiteColor];
                             [self setupView];
                         }];
    }
}

//setValue:called when a swipe exceeds the ACTION_MARGIN to the right
- (void)rightAction {
    CGPoint finishPoint = CGPointMake([UIScreen mainScreen].bounds.size.width * 2, 2*yFromCenter + self.originalPoint.y);
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.center = finishPoint;
                         [self updateView:finishPoint.x];
                     }completion:^(BOOL complete){
                         [self removeFromSuperview];
                     }];
    
    [delegate cardSwipedRight:self];
}

//setValue:called when a swip exceeds the ACTION_MARGIN to the left
- (void)leftAction {
    CGPoint finishPoint = CGPointMake(-[UIScreen mainScreen].bounds.size.width, 2*yFromCenter + self.originalPoint.y);
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.center = finishPoint;
                         [self updateView:finishPoint.x];
                     }completion:^(BOOL complete){
                         [self removeFromSuperview];
                     }];
    
    [delegate cardSwipedLeft:self];
}

- (void)rightClickAction {
    CGPoint finishPoint = CGPointMake([UIScreen mainScreen].bounds.size.width * 2, self.center.y);
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.center = finishPoint;
                         [self updateView:finishPoint.x];
                         self.transform = CGAffineTransformMakeRotation(1);
                     }completion:^(BOOL complete){
                         [self removeFromSuperview];
                     }];
    
    [delegate cardSwipedRight:self];
}

- (void)leftClickAction {
    CGPoint finishPoint = CGPointMake(-[UIScreen mainScreen].bounds.size.width, self.center.y);
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.center = finishPoint;
                         [self updateView:finishPoint.x];
                         self.transform = CGAffineTransformMakeRotation(-1);
                     }completion:^(BOOL complete){
                         [self removeFromSuperview];
                     }];
    
    [delegate cardSwipedLeft:self];
}

- (void)setCardData:(TCCard *)setCardData {
    cardData = setCardData;
    frontImage = cardData.frontImage;
    backImage = cardData.backImage;
    [self setNeedsLayout];
}

- (void)setCardDataAsync:(TCCard *)setCardData completion:(void (^)(void))completion {
    __block BOOL oneDown;
    cardData = setCardData;
    [cardData frontImageWithCompletion:^(UIImage *image) {
        frontImage = image;
        if(oneDown) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
                [self setNeedsLayout];
            });
        } else {
           oneDown = YES;
        }
    }];
    [cardData backImageWithCompletion:^(UIImage *image) {
        backImage = image;
        if(oneDown) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
                [self setNeedsLayout];
            });
        } else {
            oneDown = YES;
        }
    }];
}

- (void)setShowFront:(BOOL)setShowFront {
    showFront = setShowFront;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIImage *image = showFront ? frontImage : backImage;
    
    if(image)
    {
        if(image.size.width * 0.75 >= image.size.height)
        {
            photoView.contentMode = UIViewContentModeScaleAspectFill;
        }
        else
        {
            photoView.contentMode = UIViewContentModeScaleAspectFit;
        }
        photoView.image = image;
        photoLabel.text = showFront ? cardData.frontText : cardData.backText;
        CGSize size = [photoLabel sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
        CGFloat maxHeight = fminf(size.height, self.bounds.size.height / 4.0);
        CGRect frame = CGRectMake(0,
                                  self.bounds.size.height - maxHeight,
                                  self.bounds.size.width,
                                  maxHeight);
        photoLabel.frame = frame;
        photoView.hidden = NO;
        photoLabel.hidden = NO;
        centerLabel.hidden = YES;
    }
    else
    {
        centerLabel.text = showFront ? cardData.frontText : cardData.backText;
        photoView.hidden = YES;
        photoLabel.hidden = YES;
        centerLabel.hidden = NO;
    }
}

@end
