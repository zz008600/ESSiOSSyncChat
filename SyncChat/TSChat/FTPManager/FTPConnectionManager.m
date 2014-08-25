//
//  FTPConnectionManager.m
//  Pencil Sell
//
//  Created by Abhisek Mallik on 14/06/12.
//  Copyright (c) 2012 Aequor Information Technology Pvt. Ltd. All rights reserved.
//

#import "FTPConnectionManager.h"

@interface FTPConnectionManager ()

@property (nonatomic, strong) id <FTPConnectionManagerDelegate> delegate;
@property (nonatomic, strong) WRRequestDownload *downloadFile;
@property (nonatomic, strong) WRRequestUpload * uploadFile;

@end

@implementation FTPConnectionManager

@synthesize delegate;
@synthesize downloadFile;
@synthesize uploadFile;

- (id)initWithTarget:(id <FTPConnectionManagerDelegate>)target
{
    self = [super init];
    if (self) 
    {
        self.delegate = target;
    }
    return self;
}


#pragma mark - Download File
- (void)downloadFileAtPath:(NSString *)_filePath
{
    self.downloadFile = [[WRRequestDownload alloc] init];
    self.downloadFile.delegate = self;
    self.downloadFile.path = _filePath;
    self.downloadFile.hostname = DEF_FTP_IP;
    self.downloadFile.username = DEF_FTP_USR;
    self.downloadFile.password = DEF_FTP_PWD;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.downloadFile start];
}

#pragma mark - Download File
- (void)uploadLocalFilePath:(NSString *)_localFilePath AtFTPServerPath:(NSString *)_filePath
{
    self.uploadFile = [[WRRequestUpload alloc] init];
    self.uploadFile.delegate = self;
    
    //for anonymous login just leave the username and password nil
    self.uploadFile.hostname = DEF_FTP_IP;
    self.uploadFile.username = DEF_FTP_USR;
    self.uploadFile.password = DEF_FTP_PWD;
    
    //we set our data
    NSData *data = [NSData dataWithContentsOfFile:_localFilePath];
    
    if (data)
        self.uploadFile.sentData = data;
    
    //the path needs to be absolute to the FTP root folder.
    //full URL would be ftp://xxx.xxx.xxx.xxx/space.jpg
    self.uploadFile.path = _filePath;
    
    //we start the request    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.uploadFile start];
}


#pragma mark - WRRequestDelegate Callbacks -
-(void) requestCompleted:(WRRequest *) request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([request isEqual:self.downloadFile]) 
    {
        if ([self.delegate respondsToSelector:@selector(connection:didFinishWithSuccess:)]) 
        {
            WRRequestDownload *_download = (WRRequestDownload *)request;
            [self.delegate connection:self didFinishWithSuccess:_download.receivedData];
        }
    }
}

-(void) requestFailed:(WRRequest *) request
{
//#pragma unused(request)
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([self.delegate respondsToSelector:@selector(connection:didFinishWithError:)]) 
    {
        [self.delegate connection:self didFinishWithError:request.error];
    }
}

-(BOOL) shouldOverwriteFileWithRequest: (WRRequest *) request
{
#pragma unused(request)
    return YES;
}

@end
