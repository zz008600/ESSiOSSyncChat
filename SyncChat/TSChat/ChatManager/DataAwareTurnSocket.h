//
//  DataAwareTurnSocket.h
//  SyncChat
//
//  Created by essadmin on 8/7/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "TURNSocket.h"

@interface DataAwareTurnSocket : TURNSocket{
    NSData *dataToSend;
}

@property (nonatomic, readwrite) NSData *dataToSend;
+(DataAwareTurnSocket *)sharedInstance;
- (void)sendToOtherDevice:(NSData *)fileData receiverJid:(NSString *)receiverJid;

@end
