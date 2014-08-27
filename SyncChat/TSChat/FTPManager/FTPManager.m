//
//  FTPManager.m
//  SyncChat
//
//  Created by essadmin on 8/12/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "FTPManager.h"
#include <CFNetwork/CFNetwork.h>
#import "NetworkManager.h"


enum {
    kSendBufferSize = 32768
};

// Properties that don't need to be seen by the outside world.
@interface FTPManager ()<NSStreamDelegate>


@property (nonatomic, assign, readonly ) BOOL              isSending;
@property (nonatomic, strong, readwrite) NSOutputStream *  networkStream;
@property (nonatomic, strong, readwrite) NSInputStream *   fileStream;
@property (nonatomic, assign, readonly ) uint8_t*          buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;



// Properties that don't need to be seen by the outside world.

@property (nonatomic, assign, readonly ) BOOL              isReceiving;
@property (nonatomic, strong, readwrite) NSInputStream *   networkStream1;
@property (nonatomic, copy,   readwrite) NSString *        filePath;
@property (nonatomic, strong, readwrite) NSOutputStream *  fileStream1;

@property (nonatomic, assign, readonly ) BOOL              isFileUploading;

@end

@implementation FTPManager

{
    uint8_t                     _buffer[kSendBufferSize];
}



+ (FTPManager *)sharedInstance
{
    static dispatch_once_t  onceToken;
    static FTPManager * sSharedInstance;
    
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[FTPManager alloc] init];
    });
    return sSharedInstance;
}


#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)sendDidStart
{
    self.status = @"Sending";
    //self.cancelButton.enabled = YES;
    //[self.activityIndicator startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}

- (void)updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    self.status = statusString;
}

- (void)sendDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        statusString = @"Put succeeded";
        NSLog(@"%@",statusString);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"uploadSucceeded" object:self.filePath];
    }else{[statusString isEqualToString:@"Stream open error"];
        self.status = statusString;
        //self.cancelButton.enabled = NO;
        //[self.activityIndicator stopAnimating];
        [ESSHelper showAlertWithTitle:@"Error" andMessage:@"File transfer fails."];
        [[NetworkManager sharedInstance] didStopNetworkOperation];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [AQActivityIndicator hideIndicator];
}


#pragma mark * Core transfer code For Upload File

// This is the code that actually does the networking.

// Because buffer is declared as an array, you have to use a custom getter.
// A synthesised getter doesn't compile.

- (uint8_t *)buffer
{
    return self->_buffer;
}

- (BOOL)isSending
{
    return (self.networkStream != nil);
}

- (void)startSend:(NSString *)filePath
{
    BOOL                    success;
    NSURL *                 url;
    
    assert(filePath != nil);
    assert([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    assert([filePath.pathExtension isEqual:@"png"]||
           [filePath.pathExtension isEqual:@"jpg"]||
           [filePath.pathExtension isEqual:@"mp3"]||
           [filePath.pathExtension isEqual:@"mp4"]||
           [filePath.pathExtension isEqual:@"m4v"]||
           [filePath.pathExtension isEqual:@"m4a"]);
    
    assert(self.networkStream == nil);      // don't tap send twice in a row!
    assert(self.fileStream == nil);         // ditto
    
    // First get and check the URL.
    self.filePath = filePath;
    
    url = [[NetworkManager sharedInstance] smartURLForString: [NSString stringWithFormat:@"%@%@",DEF_FTP_IP, DEF_FTP_FILEPATH]];
    success = (url != nil);
    
    if (success) {
        // Add the last part of the file name to the end of the URL to form the final
        // URL that we're going to put to.
        
        url = CFBridgingRelease(
                                CFURLCreateCopyAppendingPathComponent(NULL, (__bridge CFURLRef) url, (__bridge CFStringRef) [filePath lastPathComponent], false)
                                );
        success = (url != nil);
    }
    
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        NSLog (@"Invalid URL");
    } else {
        
        // Open a stream for the file we're going to send.  We do not open this stream;
        // NSURLConnection will do it for us.
        
        self.fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        assert(self.fileStream != nil);
        
        [self.fileStream open];
        
        // Open a CFFTPStream for the URL.
        
        self.networkStream = CFBridgingRelease(
                                               CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                               );
        assert(self.networkStream != nil);
        
        if ([DEF_FTP_USR length] != 0) {
            success = [self.networkStream setProperty:DEF_FTP_USR forKey:(id)kCFStreamPropertyFTPUserName];
            assert(success);
            success = [self.networkStream setProperty:DEF_FTP_PWD forKey:(id)kCFStreamPropertyFTPPassword];
            assert(success);
        }
        
        self.networkStream.delegate = self;
        [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream open];
        
        // Tell the UI we're sending.
        
        [self sendDidStart];
    }
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self sendDidStopWithStatus:statusString];
}

