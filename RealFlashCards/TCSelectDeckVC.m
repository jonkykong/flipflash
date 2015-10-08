//
//  TCSelectDeckVC.m
//  FlipFlash
//
//  Created by Jon Kent on 3/23/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCSelectDeckVC.h"
#import "TCCardSwipeNC.h"
#import "TCDeckManager.h"
#import "TCAppDelegate.h"

@interface TCSelectDeckVC () <UITextFieldDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) IBOutlet UIView *noDecksView;
@property (nonatomic, strong) NSIndexPath *pathToDelete;
@property (nonatomic,strong) id <UIViewControllerTransitioningDelegate> transitioningDelegateForAlertController;
@property (assign, nonatomic) NSTimeInterval keyboardAnimationDuration;
@end

@implementation TCSelectDeckVC

@synthesize noDecksView;
@synthesize pathToDelete;

static const NSString *kTCDecks = @"decks";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppear:) name:TCNewDeckFromFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFooterView) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self updateFooterView];
}

- (void)newDeckFromFile {
    [self.tableView reloadData];
    [self updateFooterView];
    [[TCDeckManager sharedManager] saveDecks];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if(![self.tableView indexPathForSelectedRow]) {
        return YES;
    }
    
    TCDeck *deck = [TCDeckManager sharedManager].decks[[self.tableView indexPathForSelectedRow].row];
    if(deck.cards.count == 0) {
        [self performSegueWithIdentifier:@"EditDeck" sender:deck];
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if(![segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        return;
    }
    
    UINavigationController *navigationController = (id)segue.destinationViewController;
    
    if([navigationController isKindOfClass:[TCCardSwipeNC class]]) {
        TCCardSwipeNC *cardSwipeNC = (id)navigationController;
        cardSwipeNC.deck = [TCDeckManager sharedManager].decks[[self.tableView indexPathForSelectedRow].row];
        return;
    }

    TCEditDeckVC *editDeckVC = (id)navigationController.topViewController;
    editDeckVC.delegate = self;
    editDeckVC.deck = sender;
    editDeckVC.isNewDeck = YES;
}

- (void)updateFooterView {
    if([TCDeckManager sharedManager].decks.count == 0) {
        CGRect frame = noDecksView.frame;
        frame.size.height = [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationHeight;
        noDecksView.frame = frame;
        [self.tableView setTableFooterView:noDecksView];
        if(self.view.window) {
            noDecksView.alpha = 0;
            [UIView animateWithDuration:0.35 animations:^{
                noDecksView.alpha = 1;
            }];
        }
        [self.tableView setBackgroundView:nil];
    } else {
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

#pragma mark - Navigation

- (IBAction)editTitle:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"New deck title:" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        
        TCDeck *deck = [[TCDeck alloc] init];
        if(textField.text.length == 0) {
            if(deck.title.length == 0) {
                deck.title = @"New Deck";
            }
        } else {
            deck.title = textField.text;
        }
        [self performSegueWithIdentifier:@"EditDeck" sender:deck];
    }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"enter title";
        textField.adjustsFontSizeToFitWidth = NO;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.autocorrectionType = UITextAutocorrectionTypeYes;
        textField.text = @"My Deck";
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
    }];
    self.transitioningDelegateForAlertController = alertController.transitioningDelegate;
    alertController.transitioningDelegate = self;
    [self presentViewController:alertController animated:YES completion:nil];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [TCDeckManager sharedManager].decks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeckCell" forIndexPath:indexPath];
    TCDeck *deck = [TCDeckManager sharedManager].decks[indexPath.row];
    if(deck.cards.count == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (1 card)", deck.title];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%lu cards)", deck.title, (unsigned long)deck.cards.count];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *button1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                       title:@"✎"
                                                                     handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                                                                         TCDeck *deck = [TCDeckManager sharedManager].decks[indexPath.row];
                                                                         [self performSegueWithIdentifier:@"EditDeck" sender:deck];
                                                                     }];
    button1.backgroundColor = self.view.tintColor;
    
    UITableViewRowAction *button2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                       title:@"╳"
                                                                     handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                                                                         pathToDelete = indexPath;
                                                                         TCDeck *deck = [TCDeckManager sharedManager].decks[indexPath.row];
                                                                         
                                                                         UIAlertController *alertController = [UIAlertController alertControllerWithTitle:deck.title message:@"Are you sure you want to delete this deck?" preferredStyle:UIAlertControllerStyleAlert];
                                                                         [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                             self.editing = NO;
                                                                         }]];
                                                                         [alertController addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                             TCDeck *deck = [TCDeckManager sharedManager].decks[pathToDelete.row];
                                                                             [[TCDeckManager sharedManager] removeDeck:deck];
                                                                             [self.tableView deleteRowsAtIndexPaths:@[pathToDelete] withRowAnimation:UITableViewRowAnimationFade];
                                                                             [self updateFooterView];
                                                                             [[TCDeckManager sharedManager] saveDecks];
                                                                         }]];
                                                                         [self presentViewController:alertController animated:YES completion:nil];
                                                                     }];
    return @[button2, button1];
}

#pragma mark - TCEditDeckVCDelegate

- (void)editDeckVC:(TCEditDeckVC *)editDeckVC didFinishWithDeck:(TCDeck *)deck {
    [[TCDeckManager sharedManager] addDeck:deck];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Keyboard notifications

- (void)keyboardWillAppear:(NSNotification *)notification {
    self.keyboardAnimationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source {
    return [self.transitioningDelegateForAlertController animationControllerForPresentedController:presented
                                                                              presentingController:presenting
                                                                                  sourceController:source];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return self.keyboardAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (![destination isBeingPresented]) {
        [self animateDismissal:transitionContext];
    }
}

- (void)animateDismissal:(id <UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [toController beginAppearanceTransition:YES animated:YES];
    [fromController.view endEditing:YES];
    [UIView animateWithDuration:transitionDuration
                     animations:^{
                         fromController.view.superview.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [toController endAppearanceTransition];
                         [transitionContext completeTransition:YES];
                     }];
}

@end
