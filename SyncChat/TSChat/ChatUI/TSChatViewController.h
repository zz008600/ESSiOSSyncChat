//
//  TSChatViewController.h
//  TSChat
//
//  Created by essadmin on 5/2/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSChatViewController : UIViewController<UITextFieldDelegate>
@property(nonatomic,strong)NSString *objectName;
@property(nonatomic,weak)XMPPUserCoreDataStorageObject *user;
@property(nonatomic,weak)IBOutlet UITextField *msgBody;
@property(nonatomic,weak)IBOutlet UIScrollView *msgcontainerSC;
@property(nonatomic,weak)IBOutlet UIView *msgSentView;
@property(nonatomic,weak)IBOutlet UIButton *sendBtn;
@end