- (void)sendAction:(NSString *)filePath
{
    assert( [filePath isKindOfClass:[NSString class]] );
    
    if ( ! self.isSending ) {
        //NSString *  filePath;
        
        // User the tag on the UIButton to determine which image to send.
        
        //filePath = [[NSString alloc]initWithString:filePath];//[[NetworkManager sharedInstance] pathForTestImage:(NSUInteger) sender.tag];
        assert(filePath != nil);
        
        [self startSend:filePath];
        _isFileUploading = YES;
    }
}








// These methods are used by the core transfer code to update the UI.


- (void)getOrCancelAction:(NSString *)fileName
{
#pragma unused(fileName)
    _downloadedFileName = [[NSString alloc]initWithString:fileName];
    if (self.isReceiving) {
        [self stopReceiveWithStatus:@"Cancelled"];
    } else {
        [self startReceive:[NSString stringWithFormat:@"%@%@%@",DEF_FTP_IP,DEF_FTP_FILEPATH,fileName]];
    }
}

- (void)receiveDidStart
{
    // Clear the current image so that we get a nice visual cue if the receive fails.
    //self.imageView.image = [UIImage imageNamed:@"NoImage.png"];
    self.status = @"Receiving";
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //self.getOrCancelButton.title = @"Cancel";
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}


- (void)receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        assert(self.filePath != nil);
        //self.imageView.image = [UIImage imageWithContentsOfFile:self.filePath];
        statusString = @"GET succeeded";
        NSLog(@"%@File Path%@   ",statusString,self.filePath);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadSucceeded" object:self.filePath];
    }
    else
    {
        self.status = statusString;
        //self.getOrCancelButton.title = @"Get";
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [AQActivityIndicator hideIndicator];
        [[NetworkManager sharedInstance] didStopNetworkOperation];
        
        [ESSHelper showAlertWithTitle:@"Error" andMessage:self.status];
        
    }
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

- (BOOL)isReceiving
{
    return (self.networkStream != nil);
}

- (void)startReceive:(NSString *)filePath
// Starts a connection to download the current URL.
{
    BOOL                success;
    NSURL *             url;
    
    assert(self.networkStream1 == nil);      // don't tap receive twice in a row!
    assert(self.fileStream1 == nil);         // ditto
    assert(self.filePath == nil);           // ditto
    
    // First get and check the URL.
    
    url = [[NetworkManager sharedInstance] smartURLForString:filePath];
    success = (url != nil);
    
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        self.status = @"Invalid URL";
    } else {
        
        // Open a stream for the file we're going to receive into.
        
        self.filePath = [[NetworkManager sharedInstance] pathForTemporaryFileWithPrefix:[NSString stringWithFormat:@"%@",_downloadedFileName]];
        assert(self.filePath != nil);
        
        self.fileStream1 = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
        assert(self.fileStream1 != nil);
        
        [self.fileStream1 open];
        
        // Open a CFFTPStream for the URL.
        
        self.networkStream1 = CFBridgingRelease(
                                                CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                                );
        assert(self.networkStream1 != nil);
        
        if ([DEF_FTP_USR length] != 0) {
            success = [self.networkStream1 setProperty:DEF_FTP_USR forKey:(id)kCFStreamPropertyFTPUserName];
            assert(success);
            success = [self.networkStream1 setProperty:DEF_FTP_PWD forKey:(id)kCFStreamPropertyFTPPassword];
            assert(success);
        }
        
        
        self.networkStream1.delegate = self;
        [self.networkStream1 scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream1 open];
        
        // Tell the UI we're receiving.
        
        [self receiveDidStart];
    }
}

