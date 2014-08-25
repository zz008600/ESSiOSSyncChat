//
//  YDFileInfo.m
//  YDChat
//
//  Created by Peter van de Put on 16/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import "ESSFileInfo.h"

@interface ESSFileInfo()

@property(nonatomic,strong) NSString *fileName;
@property(nonatomic,strong) NSString *mediaType;
@property(nonatomic,strong) NSString *mimeType;
@property(nonatomic,assign) long fileSize;
@property(nonatomic,strong) NSString *localFileName;
@property(nonatomic,strong) NSString *originatingIQ;
@property(nonatomic,strong) NSString *filenameAsSent;
@property(nonatomic,strong) NSString *sendingJID;

@end
@implementation ESSFileInfo

-(id)initWithFileName:(NSString *)filename mediaType:(NSString *)mediatype mimeType:(NSString *)mimetype size:(long)fsize localName:(NSString *)localfilename IQ:(NSString *)iq fileNameAsSent:(NSString *)filenameassent sender:(NSString *)sendingjid
{
    self = [super init];
	if ( self != nil)
        {
        self.fileName=filename;
        self.mediaType=mediatype;
        self.mimeType=mimetype;
        self.fileSize=fsize;
        self.localFileName=localfilename;
        self.originatingIQ=iq;
        self.filenameAsSent=filenameassent;
        self.sendingJID=sendingjid;
        }
	return self;
}

@end
