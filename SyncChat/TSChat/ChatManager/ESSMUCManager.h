//
//  TTMMUCManager.h
//  TextTimeMachine
//
//  Created by Komal Verma on 23/04/14.
//  Copyright (c) 2014 Komal Verma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRoom.h"

typedef void(^MUCGroup)(NSMutableArray *groupArray);
@interface ESSMUCManager : NSObject<XMPPStreamDelegate,XMPPMUCDelegate>
@property(nonatomic,strong) id <XMPPRoomStorage> xmppRoomStorage;
@property (nonatomic, copy) MUCGroup groupCreated;
@property (nonatomic,strong) XMPPRoom* currentRoom;
@property (nonatomic,strong) XMPPRoom* currentRoom2;
@property (nonatomic,strong) NSMutableArray * rooomArray;
-(void)createGroups:(MUCGroup )groups;
-(void)askForCreatedGroup:(MUCGroup)groups;
+(ESSMUCManager *)sharedInstance;
//-(void)createRoom :(NSString *)roomName;
-(void)removeData;
-(void)createRoomWithJid :(XMPPJID *)roomJID;
-(void)createRoomWithJid :(NSString *)roomJIDString name:(NSString *)groupName;
@end
