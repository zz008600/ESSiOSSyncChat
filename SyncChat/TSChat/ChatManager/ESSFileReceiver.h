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
@interface ESSFileReceiver : NSObject

{
	int state;

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
    NSString *transferID;
    NSString *streamID;
    
}
@property(nonatomic,retain)  ESSFileInfo *fileInfo;
@property(nonatomic,retain)  NSString *transferID;
@property(nonatomic,retain)  NSString *streamID;


+ (NSArray *)proxyCandidates;
+ (void)setProxyCandidates:(NSArray *)candidates;

- (id)initWithStream:(XMPPStream *)xmppStream incomingRequest:(XMPPIQ *)iq;
- (void)startWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)aDelegateQueue;
- (void)abort;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol YDFileReceiverDelegate
@optional
- (void)fileReceiver:(ESSFileReceiver *)sender didSucceed:(ESSFileInfo *)fileInfo ;
- (void)fileReceiverDidFail:(ESSFileReceiver *)sender;
@end
