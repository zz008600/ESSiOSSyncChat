//
//  TSSyncViewController.m
//  TSChat
//
//  Created by essadmin on 5/28/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSMUCManager.h"
#import "ESSSyncViewController.h"

@interface ESSSyncViewController (){
    NSString *conversationJidString;
    NSString  *cleanName;
    NSString *sampleString;
    NSString *bitString;
    NSString *chatStatus;
    XMPPUserCoreDataStorageObject * userSelectedOnChoice;
    NSString *syncVRStatus;
    int softButtonIndex;
    BOOL isSentSelected;
    int reposeChoiceIDForGroup;
}
- (void)stopMusic;
- (void)startMusic;
@end

@implementation ESSSyncViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncNewMessageReceived:) name:kNewMessageForSYNC  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onVoiceCommand:)
                                                 name:@"onVoiceCommand"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onChoice:)
                                                 name:@"onPerformInteractionResponse"
                                               object:nil];
    [ [NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(buttonsEvent:)
                                                  name:@"onButtonPress"
                                                object:nil];
    [ [NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(onCreateInteractionChoiceSetResponseNotification:)
                                                  name:@"onCreateInteractionChoiceSetResponse"
                                                object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveAudioResponse:)
                                                 name:@"PerformAudioPassThruResponse"
                                               object:nil];
    [self addVRCommand];
    [self addMainSoftButton];
    [self syncGroupChat];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - VR Coomand and Response

- (void)addVRCommand{
    [[SyncService sharedInstance] addCommand:@"Friends"];
    [[SyncService sharedInstance] addCommand:@"Groups"];
    [[SyncService sharedInstance] addCommand:@"Reply"];
    [[SyncService sharedInstance] addCommand:@"Send"];
    [[SyncService sharedInstance] addCommand:@"Back"];
    [[SyncService sharedInstance] addCommand:@"Add Group"];
    [[SyncService sharedInstance] addCommand:@"Add Friend"];
    
}


-(void)onVoiceCommand:(NSNotification *)notify{
    
   // FMCOnCommand *notification = [notify object];
    
    NSString * cmdText = @"1";// [[[SyncService sharedInstance] allVoiceCommand] objectForKey:[NSString stringWithFormat:@"%@",notification.cmdID]];//
    
    if([cmdText isEqualToString:@"Friends"]){
        NSArray *sections = [[self fetchedResultsController] sections];
        if ([sections count]) {
            
            syncVRStatus =@"Friends";
            //chatStatus = @"Friends";
            [self setUpChoiceSetForFriendList];
        }
    }
    if([cmdText isEqualToString:@"Groups"]){
        [self syncGroupChat];
        syncVRStatus =  @"Groups";
        //chatStatus = @"Groups";
        [self setUpChoiceSetForGroupList];
    }
    if([cmdText isEqualToString:@"Reply"]){
        syncVRStatus =@"Reply";
        [self send:nil orJidString:_chats.jidString];
        //[self startTDKRecord];
    }
    if([cmdText isEqualToString:@"Send"]){
        syncVRStatus = @"Send";
        //[self startTDKRecord];
        [self send:userSelectedOnChoice orJidString:nil];
    }
    if([cmdText isEqualToString:@"Back"]){
        syncVRStatus =  @"Back";
        [self addMainSoftButton];
    }
    if([cmdText isEqualToString:@"Add Group"]){
        syncVRStatus=@"Add Group";
        [[ESSMUCManager sharedInstance] createRoomWithJid :[self getGroupJID] name:[self getGroupName]];
    }
    if([cmdText isEqualToString:@"Add Friend"]){
        syncVRStatus=@"Add Friend";
        
        syncVRStatus =@"Friends";
        [self setUpChoiceSetForFriendList];
    }
}

#pragma mark - SoftButton and response

- (void)addMainSoftButton{
    isSentSelected = NO;
    NSMutableArray *option = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:@"Friend" forKey:@"Value"];
    [data setObject:@"5001" forKey:@"Index"];
    [option addObject:data];
    data = nil;
    data = [[NSMutableDictionary alloc] init];
    [data setObject:@"Groups" forKey:@"Value"];
    [data setObject:@"5002" forKey:@"Index"];
    [option addObject:data];
    data = [[NSMutableDictionary alloc] init];
    [data setObject:@"New" forKey:@"Value"];
    [data setObject:@"5007" forKey:@"Index"];
    [option addObject:data];
    [[SyncService sharedInstance] showPressed:@"SyncChat" WithSubMessage:@"Messaging World" andSoftButtons:option];
}

