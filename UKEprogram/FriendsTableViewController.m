//
//  FriendsTableViewController.m
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 21.07.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import "FriendsTableViewController.h"
#import "Event.h"
#import "UKEprogramAppDelegate.h"
#import "EventDetailsViewController.h"
#import "JSON.h"
#import "OAuthConsumer.h"

@implementation FriendsTableViewController

@synthesize listOfFriends;
@synthesize friendsTableView;


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
    [listOfFriends dealloc];
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

    

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [friendsTableView setDelegate:self];
}


- (void)viewDidUnload
{
    [listOfFriends release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) requestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    [eventDetailsViewController.friendsButton setHidden:YES];
    [eventDetailsViewController release];
}

- (void) requestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    NSString *responseString = [[NSString alloc] initWithData:data  encoding:NSASCIIStringEncoding];
    NSArray *users = [responseString JSONValue];
    [responseString release];
    listOfFriends = [[NSMutableArray alloc] initWithCapacity:[users count]];
    for (int i = 0; i < [users count]; i++) {
            NSDictionary *user = [users objectAtIndex:i];
            NSString *name = [user objectForKey:@"fullName"];
            [listOfFriends addObject:name];
        }
    NSString * friend = @"venner";
    if ([listOfFriends count]==1){
        friend = @"venn";
    }
    [eventDetailsViewController.friendsButton setTitle:[NSString stringWithFormat:@"%i %@ deltar", [listOfFriends count], friend] forState:UIControlStateNormal];
    [eventDetailsViewController.friendsButton setEnabled:YES];
    [self setTitle:[NSString stringWithFormat:@"%i %æ skal delta", [listOfFriends count], friend]];
    [eventDetailsViewController release];
    
    
}



-(void) loadFriends:(EventDetailsViewController *) controller
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    eventDetailsViewController = controller;
    Event *event = eventDetailsViewController.event;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://findmyapp.net/findmyapp/events/%i/friends", [event.id intValue]]];
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:delegate.consumer token:nil realm:nil signatureProvider:nil] autorelease];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    OARequestParameter *tokenParam = [[OARequestParameter alloc] initWithName:@"token" value:delegate.formattedToken];
    NSArray *params = [NSArray arrayWithObjects:tokenParam, nil];
    [request setParameters:params];
    OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(requestTicket:didFinishWithData:) didFailSelector:@selector(requestTicket:didFailWithError:)];
    [tokenParam release];
}




- (void)viewWillAppear:(BOOL)animated
{
    [friendsTableView reloadData];
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [listOfFriends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    NSString *cellValue = (NSString *) [listOfFriends objectAtIndex:indexPath.row];
    NSLog(@"Lagt til venn: %@", cellValue);
    [cell.textLabel setText:[NSString stringWithFormat:@"%@", cellValue]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"AAaaaa");
    [self.friendsTableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
