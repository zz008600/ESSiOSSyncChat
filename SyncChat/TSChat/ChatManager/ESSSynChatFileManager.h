//
//  TSSynChatFileManager.h
//  SyncChat
//
//  Created by essadmin on 6/11/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESSFileInfo.h"
#import "ESSFileSender.h"
#import "ESSHelper.h"

@interface ESSSynChatFileManager : NSObject<UIImagePickerControllerDelegate,XMPPStreamDelegate,YDFileSenderDelegate>{
    UIImagePickerController *picturePicker;
    NSString *fileNameToBeUploaded;
    BOOL filesendingInProgress;
}

@property (nonatomic,strong) ESSFileSender *fileSender;
@property (nonatomic,strong) ESSFileInfo *fileInfo;
@property (nonatomic,strong) NSString *conversationJidString;
@property (nonatomic,strong) NSString *requestID;
@property (nonatomic,strong) NSString *streamID;

+(ESSSynChatFileManager *)sharedInstance;
- (void)filePickerAlbum;
- (void)fileFromCamera;
- (void)sendFile:(NSString *)fileName withJid:(NSString *)jidStr;
@end