// For all button Events
-(void)buttonsEvent:(NSNotification *)notify{
    FMCOnButtonPress *buttonPress = [notify object];
    
    //  [[SyncService sharedInstance]alert:[NSString stringWithFormat:@"Button Event Noumber %i",[buttonPress.customButtonID intValue]]];
    
    if ([buttonPress.customButtonID intValue] == 5001) {
        syncVRStatus =@"Friends";
        //chatStatus = @"Friends";
        [self setUpChoiceSetForFriendList];
    }
    if ([buttonPress.customButtonID intValue] == 5002) {
        syncVRStatus = @"Groups";
        //chatStatus = @"Groups";
        [self setUpChoiceSetForGroupList];
    }
    if ([buttonPress.customButtonID intValue] == 5003) {
         syncVRStatus =  @"Send";
        [self send:userSelectedOnChoice orJidString:nil];
        //[self startTDKRecord];
    }
    if ([buttonPress.customButtonID intValue] == 5004) {
        syncVRStatus =  @"Add Friend";
    }
    if ([buttonPress.customButtonID intValue] == 5005) {
        syncVRStatus =  @"Back";
        [self addMainSoftButton];
    }
    if ([buttonPress.customButtonID intValue] == 5006) {
        syncVRStatus =  @"Reply";
        [self send:nil orJidString:_chats.jidString];
        //[self startTDKRecord];
    }
    if ([buttonPress.customButtonID intValue] == 5007) {
        syncVRStatus =  @"Add Group";
        [[ESSMUCManager sharedInstance] createRoomWithJid :[self getGroupJID] name:[self getGroupName]];
    }
}




- (void)showConversationForJIDString:(NSString *)jidString
{
    conversationJidString = jidString;
    cleanName = [jidString stringByReplacingOccurrencesOfString:kXMPPServer withString:@""];
    cleanName=[cleanName stringByReplacingOccurrencesOfString:@"@" withString:@""];
}



#pragma mark - Friend List
- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [[ESSHelper appDelegate] managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
        
	}
	
	return fetchedResultsController;
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
}

/*
 - (ESSAppDelegate *)appDelegate
 {
 return (ESSAppDelegate *)[[UIApplication sharedApplication] delegate];
 }
 */
-(NSInteger)getNumberOfOnlineFriends:(NSInteger)sectionIndex{
    NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	}
	return 0;
}

-(void)setUpChoiceSetForFriendList {
    NSMutableArray *choices = [[NSMutableArray alloc] init];
    NSInteger j=0;
    for (j = 0 ; j < [self getNumberOfOnlineFriends:0]; j++) {
        XMPPUserCoreDataStorageObject * userSelected = [[[self fetchedResultsController] fetchedObjects] objectAtIndex:j];
        FMCChoice *FMCc = [[FMCChoice alloc] init];
        FMCc.menuName = [ESSHelper displayName:userSelected.displayName];
        FMCc.choiceID = [NSNumber numberWithInt: j];
        FMCc.vrCommands=[NSMutableArray arrayWithObjects:[ESSHelper displayName:userSelected.displayName],nil];
        [choices addObject:FMCc];
    }
    
    NSNumber * CSID=[[NSNumber alloc] initWithInt:1111];
    [[SyncService sharedInstance] createInteractionChoiceSetPressedWithID:CSID choiceSet:choices];
    
}

#pragma mark - GroupChat

-(void)syncGroupChat{
    
    [[ESSMUCManager sharedInstance]  askForCreatedGroup:^(NSMutableArray *groupArray) {
        dispatch_async(dispatch_get_main_queue(), ^{
            groupsList = [NSMutableArray arrayWithArray:groupArray];
            NSLog(@"%@",groupsList);
        });
    }];
}

