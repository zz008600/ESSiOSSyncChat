//
//  TSAppDelegate.h
//  TSChat
//
//  Created by essadmin on 5/1/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "XMPPFramework.h"
#import "ESSSyncViewController.h"
#import "ESSFileInfo.h"
#import "ESSFileReceiver.h"
#import "XMPPRoom.h"
#import "ESSMUCManager.h"
#import "ESSFileSender.h"

@interface ESSAppDelegate : UIResponder <UIApplicationDelegate ,XMPPMUCDelegate,XMPPRoomDelegate>{
    NSString *password;
	
	BOOL customCertEvaluation;
	
	BOOL isXmppConnected;
    BOOL isConnet;
     __strong id <XMPPRoomStorage> xmppRoomStorage;
}

@property (strong, nonatomic)XMPPStream *xmppStream;
@property (strong, nonatomic)XMPPReconnect *xmppReconnect;
@property (strong, nonatomic)XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (strong, nonatomic)XMPPRoster *xmppRoster;
@property (strong, nonatomic)XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (strong, nonatomic) XMPPvCardAvatarModule *xmppvCardTempModule;
@property (strong, nonatomic) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

@property (strong, nonatomic)XMPPStream *xmppRoom;

#pragma file send receive
@property(nonatomic,strong) ESSFileInfo* fileInfo;
@property(nonatomic,assign) BOOL isSending;
@property(nonatomic,assign) BOOL isReceiving;
@property(nonatomic,strong) NSString* transferID;
@property(nonatomic,strong) NSString* streamID;
@property(nonatomic,strong) ESSFileReceiver *fileReceiver;
@property(nonatomic,strong) ESSFileSender *fileSender;


@property (strong, nonatomic) UIWindow *window;


//CoreData
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator  *persistentStoreCoordinator;


@property (nonatomic,strong, readonly) XMPPMUC *xmppMUC;
@property (nonatomic,strong, readonly) XMPPRoomCoreDataStorage *xmppRoomCoreDataStore;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

- (BOOL)connect;
- (BOOL)connectUserName :(NSString *)usr andPassword:(NSString *)pwd;
- (void)disconnect;
- (void)goOnline;
- (void)goOffline;
- (void)showAlertWithMessage:(NSString *)mesg;
-(void)sendInvitationToJID:(NSString *)_jid withNickName:(NSString *)_nickName;
- (void)setupXMPPStream;
@end
