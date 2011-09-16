//
//  SettingsViewController.h
//  UKEprogram
//
//  Created by UKA-11 Accenture AS on 22.07.11.
//  Copyright 2011 Accenture AS. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
    IBOutlet UITableView *_settingsTableView;
    NSArray *_settingsName;
    NSArray *_settingsRealName;
    NSArray *_settingsValue;
    UIImage *_currentValue;
    NSMutableArray *_selectedValue;
    BOOL _loading;

}

@property (nonatomic, retain) UITableView *settingsTableView;

@end
