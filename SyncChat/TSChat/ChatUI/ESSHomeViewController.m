//
//  TSHomeViewController.m
//  TSChat
//
//  Created by essadmin on 5/28/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSHomeViewController.h"
//ch.07
#import "ESSFileInfo.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ESSFileSender.h"
#import "NSString+Emotion.h"
#import  "ESSMediaViewController.h"

@interface ESSHomeViewController ()<UIImagePickerControllerDelegate>{
    UIImagePickerController *picturePicker;
    NSString *fileNameToBeUploaded;
    BOOL filesendingInProgress;
    BOOL isSendMessage;
    BOOL isRecording;
    float rowHeight;
    int selectedRowIndex;
    AVPlayer *player;
    BOOL isPlaying;
    UISlider *playbackProgress;
}
//ch.07
@property (nonatomic,strong) ESSFileSender *fileSender;
@property (nonatomic,strong) ESSFileInfo *fileInfo;
@property (nonatomic,strong) NSString *requestID;
@property (nonatomic,strong) NSString *streamID;
@end

@implementation ESSHomeViewController

#define profileImageSize 40
#define profileSornerRadius 20
#define messageTextFeildWidth 240
#define messageFont @"Arial Rounded MT Bold"


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UIBarButtonItem *)backButton
{
    UIImage *image = [UIImage imageNamed:@"logo"];
    CGRect buttonFrame = CGRectMake(0, 5, 35, 35);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:image forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}
-(IBAction)backButtonPressed:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}
// navigate to Sync lock Screen
-(void)NavigateToSync:(NSNotification *)notify{
    
    if(![self.navigationController.visibleViewController isKindOfClass:[ESSSyncViewController class]])
        [self performSegueWithIdentifier:@"segueToSync" sender:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isSendMessage = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(NavigateToSync:)
                                                name:@"HMIStatusFullForNavigate"
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(sendImageNameTotheUser:)
                                                name:@"uploadSucceeded"
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(saveDownloadedFileForChat:)
                                                name:@"downloadSucceeded"
                                              object:nil];
    
    self.navigationItem.leftBarButtonItem=[self backButton];
    [self.navigationItem setRightBarButtonItem:[ESSHelper loggedInUserProfileImageBarButton]];
    chat_View = [[UIView alloc] initWithFrame:self.view.frame];
    chat_View.backgroundColor=[UIColor clearColor];
    [self.view addSubview:chat_View];
    
    // Do any additional setup after loading the view.
    
    chat_table= [[UITableView alloc] initWithFrame:CGRectMake(0, 65, self.view.frame.size.width, self.view.frame.size.height-100)];
    chat_table.rowHeight=80;
    chat_table.backgroundColor=[UIColor clearColor];
    chat_table.delegate=self;
    chat_table.dataSource=self;
    chat_table.separatorColor=[UIColor clearColor];
    chat_table.sectionIndexTrackingBackgroundColor=[UIColor clearColor];
    [chat_View addSubview:chat_table];
    
    botomView=[[UIView alloc]initWithFrame:CGRectMake(0,self.view.frame.size.height-35, self.view.frame.size.width,40 )];
    botomView.backgroundColor=[ESSMainViewController colorWithHexString:@"#BBDAEC"]; //[UIColor blueColor];
    messageText=[[UITextField alloc] initWithFrame:CGRectMake(30,2, self.view.frame.size.width-70,30 )];
    messageText.backgroundColor=[UIColor whiteColor];
    messageText.borderStyle=UITextBorderStyleRoundedRect;
    messageText.delegate=self;
    messageText.returnKeyType = UIReturnKeySend;
    [botomView addSubview:messageText];
    share=[[UIButton alloc] initWithFrame:CGRectMake( self.view.frame.size.width - 30 ,2, 30,30 )];
    [share setImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
    [share addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    [botomView addSubview:share];
    
    
    upload=[[UIButton alloc] initWithFrame:CGRectMake( 0 ,2, 30,30 )];
    [upload setImage:[UIImage imageNamed:@"upload-128.png"] forState:UIControlStateNormal];
    [upload addTarget:self action:@selector(uploadFile:) forControlEvents:UIControlEventTouchUpInside];
    [botomView addSubview:upload];
    [chat_View addSubview:botomView];
    frind_list =[ [UIView alloc] initWithFrame:CGRectMake(-(self.view.frame.size.width - 100) ,0, self.view.frame.size.width - 100,self.view.frame.size.height )];
    frind_list.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"3D-Background1.jpg"]];
}


