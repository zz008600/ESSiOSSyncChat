//
//  TSChatViewController.m
//  TSChat
//
//  Created by essadmin on 5/2/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "TSChatViewController.h"

@interface TSChatViewController ()<XMPPStreamDelegate,XMPPMUCDelegate,UIAlertViewDelegate>
{
    __strong id <XMPPRoomStorage> xmppRoomStorage;
    BOOL isConference;
    BOOL isConferenceExit;
}
@property (nonatomic,strong) NSString *currentRoomString;
@property (nonatomic,strong) XMPPRoom* currentRoom;
@property (nonatomic,strong) UITableView *mtableView;
@property (nonatomic,strong) NSMutableArray *rooms;

- (IBAction)conferenceChat:(id)sender;
- (IBAction)send:(id)sender;
-(IBAction)groupMsg:(id)sender;
@end

@implementation TSChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textColor = [UIColor darkTextColor];
	titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
	titleLabel.numberOfLines = 1;
	titleLabel.adjustsFontSizeToFitWidth = YES;
	titleLabel.textAlignment = NSTextAlignmentCenter;
    
	if ([[self appDelegate] connect])
	{
		titleLabel.text = _user.nickname;
	} else
	{
		titleLabel.text = @"No JID";
	}
	
	[titleLabel sizeToFit];
    
	self.navigationItem.titleView = titleLabel;
}
- (TSAppDelegate *)appDelegate
{
	return (TSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream {
	return [[self appDelegate] xmppStream];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    isConference = NO;
    _msgBody.delegate = self;
    _msgBody.returnKeyType = UIReturnKeyDone;
    
    NSLog(@"Nickname : %@",_user.nickname);
    _msgcontainerSC.backgroundColor = [UIColor whiteColor];
    
    // rosterstorage = [[XMPPRoomMemoryStorage alloc] init];
    //xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:_user.jidStr]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


- (IBAction)send:(id)sender{
    NSString *strSendMsg = _msgBody.text;
    if (isConference) {
        [self.currentRoom sendMessageWithBody:strSendMsg];
    }else{
        
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:strSendMsg];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:[_user.jid full]];
        [message addChild:body];
        [[[self appDelegate] xmppStream] sendElement:message];
        _msgBody.text = @"";
        [_msgBody resignFirstResponder];
    }
    _msgBody.text = @"";
}

#pragma  mark - GroupChatImplementation

-(IBAction)conferenceChat:(id)sender{
    if (!isConferenceExit) {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Create ROOM" message:@"Enter Roomname" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput ;
        [alert show];
    }else{
        isConference = NO;
        isConferenceExit = YES;
        [_sendBtn setTitle:@"Conference" forState:UIControlStateNormal];
    }
}


-(IBAction)groupMsg:(id)sender{
    
}

-(void)loadData
{
    if (self.rooms)
        self.rooms =nil;
    self.rooms = [[NSMutableArray alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Room"
                                              inManagedObjectContext:[self appDelegate].managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSError *error=nil;
    NSArray *fetchedObjects = [[self appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
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
            [_sendBtn setTitle:@"Exit" forState:UIControlStateNormal];
        }
    }else{
        isConference = NO;
    }
    
}
-(void)createRoom
{
    Room  *newRoom =[NSEntityDescription
                     insertNewObjectForEntityForName:@"Room"
                     inManagedObjectContext:[self  appDelegate].managedObjectContext];
    newRoom.name = self.currentRoomString;
    newRoom.roomJID = [NSString stringWithFormat:@"%@_%@%@",[self myCleanJID],self.currentRoom,kxmppConferenceServer];
    NSError *error = nil;
    if (![[self  appDelegate].managedObjectContext save:&error])
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
        [self.currentRoom activate:[self xmppStream]];
        
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
                                              inManagedObjectContext:[self appDelegate].managedObjectContext_roster];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    NSError *error=nil;
    NSArray *fetchedObjects = [[self appDelegate].managedObjectContext_roster executeFetchRequest:fetchRequest error:&error];
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

#pragma mark - UItextField Delegates
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:textField up:YES];
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_msgBody resignFirstResponder];
    //[self send:nil];
    return YES;
}

- (void)animateTextField:(UITextField *)textField up:(BOOL) up
{
    [UIView beginAnimations: nil context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: .4];
    
    
    if (up)
    {
        self.msgSentView.frame = CGRectMake(self.msgSentView.frame.origin.x, self.msgSentView.frame.origin.y-215, self.msgSentView.frame.size.width, self.msgSentView.frame.size.height);
        self.msgcontainerSC.frame = CGRectMake(self.msgcontainerSC.frame.origin.x, self.msgcontainerSC.frame.origin.y, self.msgcontainerSC.frame.size.width, self.msgcontainerSC.frame.size.height-215);
    }
    else
    {
        self.msgSentView.frame = CGRectMake(self.msgSentView.frame.origin.x, self.msgSentView.frame.origin.y+215, self.msgSentView.frame.size.width, self.msgSentView.frame.size.height);
        self.msgcontainerSC.frame = CGRectMake(self.msgcontainerSC.frame.origin.x, self.msgcontainerSC.frame.origin.y, self.msgcontainerSC.frame.size.width, self.msgcontainerSC.frame.size.height+215);
        
    }
    [UIView commitAnimations];
    
}

@end
