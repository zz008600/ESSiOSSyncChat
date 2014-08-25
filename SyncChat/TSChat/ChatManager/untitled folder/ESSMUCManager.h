//
//  TSMUCManager.h
//  SyncChat
//
//  Created by essadmin on 6/11/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESSMUCManager : NSObject <XMPPStreamDelegate,XMPPMUCDelegate,UIAlertViewDelegate>{
    BOOL isConference;
    BOOL isConferenceExit;
    __strong id <XMPPRoomStorage> xmppRoomStorage;
}

@property (nonatomic,strong) NSString *currentRoomString;
@property (nonatomic,strong) XMPPRoom* currentRoom;
@property (nonatomic,strong) UITableView *mtableView;
@property (nonatomic,strong) NSMutableArray *rooms;
@property(nonatomic,weak)XMPPUserCoreDataStorageObject *user;

+(ESSMUCManager *)sharedInstance;

@end