- (void)setUpChoiceSetForGroupList{
    
    NSMutableArray *choices = [[NSMutableArray alloc] init];
    NSInteger j=0;
    if ([groupsList count]!= 0) {
        for (j = 0 ; j < [groupsList count]; j++) {
            Room *room = [groupsList objectAtIndex:j];
            // XMPPUserCoreDataStorageObject * userSelected = [[[self fetchedResultsController] fetchedObjects] objectAtIndex:j];
            FMCChoice *FMCc = [[FMCChoice alloc] init];
            FMCc.menuName =room.name;
            FMCc.choiceID = [NSNumber numberWithInt: j];
            FMCc.vrCommands=[NSMutableArray arrayWithObjects:room.name,nil];
            [choices addObject:FMCc];
        }
        NSNumber * CSID=[[NSNumber alloc] initWithInt:2222];
        [[SyncService sharedInstance] createInteractionChoiceSetPressedWithID:CSID choiceSet:choices];
        syncVRStatus =  @"Groups";
    }
    else{
        NSMutableArray *option = [[NSMutableArray alloc] init];
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:@"New" forKey:@"Value"];
        [data setObject:@"5007" forKey:@"Index"];
        [option addObject:data];
        data = nil;
        data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Add Friend" forKey:@"Value"];
        [data setObject:@"5004" forKey:@"Index"];
        [option addObject:data];
        data = nil;
        data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Back" forKey:@"Value"];
        [data setObject:@"5005" forKey:@"Index"];
        [option addObject:data];
        /* [[SyncService sharedInstance] showPressed:@"SyncChat" WithSubMessage:@"GroupChat" andSoftButtons:nil];*/
        
        [[SyncService sharedInstance] speakPressed:@"You are not a member,  or ,  owener of,  any group ,  Please create group"];
    }
    
}


#pragma mark - Create Intraction Choice set Notification
- (void)onCreateInteractionChoiceSetResponseNotification:(NSNotification *)notify{
    if ([syncVRStatus isEqualToString:@"Friends"]){
        [self setupChoiceSetIntractionPerformer:@"Select Friend"
                                    initialText:@"Select Friend"
                                       helpText:@"Please select Friend"
                                    timeoutText:@"Try again Later"
                                       choiceID:1111];
    }
    if ([syncVRStatus isEqualToString:@"Groups"]){
        [self setupChoiceSetIntractionPerformer:@"Select Group"
                                    initialText:@"Select Group"
                                       helpText:@"Please select group"
                                    timeoutText:@"Try again Later"
                                       choiceID:2222];
    }
    if ([syncVRStatus isEqualToString:@"Add Friend"]){
        [self setupChoiceSetIntractionPerformer:@"Select Friend"
                                    initialText:@"Select Friend"
                                       helpText:@"Please select Friend"
                                    timeoutText:@"Try again Later"
                                       choiceID:1111];
    }
}


-(void)setupChoiceSetIntractionPerformer:(NSString *)initPrompt
                             initialText:(NSString *)initialText
                                helpText:(NSString *)helpText
                             timeoutText:(NSString *)timeoutText
                                choiceID:(int)choiceID1{
    
    NSArray *tempPrompt = [initPrompt componentsSeparatedByString:@","];
    NSMutableArray *initialPrompt = [[NSMutableArray alloc] init];
    for (int i = 0; i < [tempPrompt count]; i++) {
        [initialPrompt addObject:[FMCTTSChunkFactory buildTTSChunkForString:[tempPrompt objectAtIndex:i] type:[FMCSpeechCapabilities TEXT]]];
    }
    
    NSArray *tempHelp = [helpText componentsSeparatedByString:@","];
    NSMutableArray *helpChunks = [[NSMutableArray alloc] init];
    for (int i = 0; i < [tempHelp count]; i++) {
        [helpChunks addObject:[FMCTTSChunkFactory buildTTSChunkForString:[tempHelp objectAtIndex:i] type:[FMCSpeechCapabilities TEXT]]];
    }
    
    NSArray *tempTimeout = [timeoutText componentsSeparatedByString:@","];
    NSMutableArray *timeoutChunks = [[NSMutableArray alloc] init];
    for (int i = 0; i < [tempTimeout count]; i++) {
        [timeoutChunks addObject:[FMCTTSChunkFactory buildTTSChunkForString:[tempTimeout objectAtIndex:i] type:[FMCSpeechCapabilities TEXT]]];
    }
    
    FMCInteractionMode *im = [FMCInteractionMode BOTH];;
    
    
    NSNumber *duration = nil;
    float  timeout=10.000000;
    if (![timeoutText isEqualToString:@""]) {
        duration = [NSNumber numberWithDouble:(round(timeout)*1000)];
    }
    NSNumber *choiceID;
    if ([syncVRStatus isEqualToString:@"Friends"]|| [syncVRStatus isEqualToString:@"Add Friend"])  {
        choiceID  = [NSNumber numberWithInt:1111];
    }else{
        choiceID  = [NSNumber numberWithInt:2222];
    }
    
    [[SyncService sharedInstance]  performInteractionPressedwithInitialPrompt:initialPrompt
                                                                  initialText:initialText
                                                   interactionChoiceSetIDList:[NSArray arrayWithObject:choiceID]
                                                                   helpChunks:helpChunks
                                                                timeoutChunks:timeoutChunks
                                                              interactionMode:im
                                                                      timeout:duration
                                                                       vrHelp:nil];
}


