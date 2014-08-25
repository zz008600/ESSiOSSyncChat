//
//  TSSyncViewController.h
//  TSChat
//
//  Created by essadmin on 5/28/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Chat.h"
#import "SyncService.h"
#import <CoreData/CoreData.h>
#import "ESSMainViewController.h"
#import <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
//#import "SyncPlayerPlugin.h"

@interface ESSSyncViewController : ESSMainViewController <NSFetchedResultsControllerDelegate> {
    
    NSFetchedResultsController *fetchedResultsController;
    NSMutableArray *groupsList;
    AVAudioPlayer *myAudioPlayer;
    
    
    __strong id <XMPPRoomStorage> xmppRoomStorage;
    NSMutableArray * selectedFriend;
}
@property(nonatomic,strong)Chat *chats;
- (void)send:(XMPPUserCoreDataStorageObject*)userSelected orJidString:(NSString *)jidString;
@end
