//
//  YDFileReceiver.h
//  YDChat
//
//  Created by Peter van de Put on 16/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XMPPIQ;
@class XMPPJID;
@class XMPPStream;
@class GCDAsyncSocket;

#import "ESSFileInfo.h"
@interface ESSFileSender : NSObject

{
	int state;
	BOOL isClient;
	
	dispatch_queue_t turnQueue;
	
	XMPPStream *xmppStream;
	XMPPJID *jid;
	NSString *uuid;
	
	id delegate;
	dispatch_queue_t delegateQueue;
	
	dispatch_source_t turnTimer;
	
	NSString *discoUUID;
	dispatch_source_t discoTimer;
	
	NSArray *proxyCandidates;
	NSUInteger proxyCandidateIndex;
	
	NSMutableArray *candidateJIDs;
	NSUInteger candidateJIDIndex;
	
	NSMutableArray *streamhosts;
	NSUInteger streamhostIndex;
	
	XMPPJID *proxyJID;
	NSString *proxyHost;
	UInt16 proxyPort;
	
	GCDAsyncSocket *asyncSocket;
	
	NSDate *startTime, *finishTime;
      
    BOOL isSending;
    
}
@property(nonatomic,retain)  ESSFileInfo *fileInfo;
@property(nonatomic,retain)  NSString *transferID;
@property(nonatomic,retain)  NSString *streamID;


+ (NSArray *)proxyCandidates;
+ (void)setProxyCandidates:(NSArray *)candidates;


- (id)initWithStream:(XMPPStream *)xmppStream toJID:(XMPPJID *)jid;


- (void)startWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)aDelegateQueue;

- (BOOL)isClient;

- (void)abort;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol YDFileSenderDelegate
@optional

- (void)fileSender:(ESSFileSender *)sender didSucceedWithSocket:(GCDAsyncSocket *)socket;

- (void)fileSenderDidFail:(ESSFileSender *)sender;

@end