#pragma mark - Message Send Method
- (IBAction)send:(id)sender{
    if (isRecording) {
        
        
    }
    else
    {
        NSString *messageStr = messageText.text;
        [messageStr substituteEmoticons];
        if([messageStr length] > 0)
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            //send chat message
            NSArray *strArr = [messageStr componentsSeparatedByString:@"/"];
            NSLog(@"%@",strArr);
            NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
            if ([messageStr rangeOfString:documentsDirectory].location != NSNotFound)
            {
#if TARGET_IPHONE_SIMULATOR
                [body setStringValue:[strArr objectAtIndex:10]];
#elif TARGET_OS_IPHONE
                [body setStringValue:[strArr objectAtIndex:6]];
#else
                [body setStringValue:[strArr objectAtIndex:6]];
#endif
                
            }
            else
                [body setStringValue:messageStr];
            
            
            NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
            [message addAttributeWithName:@"type" stringValue:@"chat"];
            [message addAttributeWithName:@"to" stringValue:[_userSelected.jid full]];
            [message addChild:body];
            NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
            [message addChild:status];
            
            if ([_chatType isEqualToString:@"chat"]) {
                [[ESSHelper appDelegate].xmppStream sendElement:message];
            }else{
                // [self.currentRoomCVC sendMessage:[XMPPMessage messageFromElement:message]];
                NSLog(@"ooooo %@",[ESSMUCManager sharedInstance].currentRoom.roomJID);
                [[ESSMUCManager sharedInstance].currentRoom  addDelegate:self delegateQueue:dispatch_get_main_queue()];
                [[ESSMUCManager sharedInstance].currentRoom  activate:[ESSHelper xmppStream]];
                [[ESSMUCManager sharedInstance].currentRoom sendMessage:[XMPPMessage messageFromElement:message]];
            }
            // We need to put our own message also in CoreData of course and reload the data
            Chat *chat = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Chat"
                          inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
            
            
            if ([messageStr rangeOfString:documentsDirectory].location != NSNotFound)
            {
                chat.messageDate = [NSDate date];
                chat.hasMedia=[NSNumber numberWithBool:YES];
                chat.isNew=[NSNumber numberWithBool:NO];
                chat.messageStatus=@"send";
                chat.direction = @"OUT";
                chat.mimeType = [ESSHelper mediaType:messageStr];
                chat.mediaType = [ESSHelper mediaType:messageStr];
                chat.filenameAsSent = messageStr;
                chat.isFileDownloaded = [NSNumber numberWithBool:YES];
            }
            else
            {
                chat.messageBody = messageStr;
                chat.messageDate = [NSDate date];
                chat.hasMedia=[NSNumber numberWithBool:NO];
                chat.isNew=[NSNumber numberWithBool:NO];
                chat.messageStatus=@"send";
                chat.direction = @"OUT";
                
            }
            
            
            if ([_chatType isEqualToString:@"chat"]){
                chat.isGroupMessage=[NSNumber numberWithBool:NO];
                chat.jidString = [_userSelected.jid full];
                NSLog(@"%@",chat.jidString);
                
            }
            else{
                // [ESSMUCManager sharedInstance].rooomArray
                
                chat.groupNumber=  [ESSMUCManager sharedInstance].currentRoom.roomJID.user ;
                chat.isGroupMessage =[NSNumber numberWithBool:YES];
                chat.jidString =  [ESSMUCManager sharedInstance].currentRoom.roomJID.full;
                
                
                NSLog(@"%@",chat.jidString);
            }
            
            
            NSError *error = nil;
            if (![[ESSHelper appDelegate].managedObjectContext save:&error])
            {
                NSLog(@"error saving");
            }
        }
        messageText.text=@"";
        if ([messageText isFirstResponder])
            [messageText resignFirstResponder ];
        
        //Reload our data
        [self loadData];
        //Restore the Screen
        [chat_table reloadData];
        [self textFieldShouldReturn:messageText];
    }
    
}

