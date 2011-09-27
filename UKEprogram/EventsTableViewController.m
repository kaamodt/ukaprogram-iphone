//
//  EventsTableViewController.m
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 28.06.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import "EventsTableViewController.h"
#import "EventDetailsViewController.h"
#import "UKEprogramAppDelegate.h"
#import "JSON.h"
#import "Event.h"
#import "FilterViewController.h"
#import "FriendsTableViewController.h"

@implementation EventsTableViewController

@synthesize eventDetailsViewController;
@synthesize listOfEvents;
@synthesize filterViewController;
@synthesize eventsTableView;
@synthesize pickerView;
@synthesize categoryChooser, sideSwipeView, sideSwipeCell, animatingSideSwipe, sideSwipeDirection;
UIButton *filterButton;
//int days;
NSMutableArray *sectListOfEvents;
static int secondsInDay = 86400;

static int dateBoxOffset = 125;
static int dateBoxWidth = 70;
static int dateBoxTextWidth =66;
static int dateBoxSeparatorWidth = 2;

static int eTableScrollIndex = 0;
NSDate *lastScrollUpdate;

bool isUsingPicker = NO;


/**
 * Create labels for date-picking horizontal scrollview at top
 */


-(void)createPickerDates
{
    //place background image
    UIImageView *bildeView2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 42)];
    UIImage *backImg = [UIImage imageNamed:@"datePickerBackground.png"];
    [bildeView2 setImage:backImg];
    [bildeView2 setAlpha:0.35];
    [self.view addSubview:bildeView2];
    [bildeView2 release];
    
    
    UKEprogramAppDelegate *del = [[UIApplication sharedApplication] delegate];
    NSDateFormatter *onlyDateFormat = del.onlyDateFormat;
    
    for(UIView *subview in [pickerView subviews]) {
        [subview removeFromSuperview];
    }
    CGRect dateBoxRect = CGRectMake(dateBoxOffset, 2, dateBoxWidth, pickerView.bounds.size.height - 2); // width = 70
    CGRect dateBoxTextRect = CGRectMake(dateBoxSeparatorWidth, 2, dateBoxTextWidth, pickerView.bounds.size.height - 2); // width = 66
    CGRect dateBoxSeparatorRect = CGRectMake(0, 2, dateBoxSeparatorWidth, pickerView.bounds.size.height - 2); //width = 2
    int i;
    for(i = 0; i < sectListOfEvents.count; i++) {
        Event *e = [[[sectListOfEvents objectAtIndex:i] objectForKey:@"Events"] objectAtIndex:0];
        //Init colorlabelLeft (separator)
        UILabel *colorLblLeft = [[[UILabel alloc] initWithFrame:dateBoxSeparatorRect] autorelease];
        colorLblLeft.backgroundColor = [UIColor clearColor];
        //[UIColor colorWithRed:0.490 green:0.647 blue:0.682 alpha:1.0]; iPhone Grå-blå
        //[UIColor colorWithRed:0.6 green:0.113 blue:0.125 alpha:0.5]; UKA-rød
        
        //Init colorlabelRight (separator)
        dateBoxSeparatorRect.origin.x = (dateBoxWidth - dateBoxSeparatorWidth);
        UILabel *colorLblRight = [[[UILabel alloc] initWithFrame:dateBoxSeparatorRect] autorelease];
        colorLblRight.backgroundColor = [UIColor clearColor];
        dateBoxSeparatorRect.origin.x = 0;
        
        //Init dateBox
        UIView *dateBox = [[[UIView alloc] initWithFrame:dateBoxRect] autorelease];
        dateBox.backgroundColor = [UIColor clearColor];
        
        //Add Textlabel
        UILabel *lbl = [[[UILabel alloc] initWithFrame:dateBoxTextRect] autorelease];
        lbl.font = [UIFont systemFontOfSize:13];
        lbl.textColor = [UIColor colorWithRed:0.6 green:0.113 blue:0.125 alpha:1.0];
        lbl.backgroundColor = [UIColor colorWithRed:0.490 green:0.647 blue:0.682 alpha:0.2];
        lbl.textAlignment = UITextAlignmentCenter;
        [lbl setNumberOfLines:2];
        [lbl setText:[NSString stringWithFormat:@"%@\n%@", [del getWeekDay:e.showingTime], [onlyDateFormat stringFromDate:e.showingTime]]];
        
        //First, add colorLblLeft...
        [dateBox addSubview:colorLblLeft];
        //..then add textLbl...
        [dateBox addSubview:lbl];
        //..and  add colorLbRight...
        [dateBox addSubview:colorLblRight];
        
        [pickerView addSubview:dateBox];
        
        //Change the startposition of dateBoxRect before the next box is drawn
        dateBoxRect.origin.x += dateBoxWidth;
    }
    pickerView.contentSize = CGSizeMake(2 * dateBoxOffset + ( i * dateBoxWidth), 1);
    
    [self.view addSubview:pickerView];
    //place transparent image
    UIImageView *bildeView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 42)];
    UIImage *transImg = [UIImage imageNamed:@"datePickerTransparentLayer.png"];
    [bildeView setImage:transImg];
    bildeView.alpha = 0.6;
    [self.view addSubview:bildeView];
    [bildeView release];
    
}

