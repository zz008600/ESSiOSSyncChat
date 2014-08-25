//
//  TSSynChatFileManager.m
//  SyncChat
//
//  Created by essadmin on 6/11/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSSynChatFileManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ESSSynChatFileManager

static ESSSynChatFileManager *gInstance = NULL;



+(ESSSynChatFileManager *)sharedInstance{
    @synchronized(self)
	{
		if (gInstance == NULL)
			gInstance = [[self alloc] init];
        
	}
	return gInstance;
}

#pragma mark image helper

-(NSString *)generateIDWithPrefix:(NSString *)_prefix
{
    int x = arc4random() % 10000;
    return [NSString stringWithFormat:@"%@%i",_prefix,x ];
}
- (void)sendFile:(NSString *)fileName withJid:(NSString *)jidStr
{
    
    [[ESSHelper xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    fileNameToBeUploaded = fileName;
    filesendingInProgress = NO;
    NSString *filePath = fileName;
    CFStringRef fileExtension = (__bridge CFStringRef)[filePath pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    NSString *MIMETypeString = (__bridge_transfer NSString *)MIMEType;
    NSString *URL = fileName;
    
    NSError *AttributesError = nil;
    NSDictionary *FileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:URL error:&AttributesError];
    NSNumber *FileSizeNumber = [FileAttributes objectForKey:NSFileSize];
    //NSArray *splitter = [MIMETypeString componentsSeparatedByString:@"/"];
    //NSString *extension = [splitter objectAtIndex:1];
    NSString *mediaType = @"image";
    long FileSize = [FileSizeNumber longValue];
    
    //create message
    self.streamID=[self generateIDWithPrefix:@"ip_"];
    self.requestID = [self generateIDWithPrefix:@"jsi_"];
    NSXMLElement *si= [NSXMLElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    [si addAttributeWithName:@"id" stringValue:self.streamID];
    
    [si addAttributeWithName:@"mime-type" stringValue:MIMETypeString];
    [si addAttributeWithName:@"profile" stringValue:@"http://jabber.org/protocol/si/profile/file-transfer"];
    
    NSXMLElement *fileElement = [NSXMLElement elementWithName:@"file" xmlns:@"http://jabber.org/protocol/si/profile/file-transfer"];
    
    [fileElement addAttributeWithName:@"name" stringValue:[fileNameToBeUploaded lastPathComponent]];
    [fileElement addAttributeWithName:@"size" stringValue:[NSString stringWithFormat:@"%ld",FileSize]];
    [fileElement addAttributeWithName:@"desc" stringValue:@""];
    [si addChild:fileElement];
    NSXMLElement *feature = [NSXMLElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"form"];
    
    NSXMLElement *field =[NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"type" stringValue:@"list-single"];
    [field addAttributeWithName:@"var"  stringValue:@"stream-method"];
    
    NSXMLElement *option = [NSXMLElement elementWithName:@"option" ] ;
    NSXMLElement *bs =[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"] ;
    [option addChild:bs];
    [field addChild:option];
    [x addChild:field];
    [feature addChild:x];
    [si addChild:feature];
    XMPPJID *toJid = [XMPPJID jidWithString:jidStr resource:@"iPhone"];
    XMPPIQ *iqtoSend=[XMPPIQ iqWithType:@"set" to:toJid elementID:self.requestID child:si];
    //Clear your object
    if (self.fileInfo)
        self.fileInfo=nil;
    
    self.fileInfo = [[ESSFileInfo alloc] initWithFileName:fileNameToBeUploaded mediaType:mediaType mimeType:MIMETypeString size:FileSize localName:fileNameToBeUploaded IQ:[NSString stringWithFormat:@"%@",iqtoSend] fileNameAsSent:fileNameToBeUploaded sender:@""];
    
    
    //send the Stanza
    [ESSHelper appDelegate].isSending=YES;
    [[ESSHelper xmppStream] sendElement:iqtoSend];
}
#pragma mark FileSender delegates
- (void)fileSender:(ESSFileSender *)sender didSucceedWithSocket:(GCDAsyncSocket *)socket
{
    NSLog(@"localfileName %@",self.fileInfo.localFileName);
    NSData *dataToSend = [NSData dataWithContentsOfFile:self.fileInfo.localFileName];
    if (dataToSend!=nil)
    {
        [socket writeData:dataToSend withTimeout:-1 tag:-898];
        [socket disconnectAfterWriting];
        filesendingInProgress=NO;
        
    }
    Chat *chat = [NSEntityDescription
                  insertNewObjectForEntityForName:@"Chat"
                  inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
    chat.messageBody = @"file sent";
    chat.messageDate = [NSDate date];
    chat.hasMedia=[NSNumber numberWithBool:YES];
    chat.isNew=[NSNumber numberWithBool:NO];
    chat.messageStatus=@"sent";
    chat.direction = @"OUT";
    chat.groupNumber=@"";
    chat.isGroupMessage=[NSNumber numberWithBool:NO];
    chat.jidString =  self.conversationJidString;
    chat.localfileName = self.fileInfo.localFileName;
    chat.mimeType=_fileInfo.mimeType;
    chat.mediaType= @"image";
    chat.filenameAsSent=self.fileInfo.filenameAsSent;
    NSError *error = nil;
    if (![[ESSHelper appDelegate].managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    [ESSHelper appDelegate].isSending=NO;
    self.fileInfo=nil;
   // [self loadData];
     [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"GroupTableDataload" object:nil]];
     [[ESSHelper xmppStream] removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)fileSenderDidFail:(ESSFileSender *)sender
{
    [ESSHelper appDelegate].isSending=NO;
    NSLog(@"FAIL");
     [[ESSHelper xmppStream] removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark sending a file
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    
    
    NSXMLElement *siRequest = [iq elementForName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    NSXMLElement *errorElement = [iq elementForName:@"error"];
    NSXMLElement *unAvailableElement = [errorElement elementForName:@"service-unavailable" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas" ] ;
    
    if ([iq isErrorIQ] )
    {
        if (errorElement && unAvailableElement)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:@"Service unavailable." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            [ESSHelper appDelegate].isSending=NO;
            [[ESSHelper xmppStream] removeDelegate:self delegateQueue:dispatch_get_main_queue()];
            
        }
        filesendingInProgress=NO;
        return NO;
    }
    if (siRequest && !filesendingInProgress)
    {
        
        XMPPJID *toJid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@/iPhone",self.conversationJidString ]];
        if (self.fileSender)
            self.fileSender=nil;
        
        self.fileSender = [[ESSFileSender alloc] initWithStream:[ESSHelper xmppStream]  toJID:toJid];
        self.fileSender.streamID=self.streamID;
        self.fileSender.transferID=self.requestID;
        self.fileSender.fileInfo=self.fileInfo;
        [self.fileSender startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        filesendingInProgress=YES;
        [ESSHelper appDelegate].isSending=YES;
        return NO;
    }
    
    return NO;
}



@end