#pragma mark - textfield Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    [share setImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame=CGRectMake(self.view.frame.origin.x,0,self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished){
        if(!isSendMessage){
            [self send:nil];
            isSendMessage = YES;
        }
    }];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldDidBeginEditing");
    [share setImage:[UIImage imageNamed:@"sendText.png"] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame=CGRectMake(self.view.frame.origin.x,self.view.frame.origin.y-215,self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished){
        isSendMessage = NO;
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}
#pragma mark - chatView
-(UIView *)getProfileImageView:(UIImage *)fileName {
    
    UIImageView * profileFrame=[[UIImageView alloc ] initWithFrame:CGRectMake(0 , 0, profileImageSize +2, profileImageSize +2)];
    profileFrame.image =[UIImage imageNamed:@"WhiteBoader.png"];
    [self.view addSubview:profileFrame];
    profileFrame.clipsToBounds = YES;
    profileFrame.layer.cornerRadius = profileSornerRadius;
    UIImageView * profileImage=[[UIImageView alloc ] initWithFrame:CGRectMake(1 , 1, profileImageSize, profileImageSize)];
    
    profileImage.image =fileName;
    
    [self.view addSubview:profileImage];
    profileImage.clipsToBounds = YES;
    profileImage.layer.cornerRadius = profileSornerRadius;
    UIView * userProfile = [[UIView alloc] initWithFrame:CGRectMake(0 , 0, profileImage.frame.size.width, profileImage.frame.size.height)];
    userProfile.backgroundColor=[UIColor clearColor];
    [userProfile addSubview:profileFrame];
    [userProfile addSubview:profileImage];
    return userProfile;
}

-(UIView *)getMessageView:(NSString *)message  senderUserName:(NSString *)senderName time:(NSString *)msgTime aligment:(NSString *)alingment {
    
    UILabel * userNameLabel= [[UILabel alloc] initWithFrame:CGRectMake(2,3,messageTextFeildWidth,15)];
    userNameLabel.text=senderName;
    userNameLabel.font = [UIFont fontWithName:messageFont size:14];
    userNameLabel.textColor =   [UIColor whiteColor];//[ESSMainViewController colorWithHexString:@"#535456"];  //[UIColor whiteColor];
    userNameLabel.numberOfLines=0;
    [userNameLabel sizeToFit];
    
    UILabel * messageLabel= [[UILabel alloc] initWithFrame:CGRectMake(2,userNameLabel.frame.size.height+5,messageTextFeildWidth,45)];
    messageLabel.text=[message substituteEmoticons];
    messageLabel.font = [UIFont fontWithName:messageFont size:14];
    messageLabel.textColor =[ESSMainViewController colorWithHexString:@"#535456"];  //[UIColor whiteColor];
    messageLabel.numberOfLines=0;
    [messageLabel sizeToFit];
    
    UILabel * timeLabel= [[UILabel alloc] initWithFrame:CGRectMake(2,userNameLabel.frame.size.height+ messageLabel.frame.size.height +  10 ,200,10)];
    timeLabel.text=msgTime;
    timeLabel.font = [UIFont fontWithName:messageFont size:10];
    timeLabel.textColor = [ESSMainViewController colorWithHexString:@"#535456"];//[UIColor whiteColor];
    timeLabel.numberOfLines=0;
    [timeLabel sizeToFit];
    int viewWidth=timeLabel.frame.size.width +10;
    if ((messageLabel.frame.size.width + 5) >viewWidth) {
        viewWidth=messageLabel.frame.size.width + 5;
    }
    UIView * messageView= [[UIView alloc] initWithFrame:CGRectMake(0 , 0, viewWidth , userNameLabel.frame.size.height+ messageLabel.frame.size.height + timeLabel.frame.size.height +15)];
    messageView.backgroundColor=[ESSMainViewController colorWithHexString:@"#BBDAEC"];
    messageView.clipsToBounds = YES;
    messageView.layer.cornerRadius = 5;
    
    if ([alingment isEqualToString:@"left"]) {
    }else{
        timeLabel.textAlignment=NSTextAlignmentRight;
        // messageLabel.frame=CGRectMake(messageView.frame.size.width-messageLabel.frame.size.width-10, 0, messageView.frame.size.width-10, messageLabel.frame.size.height);
    }
    [messageView addSubview:userNameLabel];
    [messageView addSubview:messageLabel];
    [messageView addSubview:timeLabel];
    
    return  messageView;
}

-(UIView *)getFileDownloadView:(NSString *)filePath  fileType:(NSString *)fType time:(NSString *)msgTime aligment:(NSString *)alingment buttonIndex:(int)index{
    
    Chat *obj = (Chat *)[_chats objectAtIndex:index];
    NSLog(@"File Type:  %@ \nPath : %@ %d",fType,filePath,[obj.isFileDownloaded intValue]);
    
    UILabel * messageLabel= [[UILabel alloc] initWithFrame:CGRectMake(0,5,messageTextFeildWidth,45)];
    messageLabel.font = [UIFont fontWithName:messageFont size:14];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.numberOfLines=0;
    [messageLabel sizeToFit];
    
    UIImageView * downLoadImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,5,100,100)];
    NSLog(@"isFileDownloaded %i",[obj.isFileDownloaded intValue]);
    if ([fType isEqualToString:@"image"] && obj.isFileDownloaded  ) {
        NSData *pngData = [NSData dataWithContentsOfFile:filePath];
        UIImage *image =  [UIImage imageWithData:pngData];
        downLoadImage.image = image;
        //[UIImage imageNamed:@"1868scan0011.jpg"];
        downLoadImage.clipsToBounds = YES;
        downLoadImage.layer.cornerRadius = 10;
    }
    
    
    
    UIButton * downloadIcon = [[UIButton alloc] initWithFrame:CGRectMake(0,5,100,100)];
    
    if ([filePath length] < 25){
        [downloadIcon setBackgroundColor:[UIColor grayColor]];
        [downloadIcon setImage:[UIImage imageNamed:@"Icon_34-128.png"] forState:UIControlStateNormal];
    }
    downloadIcon.imageEdgeInsets = UIEdgeInsetsMake(30.0, 30.0, 30.0, 30.0);
    downloadIcon.alpha=0.8;
    downloadIcon.clipsToBounds = YES;
    downloadIcon.layer.cornerRadius = 10;
    downloadIcon.tag = index;//[[chat_table indexPathForSelectedRow] row];
    [downloadIcon setContentMode:UIViewContentModeCenter];
    downloadIcon.center=downLoadImage.center;
    [downloadIcon addTarget:self action:@selector(downloadFile:) forControlEvents:UIControlEventTouchDown];
    
    UILabel * timeLabel= [[UILabel alloc] initWithFrame:CGRectMake(0,downLoadImage.frame.size.height + 5 ,320,10)];
    timeLabel.text=msgTime;
    timeLabel.font = [UIFont fontWithName:messageFont size:10];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.backgroundColor=[UIColor clearColor];
    UIView * messageView = [[UIView alloc] init];
    //UIView * messageView= [[UIView alloc] initWithFrame:CGRectMake(0 ,45, 200, downLoadImage.frame.size.height )];
    
    if ([alingment isEqualToString:@"left"]) {
        timeLabel.textAlignment=NSTextAlignmentLeft;
        downloadIcon.hidden=NO;
        if ([fType isEqualToString:@"image"]) {
            messageView.frame =CGRectMake(0 ,45, 200, downLoadImage.frame.size.height );
            downLoadImage.frame=CGRectMake(5 , 0, downLoadImage.frame.size.width, downLoadImage.frame.size.height);
            downloadIcon.frame =CGRectMake(5 ,0, downloadIcon.frame.size.width, downloadIcon.frame.size.height);
            [messageView addSubview:downLoadImage];
        }else if([fType isEqualToString:@"audio"]){
           
            UIView *audio =  [self audioPlayer:filePath dataIndex:index];
            audio.frame = CGRectMake(5 ,0, audio.frame.size.width, audio.frame.size.height);
            timeLabel.frame = CGRectMake(0,audio.frame.size.height + 5 ,320,10);
            messageView.frame =CGRectMake(0 ,45, 200, audio.frame.size.height );
            [messageView addSubview:audio];
        }
    }else{
        timeLabel.textAlignment=NSTextAlignmentRight;
        downloadIcon.hidden=YES;
        if ([fType isEqualToString:@"audio"]) {
            downLoadImage.frame=CGRectMake(self.view.frame.size.width-downLoadImage.frame.size.width-5 , 0, downLoadImage.frame.size.width, downLoadImage.frame.size.height);
            
            downloadIcon.frame =CGRectMake(self.view.frame.size.width-downloadIcon.frame.size.width-5 , 0, downloadIcon.frame.size.width, downloadIcon.frame.size.height);
            [downloadIcon setBackgroundColor:[UIColor redColor]];
            messageView.frame =CGRectMake(0 ,45, 200, downLoadImage.frame.size.height );
            [messageView addSubview:downLoadImage];
        }else if([fType isEqualToString:@"image"]){
            
           UIView *audio =  [self audioPlayer:filePath dataIndex:index];
            audio.frame = CGRectMake(self.view.frame.size.width-audio.frame.size.width-5 , 0, audio.frame.size.width, audio.frame.size.height);
            //audio.backgroundColor = [UIColor redColor];
            messageView.frame =CGRectMake(0 ,45, 200, audio.frame.size.height );
            timeLabel.frame = CGRectMake(0,audio.frame.size.height + 5 ,320,10);
            [messageView addSubview:audio];
        }
        
        
    }
    
    
  
    [messageView addSubview:downloadIcon];
    [messageView addSubview:timeLabel];
    return  messageView;
}

