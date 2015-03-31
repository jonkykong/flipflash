//
//  ViewController.m
//  testing swiping
//
//  Created by Jon Kent on 5/21/14.
//  Copyright (c) 2014 Jon Kent. All rights reserved.
//


#import "TCCardSwipeVC.h"
#import "TCCardView.h"
#import "TCCard.h"
#import "TCEditDeckVC.h"
#import "TCSelectDeckVC.h"
#import "TCDeckManager.h"

@interface TCCardSwipeVC () <TCCardViewDelegate, TCEditDeckVCDelegate>
@property (nonatomic, strong) IBOutlet UIButton *checkButton;
@property (nonatomic, strong) IBOutlet UIButton *xButton;
@property (nonatomic, strong) IBOutlet UIButton *closeButton;
@property (nonatomic, strong) IBOutlet UIButton *cardRevealButton;
@property (strong,nonatomic) NSMutableArray *cardViewArray;
@property (assign,nonatomic) NSInteger watermark;
@property (weak,nonatomic) IBOutlet UIView *cardTemplateView;
@property (weak,nonatomic) IBOutlet UIButton *moreButton;
@property (weak,nonatomic) IBOutlet UIView *overlayView;
@property (weak,nonatomic) IBOutlet UIView *overlayButtonView;
@property (weak,nonatomic) IBOutlet UIImageView *overlayImageView;
@property (weak,nonatomic) IBOutlet UILabel *deckTitleLabel;
@property (assign,nonatomic) BOOL reloadDeck;

- (IBAction)swipeRight:(id)sender;
- (IBAction)swipeLeft:(id)sender;

@end

@implementation TCCardSwipeVC

@synthesize checkButton;
@synthesize xButton;
@synthesize cardTemplateView;
@synthesize moreButton;
@synthesize closeButton;
@synthesize overlayView;
@synthesize overlayImageView;
@synthesize overlayButtonView;
@synthesize watermark;
@synthesize cardViewArray;
@synthesize deck;
@synthesize deckTitleLabel;
@synthesize preview;
@synthesize cardRevealMode;
@synthesize reloadDeck;
@synthesize cardRevealButton;

static const int MAX_BUFFER_SIZE = 3;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cardTemplateView.hidden = YES;
    overlayView.hidden = YES;
    overlayView.alpha = 0;
    moreButton.hidden = preview;
    
    for(UIButton *button in @[xButton, checkButton]) {
        button.layer.cornerRadius = button.frame.size.height / 2.0;
        button.backgroundColor = [UIColor whiteColor];
        button.layer.borderColor = [UIColor lightGrayColor].CGColor;
        button.layer.borderWidth = 1;
        button.imageView.contentMode = UIViewContentModeCenter;
    }
    
    [closeButton setTitleColor:[UIView appearance].tintColor forState:UIControlStateHighlighted];
    [moreButton setTitleColor:[UIView appearance].tintColor forState:UIControlStateHighlighted];
    
    [self setCardRevealButtonTitle];
    
    deckTitleLabel.text = deck.title;
}

- (void)setupView {
    for(UIView *view in cardViewArray) {
        [view removeFromSuperview];
    }
    cardViewArray = [[NSMutableArray alloc] init];
    watermark = deck.latestCardIndex;
    
    [self loadCards];
    [self straightenTopCard];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(!overlayView.hidden) return;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if(UIInterfaceOrientationIsPortrait(orientation)) {
        self.view.frame = CGRectMake(0, 0, fminf(screenSize.width, screenSize.height), fmaxf(screenSize.width, screenSize.height));
    } else {
        self.view.frame = CGRectMake(0, 0, fmaxf(screenSize.width, screenSize.height), fminf(screenSize.width, screenSize.height));
    }
    [self.view layoutIfNeeded];
    
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // TODO: understand why this must go in viewDidAppear or else cards get improperly transformed.
    for(TCCardView *card in cardViewArray) {
        if(card == cardViewArray.firstObject) continue;
        [self kilterCard:card];
    }
    
    // delete file if it exists from previous send
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"deck.ffd"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)shouldAutorotate {
    return self.overlayView.hidden;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *navigationController = (id)segue.destinationViewController;
    TCEditDeckVC *editDeckVC = (id)navigationController.topViewController;
    editDeckVC.deck = deck;
    editDeckVC.delegate = self;
}

