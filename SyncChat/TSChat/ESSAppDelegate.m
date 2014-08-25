//
//  TSAppDelegate.m
//  TSChat
//
//  Created by essadmin on 5/1/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSAppDelegate.h"
#import "XMPPMessage+XEP0045.h"

//NSString *const kXMPPmyJID = @"kXMPPmyJID";
//NSString *const kXMPPmyPassword = @"kXMPPmyPassword";



@interface ESSAppDelegate()<XMPPStreamDelegate,XMPPMUCDelegate,XMPPRosterDelegate,UIAlertViewDelegate,YDFileReceiverDelegate>

{
    NSMutableArray *turnSockets;

}

@property (nonatomic,strong) XMPPMUC *xmppMUC;
@property (nonatomic,strong) XMPPRoomCoreDataStorage *xmppRoomCoreDataStore;
- (void)setupStream;
- (void)teardownStream;



@end




@implementation ESSAppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;


#pragma  mark  - XMMPPProtocolSetup
- (void)setupStream
{
	NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	_xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		_xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	_xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	_xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	_xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
	
	_xmppRoster.autoFetchRoster = YES;
	_xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	_xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	_xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
	
	_xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	_xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    _xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesStorage];
    
    _xmppCapabilities.autoFetchHashedCapabilities = YES;
    _xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    
    self.xmppRoomCoreDataStore = [XMPPRoomCoreDataStorage sharedInstance];
    self.xmppMUC = [[XMPPMUC alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    
	// Activate xmpp modules
    
	[_xmppReconnect         activate:_xmppStream];
	[_xmppRoster            activate:_xmppStream];
	[_xmppvCardTempModule   activate:_xmppStream];
	[_xmppvCardAvatarModule activate:_xmppStream];
	[_xmppCapabilities      activate:_xmppStream];
    [self.xmppMUC              activate:self.xmppStream];
	// Add ourself as a delegate to anything we may be interested in
    
	[_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppMUC addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    [_xmppStream setHostName:HostName];
    [_xmppStream setHostPort:5222];
	
    
	// You may need to alter these settings depending on the server you're connecting to
	customCertEvaluation = YES;
}
- (void)setupXMPPStream{
    _xmppStream = [[XMPPStream alloc] init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}
- (void)teardownStream
{
	[self.xmppStream removeDelegate:self];
	[self.xmppRoster removeDelegate:self];
    //ch.08
    [self.xmppMUC     removeDelegate:self];
	
	[self.xmppReconnect         deactivate];
	[self.xmppRoster            deactivate];
	[self.xmppvCardTempModule   deactivate];
	[self.xmppvCardAvatarModule deactivate];
	[self.xmppCapabilities      deactivate];
	//ch.08
    [self.xmppMUC     deactivate];
    
    
	[self.xmppStream disconnect];
	
	self.xmppStream = nil;
	self.xmppReconnect = nil;
    self.xmppRoster = nil;
	self.xmppRosterStorage = nil;
	self.xmppvCardStorage = nil;
    self.xmppvCardTempModule = nil;
	self.xmppvCardAvatarModule = nil;
	self.xmppCapabilities = nil;
	self.xmppCapabilitiesStorage = nil;
    //ch.08
    self.xmppMUC=nil;
}

- (void)goOnline{
    XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    NSString *domain = [_xmppStream.myJID domain];
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    if([domain isEqualToString:HostName])
    {
        NSLog(@"%@",[_xmppStream myJID]);
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
        NSLog(@"%@",priority);
    }
	
	[[self xmppStream] sendElement:presence];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"buddyList" object:nil];
    
}
- (void)goOffline{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [self.xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [self.xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark COREDATA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        [__managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        // subscribe to change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return __managedObjectContext;
}
//

- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (__managedObjectContext == savedContext)
    {
        return;
    }
    
    if (__managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator)
    {
        // that's another database
        return;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [__managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    });
}
//
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ChatModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YDChat.sqlite"];   NSError *error = nil;
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
        
    {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPConnection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect{
    NSLog(@"connect");
    return isConnet;
}
- (BOOL)connectUserName :(NSString *)usr andPassword:(NSString *)pwd{
    NSLog(@"connectUserName :(NSString *)usr andPassword:(NSString *)pwd");
    if (![_xmppStream isDisconnected]) {
        [AQActivityIndicator hideIndicator];
		return YES;
        [self showAlertWithMessage:@"Server is disconnected. Please restart the application"];
	}
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID] ;
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
	myJID = usr;//@"prem1@essadmins-macbook-pro.local/xmppframework";
	myPassword = pwd;//@"prem1230";
	
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    //[_xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    [self.xmppStream setMyJID:[XMPPJID jidWithString:myJID resource:@"iPhone"]];
    password = myPassword;
    NSError *error = nil;
    if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
        isConnet = NO;
		return NO;
	}else {
        isConnet = YES;
        return YES;
    }
    
}
- (void)disconnect{
    NSLog(@"disconnect");
    [self goOffline];
	[_xmppStream disconnect];
}

-(void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    NSLog(@"xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    NSLog(@"xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	NSString *expectedCertName = [_xmppStream.myJID domain];
	if (expectedCertName)
	{
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
	
	if (customCertEvaluation)
	{
		[settings setObject:@(YES) forKey:GCDAsyncSocketManuallyEvaluateTrust];
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    NSLog(@"xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(bgQueue, ^{
		
		SecTrustResultType result = kSecTrustResultDeny;
		OSStatus status = SecTrustEvaluate(trust, &result);
		
		if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
			completionHandler(YES);
		}
		else {
			completionHandler(NO);
		}
	});
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    NSLog(@"xmppStreamDidSecure:(XMPPStream *)sender");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"xmppStreamDidConnect:(XMPPStream *)sender");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
	
	NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:password error:&error])
	{
		DDLogError(@"Error authenticating: %@", error);
	}
}
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    NSLog(@"xmppStream:(XMPPStream *)sender didReceiveError:(id)error");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	[AQActivityIndicator hideIndicator];
	if (!isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
}
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"xmppStreamDidAuthenticate:(XMPPStream *)sender");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	[self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{

    NSLog(@"xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    //[ESSHelper showAlertWithTitle:@"Error" andMessage:@"User Not authenticated/not connected"];
    [AQActivityIndicator hideIndicator];
    NSError *err=nil;
     if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&err])
         NSLog(@"Connected");
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"%@", [iq description]);
    
    NSXMLElement *siRequest = [iq elementForName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    NSXMLElement *isByteStream = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/bytestreams"];
    NSXMLElement *fileNode= [siRequest elementForName:@"file" xmlns:@"http://jabber.org/protocol/si/profile/file-transfer"];
    
    if ([TURNSocket isNewStartTURNRequest:iq])
	{
		TURNSocket *turnSocket = [[TURNSocket alloc] initWithStream:sender incomingTURNRequest:iq];
		
		[turnSockets addObject:turnSocket];
		
		[turnSocket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		
		return YES;
	}
	if (self.isSending)
    {
      	return NO;
    }
	if (self.isSending && siRequest  )
    {
      	return NO;
    }
    if (siRequest && [iq isSetIQ] && !self.isReceiving)
    {
        NSString *fromjidString = [iq fromStr];
        NSArray *splitter1 = [fromjidString componentsSeparatedByString:@"/"];
        NSString* sendingJID = [splitter1 objectAtIndex:0];
		splitter1=nil;
        
        NSString* mimeType = [[siRequest attributeForName:@"mime-type"] stringValue];
        
        NSString* sendingIQ = [NSString stringWithFormat:@"%@",iq];
        
        NSString* fname = [[fileNode attributeForName:@"name"] stringValue ];
		//create target file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *extension = @"";
        NSString *mediaType = @"";
        NSArray *splitter = [mimeType componentsSeparatedByString:@"/"];
        if ([splitter count]==2)
        {
			extension = [splitter objectAtIndex:1];
			mediaType = [splitter objectAtIndex:0];
        }
        else
        {    extension = [fname pathExtension];
            if ([extension isEqualToString:@"m4a"])
            { mediaType = @"audio";}
            else   if ([extension isEqualToString:@"mp4"])
            { mediaType = @"video";}
            else   if ([extension isEqualToString:@"m4v"])
            { mediaType = @"video";}
            else   if ([extension isEqualToString:@"mp3"])
            { mediaType = @"audio";}
            else   if ([extension isEqualToString:@"3gp"])
            { mediaType = @"audio";}
            else   if ([extension isEqualToString:@"png"])
            { mediaType = @"image";}
            else   if ([extension isEqualToString:@"jpg"])
            { mediaType = @"image";}
            else   if ([extension isEqualToString:@"jpeg"])
            { mediaType = @"image";}
            else   if ([extension isEqualToString:@"gif"])
            {  mediaType = @"image";}
        }
		
        
        splitter=nil;
		NSString *filepath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,fname];
		paths=nil;
		long fileSize  = (long)[[[fileNode attributeForName:@"size"] stringValue ] longLongValue];
        
        self.fileInfo = [[ESSFileInfo alloc] initWithFileName:fname mediaType:mediaType mimeType:mimeType size:fileSize localName:filepath IQ:sendingIQ fileNameAsSent:@"" sender:sendingJID];
        
        self.streamID = [[siRequest attributeForName:@"id"] stringValue];
        self.transferID=[[iq attributeForName:@"id"] stringValue];
		NSString *fromJID = [iq fromStr];
        //step 2. we send our prefered stream-method as a response
        NSString *initiatorID = [[iq attributeForName:@"id"] stringValue];
        NSXMLElement *si= [NSXMLElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
        [si addAttributeWithName:@"id" stringValue:initiatorID];
        NSXMLElement *feature = [NSXMLElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
        NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        [x addAttributeWithName:@"type" stringValue:@"submit"];
        NSXMLElement *field =[NSXMLElement elementWithName:@"field"];
        [field addAttributeWithName:@"var"  stringValue:@"stream-method"];
        NSXMLElement *bs =[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"] ;
        [field addChild:bs];
        [x addChild:field];
        [feature addChild:x];
        [si addChild:feature];
        //Send
        
        self.isReceiving=YES;
        XMPPIQ *iqToReturn = [XMPPIQ iqWithType:@"result" to:[XMPPJID jidWithString:fromJID] elementID:initiatorID child:si];
        [self.xmppStream sendElement:iqToReturn];
        
        return NO;
    }
    else if (isByteStream && [iq isSetIQ] && self.isReceiving )
    {
        self.fileReceiver = [[ESSFileReceiver alloc] initWithStream:[self xmppStream] incomingRequest:iq];
        self.fileReceiver.streamID=self.streamID;
        self.fileReceiver.transferID= self.transferID;
        self.fileReceiver.fileInfo = self.fileInfo;
        [self.fileReceiver startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        return YES;
        
    }
	return NO;
}
#pragma mark FileReceiver delegates

- (void)fileReceiver:(ESSFileReceiver *)sender didSucceed:(ESSFileInfo *)fileInfo
{
    NSLog(@"fileReceiver:(ESSFileReceiver *)sender didSucceed:(ESSFileInfo *)fileInfo");
    
    Chat *chat = [NSEntityDescription
                  insertNewObjectForEntityForName:@"Chat"
                  inManagedObjectContext:self.managedObjectContext];
    chat.messageBody = @"file received";
    chat.messageDate = [NSDate date];
    chat.hasMedia=[NSNumber numberWithBool:YES];
    chat.isNew=[NSNumber numberWithBool:YES];
    chat.messageStatus=@"received";
    chat.direction = @"IN";
    chat.groupNumber=@"";
    chat.isGroupMessage=[NSNumber numberWithBool:NO];
    chat.jidString =  fileInfo.sendingJID;
    chat.localfileName = fileInfo.localFileName;
    chat.mimeType=_fileInfo.mimeType;
    chat.mediaType= fileInfo.mediaType;
    chat.filenameAsSent=fileInfo.filenameAsSent;
    NSError *error = nil;
    if (![self.managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    self.isReceiving=NO;
    self.fileReceiver = nil;
    //Send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessage object:self userInfo:nil];
}
-(void)fileReceiverDidFail:(ESSFileReceiver *)sender
{
    NSLog(@"fileReceiverDidFail:(ESSFileReceiver *)sender");
    DDLogError(@"ERROR fileReceiverDidFail");
    self.isReceiving=NO;
}

#pragma mark - ReceiveMessage
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message");
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	// A simple example of inbound message handling.
	if ([message isChatMessageWithBody] || [message isGroupChatMessageWithBody])
    {
        DDLogInfo(@"Save message in CoreData: %@", message);
		[self updateCoreDataWithIncomingMessage:message];
        
    }
    else if ([message isChatMessage])
    {
        NSArray *elements = [message elementsForXmlns:@"http://jabber.org/protocol/chatstates"];
        if ([elements count] >0)
        {
            for (NSXMLElement *element in elements)
            {
                NSString *statusString = @" ";
                NSString *cleanStatus = [element.name stringByReplacingOccurrencesOfString:@"cha:" withString:@""];
                if ([cleanStatus isEqualToString:@"composing"])
                    statusString = @" is typing";
                else if ([cleanStatus isEqualToString:@"active"])
                    statusString = @" is ready";
                else  if ([cleanStatus isEqualToString:@"paused"])
                    statusString = @" is pausing";
                else  if ([cleanStatus isEqualToString:@"inactive"])
                    statusString = @" is not active";
                else  if ([cleanStatus isEqualToString:@"gone"])
                    statusString = @" left this chat";
                NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
                [m setObject:statusString forKey:@"msg"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kChatStatus" object:self userInfo:m];
                
            }
        }
    }
}

-(void)updateCoreDataWithIncomingMessage:(XMPPMessage *)message
{
    NSLog(@"updateCoreDataWithIncomingMessage:(XMPPMessage *)message");
    //determine the sender
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self managedObjectContext_roster]];
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID] ;
	
    NSString * from =[message fromStr];
    
    
    
    NSArray * fromArray=[from componentsSeparatedByString:@"/"];
    if ([fromArray count]==2) {
        
        NSString * SenderName =[fromArray objectAtIndex:1];
        if(![SenderName isEqualToString:myJID]){
            Chat *chat = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Chat"
                          inManagedObjectContext:self.managedObjectContext];
            
            NSString *mesgStr = [[message elementForName:@"body"] stringValue];
            NSArray *strArr = [mesgStr componentsSeparatedByString:@"."];
            if ([strArr count]== 2) {
                chat.mediaType = [ESSHelper mediaType:mesgStr];
                chat.localfileName = mesgStr;
                chat.messageBody = @"";
                chat.isFileDownloaded =[NSNumber numberWithBool:NO];
                chat.hasMedia=[NSNumber numberWithBool:YES];
                
            }else {
                chat.messageBody = [[message elementForName:@"body"] stringValue];
                chat.hasMedia=[NSNumber numberWithBool:NO];
            }
            chat.messageDate = [NSDate date];
            chat.messageStatus=@"received";
            
            chat.direction = @"IN";
            
            chat.groupNumber=@"";
            chat.isNew = [NSNumber numberWithBool:YES];
            chat.senderName=SenderName;
            if ( [[message type] isEqualToString:@"chat"]) {
                chat.isGroupMessage=[NSNumber numberWithBool:NO];
                chat.jidString = user.jidStr ;
                chat.senderName = [ESSHelper userFromJid:user.jidStr];
                ;
            }else{
                chat.groupNumber=  [ESSMUCManager sharedInstance].currentRoom.roomJID.user ;
                chat.isGroupMessage=[NSNumber numberWithBool:YES];
                chat.jidString =[fromArray objectAtIndex:0];
                NSArray * confrence=  [from componentsSeparatedByString:@"_"];
                NSArray * confrence2=   [[confrence objectAtIndex:1] componentsSeparatedByString:@"@"];
                chat.groupName=[confrence2 objectAtIndex:0];
            }
            NSError *error = nil;
            if (![self.managedObjectContext save:&error])
            {
                NSLog(@"error saving");
            }
            if([((UINavigationController*)self.window.rootViewController).visibleViewController isKindOfClass:[ ESSSyncViewController class]])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageForSYNC object:chat userInfo:nil];
            }else{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessage object:self userInfo:nil];
            }
          }
        
    }else if ( [[message type] isEqualToString:@"chat"]){
        
        Chat *chat = [NSEntityDescription
                      insertNewObjectForEntityForName:@"Chat"
                      inManagedObjectContext:self.managedObjectContext];
        chat.messageBody = [[message elementForName:@"body"] stringValue];
        chat.messageDate = [NSDate date];
        chat.messageStatus=@"received";
        
        chat.direction = @"IN";
        
        chat.groupNumber=@"";
        chat.isNew = [NSNumber numberWithBool:YES];
        chat.hasMedia=[NSNumber numberWithBool:NO];
        if ( [[message type] isEqualToString:@"chat"]) {
            chat.isGroupMessage=[NSNumber numberWithBool:NO];
            chat.jidString = user.jidStr ;
        }else{
            chat.groupNumber=  [ESSMUCManager sharedInstance].currentRoom.roomJID.user ;
            chat.isGroupMessage=[NSNumber numberWithBool:YES];
            chat.jidString =  [ESSMUCManager sharedInstance].currentRoom.roomJID.full;
        }
        
        
        NSError *error = nil;
        if (![self.managedObjectContext save:&error])
        {
            NSLog(@"error saving");
        }
        if([((UINavigationController*)self.window.rootViewController).visibleViewController isKindOfClass:[ ESSSyncViewController class]])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageForSYNC object:chat userInfo:nil];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessage object:self userInfo:nil];
        }
    }
}



- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence");
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    NSString *presenceType = [NSString stringWithFormat:@"%@",presence.type];
    
    if  ([presenceType isEqualToString:@"subscribe"]) {
        
        [_xmppRoster acceptPresenceSubscriptionRequestFrom:[presence from] andAddToRoster:YES];
        
        //For reject button
        // [xmppRoster rejectPresenceSubscriptionRequestFrom:[tmpPresence from]];
        
        
    }
    
    
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
    NSLog(@"xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence");
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:[presence from]
                                                              xmppStream:_xmppStream
                                                    managedObjectContext:[self managedObjectContext_roster]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
	
	if (![displayName isEqualToString:jidStrBare])
	{
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
	
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	}
	else
	{
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
		
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRoomDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoomDidCreate:(XMPPRoom *)sender{
    NSLog(@"xmppRoomDidCreate:(XMPPRoom *)senderrm");
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender{
    NSLog(@"xmppRoomDidJoin:(XMPPRoom *)sender");
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm{
    NSLog(@"xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm");
    DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomJID.user);
    
    NSXMLElement *newConfig = [configForm copy];
    NSArray* fields = [newConfig elementsForName:@"field"];
    for (NSXMLElement *field in fields) {
        NSString *var = [field attributeStringValueForName:@"var"];
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"]) {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
        }
    }
    [sender configureRoomUsingOptions:newConfig];
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID{
    NSLog(@"xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID");
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}
- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitation:(XMPPMessage *)message{
    NSLog(@"didReceiveInvitation");
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

   [[ESSMUCManager sharedInstance] createRoomWithJid:roomJID] ;
     [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"GroupTableDataload" object:nil]];
    
}
#pragma mark MUC Delegate
- (void)xmppMUC:(XMPPMUC *)sender didReceiveRoomInvitation:(XMPPMessage *)message
{
    //isGroupChatInvite is defined in XMPPMessage+0045 category
/*    if ([message isGroupChatInvite])
    {
        NSString *roomJidString = [message fromStr];
#if USE_MEMORY_STORAGE
        xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
#elif USE_HYBRID_STORAGE
        xmppRoomStorage = [XMPPRoomCoreDataStorage sharedInstance];
#endif
        
        XMPPRoom *newRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppRoomStorage jid:[XMPPJID jidWithString:roomJidString]];
        [newRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [newRoom activate:[self xmppStream]];
        //Add it to CoreData
        Room  *room =[NSEntityDescription
                      insertNewObjectForEntityForName:@"Room"
                      inManagedObjectContext:self.managedObjectContext];
        room.roomJID = roomJidString;
        //clean the name
        NSString *roomName = [roomJidString stringByReplacingOccurrencesOfString:kxmppConferenceServer  withString:@""];
        roomName=[roomName stringByReplacingOccurrencesOfString:@"@" withString:@""];
        
        
        room.name = roomName;
        NSError *error = nil;
        if (![self.managedObjectContext save:&error])
        {
            NSLog(@"error saving");
        }
    }*/
}
- (void)xmppMUC:(XMPPMUC *)sender didReceiveRoomInvitationDecline:(XMPPMessage *)message
{
    DDLogInfo(@"%@: %@  %@", THIS_FILE, THIS_METHOD,message);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)sendInvitationToJID:(NSString *)_jid withNickName:(NSString *)_nickName
{
    
    [self.xmppRoster addUser:[XMPPJID jidWithString:_jid] withNickname:_nickName];
    [self.xmppRoster subscribePresenceToUser:[XMPPJID jidWithString:_jid]];
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[presence from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self managedObjectContext_roster]];
    DDLogVerbose(@"didReceivePresenceSubscriptionRequest from user %@ ", user.jidStr);
    [self.xmppRoster acceptPresenceSubscriptionRequestFrom:[presence from] andAddToRoster:YES];
}