/**
 * Called to show list of events
 */
-(void)updateTable {
    //sort by starting date
    
    [sectListOfEvents release];
    sectListOfEvents = [[NSMutableArray alloc] init];
    if ([listOfEvents count] > 0) {
        
        
        
        //Find first date (with time set to 00:00:00)
        Event *e = (Event *)[listOfEvents objectAtIndex:0];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *comp = [gregorian components: (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: e.showingTime];
        NSDate *firstDate = [gregorian dateFromComponents:comp];
        
        //add events to sections based on time since firstdate
        NSNumber *lastDay = 0;
        NSMutableArray *events = [[NSMutableArray alloc] init];
        for (int i = 0; i < [listOfEvents count]; i++) {
            e = (Event *)[listOfEvents objectAtIndex:i];
            if ((int)[e.showingTime timeIntervalSinceDate:firstDate]/secondsInDay != [lastDay intValue]) {
                NSDictionary *dict = [NSDictionary dictionaryWithObject:events forKey:@"Events"];
                [sectListOfEvents addObject:dict];
                [events release];
                events = [[NSMutableArray alloc] init];
            }
            lastDay = [NSNumber numberWithInt:[e.showingTime timeIntervalSinceDate:firstDate]/secondsInDay];
            [events addObject:e];
        }
        [sectListOfEvents addObject:[NSDictionary dictionaryWithObject:events forKey:@"Events"]];
        [events release];
        [gregorian release];
        //[sectListOfEvents release];
    }
    [self createPickerDates];
    
    [eventsTableView reloadData];
    
    
}



-(void)showEventsWithPredicate:(NSPredicate *)predicate
{
    NSError *error;
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *con = [delegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"showingTime" ascending:YES];
    //NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    //[request setSortDescriptors:sortDescriptors];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:con];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    //[self setListOfEvents:[[con executeFetchRequest:request error:&error] mutableCopy]];
    self.listOfEvents = [[[con executeFetchRequest:request error:&error] mutableCopy] autorelease];
    [request release];
    [self updateTable];
}

/**
 *   Fetches all the events in the object context and displays them
 */
-(void)showAllEvents{
    self.navigationItem.rightBarButtonItem = categoryChooser;
    [self showEventsWithPredicate:Nil];
    //[filterButton setTitle:@"Alle" forState:UIControlStateNormal];
}
-(void)showFavoriteEventsFromFilterView:(BOOL) value{
    if (!value) {
        self.navigationItem.rightBarButtonItem=nil;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"favorites == %i", 1];
    [self showEventsWithPredicate:predicate];
    
    //[filterButton setTitle:@"Favoritt" forState:UIControlStateNormal];
}
-(void)showKonsertEvents
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventType == %@", @"Konsert"];
    [self showEventsWithPredicate:predicate];
    //[filterButton setTitle:@"Konsert" forState:UIControlStateNormal];
}
-(void)showRevyEvents
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventType == %@", @"Revy og teater"];
    [self showEventsWithPredicate:predicate];
    //[filterButton setTitle:@"Favoritt" forState:UIControlStateNormal];
}
-(void)showKursEvents
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventType == %@", @"Kurs og events"];
    [self showEventsWithPredicate:predicate];
    //[filterButton setTitle:@"Favoritt" forState:UIControlStateNormal];
}
-(void)showFestEvents
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventType == %@", @"Fest og moro"];
    [self showEventsWithPredicate:predicate];
    //[filterButton setTitle:@"Favoritt" forState:UIControlStateNormal];
}