- (UIView *)audioPlayer:(NSString *)filePath dataIndex:(int)index{
    isPlaying = NO;
   // [self audioPlayerSetup:filePath];
    UIView *playerMedia= [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 40)];
    playerMedia.backgroundColor =[ESSMainViewController colorWithHexString:@"#BBDAEC"];
    playerMedia.clipsToBounds = YES;
    playerMedia.layer.cornerRadius = profileSornerRadius;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = index;
    [button addTarget:self
               action:@selector(mediaPlayPause:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"player_play.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(5.0, 4, 32.0, 32.0);
    [playerMedia addSubview:button];
    
    CGRect frame = CGRectMake(button.frame.size.width+5, 15, 140 , 10.0);
    playbackProgress = [[UISlider alloc] initWithFrame:frame];
    playbackProgress.tag = index;
    [playbackProgress addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventValueChanged];
    [playbackProgress setBackgroundColor:[UIColor clearColor]];
    [playerMedia addSubview:playbackProgress];
    return playerMedia;
}

- (void)audioPlayerSetup:(NSString *)filePath{
}
- (void)mediaPlayPause:(id)sender{
    NSLog(@"Button Prees");
    UIButton *btn = (UIButton *)sender;
   // Chat *obj = [_chats objectAtIndex:btn.tag];
   // [[SyncPlayerPlugin sharedMPInstance] playMediaFile:obj.localfileName];
    

    if (isPlaying) {
        //[player pause];
        [[SyncPlayerPlugin sharedMPInstance].player pause];
        [btn setImage:[UIImage imageNamed:@"player_play.png"] forState:UIControlStateNormal];
        //[btn setTitle:@"Play" forState:UIControlStateNormal];
        isPlaying = NO;
    }else{
        [[SyncPlayerPlugin sharedMPInstance] playMediaFile:@"Againandagain"];
        [[SyncPlayerPlugin sharedMPInstance].player play];
        [btn setImage:[UIImage imageNamed:@"player_pause.png"] forState:UIControlStateNormal];
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(playbackProgressBar:)
                                       userInfo:nil
                                        repeats:YES];
        //[btn setTitle:@"Pause" forState:UIControlStateNormal];
        isPlaying = YES;
    }
}
// Method to change the state ot Track timer Slider value to song  current time and chnege the trackCompleted and trackRemaing Lable text
-(void)playbackProgressBar:(NSTimer*)timer{
    
    CMTime total= [SyncPlayerPlugin sharedMPInstance].player.currentItem.asset.duration;
    CMTime currentTime= [SyncPlayerPlugin sharedMPInstance].player.currentItem.currentTime;
    float totalSeconds = CMTimeGetSeconds(total);
    float currentTimeSeconds = CMTimeGetSeconds(currentTime);
    float f=currentTimeSeconds / totalSeconds;
    playbackProgress.value=f;
    //trackCompleted.text=[NSString stringWithFormat:@"%.2f",currentTimeSeconds/ 60];
    //trackRemain.text=[NSString stringWithFormat:@"%.2f",(currentTimeSeconds-totalSeconds)/ 60];
}

