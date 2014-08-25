//
//  DataAwareTurnSocket.m
//  SyncChat
//
//  Created by essadmin on 8/7/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "DataAwareTurnSocket.h"


@implementation DataAwareTurnSocket
@synthesize  dataToSend;

static DataAwareTurnSocket *sInstance = NULL;

+(DataAwareTurnSocket *)sharedInstance{
    
    @synchronized(self)
	{
		if (sInstance == NULL)
			sInstance = [[self alloc] init];
	}
	return sInstance;
}


- (void)sendToOtherDevice:(NSData *)fileData receiverJid:(NSString *)receiverJid {
    
   /* if ([[XMPPJID jidWithString:receiverJid].domain isEqualToString:([ESSHelper xmppStream]).myJID.domain]) {
        
        NSLog(@"Receiver JID : %@",[NSArray arrayWithObjects:[XMPPJID jidWithString:receiverJid].domain,nil]);
        [TURNSocket setProxyCandidates:[NSArray arrayWithObjects:[XMPPJID jidWithString:receiverJid].domain, nil]];
    } else {
        [TURNSocket setProxyCandidates:[NSArray arrayWithObjects:[XMPPJID jidWithString:receiverJid].domain, ([ESSHelper xmppStream]).myJID.domain, nil]];
    }
    DataAwareTurnSocket *socket = [[DataAwareTurnSocket alloc] initWithStream:[ESSHelper xmppStream] toJID:[XMPPJID jidWithString:receiverJid resource:@"Spark 2.6.3"]];
    [socket setDataToSend:fileData];
    [socket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];*/
    
    
   
    
    //NSString *s = [NSString stringWithFormat:@"%@/spark",receiverJid];
    NSString *jabbarID = [[[[ESSHelper appDelegate] xmppStream] myJID] bare];
    XMPPJID *senderjid = [XMPPJID jidWithString:jabbarID];
    
    //[TURNSocket setProxyCandidates:[NSArray arrayWithObjects:s, nil]];
    // [TURNSocket setProxyCandidates:[NSArray arrayWithObjects:s,jabbarID, nil]];
    
    [TURNSocket setProxyCandidates:[NSArray arrayWithObjects:[XMPPJID jidWithString:receiverJid resource:@"Spark 2.6.3"].domain,senderjid.domain, nil]];
    
    // [TURNSocket setProxyCandidates:[NSArray arrayWithObjects:jid.domain, nil]];
    //[TURNSocket setProxyCandidates:[NSArray arrayWithObjects:@"111.11.111.111", nil]];
    
    TURNSocket *socket1 = [[TURNSocket alloc] initWithStream:[ESSHelper xmppStream] toJID:[XMPPJID jidWithString:receiverJid resource:@"Spark 2.6.3"]];
    
    // [turnSockets addObject:turnSocket];
    [socket1 startWithDelegate:self delegateQueue:dispatch_get_main_queue()];

}

- (void)turnSocket:(DataAwareTurnSocket *)sender didSucceed:(GCDAsyncSocket *)socket {
    [socket writeData:sender.dataToSend withTimeout:60.0f tag:0];
    [socket disconnectAfterWriting];
}

- (void)turnSocketDidFail:(TURNSocket *)sender {
    NSLog(@"Couldn't set up bytestream for file transfer!");
}

@end
