//
//  YDFileInfo.h
//  YDChat
//
//  Created by Peter van de Put on 16/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESSFileInfo : NSObject
@property(nonatomic,readonly) NSString *fileName;
@property(nonatomic,readonly) NSString *mediaType;
@property(nonatomic,readonly) NSString *mimeType;
@property(nonatomic,readonly) long fileSize;
@property(nonatomic,readonly) NSString *localFileName;
@property(nonatomic,readonly) NSString *originatingIQ;
@property(nonatomic,readonly) NSString *filenameAsSent;
@property(nonatomic,readonly) NSString *sendingJID;

-(id)initWithFileName:(NSString *)filename mediaType:(NSString *)mediatype mimeType:(NSString *)mimetype size:(long)fsize localName:(NSString *)localfilename IQ:(NSString *)iq fileNameAsSent:(NSString *)filenameassent sender:(NSString *)sendingjid;
@end
