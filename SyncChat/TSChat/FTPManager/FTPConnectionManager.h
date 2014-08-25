//
//  FTPConnectionManager.h
//  Pencil Sell
//
//  Created by Abhisek Mallik on 14/06/12.
//  Copyright (c) 2012 Aequor Information Technology Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WhiteRaccoon.h"
/*
#define DEF_FTP_IP			@"ftp.aequortechnologies.com"
#define DEF_FTP_USR			@"appdata@aequortechnologies.com"
#define DEF_FTP_PWD			@"Aequor377"
*/

#define DEF_FTP_IP			@"ftp://192.168.1.236"
#define DEF_FTP_USR			@"Guest24"
#define DEF_FTP_PWD			@"123456"

@class FTPConnectionManager;

@protocol FTPConnectionManagerDelegate <NSObject>
@required
- (void)connection:(FTPConnectionManager *)connection didFinishWithSuccess:(id)response;
- (void)connection:(FTPConnectionManager *)connection didFinishWithError:(id)response;

@end

@interface FTPConnectionManager : NSObject <WRRequestDelegate>

- (id)initWithTarget:(id <FTPConnectionManagerDelegate>)target;

- (void)downloadFileAtPath:(NSString *)_filePath;
- (void)uploadLocalFilePath:(NSString *)_localFilePath AtFTPServerPath:(NSString *)_filePath;

@end