#pragma mark - PerformIntraction Notifcation

-(void)onChoice:(NSNotification *)notify{
    
    FMCPerformInteractionResponse *response = [notify object];
    if ([syncVRStatus isEqualToString:@"Friends"]) {
        userSelectedOnChoice = [[[self fetchedResultsController] fetchedObjects] objectAtIndex:[response.choiceID intValue]];
        NSMutableArray *option = [[NSMutableArray alloc] init];
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Send" forKey:@"Value"];
        [data setObject:@"5003" forKey:@"Index"];
        [option addObject:data];
        data = nil;
        data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Back" forKey:@"Value"];
        [data setObject:@"5005" forKey:@"Index"];
        [option addObject:data];
        
        [[SyncService sharedInstance] showPressed:@"Chat with " WithSubMessage: [ESSHelper displayName:    userSelectedOnChoice.jidStr] andSoftButtons:option];
        [[SyncService sharedInstance] deleteInteractionChoiceSetPressedWithID:[NSNumber numberWithInt:1111]];
        isSentSelected = YES;
    }
    if ([syncVRStatus isEqualToString:@"Groups"]){
        reposeChoiceIDForGroup = [response.choiceID intValue];
        Room *roomObj = (Room *)[groupsList objectAtIndex:[response.choiceID intValue]];
        XMPPJID *roomJID = [XMPPJID jidWithString:roomObj.roomJID];
        [[ESSMUCManager sharedInstance] createRoomWithJid:roomJID] ;
        NSMutableArray *option = [[NSMutableArray alloc] init];
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Send" forKey:@"Value"];
        [data setObject:@"5003" forKey:@"Index"];
        [option addObject:data];
        data = nil;
        data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Add Friend" forKey:@"Value"];
        [data setObject:@"5004" forKey:@"Index"];
        //[option addObject:data];
        data = nil;
        data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Back" forKey:@"Value"];
        [data setObject:@"5005" forKey:@"Index"];
        [option addObject:data];
        [[SyncService sharedInstance] showPressed:@"SyncChat" WithSubMessage:@"GroupChat" andSoftButtons:option];
        [[SyncService sharedInstance] deleteInteractionChoiceSetPressedWithID:[NSNumber numberWithInt:2222]];
    }
    if ([syncVRStatus isEqualToString:@"Add Friend"]){
        NSMutableArray *option = [[NSMutableArray alloc] init];
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:@"Back" forKey:@"Value"];
        [data setObject:@"5005" forKey:@"Index"];
        [option addObject:data];
        [[SyncService sharedInstance] showPressed:[ESSHelper displayName:    userSelectedOnChoice.jidStr]  WithSubMessage: @"Invited for Group chat"  andSoftButtons:option];
        [self AddFriendToGroup:[response.choiceID intValue]];
    }
    
}

-(NSString *) getGroupJID{
    [self syncGroupChat];
    int count=0;
    for(int i=0;i<[groupsList count];i++)
    {
        Room *room = [groupsList objectAtIndex:i];
        if ([room.roomJID rangeOfString:@"sync_group"].location !=NSNotFound){
            count=count+1;
        }
    }
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // display in 12HR/24HR (i.e. 11:25PM or 23:25) format according to User Settings
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return [NSString stringWithFormat:@"SYNC_Group_%@",currentTime];
}

-(NSString *) getGroupName{
    [self syncGroupChat];
    int count=0;
    for(int i=0;i<[groupsList count];i++)
    {
        Room *room = [groupsList objectAtIndex:i];
        if ([room.name rangeOfString:@"SYNC Group"].location !=NSNotFound){
            count=count+1;
        }
    }
    return [NSString stringWithFormat:@"SYNC Group %d",count];
}