-(void) scrollToDate:(NSDate *)date animated: (BOOL)animated
{
    Event *e;
    NSIndexPath *scrollPath;
    BOOL found = NO;
    for (int i = 0; i < [sectListOfEvents count]; i++) {
        for (int j = 0; j < [[[sectListOfEvents objectAtIndex:i] objectForKey:@"Events"] count]; j++) {
            e = (Event *) [[[sectListOfEvents objectAtIndex:i] objectForKey:@"Events"] objectAtIndex:j];
            if (((long)[e.showingTime  timeIntervalSinceDate:date]) > 0 && !found) {
                scrollPath = [NSIndexPath indexPathForRow:j inSection:i];
                found = YES;
                
            }
        }
    }
    if (found) {
        [eventsTableView scrollToRowAtIndexPath:scrollPath atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

/*
 - (id)initWithStyle:(UITableViewStyle)style
 {
 self = [super initWithStyle:style];
 if (self) {
 // Custom initialization
 }
 return self;
 }*/

- (void)dealloc
{
    [filterViewController release];
    [categoryChooser release];
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    animatingSideSwipe = NO;
    lastScrollUpdate = [NSDate date];
    [lastScrollUpdate retain];
    [eventsTableView setDelegate:self];
    [eventsTableView setDataSource:self];
    [pickerView setDelegate:self];
    listOfEvents = [[NSMutableArray alloc] init];
    self.navigationItem.title = @"Program";
    categoryChooser = [[UIBarButtonItem alloc] initWithTitle:@"Kategori" 
                                                       style:UIBarButtonItemStylePlain
                                                      target:self 
                                                      action:@selector(comboClicked:)];
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    gesture.direction = UISwipeGestureRecognizerDirectionRight;
    UISwipeGestureRecognizer *removeMenyGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(removeMenySwipe:)];
    removeMenyGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [eventsTableView addGestureRecognizer:gesture];
    [eventsTableView addGestureRecognizer:removeMenyGesture];
    [gesture release];
    [removeMenyGesture release];
    
    
    
    
    
    UILabel * lblTemp = [[UILabel alloc] initWithFrame:CGRectMake(75, 32, 50, 13)];
    lblTemp.tag = 1;
    lblTemp.font = [UIFont boldSystemFontOfSize:12];
    lblTemp.textColor = [UIColor colorWithRed:0.6 green:0.113 blue:0.125 alpha:0.7];
    lblTemp.text = @"Favoritt";
    lblTemp.textAlignment = UITextAlignmentCenter;
    [sideSwipeView addSubview:lblTemp];
    [lblTemp release];
    
    UIButton *favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    favoriteButton.frame = CGRectMake(85, 2, 50-20, 50-20);
    favoriteButton.tag = 3;
    [favoriteButton addTarget:self action:@selector(favoritesClicked:event:) forControlEvents:UIControlEventTouchUpInside];
    favoriteButton.backgroundColor = [UIColor clearColor];
    [sideSwipeView addSubview:favoriteButton];
    //Initialize attending label
    lblTemp = [[UILabel alloc] initWithFrame:CGRectMake(175, 32, 50, 13)];
    lblTemp.tag = 2;
    lblTemp.font = [UIFont boldSystemFontOfSize:12];
    lblTemp.textColor = [UIColor colorWithRed:0.6 green:0.113 blue:0.125 alpha:0.7];
    lblTemp.text = @"Delta";
    lblTemp.textAlignment = UITextAlignmentCenter;
    [sideSwipeView addSubview:lblTemp];
    [lblTemp release];
    UIButton *attendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    attendButton.frame = CGRectMake(185, 2, 50-20, 50-20);
    attendButton.backgroundColor = [UIColor clearColor];
    attendButton.tag = 4;
    [attendButton addTarget:self action:@selector(attendClicked:event:) forControlEvents:UIControlEventTouchUpInside];
    [attendButton setHidden:YES];
    [attendButton setEnabled:NO];
    [sideSwipeView addSubview:attendButton];
    
    
}

#define BOUNCE_PIXELS 5.0

- (void) removeSideSwipeView:(BOOL)animated
{
    if (!sideSwipeCell || animatingSideSwipe) return;
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        animatingSideSwipe = YES;
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStopOne:finished:context:)];
        [UIView commitAnimations];
    }
    else
    {
        [sideSwipeView removeFromSuperview];
        sideSwipeCell.frame = CGRectMake(0,sideSwipeCell.frame.origin.y,sideSwipeCell.frame.size.width, sideSwipeCell.frame.size.height);
        self.sideSwipeCell = nil;
    }
}

