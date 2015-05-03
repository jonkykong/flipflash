//
//  TCEditDeckVC.m
//  FlipFlash
//
//  Created by Jon Kent on 3/20/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCEditDeckVC.h"
#import "TCEditCardVC.h"
#import "TCCard.h"
#import "TCCardSwipeNC.h"

@interface TCEditDeckVC () <UITextFieldDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UIButton *deckTitleButton;
@property (nonatomic, strong) IBOutlet UIView *noCardsView;
@property (nonatomic, strong) IBOutlet UIView *statsView;
@property (nonatomic, weak) IBOutlet UILabel *deckCompletionsLabel;
@property (nonatomic, assign) BOOL didViewDeck;
@property (nonatomic, strong) NSMutableArray *clipboardLines;
@property (nonatomic, strong) NSString *clipboardLinesSeparator;
@end

@implementation TCEditDeckVC

@synthesize deck;
@synthesize deckTitleButton;
@synthesize noCardsView;
@synthesize didViewDeck;
@synthesize isNewDeck;
@synthesize deckCompletionsLabel;
@synthesize statsView;
@synthesize clipboardLines;
@synthesize clipboardLinesSeparator;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(isNewDeck) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeaderAndFooterView) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self checkClipboard];
    }
    
    [deckTitleButton setTitle:deck.title forState:UIControlStateNormal];
    
    self.navigationController.view.clipsToBounds = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)orientationChanged:(NSNotification *)notification{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(!self.view.window || deck.cards.count == 0) {
        return;
    }
    
    if(UIDeviceOrientationIsLandscape(orientation)) {
        if(!didViewDeck) {
            didViewDeck = YES;
            [self performSegueWithIdentifier:@"ViewDeck" sender:nil];
        }
    }
}

