//
//  TCEditCardVC.m
//  Real Flash Cards
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCEditCardVC.h"

@interface TCEditCardVC () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *nextCardButton;
@property (nonatomic, weak) IBOutlet UIButton *previousCardButton;
@property (nonatomic, weak) IBOutlet UITextView *cardTextView;
@property (nonatomic, weak) IBOutlet UIImageView *cardImageView;
@property (nonatomic, weak) IBOutlet UIView *cardView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *flipCardSegmentControl;
@property (nonatomic, weak) IBOutlet UIButton *imageButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *scrollViewBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tipLabelHeighConstraint;
@property (nonatomic, assign) BOOL showFront;

@end

@implementation TCEditCardVC

@synthesize nextCardButton;
@synthesize previousCardButton;
@synthesize flipCardSegmentControl;
@synthesize cardTextView;
@synthesize cardView;
@synthesize cardImageView;
@synthesize showFront;
@synthesize imageButton;
@synthesize scrollView;
@synthesize deck;
@synthesize card;
@synthesize scrollViewBottomConstraint;
@synthesize tipLabelHeighConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cardView.layer.borderWidth = 0.5;
    cardView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    [cardTextView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];
    
    imageButton.layer.borderWidth = 1;
    imageButton.layer.borderColor = [UIView appearance].tintColor.CGColor;
    imageButton.layer.cornerRadius = 4;
    [imageButton setImage:imageButton.imageView.image forState:UIControlStateSelected];
    UIImage *template = [imageButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [imageButton setImage:template forState:UIControlStateNormal];
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIView appearance].tintColor.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [imageButton setBackgroundImage:image forState:UIControlStateSelected];
    imageButton.clipsToBounds = YES;
    imageButton.imageView.contentMode = UIViewContentModeCenter;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    tipLabelHeighConstraint.constant = screenSize.height - NavigationHeight - cardView.frame.origin.y - (screenSize.width - 16) * 0.75;
    
    CALayer *layer = [[CALayer alloc] init];
    layer.frame = CGRectMake(0, 0, screenSize.width - 16, (screenSize.width - 16) * 0.75);
    layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
    [cardImageView.layer addSublayer:layer];
    
    if(!card) {
        card = [[TCCard alloc] init];
        [deck.cards addObject:card];
    }
    
    [self enablePreviousAndNextButtons];
    [self displayCard:YES];
}

- (void)dealloc {
    [cardTextView removeObserver:self forKeyPath:@"contentSize"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setTextVerticalAlignment];
}

- (void)setTextVerticalAlignment {
//    if(!cardImageView.image) {
        CGFloat topCorrect = ([cardTextView bounds].size.height - [cardTextView contentSize].height * [cardTextView zoomScale])/2.0;
        topCorrect = fmaxf(0.0, topCorrect);
        cardTextView.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
        cardTextView.textAlignment = NSTextAlignmentCenter;
//    } else {
//        CGFloat topCorrect = ([cardTextView bounds].size.height - [cardTextView contentSize].height * [cardTextView zoomScale]);
//        topCorrect = fmaxf(0.0, topCorrect);
//        cardTextView.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
//        cardTextView.textAlignment = NSTextAlignmentCenter;
//    }
}

- (void)keyboardWillShowOrHide:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    
    NSValue *bv = info[UIKeyboardFrameEndUserInfoKey];
    
    NSValue* ad = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = 0;
    [ad getValue:&animationDuration];
    
    NSNumber *ao = info[UIKeyboardAnimationCurveUserInfoKey];
    NSUInteger animationOptions;
    [ao getValue:&animationOptions];
    
    CGRect br = [bv CGRectValue];

    CGFloat height = br.origin.y >= [UIScreen mainScreen].bounds.size.height - FLT_EPSILON ? 0 : br.size.height;
    scrollViewBottomConstraint.constant = height;
    
    [UIView animateWithDuration:animationDuration delay:0 options:animationOptions
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    if(!self.presentedViewController) {
        [self saveCard];
        
        for(TCCard *cardData in [deck.cards copy]) {
            if(cardData.frontText.length == 0 &&
               card.backText.length == 0 &&
               !cardData.frontImage &&
               !cardData.backImage) {
                [deck.cards removeObject:cardData];
            }
        }
    }
    
    [super viewWillDisappear:animated];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)addCard:(id)sender {
    [self saveCard];
    NSUInteger index = [deck.cards indexOfObject:card];
    
    card = [[TCCard alloc] init];
    [deck.cards insertObject:card atIndex:index + 1];
    [self enablePreviousAndNextButtons];
    
    [self animateCardSlideLeft:YES];
}

