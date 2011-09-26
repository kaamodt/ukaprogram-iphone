//
//  EventDetailsViewController.m
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 28.06.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import "EventDetailsViewController.h"
#import "Event.h"
#import "UKEprogramAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "Facebook.h"
#import "FriendsTableViewController.h"
#import "OAuthConsumer.h"
#import "JSON.h"
#import "StartViewController.h"

/*IBOutlet UILabel *PlaceLabel;
 IBOutlet UILabel *DateLabel;
 IBOutlet UILabel *leadLabel;
 IBOutlet UILabel *textLabel;
 IBOutlet UIImage *eventImg;
 */
@implementation EventDetailsViewController
@synthesize headerLabel;
@synthesize footerLabel;
@synthesize leadLabel;
@synthesize textLabel;
@synthesize titleLabel;
@synthesize event;
@synthesize sView;
@synthesize eventImgView;
@synthesize notInUseLabel;
@synthesize attendingButton;
@synthesize friendsButton;
@synthesize loadSpinner;
NSThread* myThread;

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
    [loadSpinner release];
    [super dealloc];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */
- (void)setAttendButton
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if (![delegate isInMyEvents:event.id]) {
        [attendingButton setTitle:@"Delta" forState:UIControlStateNormal];
        [attendingButton setImage:[UIImage imageNamed:@"faceIconunchecked20x20.png"] forState:UIControlStateNormal];
    } else {
        [attendingButton setTitle:@"Ikke delta" forState:UIControlStateNormal];
        [attendingButton setImage:[UIImage imageNamed:@"faceIcon20x20.png"]  forState:UIControlStateNormal];
    }
}

- (void)attendingClicked:(id)sender
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate isReachable]) {
        [delegate flipAttendStatus:event.id];
        [self setAttendButton];
    } else if (!(delegate.lostInternetMessageShown)) {
        [attendingButton setHidden:YES];
        
        NSString *melding = [[NSString alloc] initWithString:@"Det ser ut som du har mistet tilgangen til internett. Man trenger internett for å endre status."];
        [delegate showAlertWithMessage:melding andTitle:@"Ingen nettilgang!"];
        [melding release];
        delegate.lostInternetMessageShown=true;
        
    }
}

- (void)pushFriendsView:(id)sender
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.rootController pushViewController:friendsTableViewController animated:YES];
}


- (void)setLoginButtons
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if (![delegate isReachable]){
        if (!(delegate.lostInternetMessageShown) && delegate.isLoggedIntoFacebook){
            NSString *melding = [[NSString alloc] initWithString:@"Du har mistet tilgangen til internett og derfor tilgang til facebook!"];
            [delegate showAlertWithMessage:melding andTitle:@"Ingen nettilgang!"];
            delegate.lostInternetMessageShown=true;
            delegate.isLoggedIntoFacebook = false;
            [melding release];
        }
    }
    if (friendsTableViewController.listOfFriends == nil) {
        [friendsButton setHidden:YES];
    }
    
    [attendingButton setHidden:YES];
    
    if ([delegate isReachable]) {
        if (![delegate isLoggedIn]) {
            [friendsButton setFrame:CGRectMake(friendsButton.frame.origin.x, friendsButton.frame.origin.y, 250, 37)];
            [friendsButton setTitle:@"Logg inn for å se deltakende venner" forState:UIControlStateNormal];
            [friendsButton addTarget:self action:@selector(fbLoginClicked:) forControlEvents:UIControlEventTouchUpInside];
            [attendingButton setHidden:YES];
            [friendsButton setHidden:NO];
            [friendsButton setEnabled:YES];
            [attendingButton setHidden:YES];
        } else {
            [friendsButton setFrame:CGRectMake(friendsButton.frame.origin.x, friendsButton.frame.origin.y, 167, 37)];
            [friendsButton setHidden:NO];
            if (friendsTableViewController.listOfFriends == nil) {//prevent loading when friends are already loaded
                [self performSelectorInBackground:@selector(friendsTableLoadFriends) withObject:nil];
            }
            [self setAttendButton];
            [friendsButton addTarget:self action:@selector(pushFriendsView:) forControlEvents:UIControlEventTouchUpInside];
            [attendingButton setHidden:NO];
            [attendingButton addTarget:self action:@selector(attendingClicked:) forControlEvents:UIControlEventTouchUpInside];
            
        }
    }
}
//Hjelpemetode for å loade friends uten at alt henger seg
-(void)friendsTableLoadFriends {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [friendsTableViewController loadFriends:self];
    [pool drain];
    
}




// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
/**
 * Sets the text in labels, and the size of the description and lead label
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    //Hide buttons
    [friendsButton setHidden:YES];
    [attendingButton setHidden:YES];
    
    
    
    
    //Put the loadSpinner into the eventImgView
    loadSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadSpinner setCenter:CGPointMake(eventImgView.frame.size.width/2, eventImgView.frame.size.height/2)];
    [eventImgView addSubview:loadSpinner];
    
    //[self setTitle:event.title];
    event.lead = [event.lead stringByReplacingOccurrencesOfString:@"\r\n\r\n" withString:@"###"];
    event.lead = [event.lead stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    event.lead = [event.lead stringByReplacingOccurrencesOfString:@"###" withString:@"\r\n\r\n"];
    
    event.text = [event.text stringByReplacingOccurrencesOfString:@"\r\n\r\n" withString:@"###"];
    event.text = [event.text stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    event.text = [event.text stringByReplacingOccurrencesOfString:@"###" withString:@"\r\n\r\n"];
    
    [leadLabel setText:event.lead];
    [textLabel setText:event.text];
    
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSString *dateString = [[NSString alloc] initWithFormat:@"%@ %@", [delegate.onlyDateFormat stringFromDate:event.showingTime], [delegate.onlyTimeFormat stringFromDate:event.showingTime]]; 
    NSString *labelText = [[NSString alloc] initWithFormat:@"%@  -   %@ %@ ", event.placeString, [delegate getWeekDay:event.showingTime], dateString];
    [dateString release];
    
    [titleLabel setText:event.title];
    [headerLabel setText:labelText];
    headerLabel.backgroundColor = [delegate getColorForEventCategory:event.eventType];
 	headerLabel.textColor = [UIColor darkGrayColor];
    NSString * ageLimit;
    if ([event.ageLimit intValue]!=0){
        ageLimit =  [NSString stringWithFormat:@"Aldersgrense: %@ år", event.ageLimit];
        
    } else {
        ageLimit =  [NSString stringWithFormat:@"Ingen aldersgrense"];
    }
    NSString * pris;
    if (event.lowestPrice!=0){
        pris = [NSString stringWithFormat:@"Pris: %i kr", [event.lowestPrice intValue]];
    } else {
        pris = [NSString stringWithFormat:@"Gratis"];
    }
    NSString *footerText = [ageLimit stringByAppendingString:@"  -  "];
    footerText = [footerText stringByAppendingString:pris];
    footerLabel.lineBreakMode = UILineBreakModeWordWrap; 
    footerLabel.numberOfLines = 0;
 	footerLabel.text = footerText;
 	footerLabel.backgroundColor = [delegate getColorForEventCategory:event.eventType];
 	footerLabel.textColor = [UIColor darkGrayColor];
    
    [labelText release];
    //find the size of lead and description text
    CGSize constraintSize = CGSizeMake(300.0f, MAXFLOAT);
    CGSize labelSize = [event.text sizeWithFont:textLabel.font constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    CGFloat textHeight = labelSize.height;
    labelSize = [event.lead sizeWithFont:leadLabel.font constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    CGFloat leadHeight = labelSize.height;
    //Set the lead and text labels to the size found
    [leadLabel setFrame:CGRectMake(leadLabel.frame.origin.x, leadLabel.frame.origin.y, 305, leadHeight)];
    [textLabel setFrame:CGRectMake(textLabel.frame.origin.x, textLabel.frame.origin.y + leadHeight, 305, textHeight)];
    
    sView = (UIScrollView *) self.view;
    sView.contentSize=CGSizeMake(1, textHeight + leadHeight + leadLabel.frame.origin.y + 50);//1 is less than width of iphone
    [friendsButton setEnabled:NO];
    friendsTableViewController = [[FriendsTableViewController alloc] initWithNibName:@"FriendsTableView" bundle:nil];
    
    
    favButton = [UIButton buttonWithType:UIButtonTypeCustom];
    favButton.frame = CGRectMake(0, 0, 20, 20);
    [favButton addTarget:self action:@selector(favoritesClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([event.favorites intValue] > 0) {
        [favButton setImage:[UIImage imageNamed:@"favorite.png"] forState:UIControlStateNormal];
    }
    else {
        [favButton setImage:[UIImage imageNamed:@"unfavorite.png"] forState:UIControlStateNormal];
    }
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:favButton] autorelease];
    
    
}

- (void)favoritesClicked:(id)sender
{
    NSError *error;
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *con = [delegate managedObjectContext];
    if ([event.favorites intValue] > 0) {
        event.favorites = [NSNumber numberWithInt:0];
        [favButton setImage:[UIImage imageNamed:@"unfavorite.png"] forState:UIControlStateNormal];

    }
    else {
        event.favorites = [NSNumber numberWithInt:1];
        [favButton setImage:[UIImage imageNamed:@"favorite.png"] forState:UIControlStateNormal];
    }
    if (![con save:&error]) {
        NSLog(@"Lagring av %@ feilet", event.title);
    } else {
        NSLog(@"Lagret event %@", event.title);
    }
}
- (void)fbLoginClicked:(id)sender
{
    NSArray *views = self.navigationController.viewControllers;
    StartViewController *stView = (StartViewController *)[views objectAtIndex:0];
    [stView loginFacebook];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //Start spinner
    [loadSpinner startAnimating];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Check if you should load Image
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //Create file manager
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    //Extract the filename
    NSArray *split = [event.image componentsSeparatedByString:@"/"];
    NSString *fileNameWithoutExtention = [split objectAtIndex:[split count] - 1];
    fileNameWithoutExtention = [fileNameWithoutExtention stringByDeletingPathExtension];
    
    //Find all stored images
    NSArray *listOfImages = [fileMgr contentsOfDirectoryAtPath:docDir error:&error];
    NSString *savedImage;
    
    BOOL doWeNeedToDownLoadImage = YES;
    
    for (id file in listOfImages) {
        if ([file isKindOfClass:[NSString class]] && [[file stringByDeletingPathExtension] isEqualToString:fileNameWithoutExtention] ) {
            doWeNeedToDownLoadImage = NO;
            savedImage = [NSString stringWithFormat:@"%@/%@", docDir, file];
            break;
        }
    }
    
    if (doWeNeedToDownLoadImage) {
        UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:event.image]]];
        if (img != nil) {
            eventImgView.image = img;
            NSString *jpegFilePath = [NSString stringWithFormat:@"%@/%@.jpeg",docDir,fileNameWithoutExtention];
            NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(img, 1.0f)];//1.0f = 100% quality
            [data writeToFile:jpegFilePath atomically:YES];
        }
    } else {
        UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfFile:savedImage]];
        if (img != nil) {
            eventImgView.image = img;
        }
    }
    
    
    [self setLoginButtons];
    [loadSpinner stopAnimating];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [friendsTableViewController release];
    [favButton release];
    [event release];
    [loadSpinner release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [sView setNeedsLayout];
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);// || 
            //interfaceOrientation == UIInterfaceOrientationLandscapeRight || 
            //interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            //interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

@end