// Button action when user drag the slider position
- (IBAction)sliderValueChangedAction:(id)sender{
    
    CMTime total= [SyncPlayerPlugin sharedMPInstance] .player.currentItem.asset.duration;
    float totalSeconds = CMTimeGetSeconds(total);
    float trackTime = [(UISlider *)sender value] * totalSeconds;
    CMTime seekingCM = CMTimeMake(trackTime, 1);
    [[SyncPlayerPlugin sharedMPInstance]      .player seekToTime:seekingCM];
    
}
- (void)mediaSlider:(id)sender{
    UISlider *sl = (UISlider *)sender;
    NSLog(@"%f",sl.frame.size.width);
    CMTime total= player.currentItem.asset.duration;
    float totalSeconds = CMTimeGetSeconds(total);
    float trackTime = [(UISlider *)sender value] * totalSeconds;
    CMTime seekingCM = CMTimeMake(trackTime, 1);
    [player seekToTime:seekingCM];
}

-(UIView *)messageContainer:(NSString *)message  senderUserName:(NSString *)senderName  time:(NSString *)time  profileImage:(UIImage *)image aligment:(NSString *)alingment isFile:(BOOL)isFile fileType:(NSString *)fType buttonIndex:(int)index{
    UIView * profileImage =   [self getProfileImageView:image];
    UIView * profileMessage;
    // NSLog(@"Message : %@ \n file Type%@",message ,fType);
    if (isFile) {
        profileMessage = [self getFileDownloadView:message fileType:fType time:time aligment:alingment buttonIndex:index]; //[self getFileDownloadView:message time:time aligment:alingment buttonIndex:index];
        
    }else{
        profileMessage = [self getMessageView:message senderUserName:senderName time:time aligment:alingment];//[self getMessageView:message time:time aligment:alingment];
        if ([alingment isEqualToString:@"left"]) {
            profileMessage.frame = CGRectMake(5 , profileImage.frame.size.height+5, profileMessage.frame.size.width, profileMessage.frame.size.height );
        }else{
            profileMessage.frame=CGRectMake(self.view.frame.size.width-profileMessage.frame.size.width-5 , profileImage.frame.size.height+5, profileMessage.frame.size.width, profileMessage.frame.size.height );
        }
        
    }
    
    
    if ([alingment isEqualToString:@"left"]) {
        profileImage.frame=CGRectMake(10 , 0, profileImage.frame.size.width, profileImage.frame.size.height );
        
    }else{
        profileImage.frame=CGRectMake((self.view.frame.size.width-profileImage.frame.size.width)-profileImage.frame.size.width +20, 0, profileImage.frame.size.width, profileImage.frame.size.height );
    }
    UIView * messageView= [[UIView alloc] initWithFrame:CGRectMake(0 , 0, 200+10, profileImage.frame.size.height + profileMessage.frame.size.height +10)];
    // messageView.backgroundColor=[UIColor grayColor];
    [messageView addSubview:profileImage];
    [messageView addSubview:profileMessage];
    return  messageView;
    
}


