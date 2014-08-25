//
//  TTMMUCManager.m
//  TextTimeMachine
//
//  Created by Komal Verma on 23/04/14.
//  Copyright (c) 2014 Komal Verma. All rights reserved.
//

#import "ESSMUCManager.h"
#import "XMPPRoomHybridStorage.h"
#import "XMPPRoomMemoryStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#import "Room.h"




@interface ESSMUCManager ()<UIAlertViewDelegate>
{
    
    XMPPUserCoreDataStorageObject *user;
}
@property (nonatomic,strong) NSString *currentRoomString;

@property (nonatomic,strong) NSMutableArray *rooms;
@end


@implementation ESSMUCManager

static ESSMUCManager *sInstance = NULL;

+(ESSMUCManager *)sharedInstance{
    
    @synchronized(self)
	{
		if (sInstance == NULL)
			sInstance = [[self alloc] init];
	}
	return sInstance;
}
/*
 - (XMPPRoom *)currentRoom {
 return self.currentRoom;
 }
 */

-(void)loadData
{
    if (self.rooms)
        self.rooms =nil;
    self.rooms = [[NSMutableArray alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Room"
                                              inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSError *error=nil;
    NSArray *fetchedObjects = [[ESSHelper appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *obj in fetchedObjects)
    {
        Room *currentRoom = (Room *)obj;
        [self.rooms addObject:currentRoom];
    }
    //reload the table view
    self.groupCreated(self.rooms);
}

-(void)askForCreatedGroup:(MUCGroup)groups {
    self.groupCreated = groups;
    [self loadData];
}
-(void)createGroups:(MUCGroup )groups {
    self.groupCreated = groups;
    [self askForRoomName:nil];
}
-(NSString *)myCleanJID
{
    NSString *myJid = [[NSUserDefaults standardUserDefaults] valueForKey:@"kXMPPmyJID"];
    myJid = [myJid stringByReplacingOccurrencesOfString:kXMPPServer withString:@""];
    myJid = [myJid stringByReplacingOccurrencesOfString:@"@" withString:@""];
    NSLog(@"myCleanJID : %@",myJid);
    return myJid;
}

#pragma mark actions
-(IBAction)askForRoomName:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Create ROOM" message:@"Enter Room Name" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", @"Cancel",nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput ;
    [alert show];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
    {
        UITextField* roomName = [alertView textFieldAtIndex:0];
        if ([roomName.text length]> 0)
        {
            self.currentRoomString = roomName.text;
            NSLog(@"currentRoomString %@",self.currentRoomString);
            // [self createRoom] ;
            NSString *roomJIDString = [NSString stringWithFormat:@"%@_%@@%@",[self myCleanJID],self.currentRoomString,kxmppConferenceServer];
            XMPPJID *roomJID = [XMPPJID jidWithString:roomJIDString];
            [self createRoomWithJid:roomJID];
        }
        
    }
    
}
/*
 -(void)createRoom
 {
 Room  *newRoom =[NSEntityDescription
 insertNewObjectForEntityForName:@"Room"
 inManagedObjectContext:[ESSHelper  appDelegate].managedObjectContext];
 newRoom.name = self.currentRoomString;
 newRoom.roomJID = [NSString stringWithFormat:@"%@_%@@%@",[self myCleanJID],self.currentRoomString,kxmppConferenceServer];
 NSError *error = nil;
 if (![[ESSHelper  appDelegate].managedObjectContext save:&error])
 {
 NSLog(@"error saving");
 }
 else
 {
 //Create the room
 //Create a unique name
 NSString *roomJIDString = [NSString stringWithFormat:@"%@_%@@%@",[self myCleanJID],self.currentRoomString,kxmppConferenceServer];
 XMPPJID *roomJID = [XMPPJID jidWithString:roomJIDString];
 #if USE_MEMORY_STORAGE
 _xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
 #elif USE_HYBRID_STORAGE
 xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
 #endif
 //Clean first
 if (self.currentRoom)
 {
 [self.currentRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
 [self.currentRoom deactivate];
 self.currentRoom=nil;
 
 }
 
 self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
 [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
 [self.currentRoom activate:[ESSHelper xmppStream]];
 
 //joining will create the room
 //We now use a hardcoded nickname of course this should be configurable in some kind of settings option
 [self.currentRoom joinRoomUsingNickname:[self myCleanJID] history:nil];
 [_rooomArray addObject:self.currentRoom];
 }
 }
 
 
 -(void)createRoom :(NSString *)roomName
 {
 //Create the room
 //Create a unique name
 NSString *roomJIDString = [NSString stringWithFormat:@"%@_%@@%@",[self myCleanJID],roomName,kxmppConferenceServer];
 XMPPJID *roomJID = [XMPPJID jidWithString:roomJIDString];
 #if USE_MEMORY_STORAGE
 _xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
 #elif USE_HYBRID_STORAGE
 xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
 #endif
 //Clean first
 if (self.currentRoom)
 {
 [self.currentRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
 [self.currentRoom deactivate];
 self.currentRoom=nil;
 
 }
 
 self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
 [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
 [self.currentRoom activate:[ESSHelper xmppStream]];
 
 //joining will create the room
 //We now use a hardcoded nickname of course this should be configurable in some kind of settings option
 [self.currentRoom joinRoomUsingNickname:[self myCleanJID] history:nil];
 
 }
 */

- (BOOL)isGroupExisted:(XMPPJID *)roomJID{
    BOOL ifFound= NO;
    NSError *error = nil;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Room"
                                              inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [[ESSHelper appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:@"jidString == %@", roomJID.full];
    [fetchRequest setPredicate:predicate];
    for (NSManagedObject *obj in fetchedObjects)
    {
        if ([roomJID.full isEqualToString:((Room *)obj).roomJID]) {
            ifFound = YES;
        }
    }
    return ifFound;
}
-(void)createRoomWithJid :(XMPPJID *)roomJID
{
    
    if (![self isGroupExisted:roomJID])
    {
        NSArray * RoomName=[roomJID.user componentsSeparatedByString:@"_"];
        Room  *newRoom =[NSEntityDescription
                         insertNewObjectForEntityForName:@"Room"
                         inManagedObjectContext:[ESSHelper  appDelegate].managedObjectContext];
        
        newRoom.name = [RoomName objectAtIndex:1];
        
        newRoom.roomJID =roomJID.bare;
        // Room verification
        NSError *error = nil;
        if (![[ESSHelper  appDelegate].managedObjectContext save:&error])
        {
            NSLog(@"error saving");
        }
        else {
#if USE_MEMORY_STORAGE
            _xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
#elif USE_HYBRID_STORAGE
            xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
#endif
            
            if (self.currentRoom)
            {
                [self.currentRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
                [self.currentRoom deactivate];
                self.currentRoom=nil;
                
            }
            
            self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
            [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
            [self.currentRoom activate:[ESSHelper xmppStream]];
            [self.currentRoom joinRoomUsingNickname:[self myCleanJID] history:nil];
            [_rooomArray addObject:self.currentRoom];
            // NSLog(@"error saving");
        }
    }
    else
    {
        
#if USE_MEMORY_STORAGE
        _xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
#elif USE_HYBRID_STORAGE
        xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
#endif
        
        if (self.currentRoom)
        {
            [self.currentRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
            [self.currentRoom deactivate];
            self.currentRoom=nil;
            
        }
        
        self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
        [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.currentRoom activate:[ESSHelper xmppStream]];
        [self.currentRoom joinRoomUsingNickname:[self myCleanJID] history:nil];
       // [_rooomArray addObject:self.currentRoom];
    }
}


-(void)createRoomWithJid :(NSString *)roomJIDString name:(NSString *)groupName
{
    NSString *jidStr = [[NSString stringWithFormat:@"%@_%@@%@",[self myCleanJID],roomJIDString,kxmppConferenceServer]stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    XMPPJID *roomJID = [XMPPJID jidWithString:[jidStr stringByReplacingOccurrencesOfString:@" " withString:@""]];
    
    if (![self isGroupExisted:roomJID])
    {
        Room  *newRoom =[NSEntityDescription
                         insertNewObjectForEntityForName:@"Room"
                         inManagedObjectContext:[ESSHelper  appDelegate].managedObjectContext];
        
        newRoom.name = groupName;
        
        newRoom.roomJID =roomJID.bare;        // Room verification
        NSError *error = nil;
        if (![[ESSHelper  appDelegate].managedObjectContext save:&error])
        {
            NSLog(@"error saving");
        }
        else {
#if USE_MEMORY_STORAGE
            _xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
#elif USE_HYBRID_STORAGE
            xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
#endif
            
            if (self.currentRoom)
            {
                [self.currentRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
                [self.currentRoom deactivate];
                self.currentRoom=nil;
                
            }
            
            self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
            [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
            [self.currentRoom activate:[ESSHelper xmppStream]];
            [self.currentRoom joinRoomUsingNickname:[self myCleanJID] history:nil];
            //[_rooomArray addObject:self.currentRoom];
            // NSLog(@"error saving");
        }
    }
    else
    {
        
#if USE_MEMORY_STORAGE
        _xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
#elif USE_HYBRID_STORAGE
        xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
#endif
        
        if (self.currentRoom)
        {
            [self.currentRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
            [self.currentRoom deactivate];
            self.currentRoom=nil;
            
        }
        
        self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
        [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.currentRoom activate:[ESSHelper xmppStream]];
        [self.currentRoom joinRoomUsingNickname:[self myCleanJID] history:nil];
        [_rooomArray addObject:self.currentRoom];
    }
}

#pragma mark delegate methods
-(void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    DDLogInfo(@"joined room");
}
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    //now we can configure the room
    [self configureThisRoom:sender];
}

-(void)configureThisRoom:(XMPPRoom *)sender
{
    //configure the room
    //NSXMLElement *query= [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCOwnerNamespace];
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    
    NSXMLElement *root =[NSXMLElement elementWithName:@"field"];
    [root addAttributeWithName:@"type" stringValue:@"hidden"];
    [root addAttributeWithName:@"var"  stringValue:@"FORM_TYPE"];
    NSXMLElement *valField1 = [NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/muc#roomconfig"];
    [root addChild:valField1];
    //[x addChild:field1];
    
    NSXMLElement *loggingfield = [NSXMLElement elementWithName:@"field"];
    [loggingfield addAttributeWithName:@"type" stringValue:@"boolean"];
    [loggingfield addAttributeWithName:@"var" stringValue:@"muc#roomconfig_enable_logging"];
    [loggingfield addAttributeWithName:@"value" stringValue:@"1"];
    //
    NSXMLElement *namefield = [NSXMLElement elementWithName:@"field"];
    [namefield addAttributeWithName:@"type" stringValue:@"text-single"];
    [namefield addAttributeWithName:@"var" stringValue:@"muc#roomconfig_roomname"];
    [namefield addAttributeWithName:@"value" stringValue:self.currentRoomString];
    
    //
    NSXMLElement *subjectField = [NSXMLElement elementWithName:@"field"];
    [subjectField addAttributeWithName:@"type" stringValue:@"boolean"];
    [subjectField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_changesubject"];
    [subjectField addAttributeWithName:@"value" stringValue:@"1"];
    //
    NSXMLElement *membersonlyField = [NSXMLElement elementWithName:@"field"];
    [membersonlyField addAttributeWithName:@"type" stringValue:@"boolean"];
    [membersonlyField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_membersonly"];
    [membersonlyField addAttributeWithName:@"value" stringValue:@"1"];
    //
    NSXMLElement *moderatedfield = [NSXMLElement elementWithName:@"field"];
    [moderatedfield addAttributeWithName:@"type" stringValue:@"boolean"];
    [moderatedfield addAttributeWithName:@"var" stringValue:@"muc#roomconfig_moderatedroom"];
    [moderatedfield addAttributeWithName:@"value" stringValue:@"0"];
    //
    NSXMLElement *persistentroomfield = [NSXMLElement elementWithName:@"field"];
    [persistentroomfield addAttributeWithName:@"type" stringValue:@"boolean"];
    [persistentroomfield addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];
    [persistentroomfield addAttributeWithName:@"value" stringValue:@"0"];
    //
    NSXMLElement *publicroomfield = [NSXMLElement elementWithName:@"field"];
    [publicroomfield addAttributeWithName:@"type" stringValue:@"boolean"];
    [publicroomfield addAttributeWithName:@"var" stringValue:@"muc#roomconfig_publicroom"];
    [publicroomfield addAttributeWithName:@"value" stringValue:@"0"];
    //
    NSXMLElement *maxusersField = [NSXMLElement elementWithName:@"field"];
    [maxusersField addAttributeWithName:@"type" stringValue:@"text-single"];
    [maxusersField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_maxusers"];
    [maxusersField addAttributeWithName:@"value" stringValue:@"10"];
    
    NSXMLElement *ownerField = [NSXMLElement elementWithName:@"field"];
    [ownerField addAttributeWithName:@"type" stringValue:@"jid-multi"];
    [ownerField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_roomowners"];
    [ownerField addAttributeWithName:@"value" stringValue: [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID]];
    
    
    [root addChild:loggingfield];
    [root addChild:namefield];
    [root addChild:membersonlyField];
    [root addChild:moderatedfield];
    [root addChild:persistentroomfield];
    [root addChild:publicroomfield];
    [root addChild:maxusersField];
    [root addChild:ownerField];
    [root addChild:subjectField];
    [x addChild:root];
    // [query addChild:x];
    
    [sender configureRoomUsingOptions:x];
}


-(void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    //update data
    [self loadData];
}
- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items{
    
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError{
    
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items{
    
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError{
    
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items{
    
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError{
    
}

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult{
    
}
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError{
    
}

- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room{
    DDLogInfo(@"Incoming message %@",message);
}
- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room{
    DDLogInfo(@"Outgoing message %@",message);
}

-(void)removeData
{
    if (self.rooms)
        self.rooms =nil;
    self.rooms = [[NSMutableArray alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Room"
                                              inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSError *error=nil;
    NSArray *fetchedObjects = [[ESSHelper appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *obj in fetchedObjects)
    {
        [[ESSHelper appDelegate].managedObjectContext deleteObject:obj];
    }
    //reload the table view
}
@end