- (void)checkClipboard {
    if(deck.cards.count > 0) return;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *string = pasteboard.string;
    if(string.length > 0) {
        clipboardLines = [[string componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] mutableCopy];
        if(clipboardLines.count > 1) {
            [[[UIAlertView alloc] initWithTitle:@"Auto-Create Cards" message:@"Cards can be created automatically from clipboard text. Each new line of text will go on a new card." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Create!", @"Create on Both Sides...", @"No Thanks", nil] show];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    didViewDeck = NO;
    
    if(deck.cards.count > 0 && isNewDeck) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
    
    [self updateHeaderAndFooterView];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([[segue destinationViewController] isKindOfClass:[TCCardSwipeNC class]]) {
        TCCardSwipeNC *cardSwipeNC = (id)[segue destinationViewController];
        cardSwipeNC.deck = deck;
        cardSwipeNC.preview = YES;
        return;
    }
    
    TCEditCardVC *editCardVC = (id)[segue destinationViewController];
    editCardVC.deck = deck;
    if([self.tableView indexPathForSelectedRow]) {
        editCardVC.card = deck.cards[[self.tableView indexPathForSelectedRow].row];
    }
}

- (void)updateHeaderAndFooterView {
    if(deck.cards.count == 0) {
        [self.tableView setTableHeaderView:nil];
        CGRect frame = noCardsView.frame;
        frame.size.height = [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationHeight;
        noCardsView.frame = frame;
        [self.tableView setTableFooterView:noCardsView];
        if(self.view.window) {
            noCardsView.alpha = 0;
            [UIView animateWithDuration:0.35 animations:^{
                noCardsView.alpha = 1;
            }];
        }
        [self.tableView setBackgroundView:nil];
    } else {
        deckCompletionsLabel.text = [NSString stringWithFormat:@"Deck Completions: %lu", (unsigned long)deck.deckCycles];
        [self.tableView setTableHeaderView:statsView];
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0.5)];
        separator.backgroundColor = self.tableView.separatorColor;
        [self.tableView setTableFooterView:separator];
        UIImageView *boltView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bolt"]];
        boltView.image = [boltView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        boltView.alpha = .1;
        boltView.contentMode = UIViewContentModeCenter;
        [self.tableView setBackgroundView:boltView];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return deck.cards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CardCell" forIndexPath:indexPath];
    
    TCCard *card = deck.cards[indexPath.row];
    
    NSString *frontImage = card.frontImage ? @"(image) " : @"";
    NSString *backImage = card.backImage ? @"(image) " : @"";
    NSString *frontText = card.frontText.length > 0 ? card.frontText : @"";
    NSString *backText = card.backText.length > 0 ? card.backText : @"";
    cell.textLabel.text = [frontImage stringByAppendingString:frontText];
    cell.detailTextLabel.text = [backImage stringByAppendingString:backText];
    
    UILabel *scoreLabel = (id)cell.accessoryView;
    if(!scoreLabel) {
        scoreLabel = [[UILabel alloc] init];
        scoreLabel.font = cell.textLabel.font;
        cell.accessoryView = scoreLabel;
    }
    NSString *numberString = [NSString stringWithFormat:@"%li", (long)[card scoredNet]];
    scoreLabel.text = [card scoredNet] >= 0 ? [@"+" stringByAppendingString:numberString] : numberString;
    scoreLabel.textColor = [card scoredNet] >= 0 ? [UIColor colorWithRed:0 green:0.70 blue:0 alpha:1] : [UIColor redColor];
    [scoreLabel sizeToFit];
    [cell layoutSubviews]; // otherwise detailTextLabel doesn't show
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"╳";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [deck.cards removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self updateHeaderAndFooterView];
    if (deck.cards.count == 0) {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    TCCard *card = deck.cards[sourceIndexPath.row];
    [deck.cards removeObject:card];
    [deck.cards insertObject:card atIndex:destinationIndexPath.row];
}

- (IBAction)close:(id)sender {
    [self.view endEditing:YES];
    [self.delegate editDeckVC:self didFinishWithDeck:deck];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(newText.length == 0) {
        textField.superview.backgroundColor = [UIColor colorWithRed:1 green:0.7 blue:0.7 alpha:1];
        textField.superview.layer.borderColor = [UIColor redColor].CGColor;
    } else {
        textField.superview.backgroundColor = [UIColor whiteColor];
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = @"";
    [self textField:textField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
}

- (IBAction)editTitle:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Change deck title:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"enter title";
    textField.adjustsFontSizeToFitWidth = NO;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField.autocorrectionType = UITextAutocorrectionTypeYes;
    if(deck.title.length == 0) {
        textField.text = @"My Deck";
    } else {
        textField.text = deck.title;
    }
    textField.clearButtonMode = UITextFieldViewModeAlways;
    textField.delegate = self;
    [alertView show];
}

- (IBAction)reset:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Reset Stats" message:@"Are you sure you want to reset your stats for this deck?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
        [deck resetDeckCycles];
        for(TCCard *card in deck.cards) {
            [card resetScores];
        }
        [self updateHeaderAndFooterView];
        [self.tableView reloadData];
        return;
    }
    
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"No"]) {
        return;
    }
    
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Create!"]) {
        clipboardLinesSeparator = [alertView textFieldAtIndex:0].text;
        [self createCardsFromClipboard:clipboardLinesSeparator];
        return;
    }
    
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Create on Both Sides..."]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create on Both Sides" message:@"Enter the text that separates the front of a card from the back:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create!", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [alertView textFieldAtIndex:0];
        textField.placeholder = @"enter separator";
        textField.adjustsFontSizeToFitWidth = NO;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.text = clipboardLinesSeparator.length > 0 ? clipboardLinesSeparator : @"=";
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        [alertView show];
        return;
    }
    
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"No Thanks"]) {
        clipboardLines = nil;
        return;
    }
    
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        return;
    }
    
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        [textField endEditing:YES];
        
        if(textField.text.length == 0) {
            if(deck.title.length == 0) {
                deck.title = @"New Deck";
            }
        } else {
            deck.title = textField.text;
        }
        [deckTitleButton setTitle:deck.title forState:UIControlStateNormal];
    }
}

- (void)createCardsFromClipboard:(NSString *)separator {
    NSMutableArray *newCards = [NSMutableArray arrayWithCapacity:clipboardLines.count];
    if(separator.length > 0) {
        for(NSString *line in clipboardLines) {
            NSArray *equalArray = [line componentsSeparatedByString:separator];
            TCCard *card = nil;
            
            NSMutableArray *equalArrayCopy = [equalArray mutableCopy];
            for(NSString *breakLine in equalArray) {
                if(card.frontText.length > 0) {
                    card.backText = [[equalArrayCopy componentsJoinedByString:separator] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    break;
                }
                
                NSString *cleanedLine = breakLine;
                cleanedLine = [cleanedLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                if(cleanedLine.length > 0) {
                    if(!card) {
                        card = [[TCCard alloc] init];
                    }
                    card.frontText = cleanedLine;
                }
                [equalArrayCopy removeObject:breakLine];
            }
            if(card) {
                [newCards addObject:card];
            }
        }
    } else {
        for(NSString *line in clipboardLines) {
            NSString *cleanedLine = line;
            cleanedLine = [cleanedLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if(cleanedLine.length > 0) {
                TCCard *card = [[TCCard alloc] init];
                card.frontText = cleanedLine;
                [newCards addObject:card];
            }
        }
    }
    deck.cards = newCards;
    clipboardLines = nil;
    [self.tableView beginUpdates];
    for(NSUInteger i = 0; i < deck.cards.count; i++) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
    [self updateHeaderAndFooterView];
    if(deck.cards.count > 0 && isNewDeck) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
}

@end