#pragma mark - Deck Management

- (void)editDeckVC:(TCEditDeckVC *)editDeckVC didFinishWithDeck:(TCDeck *)deck {
    [self.deck setLatestCardIndex:0 showFront:YES];
    [[TCDeckManager sharedManager] saveDecks];
    deckTitleLabel.text = self.deck.title;
    [self dismissViewControllerAnimated:YES completion:^{
        reloadDeck = YES;
        [self hideOverlay:editDeckVC];
    }];
}

-(TCCardView *)createCardViewWithDataAtIndex:(NSInteger)index asynchronously:(BOOL)async {
    TCCardView *cardView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TCCardView class]) owner:self options:nil].firstObject;
    cardView.frame = cardTemplateView.frame;
    TCCard *card = [deck.cards objectAtIndex:index];
    if(async) {
        __weak TCCardView *weakCardView = cardView;
        [weakCardView setCardDataAsync:card completion:^{
            if(card.backText.length > 0 || card.backImage) {
                weakCardView.showFront = [self shouldShowFrontForCardRevealMode];
            }
        }];
    } else {
        [cardView setCardData:card];
        if(card.backText.length > 0 || card.backImage) {
            cardView.showFront = [self shouldShowFrontForCardRevealMode];
        }
    }
    cardView.delegate = self;
    return cardView;
}

- (void)loadCards {
    if(deck.cards.count > 0) {
        NSInteger numLoadedCardsCap = MIN(MAX_BUFFER_SIZE, deck.cards.count - deck.latestCardIndex);
        
        for (NSUInteger i = 0; i < numLoadedCardsCap; i++) {
            TCCardView* card = [self createCardViewWithDataAtIndex:i + deck.latestCardIndex asynchronously:i > 0];
            if(i == 0) card.showFront = deck.latestCardShowFront;
            [cardViewArray addObject:card];
            if (cardViewArray.count > 1) {
                [self.view insertSubview:card belowSubview:[cardViewArray objectAtIndex:i-1]];
            } else {
                [self.view addSubview:card];
            }
            if(self.view.window) [self kilterCard:card];
            watermark++;
        }
    }
}

- (BOOL)shouldShowFrontForCardRevealMode {
    switch (cardRevealMode) {
        case TCCardRevealFront: return YES;
        case TCCardRevealBack : return NO;
        case TCCardRevealRandom: return arc4random() % 2;
    }
}

- (void)straightenTopCard {
    TCCardView *card = cardViewArray.firstObject;
    card.userInteractionEnabled = YES;
    [UIView animateWithDuration:0.3 animations:^{
        card.transform = CGAffineTransformIdentity;
    }];
}

- (void)kilterCard:(TCCardView *)card {
//    card.frame = cardTemplateView.frame;
    card.userInteractionEnabled = NO;
    CGFloat kilter = (arc4random() % 101);
    kilter = kilter / 101.0 - 0.5;
    if(!self.view.window)
    {
        card.transform = CGAffineTransformMakeRotation(kilter * 0.1);
        return;
    }
    [UIView animateWithDuration:0.3 animations:^{
        card.transform = CGAffineTransformMakeRotation(kilter * 0.1);
    }];
}