- (void)stopReceiveWithStatus:(NSString *)statusString
// Shuts down the connection and displays the result (statusString == nil)
// or the error status (otherwise).
{
    if (self.networkStream1 != nil) {
        [self.networkStream1 removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream1.delegate = nil;
        [self.networkStream1 close];
        self.networkStream1 = nil;
    }
    if (self.fileStream1 != nil) {
        [self.fileStream1 close];
        self.fileStream1 = nil;
    }
    [self receiveDidStopWithStatus:statusString];
    self.filePath = nil;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
    
    
    if (_isFileUploading) {
#pragma unused(aStream)
        assert(aStream == self.networkStream);
        
        switch (eventCode) {
            case NSStreamEventOpenCompleted: {
                [self updateStatus:@"Opened connection"];
            } break;
            case NSStreamEventHasBytesAvailable: {
                assert(NO);     // should never happen for the output stream
            } break;
            case NSStreamEventHasSpaceAvailable: {
                [self updateStatus:@"Sending"];
                
                // If we don't have any data buffered, go read the next chunk of data.
                
                if (self.bufferOffset == self.bufferLimit) {
                    NSInteger   bytesRead;
                    
                    bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
                    
                    if (bytesRead == -1) {
                        [self stopSendWithStatus:@"File read error"];
                    } else if (bytesRead == 0) {
                        [self stopSendWithStatus:nil];
                    } else {
                        self.bufferOffset = 0;
                        self.bufferLimit  = bytesRead;
                    }
                }
                
                // If we're not out of data completely, send the next chunk.
                
                if (self.bufferOffset != self.bufferLimit) {
                    NSInteger   bytesWritten;
                    bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        [self stopSendWithStatus:@"Network write error"];
                    } else {
                        self.bufferOffset += bytesWritten;
                    }
                }
            } break;
            case NSStreamEventErrorOccurred: {
                [self stopSendWithStatus:@"Stream open error"];
            } break;
            case NSStreamEventEndEncountered: {
                // ignore
            } break;
            default: {
                assert(NO);
            } break;
        }
    }
    else{
#pragma unused(aStream)
        assert(aStream == self.networkStream1);
        
        switch (eventCode) {
            case NSStreamEventOpenCompleted: {
                [self updateStatus:@"Opened connection"];
            } break;
            case NSStreamEventHasBytesAvailable: {
                NSInteger       bytesRead;
                uint8_t         buffer[32768];
                
                [self updateStatus:@"Receiving"];
                
                // Pull some data off the network.
                
                bytesRead = [self.networkStream1 read:buffer maxLength:sizeof(buffer)];
                if (bytesRead == -1) {
                    [self stopReceiveWithStatus:@"Network read error"];
                } else if (bytesRead == 0) {
                    [self stopReceiveWithStatus:nil];
                } else {
                    NSInteger   bytesWritten;
                    NSInteger   bytesWrittenSoFar;
                    
                    // Write to the file.
                    
                    bytesWrittenSoFar = 0;
                    do {
                        bytesWritten = [self.fileStream1 write:&buffer[bytesWrittenSoFar] maxLength:(NSUInteger) (bytesRead - bytesWrittenSoFar)];
                        assert(bytesWritten != 0);
                        if (bytesWritten == -1) {
                            [self stopReceiveWithStatus:@"File write error"];
                            break;
                        } else {
                            bytesWrittenSoFar += bytesWritten;
                        }
                    } while (bytesWrittenSoFar != bytesRead);
                }
            } break;
            case NSStreamEventHasSpaceAvailable: {
                assert(NO);     // should never happen for the output stream
            } break;
            case NSStreamEventErrorOccurred: {
                [self stopReceiveWithStatus:@"Stream open error"];
            } break;
            case NSStreamEventEndEncountered: {
                // ignore
            } break;
            default: {
                assert(NO);
            } break;
        }
    }
}

@end
