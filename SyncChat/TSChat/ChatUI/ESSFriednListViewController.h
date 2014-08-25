//
//  ESSFriednListViewController.h
//  SyncChat
//
//  Created by essadmin on 6/27/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESSFriednListViewController : ESSMainViewController<UITableViewDataSource,UITabBarDelegate,NSFetchedResultsControllerDelegate>{
    NSFetchedResultsController *fetchedResultsController;
    XMPPUserCoreDataStorageObject *userSelected;
    __strong id <XMPPRoomStorage> xmppRoomStorage;
}
@property(nonatomic,strong)IBOutlet UITableView *friendListTable;
@property(nonatomic,strong)Room *selectedRoom;
@property(nonatomic,strong)XMPPRoom *xmppRoom;
@end