- (void)removeTopCardAndReplenishDeck {
    [cardViewArray removeObjectAtIndex:0];
    
    if(cardViewArray.count == 0) {
        if(!preview) {
            [deck incrementDeckCycles];
            [deck setLatestCardIndex:0 showFront:YES];
            [self performSelector:@selector(more:) withObject:nil afterDelay:0.5];
        } else {
            [self performSelector:@selector(close:) withObject:self afterDelay:0.5];
        }
        return;
    } else {
        if(!preview) {
            TCCardView *card = [cardViewArray objectAtIndex:0];
            [deck setLatestCardIndex:deck.latestCardIndex + 1 showFront:card.showFront];
        }
    }
    
    [self straightenTopCard];
    
    if (watermark < [deck.cards count]) {
        TCCardView *card = [self createCardViewWithDataAtIndex:watermark asynchronously:YES];
        [cardViewArray addObject:card];
        watermark++;
        [self.view insertSubview:card belowSubview:[cardViewArray objectAtIndex:(MAX_BUFFER_SIZE-2)]];
        [self kilterCard:card];
    }
}

//%%% when you hit the right button, this is called and substitutes the swipe
- (IBAction)swipeRight:(id)sender {
    TCCardView *dragView = [cardViewArray firstObject];
//    dragView.overlayView.mode = GGOverlayViewModeRight;
//    [UIView animateWithDuration:0.2 animations:^{
//        dragView.overlayView.alpha = 1;
//    }];
    [dragView rightClickAction];
}

//%%% when you hit the left button, this is called and substitutes the swipe
- (IBAction)swipeLeft:(id)sender {
    TCCardView *dragView = [cardViewArray firstObject];
//    dragView.overlayView.mode = GGOverlayViewModeLeft;
//    [UIView animateWithDuration:0.2 animations:^{
//        dragView.overlayView.alpha = 1;
//    }];
    [dragView leftClickAction];
}

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscape;
//}

#pragma mark - TCCardViewDelegate

- (void)cardSwipedLeft:(UIView *)card {
    TCCard *cardData = deck.cards[deck.latestCardIndex];
    if(!preview) [cardData incrementScoreWrong];
    
    [self removeTopCardAndReplenishDeck];
}

- (void)cardSwipedRight:(UIView *)card {
    TCCard *cardData = deck.cards[deck.latestCardIndex];
    if(!preview) [cardData incrementScoreRight];
    
    [self removeTopCardAndReplenishDeck];
}

- (void)cardFlipped:(BOOL)showFront {
    [deck setLatestCardIndex:deck.latestCardIndex showFront:showFront];
}

#pragma mark - Menu & Navigation

- (IBAction)close:(id)sender {
    [[TCDeckManager sharedManager] saveDecks];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)more:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    UIImage *snapshot = [self takeSnapshotOfView:self.view];
    overlayImageView.image = [self blurWithCoreImage:snapshot];
    
    [self.view bringSubviewToFront:overlayView];
    overlayView.hidden = NO;
    overlayView.alpha = 0;
    
    for(UIView *view in overlayButtonView.subviews) {
        if([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (id)view;
            button.hidden = YES;
            button.backgroundColor = [[UIView appearance].tintColor colorWithAlphaComponent:0.5];
        }
    }
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    NSUInteger index = 0;
    CGFloat delay = 0.1;
    for(UIView *view in overlayButtonView.subviews) {
        if([view isKindOfClass:[UIButton class]]) {
            if(UIInterfaceOrientationIsPortrait(orientation)) {
                [self performSelector:@selector(animateButtonFlipFromBottom:) withObject:view afterDelay:(delay / 2.0) * index];
            } else {
                [self performSelector:@selector(animateButtonFlipFromBottom:) withObject:view afterDelay:delay * (index / 2)];
            }
            index++;
        }
    }
    
    [UIView animateWithDuration:0.35 animations:^{
        overlayView.alpha = 1;
    }];
}

- (void)animateButtonFlipFromBottom:(UIButton *)button {
    [UIView transitionWithView:button duration:0.7
                       options:UIViewAnimationOptionTransitionFlipFromBottom
                    animations:^{
                        button.hidden = NO;
                    } completion:nil];
}

- (IBAction)toggleFaceMode:(id)sender {
    cardRevealMode = (cardRevealMode + 1) % 3;
    [self setCardRevealButtonTitle];
    reloadDeck = YES;
}