-(void)removeMenySwipe:(UIGestureRecognizer *)gestureRecognizer  {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint swipeLocation = [gestureRecognizer locationInView:self.eventsTableView];
        NSIndexPath *swipedIndexPath = [self.eventsTableView indexPathForRowAtPoint:swipeLocation];
        UITableViewCell* swipedCell = [self.eventsTableView cellForRowAtIndexPath:swipedIndexPath];
        if (swipedCell.frame.origin.x != 0)
        {
            [self removeSideSwipeView:YES];
            return;
        }
    }
}

- (void)animationDidStopOne:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS*2, sideSwipeCell.frame.origin.y, sideSwipeCell.frame.size.width, sideSwipeCell.frame.size.height);
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopTwo:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

// The final step in a bounce animation is to move the side swipe completely offscreen
- (void)animationDidStopTwo:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    sideSwipeCell.frame = CGRectMake(0, sideSwipeCell.frame.origin.y, sideSwipeCell.frame.size.width, sideSwipeCell.frame.size.height);
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopThree:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}


- (void)animationDidStopThree:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    animatingSideSwipe = NO;
    self.sideSwipeCell = nil;
    [sideSwipeView removeFromSuperview];
}

-(void)setMenyButtonsWithIndexPath:(NSIndexPath*)indexPath{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    Event *e = (Event *) [[[sectListOfEvents objectAtIndex:indexPath.section] objectForKey:@"Events"] objectAtIndex:indexPath.row];
    UIButton * favoriteButton = (UIButton *) [sideSwipeView viewWithTag:3];
    UIButton * attendButton = (UIButton *) [sideSwipeView viewWithTag:4];
    UILabel * attendLabel = (UILabel *) [sideSwipeView viewWithTag:2];
    if ([e.favorites intValue] > 0) {
        [favoriteButton setImage:[UIImage imageNamed:@"favorite.png"] forState:UIControlStateNormal];
    }
    else {
        [favoriteButton setImage:[UIImage imageNamed:@"unfavorite.png"] forState:UIControlStateNormal];
    }
    if ([delegate isLoggedIn]  && [delegate isReachable]) {
        [attendButton setHidden:NO];
        [attendButton setEnabled:YES];
        [attendLabel setHidden:NO];
        if ([delegate isInMyEvents:e.id]){
            [attendButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];  
        } else {
            [attendButton setImage:[UIImage imageNamed:@"facebookunchecked.png"] forState:UIControlStateNormal];
        }
    } else {
        [attendButton setImage:nil forState:UIControlStateNormal];
        [attendButton setHidden:YES];
        [attendLabel setHidden:YES];
        [attendButton setEnabled:NO];
    }
}


- (void) addSwipeViewTo:(UITableViewCell*)cell
{
    sideSwipeView.frame =  cell.frame;
    [self setMenyButtonsWithIndexPath:[eventsTableView indexPathForCell:cell]];  
    [eventsTableView insertSubview:sideSwipeView belowSubview:cell];
    self.sideSwipeCell = cell;
    CGRect cellFrame = cell.frame;
    sideSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    animatingSideSwipe = YES;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopAddingSwipeView:finished:context:)];
    cell.frame = CGRectMake(cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    [UIView commitAnimations];
}


-(void)didSwipe:(UIGestureRecognizer *)gestureRecognizer  {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint swipeLocation = [gestureRecognizer locationInView:self.eventsTableView];
        NSIndexPath *swipedIndexPath = [self.eventsTableView indexPathForRowAtPoint:swipeLocation];
        UITableViewCell* swipedCell = [self.eventsTableView cellForRowAtIndexPath:swipedIndexPath];
        if (swipedCell.frame.origin.x != 0)
        {
            return;
        }
        if (swipedCell!= sideSwipeCell && !animatingSideSwipe)
            [self removeSideSwipeView:NO];
            [self addSwipeViewTo:swipedCell];
    }
}