- (void)AddFriendToGroup:(int)index{
    
    xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
    XMPPUserCoreDataStorageObject *userSelected = [[[self fetchedResultsController] fetchedObjects] objectAtIndex:index];
    [[ESSMUCManager sharedInstance].currentRoom inviteUser:userSelected.jid withMessage:@"Please join my room."];
}



#pragma mark - Message  feature
- (void)send:(XMPPUserCoreDataStorageObject*)userSelected orJidString:(NSString *)jidString{
    
    if ( [syncVRStatus isEqualToString:@"Groups"] || [jidString rangeOfString:kxmppConferenceServer].length >0 || [userSelectedOnChoice.jidStr rangeOfString:kxmppConferenceServer].length >0) {
        [self sendMessageToGroup];
    }else if([syncVRStatus isEqualToString:@"Reply"] && [jidString rangeOfString:kxmppConferenceServer].length >0){
        [self sendMessageToGroup];
    }else if(userSelected !=nil || jidString != nil){
        [self sendMessageToIndividual:(userSelected !=nil)?userSelected.jidStr:jidString];
    }
    // We need to put our own message also in CoreData of course and reload the data
    NSError *error = nil;
    if (![[ESSHelper appDelegate].managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
}

#pragma mark - send Message to Individual

- (void)sendMessageToIndividual:(NSString *)jid{
    NSString *messageStr = @"Using Sync Chat";
    //send chat message
    if([messageStr length] > 0)
    {
        
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:messageStr];
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:jid];
        [message addChild:body];
        NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
        [message addChild:status];
        [[ESSHelper appDelegate].xmppStream sendElement:message];
        //[[SyncService sharedInstance]alertPressed:@"Message Sent"];
    }
}

#pragma mark - Send Message to Group
- (void)sendMessageToGroup{
    
    NSString *messageStr = @"Using Sync Chat.";
    //send chat message
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageStr];
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:[[ESSMUCManager sharedInstance].currentRoom2.myRoomJID full]];
    [message addChild:body];
    NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
    [message addChild:status];
    [[ESSMUCManager sharedInstance].currentRoom sendMessage:[XMPPMessage messageFromElement:message]];
    [[SyncService sharedInstance] deleteInteractionChoiceSetPressedWithID:[NSNumber numberWithInt:2222]];
    //[[SyncService sharedInstance]alertPressed:@"Message Sent"];
}

#pragma mark - Received Message Speak  out
-(void)syncNewMessageReceived:(NSNotification *)aNotification
{
    _chats =(Chat *) [aNotification object];
    [self showConversationForJIDString:_chats.jidString];
    NSMutableArray *option = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:@"Reply" forKey:@"Value"];
    [data setObject:@"5006" forKey:@"Index"];
    [option addObject:data];
    data = nil;
    data = [[NSMutableDictionary alloc] init];
    [data setObject:@"Back" forKey:@"Value"];
    [data setObject:@"5005" forKey:@"Index"];
    [option addObject:data];
    
    
    // syncVRStatus = @"Reply";
    if ([_chats.jidString rangeOfString:@"conference"].location != NSNotFound) {
        if (!isSentSelected)
            [[SyncService sharedInstance] showPressed:_chats.groupName WithSubMessage:_chats.senderName andSoftButtons:option];
        [[SyncService sharedInstance] speakPressed:[NSString stringWithFormat:@"message from %@, in group , %@ , %@",_chats.senderName,_chats.groupName, _chats.messageBody]];
        
    }else{
        if (!isSentSelected)
            [[SyncService sharedInstance] showPressed:@"Message from" WithSubMessage: [ESSHelper displayName:  _chats.jidString] andSoftButtons:option];
        [[SyncService sharedInstance] speakPressed:[NSString stringWithFormat:@"message from %@, %@",cleanName, _chats.messageBody]];
    }
}

#pragma mark - AudioPassThrogh

