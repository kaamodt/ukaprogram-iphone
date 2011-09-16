//
//  StartViewController.m
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 18.07.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import "StartViewController.h"
#import "UKEprogramAppDelegate.h"
#import "EventsTableViewController.h"
#import "Facebook.h"
#import "SettingsViewController.h"
#import "EventDetailsViewController.h"
#import "Reachability.h"


@implementation StartViewController

@synthesize allButton;
@synthesize artistButton;
@synthesize favoritesButton;
@synthesize eventsTableViewController;
@synthesize settingsViewController;
@synthesize fbLoginButton;
@synthesize settingsButton;
@synthesize activityView;
@synthesize activityLabel;

//UIImageView *titleImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [self.eventsTableViewController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
-(void)settingsClicked:(id)sender
{
    [settingsViewController release];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
    [delegate.rootController pushViewController:settingsViewController animated:YES];
    
}

-(void)facebookLogin:(id)sender
{
    [self loginFacebook];
}
-(void)loginFacebook
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate isReachable]){
        Facebook *facebook = delegate.facebook;
        [facebook authorize:nil delegate:self];
    } else  {
        NSString *melding = [[NSString alloc] initWithString:@"Ingen internett tilgang. Man trenger internett for å koble på facebook"];
        [delegate showAlertWithMessage:melding andTitle:@"Ingen nettilgang!"];
        [melding release];
        delegate.lostInternetMessageShown=true;
    }
}

-(void)facebookLogout:(id)sender
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.facebook logout:self];
}

-(void)stopActivityIndication:(NSNotification *)notification

{
 	
    [activityView stopAnimating];
 	
    [activityView setHidden:YES];
 	
    [activityLabel setHidden:YES];
    
}

-(void)startActivityIndication:(NSNotification *)notification

{
    
    [activityView startAnimating];
    
    [activityView setHidden:NO];
    
    [activityLabel setHidden:NO];
    
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

-(void)facebookSessionIsValid {
    [fbLoginButton removeTarget:self action:@selector(facebookLogin:) forControlEvents:UIControlEventTouchUpInside];
    [fbLoginButton addTarget:self action:@selector(facebookLogout:) forControlEvents:(UIControlEvents)UIControlEventTouchUpInside];
    [fbLoginButton setTitle:@"Logg ut" forState:UIControlStateNormal];
    [settingsButton setHidden:NO];
}

-(void)facebookSessionIsNotValid {
    [fbLoginButton removeTarget:self action:@selector(facebookLogout:) forControlEvents:UIControlEventTouchUpInside];
    [fbLoginButton addTarget:self action:@selector(facebookLogin:) forControlEvents:(UIControlEvents)UIControlEventTouchUpInside];
    [fbLoginButton setTitle:@"Logg på" forState:UIControlStateNormal];
    [settingsButton setHidden:YES];
}


- (void)setLoggedIn:(bool)sessionValid {
    if (!sessionValid) {
        [self facebookSessionIsNotValid];
    } else {
        [self facebookSessionIsValid];
        UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate loginBackend];
    }
}


-(void)allEventsClicked:(id)sender {
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    //self.eventsTableViewController = [[EventsTableViewController alloc] initWithNibName:@"EventsTableView" bundle:nil];
    [delegate.rootController pushViewController:eventsTableViewController animated:YES];
    [eventsTableViewController showAllEvents];
    NSDate *now = [[NSDate alloc] init];
    [eventsTableViewController scrollToDate:now animated:YES];
    [now release];
}
-(void)favoriteEventsClicked:(id)sender {
    //self.eventsTableViewController = [[EventsTableViewController alloc] initWithNibName:@"EventsTableView" bundle:nil];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.rootController pushViewController:eventsTableViewController animated:YES];
    [eventsTableViewController showFavoriteEventsFromFilterView:NO];
    NSDate *now = [[NSDate alloc] init];
    [eventsTableViewController scrollToDate:now animated:YES];
    [now release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    //NSLog(@"Loading startupView");
    
    [super viewDidLoad];
    [allButton addTarget:self action:@selector(allEventsClicked:) forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [favoritesButton addTarget:self action:@selector(favoriteEventsClicked:) forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    self.navigationItem.title = @"Hjem";
    
    
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    BOOL facebookSessionValid = [delegate.facebook isSessionValid];
    if (facebookSessionValid) {
        delegate.isLoggedIntoFacebook=true;
    } else {
        delegate.isLoggedIntoFacebook=false;
    }
    [self setLoggedIn: facebookSessionValid];
    [settingsButton addTarget:self action:@selector(settingsClicked:) forControlEvents:UIControlEventTouchDown];
    [activityView startAnimating];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopActivityIndication:) name:@"stopActivityIndication" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startActivityIndication:) name:@"startActivityIndication" object:nil];
    self.eventsTableViewController = [[EventsTableViewController alloc] initWithNibName:@"EventsTableView" bundle:nil];
}




- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [settingsViewController release];
    [eventsTableViewController release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [[delegate rootController] setNavigationBarHidden:YES];
    if(![delegate isReachable]) {
        [self stopActivityIndication:nil];
        if (![settingsButton isHidden]){
            [self setLoggedIn:NO];
            if (!(delegate.lostInternetMessageShown)){
                NSString *melding = [[NSString alloc] initWithString:@"Du har mistet internettilgangen og ble derfor tilgangen til facebook"];
                [delegate showAlertWithMessage:melding andTitle:@"Ingen nettilgang!"];
                delegate.lostInternetMessageShown=true;
                [melding release];
            }
        }
    } else{
        if ([delegate.facebook isSessionValid]){
            [self facebookSessionIsValid];
            delegate.isLoggedIntoFacebook=true;
        } else {
            [self facebookSessionIsNotValid];
            delegate.isLoggedIntoFacebook=false;
        }
    }
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [[delegate rootController] setNavigationBarHidden:NO];
}
- (void) notifyViews 
{
    //NSLog(@"blabla %i", [self.navigationController.viewControllers count]);
    if ([self.navigationController.viewControllers count] > 2) {
        EventsTableViewController *etView = (EventsTableViewController *)[self.navigationController.viewControllers objectAtIndex:1];
        EventDetailsViewController *edView = (EventDetailsViewController *)[self.navigationController.viewControllers objectAtIndex:2];
        [etView setLoginButtons];
        [edView setLoginButtons];
    }
}

- (void) fbDidLogin {
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[delegate.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[delegate.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    [self setLoggedIn: [delegate.facebook isSessionValid]];
    delegate.isLoggedIntoFacebook=true;
    [self notifyViews];
}

-(void)fbDidLogout {
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[delegate.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults synchronize];
    [self setLoggedIn: [delegate.facebook isSessionValid]];
    delegate.isLoggedIntoFacebook=false;
    [self notifyViews];
}
-(void)fbDidNotLogin:(BOOL)cancelled {
    
}

@end