#pragma mark - Get Profile Image
-(UIImage *)getProfileImageView1:(XMPPUserCoreDataStorageObject *)user {
    
    UIImageView * profileFrame=[[UIImageView alloc ] initWithFrame:CGRectMake(0 , 0, profileImageSize +2, profileImageSize +2)];
    profileFrame.image =[UIImage imageNamed:@"WhiteBoader.png"];
    [self.view addSubview:profileFrame];
    profileFrame.clipsToBounds = YES;
    profileFrame.layer.cornerRadius = profileSornerRadius;
    
    
    UIImageView * profileImage=[[UIImageView alloc ] initWithFrame:CGRectMake(1 , 1, profileImageSize, profileImageSize)];
    
    if (user.photo != nil)
	{
        profileImage.image  = user.photo;
	}
	else
	{
		NSData *photoData = [[[ESSHelper appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        
		if (photoData != nil){
            profileImage.image  = [UIImage imageWithData:photoData];
        }
		else{
            profileImage.image  = [UIImage imageNamed:@"images.png"];
        }
	}
    
    [self.view addSubview:profileImage];
    
    profileImage.clipsToBounds = YES;
    profileImage.layer.cornerRadius = profileSornerRadius;
    UIView * userProfile = [[UIView alloc] initWithFrame:CGRectMake(0 , 0, profileImage.frame.size.width, profileImage.frame.size.height)];
    userProfile.backgroundColor=[UIColor clearColor];
    [userProfile addSubview:profileFrame];
    [userProfile addSubview:profileImage];
    
    return profileImage.image;
}



#pragma mark - tableView Deligates Method
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.chats count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell=[tableView  dequeueReusableCellWithIdentifier:@""];
    
    if (cell==nil) {
        cell= [[ UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tableView.frame.size.width,tableView.rowHeight)];
    }
    cell.contentView.frame=CGRectMake(0,0,tableView.frame.size.width,tableView.rowHeight);
    cell.backgroundColor=[UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIView * backGroundView= [[UIView alloc] initWithFrame:CGRectMake(0,0,tableView.frame.size.width,tableView.rowHeight)];
    
    Chat* chat = [self.chats objectAtIndex:indexPath.row];
    NSString * Time= [ESSHelper dayLabelForMessage:chat.messageDate];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a  -    dd MMM yyyy"];
    
    //Optionally for time zone converstions
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    
    Time = [formatter stringFromDate:chat.messageDate];
    if([chat.direction isEqualToString:@"IN"])
    {
        
        [cell.contentView addSubview:[self messageContainer:([chat.hasMedia intValue]== 0)?chat.messageBody:chat.localfileName senderUserName:chat.senderName time:Time profileImage:[self getProfileImageView1:_userSelected] aligment:@"left" isFile:([chat.hasMedia intValue]== 1) ?TRUE:FALSE fileType:chat.mediaType buttonIndex:indexPath.row]];
    }else{
        NSString *name = [[[[NSUserDefaults standardUserDefaults] objectForKey:kXMPPmyJID] componentsSeparatedByString:@"@"] objectAtIndex:0];
        [cell.contentView addSubview:[self messageContainer:([chat.hasMedia intValue]== 0)?chat.messageBody:chat.filenameAsSent senderUserName:name time:Time profileImage:[ESSHelper loggedInUserProfileImage] aligment:@"right" isFile:([chat.hasMedia intValue]== 1) ?TRUE:FALSE fileType:chat.mediaType buttonIndex:indexPath.row]];
    }
    backGroundView.alpha=0.5;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    Chat* chat = [self.chats objectAtIndex:indexPath.row];
    return [self messageContainer:([chat.hasMedia intValue]== 0)?chat.messageBody:chat.filenameAsSent senderUserName:chat.senderName time:@"00.00" profileImage:([chat.direction isEqualToString:@"IN"])?[self getProfileImageView1:_userSelected]:[ESSHelper loggedInUserProfileImage] aligment:([chat.direction isEqualToString:@"IN"])?@"left":@"right" isFile:([chat.hasMedia intValue]== 1) ?TRUE:FALSE fileType:chat.mediaType buttonIndex:indexPath.row].frame.size.height +20;
    
}



#pragma mark view appearance
-(void)viewWillAppear:(BOOL)animated
{
    //Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessageReceived:) name:kNewMessage  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusUpdateReceived:) name:kChatStatus  object:nil];
    [self loadData];
}
-(void)viewWillDisappear:(BOOL)animated
{
    //Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kChatStatus  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMessage object:nil];
    
}
-(void)statusUpdateReceived:(NSNotification *)aNotification
{
    NSString *msgStr=  [[aNotification userInfo] valueForKey:@"msg"] ;
    msgStr = [msgStr stringByReplacingOccurrencesOfString:@"@" withString:@""];
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Status" message:msgStr delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
    
}
-(void)newMessageReceived:(NSNotification *)aNotification
{
    
    //reload our data
    [self loadData];
}

-(void)loadData
{
    if (self.chats)
        self.chats =nil;
    self.chats = [[NSMutableArray alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chat"
                                              inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];;
    NSPredicate *predicate;
    if ([_chatType isEqualToString:@"chat"]) {
        NSLog(@"For predicate : %@",_userSelected.jidStr);
        predicate = [NSPredicate predicateWithFormat:@"jidString == %@",_userSelected.jidStr];
    }else {
        NSLog(@"For predicate : %@",[ESSMUCManager sharedInstance].currentRoom.roomJID.full);
        predicate = [NSPredicate predicateWithFormat:@"jidString == %@", [ESSMUCManager sharedInstance].currentRoom.roomJID.full];
    }
    
    [fetchRequest setPredicate:predicate];
    NSError *error=nil;
    NSArray *fetchedObjects = [[ESSHelper appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *obj in fetchedObjects)
    {
        [self.chats addObject:obj];
        //Since they are now visible set the isNew to NO
        Chat *thisChat = (Chat *)obj;
        if ([thisChat.isNew  boolValue])
            thisChat.isNew = [NSNumber numberWithBool:NO];
    }
    //Save changes
    error = nil;
    if (![[ESSHelper appDelegate].managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    [chat_table reloadData];
    [self scrollToBottomAnimated:YES];
}

-(void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger bottomRow = [self.chats count] - 1;
    if (bottomRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
        [chat_table scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}


- (IBAction)uploadFile:(id)sender{
    
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select Photo/Media file from :" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                            @"Album",
                            @"Camera",
                            nil];
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    [self filePickerAlbum];
                    break;
                case 1:
                    [self fileFromCamera];
                    break;
                case 2:
                    //[self emailContent];
                    break;
                case 3:
                    //[self saveContent];
                    break;
                case 4:
                    //[self rateAppYes];
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}


- (void)filePickerAlbum{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypePhotoLibrary])
    {
        fileNameToBeUploaded=@"";
        picturePicker = [[UIImagePickerController alloc] init];
        picturePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        picturePicker.delegate = self;
        if (  [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone  )
        {
            [self presentViewController:picturePicker animated:YES completion:nil];
        }
    }
    
}

- (void)fileFromCamera{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        fileNameToBeUploaded=@"";
        picturePicker = [[UIImagePickerController alloc] init];
        picturePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picturePicker.delegate = self;
        if (  [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone  )
        {
            [self presentViewController:picturePicker animated:YES completion:nil];
        }
    }
}
#pragma mark UIImpagePicker Delegate
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //UIImagePickerControllerMediaType ==
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    UIImage *correctImage = [ESSHelper scaleAndRotateImage:image];
    NSString *fname = [ESSHelper createUniqueFileNameWithoutExtension];
    NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"/Documents/%@.jpg",fname]];
    [UIImageJPEGRepresentation(correctImage, 0.5f) writeToFile:jpgPath atomically:YES];
    fileNameToBeUploaded=jpgPath;
    [self dismissViewControllerAnimated:YES completion:nil];
    if(![ESSHelper appDelegate].isSending)
    {
        [[FTPManager sharedInstance] sendAction:jpgPath];
    }
    else
    {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"error"
                                                        message:@"filetransfer in progress"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



-(void)sendImageNameTotheUser:(NSNotification *)filePath{
    messageText.text = (NSString *)[filePath object];
    NSLog(@"%@",messageText.text);
    [self send:nil];
}

- (IBAction)downloadFile:(id)sender{
    selectedRowIndex = ((UIButton *)sender).tag;
    Chat *obj = (Chat *)[_chats objectAtIndex:selectedRowIndex];
    if ([obj.localfileName length]<25) {
        [AQActivityIndicator sharedInstance:@""];
        [AQActivityIndicator showIndicatorInView:(UIButton *)sender];
        //[[FTPManager sharedInstance]getOrCancelAction:obj.localfileName];
        [[FTPManager sharedInstance]getOrCancelAction:@"2014-08-16 14-43-12.wav"];
    }else{
        [self performSegueWithIdentifier:@"segueToMedia" sender:obj.localfileName];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"segueToMedia"]){
        ESSMediaViewController *mediaViewController = (ESSMediaViewController *) [segue destinationViewController];
        NSLog(@"File Name%@",(NSString *)sender);
        mediaViewController.mediaFileName =(NSString *)sender;
        
        
    }
}
- (void)saveDownloadedFileForChat:(NSNotification *)notify{
    [AQActivityIndicator hideIndicator];
    if ((NSString *)[notify object]!=nil) {
        [self updateData:(NSString *)[notify object]];
    }
}


-(void)updateData:(NSString *)filePath
{
    Chat *objTemp = (Chat *)[_chats objectAtIndex:selectedRowIndex];
    if (self.chats)
        self.chats =nil;
    self.chats = [[NSMutableArray alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chat"
                                              inManagedObjectContext:[ESSHelper appDelegate].managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];;
    NSPredicate *predicate;
    if ([_chatType isEqualToString:@"chat"]) {
        NSLog(@"For predicate : %@",_userSelected.jidStr);
        predicate = [NSPredicate predicateWithFormat:@"jidString == %@",_userSelected.jidStr];
    }else {
        NSLog(@"For predicate : %@",[ESSMUCManager sharedInstance].currentRoom.roomJID.full);
        predicate = [NSPredicate predicateWithFormat:@"jidString == %@", [ESSMUCManager sharedInstance].currentRoom.roomJID.full];
    }
    
    [fetchRequest setPredicate:predicate];
    NSError *error=nil;
    NSArray *fetchedObjects = [[ESSHelper appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *obj in fetchedObjects)
    {
        [self.chats addObject:obj];
        //Since they are now visible set the isNew to NO
        Chat *thisChat = (Chat *)obj;
        if ([thisChat.localfileName  isEqualToString:objTemp.localfileName]){//
            thisChat.isFileDownloaded = [NSNumber numberWithBool:YES];
            thisChat.localfileName = filePath;
            
        }
    }
    //Save changes
    error = nil;
    if (![[ESSHelper appDelegate].managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    [self loadData];
    [self scrollToBottomAnimated:YES];
}


@end
