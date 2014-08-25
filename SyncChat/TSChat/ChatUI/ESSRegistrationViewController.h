//
//  TSRegistrationViewController.h
//  SyncChat
//
//  Created by essadmin on 6/5/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESSMainViewController.h"

@interface ESSRegistrationViewController : ESSMainViewController<UITextFieldDelegate>
@property(nonatomic,weak)IBOutlet UITextField *userName;
@property(nonatomic,weak)IBOutlet UITextField *name;
@property(nonatomic,weak)IBOutlet UITextField *pwd;
@property(nonatomic,weak)IBOutlet UITextField *confirmPwd;
@property(nonatomic,weak)IBOutlet UITextField *email;

@end
