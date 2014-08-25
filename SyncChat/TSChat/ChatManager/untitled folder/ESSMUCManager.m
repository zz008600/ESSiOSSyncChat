//
//  TSMUCManager.m
//  SyncChat
//
//  Created by essadmin on 6/11/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSMUCManager.h"

@implementation ESSMUCManager
static ESSMUCManager *gInstance = NULL;

+(ESSMUCManager *)sharedInstance{
    @synchronized(self)
	{
		if (gInstance == NULL)
			gInstance = [[self alloc] init];
	}
	return gInstance;
}

#pragma  mark - GroupChatImplementation

-(void)conferenceChat{
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Create ROOM" message:@"Enter Roomname" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput ;
        [alert show];
}


-(IBAction)groupMsg:(id)sender{
    
}

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
    NSLog(@"fetchedObjects %@",fetchedObjects);
    for (NSManagedObject *obj in fetchedObjects)
    {
        Room *currentRoom = (Room *)obj;
        [self.rooms addObject:currentRoom];
    }
    isConference = YES;
    //reload the table view
    [self.mtableView reloadData];
}
-(NSString *)myCleanJID
{
    NSString *myJid = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    myJid = [myJid stringByReplacingOccurrencesOfString:kXMPPServer withString:@""];
    myJid = [myJid stringByReplacingOccurrencesOfString:@"@" withString:@""];
    return myJid;
}


#pragma mark actions
-(IBAction)askForRoomName:(id)sender
{
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
        {
            UITextField* roomName = [alertView textFieldAtIndex:0];
            if ([roomName.text length]> 0)
            {
                self.currentRoomString = roomName.text;
                [self createRoom] ;
            }
            isConferenceExit = YES;
            //[_sendBtn setTitle:@"Exit" forState:UIControlStateNormal];
        }
    }else{
        isConference = NO;
    }
    
}
-(void)createRoom
{
    Room  *newRoom =[NSEntityDescription
                     insertNewObjectForEntityForName:@"Room"
                     inManagedObjectContext:[ESSHelper  appDelegate].managedObjectContext];
    newRoom.name = self.currentRoomString;
    newRoom.roomJID = [NSString stringWithFormat:@"%@_%@%@",[self myCleanJID],self.currentRoom,kxmppConferenceServer];
    NSError *error = nil;
    if (![[ESSHelper  appDelegate].managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    else
    {
        //Create the room
        //Create a unique name
        NSString *roomJIDString = [NSString stringWithFormat:@"%@_%@%@",[self myCleanJID],self.currentRoomString,kxmppConferenceServer];
        XMPPJID *roomJID = [XMPPJID jidWithString:roomJIDString];
#if USE_MEMORY_STORAGE
        xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
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
        
        self.currentRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppRoomStorage jid:roomJID];
        [self.currentRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.currentRoom activate:[ESSHelper xmppStream]];
        
        //joining will create the room
        //We now use a hardcoded nickname of course this should be configurable in some kind of settings option
        [self.currentRoom joinRoomUsingNickname:_user.nickname history:nil];
        
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
    
    [sender configureRoomUsingOptions:x];
}

-(void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    //update data
    [self loadData];
    //Invite all your contacts to join
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                              inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext_roster];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSError *error=nil;
    NSArray *fetchedObjects = [[ESSHelper appDelegate].managedObjectContext_roster executeFetchRequest:fetchRequest error:&error];
    NSLog(@"fetchedObjects : %@",fetchedObjects);
    for (NSManagedObject *obj in fetchedObjects)
    {
        XMPPUserCoreDataStorageObject *user = (XMPPUserCoreDataStorageObject *)obj;
        NSLog(@"Nick Name : %@",user.nickname);
        NSLog(@"Status : %@",user.jidStr);
        NSLog(@"Jid %@",user.jid);
        [self.currentRoom inviteUser:user.jid withMessage:@"Join this room"];
    }
}


@end
