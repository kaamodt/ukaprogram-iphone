//
//  EventsTableViewController.h
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 28.06.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EventDetailsViewController;
@class FilterViewController;

@interface EventsTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    IBOutlet UITableView *eventsTableView;
    IBOutlet UIScrollView *pickerView;
    NSMutableArray *listOfEvents;
    EventDetailsViewController *eventDetailsViewController;
    FilterViewController *filterViewController;
    UIBarButtonItem *categoryChooser;
    IBOutlet UIView* sideSwipeView;
    UITableViewCell* sideSwipeCell;
    BOOL animatingSideSwipe;
    UISwipeGestureRecognizerDirection sideSwipeDirection;
}
@property (nonatomic, retain) UIScrollView *pickerView;
@property (nonatomic, retain) NSMutableArray *listOfEvents;
@property (nonatomic, retain) EventDetailsViewController *eventDetailsViewController;
@property (nonatomic, retain) FilterViewController *filterViewController;
@property (nonatomic, retain) UITableView *eventsTableView;
@property (nonatomic, retain) UIBarButtonItem *categoryChooser;
@property (nonatomic, retain) IBOutlet UIView* sideSwipeView;
@property (nonatomic, retain) UITableViewCell* sideSwipeCell;
@property (nonatomic) UISwipeGestureRecognizerDirection sideSwipeDirection;
@property (nonatomic) BOOL animatingSideSwipe;

-(void) showAllEvents;
-(void) showFavoriteEventsFromFilterView:(BOOL) value;
-(void) showKonsertEvents;
-(void) showRevyEvents;
-(void) showKursEvents;
-(void) showFestEvents;
-(void) scrollToDate:(NSDate *)date animated:(BOOL)animated;
//-(void) setLoginButtons;
-(void) snapToPosition:(UIScrollView*) sView;

@end
