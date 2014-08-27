//
//  TSHomeViewController.h
//  TSChat
//
//  Created by essadmin on 5/28/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESSBuddyListViewController.h"
#import "ESSSyncViewController.h"
#import "ESSSynChatFileManager.h"
#import "DataAwareTurnSocket.h"
#import "FTPConnectionManager.h"
#import "FTPManager.h"
#import "SyncPlayerPlugin.h"

@interface ESSHomeViewController : ESSMainViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIActionSheetDelegate>{
    UIView * chat_View;
    UITableView * chat_table;
    UITextField * messageText;
    UIButton * share;
    UIButton *upload;
    NSString * Message;
    UIView * frind_list;
    BOOL isSideViewHide;
  //  ESSBuddyListViewController * frndList;
    UIView * bottomView;
    
    //FTP Connection
    FTPConnectionManager *ftpManager;
    
}
//@property(nonatomic,retain) selectedUserIndex;
@property(nonatomic,retain) NSMutableArray * chats;
@property (nonatomic, strong) NSString *chatType;
@property(nonatomic,strong) XMPPUserCoreDataStorageObject *userSelected;
@property (nonatomic,strong) XMPPRoom* currentRoomCVC;
@end