- (IBAction)nextCard:(id)sender {
    [self saveCard];
    
    NSUInteger index = [deck.cards indexOfObject:card];
    if(index == deck.cards.count - 1) return;
    index++;
    card = [deck.cards objectAtIndex:index];
    [self enablePreviousAndNextButtons];
    [self.view endEditing:YES];
    
    [self animateCardSlideLeft:YES];
}

- (IBAction)previousCard:(id)sender {
    [self saveCard];
    
    NSUInteger index = [deck.cards indexOfObject:card];
    if(index == 0) return;
    index--;
    card = [deck.cards objectAtIndex:index];
    [self enablePreviousAndNextButtons];
    [self.view endEditing:YES];
    
    [self animateCardSlideLeft:NO];
}

- (void)animateCardSlideLeft:(BOOL)left {
    CGFloat x = self.view.frame.size.width;
    if(!left) x *= -1;
    
    [UIView animateWithDuration:0.15 animations:^{
        cardView.transform = CGAffineTransformMakeTranslation(-x, 0);
    } completion:^(BOOL finished) {
        cardView.transform = CGAffineTransformMakeTranslation(x, 0);
        
        [self displayCard:YES];
        
        [UIView animateWithDuration:0.15 animations:^{
            cardView.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (IBAction)flipCard:(id)sender {
    [self saveCard];
    
    [UIView transitionWithView:cardView duration:0.50f
                       options:showFront ?
    UIViewAnimationOptionTransitionFlipFromBottom :
    UIViewAnimationOptionTransitionFlipFromTop
                    animations:^{
                        [self displayCard:!showFront];
                    } completion:nil];
}

- (IBAction)addImage:(UIButton *)sender {
    BOOL cameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    if (!cameraAvailable) {
        UIAlertView *authorizationAlertView;
        
        if(&UIApplicationOpenSettingsURLString != NULL)
        {
            authorizationAlertView = [[UIAlertView alloc] initWithTitle:@"Camera Access" message:@"Please enable Camera Access in Settings." delegate:self cancelButtonTitle:@"Close" otherButtonTitles:@"Settings", nil];
        }
        else
        {
            authorizationAlertView = [[UIAlertView alloc] initWithTitle:@"Camera Access" message:@"Please enable Camera Access in Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        
        [authorizationAlertView show];
        return;
    }
        
    imageButton.selected = !imageButton.selected;
    if(!imageButton.selected) {
        cardTextView.textColor = [UIColor darkGrayColor];
        [UIView animateWithDuration:0.35 animations:^{
            cardImageView.alpha = 0;
        } completion:^(BOOL finished) {
            cardImageView.image = nil;
            cardImageView.hidden = YES;
            cardImageView.alpha = 1;
            if(showFront) {
                card.frontImage = nil;
            } else {
                card.backImage = nil;
            }
        }];
        return;
    }
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)enablePreviousAndNextButtons {
    NSUInteger index = [deck.cards indexOfObject:card];
    previousCardButton.enabled = YES;
    nextCardButton.enabled = YES;
    if(index == 0) {
        previousCardButton.enabled = NO;
    }
    if(index == deck.cards.count - 1 || deck.cards.count == 0) {
        nextCardButton.enabled = NO;
    }
}

- (void)saveCard {
    if(showFront) {
        card.frontText = [cardTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        card.backText = [cardTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

- (void)displayCard:(BOOL)front {
    showFront = front;
    
    if(front) {
        imageButton.selected = card.frontImage != nil;
    } else {
        imageButton.selected = card.backImage != nil;
    }
    
    flipCardSegmentControl.selectedSegmentIndex = front ? 0 : 1;
    cardTextView.text = front ? card.frontText : card.backText;
    
    UIImage *image = showFront ? card.frontImage : card.backImage;
    if(image) {
        if(image.size.width * 0.75 >= image.size.height)
        {
            cardImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        else
        {
            cardImageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        cardImageView.image = image;
        cardImageView.hidden = NO;
        cardTextView.textColor = [UIColor whiteColor];
    } else {
        cardImageView.hidden = YES;
        cardImageView.image = nil;
        cardTextView.textColor = [UIColor darkGrayColor];
    }
    
    [self setTextVerticalAlignment];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    cardImageView.image = image;
    if(showFront) {
        card.frontImage = cardImageView.image;
    } else {
        card.backImage = cardImageView.image;
    }
    cardImageView.image = nil;
    [self displayCard:showFront];
    cardImageView.alpha = 0;
    [UIView animateWithDuration:0.35 animations:^{
        cardImageView.alpha = 1;
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    imageButton.selected = NO;
    [self setTextVerticalAlignment];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Settings"])
    {
        NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:appSettings];
    }
}

@end