- (NSIndexPath *)tableView:(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeSideSwipeView:YES];
    return indexPath;
}

// UIScrollViewDelegate
// When the table is scrolled, animate the removal of the side swipe view
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == pickerView) {
        isUsingPicker = YES;
        //NSLog(@"Started picker");
    } else {
        isUsingPicker = NO;
        //NSLog(@"Stopped using picker");
    }
    
    [self removeSideSwipeView:YES];
}

// When the table is scrolled to the top, remove the side swipe view
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [self removeSideSwipeView:NO];
    return YES;
}



// Note that the animation is done
- (void)animationDidStopAddingSwipeView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    animatingSideSwipe = NO;
}



- (void)viewDidUnload
{
    [eventDetailsViewController release];
    [listOfEvents release];
    [filterViewController release];
    [filterButton release];
    [sectListOfEvents release];
    [lastScrollUpdate release];
    [sideSwipeView release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (CGPoint) makeGoodPickerPosition
{
    CGPoint topLeft = [eventsTableView contentOffset];
    topLeft.x = 160;
    topLeft.y = topLeft.y + 310;
    return topLeft;
}

- (void)comboClicked:(id)sender
{
    //[filterViewController release];
    self.filterViewController = [[[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil] autorelease];
    [self.filterViewController setEventsTableViewController:self];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.rootController presentModalViewController:filterViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    BOOL isReachable = [delegate isReachable];
    if (!isReachable && delegate.isLoggedIntoFacebook && !delegate.lostInternetMessageShown) {
        NSString * melding = [[NSString alloc] initWithString:@"Du har mistet tilgangen til internett og derfor tilgang til facebook."];
        [delegate showAlertWithMessage:melding andTitle:@"Ingen nettilgang!"];
        delegate.lostInternetMessageShown = true;
        delegate.isLoggedIntoFacebook = false;
        [melding release];
    }
    [eventsTableView reloadData];
    [self snapToPosition:pickerView];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
    
    //[filterButton setHidden:NO];
    //[datePickButton setHidden:NO];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //[filterButton setHidden:YES];
    //[datePickButton setHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)favoritesClicked:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:eventsTableView];
    NSIndexPath *indexPath = [eventsTableView indexPathForRowAtPoint:currentTouchPosition];
    
    if (indexPath != nil) {
        NSError *error;
        UITableViewCell * cell = [eventsTableView cellForRowAtIndexPath:indexPath];
        UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *con = [delegate managedObjectContext];
        Event *e = (Event *)[[[sectListOfEvents objectAtIndex:indexPath.section] objectForKey:@"Events"] objectAtIndex:indexPath.row];
        UIButton *button = (UIButton *)[sideSwipeView viewWithTag:3];
        UIImageView * favoriteView = (UIImageView *) [cell viewWithTag:3];
        if ([e.favorites intValue] > 0) {
            e.favorites = [NSNumber numberWithInt:0];
            [button setImage:[UIImage imageNamed:@"unfavorite.png"] forState:UIControlStateNormal];
            [favoriteView setImage:nil];
        }
        else {
            e.favorites = [NSNumber numberWithInt:1];
            [button setImage:[UIImage imageNamed:@"favorite.png"] forState:UIControlStateNormal];
            [favoriteView setImage:[UIImage imageNamed:@"favorite.png"]];
        }
        if (![con save:&error]) {
            //NSLog(@"Lagring av %@ feilet", e.title);
        } else {
            //NSLog(@"Lagret event %@", e.title);
        }
    }
}

-(void) attendClicked:(id)sender event:(id)event{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:eventsTableView];
    NSIndexPath *indexPath = [eventsTableView indexPathForRowAtPoint:currentTouchPosition];
    UIButton *button = (UIButton *)[sideSwipeView viewWithTag:4];
    UILabel * attendLabel =(UILabel *) [sideSwipeView viewWithTag:2];
        if ([delegate isReachable]) {
            
            
            if (indexPath != nil) {
                UITableViewCell * cell = [eventsTableView cellForRowAtIndexPath:indexPath];
                NSError *error;
                UIImageView * attendView = (UIImageView *) [cell viewWithTag:4];
                NSManagedObjectContext *con = [delegate managedObjectContext];
                
                NSNumber *eventID = [[[[sectListOfEvents objectAtIndex:indexPath.section] objectForKey:@"Events"] objectAtIndex:indexPath.row] id];
                
                [delegate flipAttendStatus:eventID];
                if ([delegate isInMyEvents:eventID]){
                    [button setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
                    [attendView setImage:[UIImage imageNamed:@"facebook.png"]];
                } else {
                    [button setImage:[UIImage imageNamed:@"facebookunchecked.png"] forState:UIControlStateNormal];
                    [attendView setImage:nil];
                }
                if (![con save:&error]) {
                    //NSLog(@"Lagring av %@ feilet", e.title);
                } else {
                    //NSLog(@"Lagret event %@", e.title);
                }
            }
        } else {
            NSString *melding = [[NSString alloc] initWithString:@"Du har mistet tilgangen til internett og derfor tilgang til facebook."];
            [delegate showAlertWithMessage:melding andTitle:@"Ingen nettilgang!"];
            [melding release];
            delegate.lostInternetMessageShown=true;
            delegate.isLoggedIntoFacebook = false;
            [button setHidden:YES];
            [button setEnabled:NO];
            [attendLabel setHidden:YES];
            [self updateTable];
        }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [sectListOfEvents count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *dict = [sectListOfEvents objectAtIndex:section];
    return [[dict objectForKey:@"Events"] count];
}

#define CELL_ROW_HEIGHT 50

/**
 *  returns a view for displaying each event in the table
 */
- (UITableViewCell *) getCellContentView:(NSString *)cellIdentifier 
{
    
    UILabel *lblTemp;
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 300, CELL_ROW_HEIGHT) reuseIdentifier:cellIdentifier] autorelease];
    //Initialize Label with tag 1.
    lblTemp = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 280, 20)];
    lblTemp.tag = 1;
    //lblTemp.font = [UIFont systemFontOfSize:14];
    [cell.contentView addSubview:lblTemp];
    [lblTemp release];
    //Initialize Label with tag 2.
    lblTemp = [[UILabel alloc] initWithFrame:CGRectMake(12, 27, 187, 13)];
    lblTemp.tag = 2;
    lblTemp.font = [UIFont boldSystemFontOfSize:12];
    lblTemp.textColor = [UIColor colorWithRed:0.6 green:0.113 blue:0.125 alpha:0.7];
    [cell.contentView addSubview:lblTemp];
    [lblTemp release];
    //Initialize favorite view
    UIImageView * favoritView = [[UIImageView alloc] initWithFrame:CGRectMake(190, 27, 13, 13)];
    favoritView.tag = 3;
    favoritView.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:favoritView];
    [favoritView release];
    //Initialize attend view
    UIImageView * attendView =[[UIImageView alloc] initWithFrame:CGRectMake(205, 27, 13, 13)];
    attendView.tag = 4;
    attendView.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:attendView];
    [attendView release];
    //Initialize color code
    lblTemp = [[UILabel alloc] initWithFrame:CGRectMake(0 , 0, 6, CELL_ROW_HEIGHT-6)];//vet ikke hvorfor, men cell row height er ikke cell row height. Derfor minus 6 for å få fargekoden til å passe
    lblTemp.tag = 5;
    lblTemp.backgroundColor = [UIColor lightGrayColor];
    [cell.contentView addSubview:lblTemp];
    [lblTemp release];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIImageView *containerView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 21)] autorelease];
    UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 200, 21)] autorelease];
    //UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    UIImage *backImg = [UIImage imageNamed:@"tableRowHeader.png"];
    if (backImg == nil) {
        //NSLog(@"Cant find image!");
    }
    [containerView setImage:backImg];
    
    headerLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.shadowColor = [UIColor blackColor];
    headerLabel.shadowOffset = CGSizeMake(0, 1);
    headerLabel.font = [UIFont boldSystemFontOfSize:16];
    headerLabel.backgroundColor = [UIColor clearColor];
    
    [containerView addSubview:headerLabel];
    
    return containerView;
}


