//
//  FTPManager.h
//  SyncChat
//
//  Created by essadmin on 8/12/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <Foundation/Foundation.h>
#define DEF_FTP_IP			@"ftp://192.168.1.236"
//#define DEF_FTP_IP   @"http://182.73.73.181:92"
#define DEF_FTP_USR			@"Guest24"
#define DEF_FTP_PWD			@"123456"
#define DEF_FTP_FILEPATH    @"/SyncChat/iOS/"

@interface FTPManager : NSObject{
    NSString *downloadedFileName;
    
}

+ (FTPManager *)sharedInstance;
@property(nonatomic,strong)NSString *url;
@property(nonatomic,strong)NSString *status;
@property(nonatomic,strong)NSString *downloadedFileName;
- (void)sendAction:(NSString *)filePath;
- (void)getOrCancelAction:(NSString *)filePath;
- (BOOL)isReceiving;
@end