- (void)startTDKRecord{
    
    NSString *initialPrompt = @"Please Record Message";
    NSString *displayText1 =[ NSString stringWithFormat:@"Send message to"];
    NSString *displayText2 =( [[ESSHelper displayName:userSelectedOnChoice.displayName] length]!=0)?[ESSHelper displayName:userSelectedOnChoice.displayName] :@"user or group ";
    
    FMCSamplingRate *samplingRate = [FMCSamplingRate _8KHZ];
    
    NSNumber *duration = [NSNumber numberWithInteger:10000];
    
    FMCBitsPerSample *bits =  [FMCBitsPerSample _8_BIT];
    
    FMCAudioType *type = [FMCAudioType valueOf:@"PCM"];
    
    NSNumber *mute = [NSNumber numberWithBool:1];
    
    [[SyncService sharedInstance] performAudioPassThruPressedWithInitialPrompt:initialPrompt
                                                                  disPlayText1:displayText1
                                                                  disPlayText2:displayText2
                                                                  samplingRate:samplingRate
                                                                   maxDuration:duration
                                                                 bitsPerSample:bits
                                                                     audioType:type
                                                                     muteAudio:mute];
}
#pragma mark - receiveAudioResponse

- (void)receiveAudioResponse:(NSNotification *)obj{
    [[SyncService sharedInstance] alert:@"receiveAudioResponse"];
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsFolde = [folders objectAtIndex:0];
    NSString *filename = [documentsFolde stringByAppendingPathComponent:@"Recording.pcm"];
    [self doConvertAudio:filename];
    [self stopTDKRecord];
    if ([syncVRStatus isEqualToString:@"Send"]) {
        [self send:userSelectedOnChoice orJidString:nil];
    }else if ([syncVRStatus isEqualToString:@"Reply"]){
        [self send:nil orJidString:_chats.jidString];
    }
}


- (void)doConvertAudio:(NSString *)originalPath
{
    NSLog(@"转码开始");
    const char *m_fileName = [originalPath cStringUsingEncoding:NSASCIIStringEncoding];
    NSString*resultPath = [self getFileName];
    const char *m_tranName = [resultPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    @try {
        
        //wav头的结构如下所示：
        typedef   struct
        {
            char     fccID[4];
            unsigned   long      dwSize;
            char     fccType[4];
        }HEADER; //RIFF WAVE Chunk
        
        typedef   struct
        {
            char    fccID[4];
            unsigned   long  dwSize;
            unsigned   short    wFormatTag;
            unsigned   short    wChannels;
            unsigned   long     dwSamplesPerSec;
            unsigned   long     dwAvgBytesPerSec;
            unsigned   short    wBlockAlign;
            unsigned   short    uiBitsPerSample;
        }FMT; //Format Chunk
        
        typedef   struct
        {
            char    fccID[4];
            unsigned   long     dwSize;
        }DATA; //Data Chunk
        //以上是wav头文件
        
        //以下是为了建立.wav头而准备的变量
        HEADER  pcmHEADER;
        FMT  pcmFMT;
        DATA pcmDATA;
        //以上是为了建立.wav头而准备的变量
        
        unsigned   short   m_pcmData;                       //读入.pcm和写入文件.wav数据变量
        FILE   *fp,*fpCpy;
        
        if((fp=fopen(m_fileName,   "rb "))   ==   NULL)  //读取文件
        {
            printf( "打开pcm文件出错 \n");
            exit(0);
        }
        
        if((fpCpy=fopen(m_tranName,   "wb+ "))   ==   NULL)  //为转换建立一个新文件
        {
            printf( "创建wav文件出错\n ");
            exit(0);
        }
        
        //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
        strcpy(pcmHEADER.fccID, "RIFF");
        //pcmHEADER.dwsize==?
        strncpy(pcmHEADER.fccType, "WAVE", 4);
        fseek(fpCpy,sizeof(HEADER),1); //跳过HEADER的长度，以便下面继续写入wav文件的数据;
        //以上是创建wav头的HEADER;
        
        if(ferror(fpCpy))
        {
            printf( "error!\n ");
        }
        
        sampleString = @"16KHZ";//samplingRatePicker.fieldContentText.text;
        int sample;
        if ([sampleString isEqualToString:@"8KHZ"]) {
            sample = 8000;
        } else if ([sampleString isEqualToString:@"16KHZ"]) {
            sample = 16000;
        } else if ([sampleString isEqualToString:@"22KHZ"]) {
            sample = 22050;
        } else if ([sampleString isEqualToString:@"44KHZ"]) {
            sample = 44100;
        }
        
        bitString = @"8_BIT";//bitsPerSamplePicker.fieldContentText.text;
        int bit;
        if ([bitString isEqualToString:@"8_BIT"]) {
            bit = 8;
        } else if ([bitString isEqualToString:@"16_BIT"]) {
            bit = 16;
        }
        
        //以下是创建wav头的FMT;
        strcpy(pcmFMT.fccID, "fmt   ");
        pcmFMT.dwSize=16;
        pcmFMT.wFormatTag=1;
        pcmFMT.wChannels=1;
        pcmFMT.dwSamplesPerSec = sample;
        pcmFMT.dwAvgBytesPerSec=pcmFMT.dwSamplesPerSec*sizeof(m_pcmData);
        pcmFMT.wBlockAlign= 1;
        pcmFMT.uiBitsPerSample = bit;
        //以上是创建wav头的FMT;
        
        
        fwrite(&pcmFMT,sizeof(FMT),1,fpCpy); //将FMT写入.wav文件;
        //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
        strcpy(pcmDATA.fccID, "data ");
        //以上是创建wav头的DATA;
        
        pcmDATA.dwSize=0; //给pcmDATA.dwsize   0以便于下面给它赋值
        fseek(fpCpy,sizeof(DATA),1); //跳过DATA的长度，以便以后再写入wav头的DATA;
        fread(&m_pcmData,sizeof(unsigned   short),1,fp); //从.pcm中读入数据
        
        while(!feof(fp)) //在.pcm文件结束前将他的数据转化并赋给.wav;
        {
            
            pcmDATA.dwSize+=2; //计算数据的长度；每读入一个数据，长度就加1
            fwrite(&m_pcmData,sizeof(unsigned   short),1,fpCpy); //将数据写入.wav文件;
            fread(&m_pcmData,sizeof(unsigned   short),1,fp); //从.pcm中读入数据
        }
        
        fclose(fp); //关闭文件
        pcmHEADER.dwSize=44+pcmDATA.dwSize;   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
        rewind(fpCpy); //将fpCpy变为.wav的头，以便于写入HEADER和DATA;
        fwrite(&pcmHEADER,sizeof(HEADER),1,fpCpy); //写入HEADER
        fseek(fpCpy,sizeof(FMT),1); //跳过FMT,因为FMT已经写入
        fwrite(&pcmDATA,sizeof(DATA),1,fpCpy);   //写入DATA;
        fclose(fpCpy);   //关闭文件
        
        return;
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
}

- (NSString *)getFileName
{
    static int fileIndex = 1;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *result = nil;
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsFolde = [folders objectAtIndex:0];
    result = [documentsFolde stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_%@_%i.wav", @"16KHZ", @"16_BIT", dateString,fileIndex++]];
    //result = [documentsFolde stringByAppendingPathComponent:@"Againandagain.mp3"];
    return (result);
    
}
- (NSInteger) getFileSize:(NSString*) path
{
    NSFileManager * filemanager = [[NSFileManager alloc]init] ;
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) ){
            NSLog(@"result is %d",[theFileSize intValue]);
            return  [theFileSize intValue]/1024;
            
        }else{
            return -1;
        }
    }
    else
    {
        return -1;
    }
}