/**
 *  Displays events in the table
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [self getCellContentView:CellIdentifier];
    }
    [cell setSelected:NO];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    Event *e = (Event *) [[[sectListOfEvents objectAtIndex:indexPath.section] objectForKey:@"Events"] objectAtIndex:indexPath.row];
    
    // Configure the cell...
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:2];
    UIImageView * favoriteView = (UIImageView *) [cell viewWithTag:3];
    UIImageView * attendView = (UIImageView *) [cell viewWithTag:4];
    UILabel *colorCodeLabel = (UILabel *)[cell viewWithTag:5];
    colorCodeLabel.backgroundColor = [delegate getColorForEventCategory:e.eventType];
    
    
    dateLabel.text = [NSString stringWithFormat:@"%@ - kl.%@", e.placeString, [delegate.onlyTimeFormat stringFromDate:e.showingTime]];
    titleLabel.text = e.title;
    
    
    if ([e.favorites intValue] > 0) {
        [favoriteView setImage:[UIImage imageNamed:@"favorite.png"]];
    }
    else {
        [favoriteView setImage:nil];
    }
    if ([delegate isLoggedIn]  && [delegate isReachable]) {
        [attendView setHidden:NO];
        if ([delegate isInMyEvents:e.id]){
            [attendView setImage:[UIImage imageNamed:@"facebook.png"]];  
        } else {
            [attendView setImage:nil];
        }
    } else {
        [attendView setImage:nil];
        [attendView setHidden:YES];
    }
    
    
    return cell;
}
/*
 * Sets header to section remove if sections isnt used
 */
