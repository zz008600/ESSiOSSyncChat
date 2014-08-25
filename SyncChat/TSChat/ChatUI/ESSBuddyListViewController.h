//
//  TSBuddyListViewController.h
//  TSChat
//
//  Created by essadmin on 5/2/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "TSChatViewController.h"
#import "ESSMainViewController.h"
#import "ESSHomeViewController.h"
#import "ESSMUCManager.h"
#import "ESSFriednListViewController.h"

@interface ESSBuddyListViewController : ESSMainViewController <UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>{
    NSFetchedResultsController *fetchedResultsController;
    XMPPUserCoreDataStorageObject *userSelected;
    NSMutableArray *groupsList;
     __strong id <XMPPRoomStorage> xmppRoomStorage;
}
@property(nonatomic,weak)IBOutlet UITableView *buddyListTable;
@property(nonatomic,weak)IBOutlet UISegmentedControl *groupFriendSegment;
@property(nonatomic,weak)IBOutlet UIButton *addFriedn;
@property(nonatomic,weak)IBOutlet UIButton *addGroup;
@property(nonatomic,strong) XMPPUserCoreDataStorageObject *userSelected;
@property(nonatomic,weak) IBOutlet UIView *sideView;

- (IBAction)settingView:(id)sender;
- (IBAction)signOut:(id)sender;

@end
