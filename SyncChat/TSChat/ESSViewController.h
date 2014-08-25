//
//  TSViewController.h
//  TSChat
//
//  Created by essadmin on 5/1/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESSAppDelegate.h"
#import "ESSMainViewController.h"
#import "ESSHelper.h"

@interface ESSViewController : ESSMainViewController<UITextFieldDelegate>
@property(nonatomic,weak)IBOutlet UITextField *usrName;
@property(nonatomic,weak)IBOutlet UITextField *password;
@property(nonatomic,weak)IBOutlet UIView *loginView;

- (IBAction)signIN:(id)sender;
@end