- (void)setCardRevealButtonTitle {
    switch(cardRevealMode) {
        case TCCardRevealFront:
            [cardRevealButton setTitle:@"Show Card Front" forState:UIControlStateNormal];
            break;
        case TCCardRevealBack:
            [cardRevealButton setTitle:@"Show Card Back" forState:UIControlStateNormal];
            break;
        case TCCardRevealRandom:
            [cardRevealButton setTitle:@"Show Card Front or Back" forState:UIControlStateNormal];
            break;
    }
}

- (IBAction)restart:(id)sender {
    [deck setLatestCardIndex:0 showFront:YES];
    reloadDeck = YES;
    [self hideOverlay:sender];
}

- (IBAction)restartWithShuffle:(id)sender {
    [deck shuffleCards];
    reloadDeck = YES;
    [self hideOverlay:sender];
}

- (IBAction)restartWithHardCardsFirst:(id)sender {
    [deck sortCardsByDifficulty];
    reloadDeck = YES;
    [self hideOverlay:sender];
}

- (IBAction)hideOverlay:(id)sender {
    if(cardViewArray.count == 0 && !reloadDeck) {
        [self close:sender];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:0.35 animations:^{
        overlayView.alpha = 0;
    } completion:^(BOOL finished) {
        overlayView.hidden = YES;
        if(reloadDeck) {
            reloadDeck = NO;
            NSArray *cardViewArrayCopy = [cardViewArray copy];
            [self setupView];
            for(UIView *view in cardViewArrayCopy) {
                [view removeFromSuperview];
            }
        }
    }];
}

- (IBAction)share:(id)sender {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"deck.ffd"];
    
    TCDeck *deckCopy = [deck copy];
    
    [deckCopy encodeForSending:YES];
    if(![NSKeyedArchiver archiveRootObject:deckCopy toFile:filePath]) return;
    
    unsigned long long size = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil].fileSize;
    NSString *stringSize = size > 1024 * 1024 ? [NSString stringWithFormat:@"%.1f MB", size / (1024.0 * 1024.0)] : [NSString stringWithFormat:@"%.1f KB", size / 1024.0];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"\"%@\" (%@), a deck of cards made with FlipFlash for iPhone. Get the app to view the deck:\n\nhttps://itunes.apple.com/app/id980909860", deck.title, stringSize], [NSURL fileURLWithPath:filePath]]
                                                                            applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePostToFacebook,
                                         UIActivityTypeMessage,
                                         UIActivityTypePostToWeibo,
                                         UIActivityTypePrint,
                                         UIActivityTypeCopyToPasteboard,
                                         UIActivityTypeAssignToContact,
                                         UIActivityTypeSaveToCameraRoll,
                                         UIActivityTypeAddToReadingList,
                                         UIActivityTypePostToFlickr,
                                         UIActivityTypePostToVimeo,
                                         UIActivityTypePostToTencentWeibo];
    [self.navigationController presentViewController:activityVC animated:YES completion:nil];
}

- (UIImage *)takeSnapshotOfView:(UIView *)view {
    UIGraphicsBeginImageContext(CGSizeMake(view.frame.size.width, view.frame.size.height));
    [view drawViewHierarchyInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height) afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)blurWithCoreImage:(UIImage *)sourceImage {
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];
    
    // Apply Affine-Clamp filter to stretch the image so that it does not
    // look shrunken when gaussian blur is applied
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:@"inputImage"];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    // Apply gaussian blur filter
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:clampFilter.outputImage forKey: @"inputImage"];
    [gaussianBlurFilter setValue:@5 forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:gaussianBlurFilter.outputImage fromRect:[inputImage extent]];
    
    // Set up output context.
    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    // Invert image coordinates
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.view.frame.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, self.view.frame, cgImage);
    
    // Apply white tint
//    CGContextSaveGState(outputContext);
//    CGContextSetFillColorWithColor(outputContext, [UIColor colorWithWhite:1 alpha:0.2].CGColor);
//    CGContextFillRect(outputContext, self.view.frame);
//    CGContextRestoreGState(outputContext);
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