#pragma  mark  -  Common Method

- (void)showAlertWithMessage:(NSString *)mesg{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:mesg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

#pragma  mark  -  Registration Delgate Method
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error{
    
    DDXMLElement *errorXML = [error elementForName:@"error"];
    NSString *errorCode  = [[errorXML attributeForName:@"code"] stringValue];
    
    NSString *regError = [NSString stringWithFormat:@"ERROR :- %@",error.description];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Registration Failed!" message:regError delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    if([errorCode isEqualToString:@"409"]){
        
        [alert setMessage:@"Username Already Exists!"];
    }   
    [alert show];
}
- (void)xmppStreamDidRegister:(XMPPStream *)sender{
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Registration" message:@"Registration Successful!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)connectViaXEP65:(XMPPJID *)jid
{
	if(jid == nil) return;
	
	DDLogInfo(@"Attempting TURN connection to %@", jid);
	
	TURNSocket *turnSocket = [[TURNSocket alloc] initWithStream:_xmppStream toJID:jid];
	
	[turnSockets addObject:turnSocket];
	
	[turnSocket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma  mark  -  AppLifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [self setupStream];
    [[SyncService sharedInstance]  setupProxy];
   // [[ESSMUCManager sharedInstance] removeData];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
#if TARGET_IPHONE_SIMULATOR
	DDLogError(@"The iPhone simulator does not process background network traffic. "
			   @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
	if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)])
	{
		[application setKeepAliveTimeout:600 handler:^{
			
			DDLogVerbose(@"KeepAliveHandler");
			
			// Do other keep alive stuff here.
		}];
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



@end