- (NSString *)tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section {
    Event *e = (Event *) [[[sectListOfEvents objectAtIndex:section] objectForKey:@"Events"] objectAtIndex:0];
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSString *s = [delegate.weekDays objectAtIndex:[[delegate.weekDayFormat stringFromDate:e.showingTime] intValue]];
    return [NSString stringWithFormat:@"%@ %@", s, [delegate.onlyDateFormat stringFromDate:e.showingTime]];
    
}

#pragma mark - Table view delegate
/**
 *  Creates a new detailed view of an event
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        eventDetailsViewController = [[EventDetailsViewController alloc] initWithNibName:@"EventDetailsView" bundle:nil];
        eventDetailsViewController.event = (Event *) [[[sectListOfEvents objectAtIndex:indexPath.section] objectForKey:@"Events"] objectAtIndex:indexPath.row];
        [delegate.rootController pushViewController:eventDetailsViewController animated:YES];
}



-(void)snapToPosition:(UIScrollView *)sView
{
    if (sView == pickerView){
        int pos = ((sView.contentOffset.x + dateBoxWidth/2) * [sectListOfEvents count]) / (sView.contentSize.width - dateBoxOffset * 2);
        pos = MAX(0, pos);
        pos = MIN([sectListOfEvents count]-1, pos);
        [pickerView setContentOffset:CGPointMake((pos * dateBoxWidth), 0) animated:YES];
    } else if (sView == eventsTableView) {
        NSIndexPath *path = [eventsTableView indexPathForRowAtPoint:CGPointMake(10, sView.contentOffset.y + 22)];
        if (path) {
            eTableScrollIndex = [[NSNumber numberWithUnsignedInteger:[path section]] intValue];
            [pickerView setContentOffset:CGPointMake((eTableScrollIndex * dateBoxWidth), 0) animated:YES];
        } 
    }
}

/**
 * Catches both datepick- and tableview-scrollevents
 */
- (void)scrollViewDidScroll:(UIScrollView *)sView
{
    NSTimeInterval timePassed_ms = [lastScrollUpdate timeIntervalSinceNow] * -1000.0;
    if (timePassed_ms > 300) {
        [lastScrollUpdate release];
        lastScrollUpdate = [NSDate date];
        [lastScrollUpdate retain];
        if (isUsingPicker && sView == pickerView) {
            int pos = ((sView.contentOffset.x + dateBoxWidth/2) * [sectListOfEvents count]) / (sView.contentSize.width - dateBoxOffset * 2);//finds the section
            pos = MAX(0, pos);
            pos = MIN([sectListOfEvents count]-1, pos);
            NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:pos];
            [eventsTableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if (!isUsingPicker && sView == eventsTableView) {
            [self snapToPosition:sView];
        }
    }
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self snapToPosition:scrollView];
    }
}
-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self snapToPosition:scrollView];
}

/**
 * Sets what view user is scrolling in
 */

@end
