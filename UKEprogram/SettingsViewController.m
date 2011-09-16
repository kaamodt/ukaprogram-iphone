//
//  SettingsViewController.m
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 22.07.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import "SettingsViewController.h"
#import "JSON.h"
#import "UKEprogramAppDelegate.h"
#import "OAuthConsumer.h"

@implementation SettingsViewController

@synthesize settingsTableView = _settingsTableView;


- (NSNumber *)mapValue:(NSString *)sValue
{
    if ([sValue isEqualToString:@"ANYONE"]) {
        return [NSNumber numberWithInt:0];
    }
    else if ([sValue isEqualToString:@"FRIENDS"]) {
        return [NSNumber numberWithInt:1];
    }
    else if ([sValue isEqualToString:@"ONLY_ME"]) {
        return [NSNumber numberWithInt:2];
    }
    else {
        return [NSNumber numberWithInt:3];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
/**
 * Request to uka backend to retrieve all events
 */

- (void)dealloc
{
    [super dealloc];
    /*[_settingsName dealloc];
    [_settingsValue dealloc];
    [_currentValue dealloc];
    [_settingsRealName dealloc];
    [_selectedValue dealloc];*/
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
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) requestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    NSLog(@"unsuccessfull finish %@", error);
}

- (void) requestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    //NSLog(@"successfull finish");
    NSString *responseString = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    //NSLog(@"recieved %@", responseString);
    NSDictionary *settings = [responseString JSONValue];
    
    [_selectedValue replaceObjectAtIndex:0 withObject:[self mapValue:[settings valueForKey:@"positionPrivacySetting"]]];
    [_selectedValue replaceObjectAtIndex:1 withObject:[self mapValue:[settings valueForKey:@"eventsPrivacySetting"]]];
    [_selectedValue replaceObjectAtIndex:2 withObject:[self mapValue:[settings valueForKey:@"moneyPrivacySetting"]]];
    [_selectedValue replaceObjectAtIndex:3 withObject:[self mapValue:[settings valueForKey:@"mediaPrivacySetting"]]];
    
    _loading = NO;
    [_settingsTableView reloadData];
    [responseString release];
    //[data release];
}

// Implement viewDidLoad to do additional setup after _loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    //NSLog(@"TOOKEN %@", delegate.formattedToken);
    
    _settingsName = [[NSArray alloc] initWithObjects:@"Deling av posisjonsdata",@"Deling av arrangementsdata",@"Deling av pengebruk",@"Deling av media", nil];
    _settingsRealName = [[NSArray alloc] initWithObjects:@"positionPrivacySetting",@"eventsPrivacySetting",@"moneyPrivacySetting",@"mediaPrivacySetting", nil];
    _settingsValue = [[NSArray alloc] initWithObjects:@"Alle",@"Venner",@"Bare meg", nil];
    _currentValue = [UIImage imageNamed:@"currentValue"];
    _selectedValue = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:0], [NSNumber numberWithInt:2], [NSNumber numberWithInt:1], nil];
    _loading = YES;
    self.navigationItem.title = @"Innstillinger for UKApps";
    
    //OAuth
    
    NSURL *url = [NSURL URLWithString:@"http://findmyapp.net/findmyapp/users/me/privacy"];
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:delegate.consumer token:nil realm:nil signatureProvider:nil] autorelease];//should default sha1
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    OARequestParameter *token = [[OARequestParameter alloc] initWithName:@"token" value:delegate.formattedToken];
    NSArray *params = [NSArray arrayWithObjects:token, nil];
    [request setParameters:params];
    OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(requestTicket:didFinishWithData:) didFailSelector:@selector(requestTicket:didFailWithError:)];
    
    
    
    [token release];
    /*
    NSString *eventsApiUrl = [NSString stringWithFormat: @"http://findmyapp.net/findmyapp/users/1/privacy"];
    responseData = [[NSMutableData data] retain];
    NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString:eventsApiUrl]];
    NSLog(@"Opening connection");
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    */
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_settingsName release];
    [_settingsValue release];
    [_currentValue release];
    [_settingsRealName release];
    [_selectedValue release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UKEprogramAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    //Check is you still have internet access before changing settings
    if (![delegate isReachable]){
        [delegate.rootController popViewControllerAnimated:YES];
        return;
    }
    [self.settingsTableView deselectRowAtIndexPath:indexPath animated:NO];
    if (!_loading && [[_selectedValue objectAtIndex:indexPath.section] intValue] != [[NSNumber numberWithUnsignedInteger:indexPath.row] intValue]) {
        _loading = YES;
        [tableView reloadData];
        NSURL *url = [NSURL URLWithString:@"http://findmyapp.net/findmyapp/users/me/privacy"];
        OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:delegate.consumer token:nil realm:nil signatureProvider:nil] autorelease];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        NSNumber *num = [NSNumber numberWithInt:([[NSNumber numberWithUnsignedInteger:indexPath.row] intValue] + 1)];
        //NSNumber *num = [NSNumber numberWithUnsignedInteger:indexPath.row];
        NSLog(@"Posting %@: %i", [_settingsRealName objectAtIndex:indexPath.section], [num intValue]);
        OARequestParameter *postData = [[OARequestParameter alloc] initWithName:[_settingsRealName objectAtIndex:indexPath.section] value:[num stringValue]];
        OARequestParameter *token = [[OARequestParameter alloc] initWithName:@"token" value:delegate.formattedToken];
        NSArray *params = [NSArray arrayWithObjects:postData, token, nil];
        [request setParameters:params];
        OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
        [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(requestTicket:didFinishWithData:) didFailSelector:@selector(requestTicket:didFailWithError:)];
        
       
        [postData release];
        [token release];
    }
}

- (NSString *)tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section {
    return [_settingsName objectAtIndex:section];
}

- (UITableViewCell *) getCellContentView:(NSString *)cellIdentifier 
{
    UILabel *lblTemp;
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 300, 35)] autorelease];
    UIImageView *tempView;
    //Initialize Label with tag 1.
    lblTemp = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 290, 30)];
    lblTemp.tag = 1;
    [cell.contentView addSubview:lblTemp];
    [lblTemp release];
    
    tempView = [[UIImageView alloc] initWithFrame:CGRectMake(250, 10, 30, 30)];
    tempView.tag = 2;
    [cell.contentView addSubview:tempView];
    [tempView release];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    /*if (cell == nil) {
     cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
     }*/
    if (cell == nil) {
        cell = [self getCellContentView:CellIdentifier];
    }
    // Configure the cell...
    UILabel *textLabel = (UILabel *)[cell viewWithTag:1];
    UIImageView *view = (UIImageView *)[cell viewWithTag:2];
    
    
    [textLabel setText:[_settingsValue objectAtIndex:indexPath.row]];
    if (_loading) {
        
    }
    else if ([[_selectedValue objectAtIndex:indexPath.section] isEqualToNumber:[NSNumber numberWithUnsignedInteger:indexPath.row ]]) {
        [view setImage:_currentValue];
    }
    
    
    return cell;
}

@end