- (void)playMesasage{
    NSString *soundFilePath = [self getFileName] ;//[[NSBundle mainBundle] pathForResource:@"Againandagain" ofType: @"mp3"];
     // [[SyncService sharedInstance] alert:[self getFileName]];
     NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
     myAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
     myAudioPlayer.numberOfLoops = -1; //infinite loop
     [myAudioPlayer play];
    //[self playRecordedAudio];
}
- (IBAction)playSound:(id)sender{
    [self playRecordedAudio];
}
- (void)playRecordedAudio{
    
    
    [[SyncService sharedInstance] alert:[NSString stringWithFormat:@"%@%ld",[self getFileName],(long)[self getFileSize:[self getFileName]]]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getFileName]]) {
        
        NSError *error = nil;
        AVAudioPlayer * audioPath1 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:[self getFileName]] error:&error];
        if (!error) {
            [audioPath1 play];
        }
        else {
            
            NSLog(@"Error in creating audio player:%@",[error description]);
        }
    }
    else {
        
        NSLog(@"File doesn't exists");
    }
    
    [[SyncService sharedInstance] alert:@"Recorded Music Played"];
}
- (void)stopMusic
{
    
    [myAudioPlayer stop];
}


- (void)startMusic
{
    
    [myAudioPlayer play];
}

- (void)stopTDKRecord
{
    //结束TDKRecord
    [[SyncService sharedInstance] endAudioPassThruPressed];
}



@end
