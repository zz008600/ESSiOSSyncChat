//
//  FriendListSideview.h
//  SyncChat
//
//  Created by FORD MODS on 22/05/14.
//  Copyright (c) 2014 ESS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "TSChatViewController.h"
@interface FriendListSideview : UITableViewController<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>{
    NSFetchedResultsController *fetchedResultsController;
    XMPPUserCoreDataStorageObject *userSelected;
}
@property(nonatomic,weak)IBOutlet UITableView *buddyListTable;
@property(nonatomic,strong) XMPPUserCoreDataStorageObject *userSelected;
@end
