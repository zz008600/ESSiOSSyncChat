//
//  TSViewController.m
//  TSChat
//
//  Created by essadmin on 5/1/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSViewController.h"
//NSString *const kXMPPmyJID = @"kXMPPmyJID";
//NSString *const kXMPPmyPassword = @"kXMPPmyPassword";
#import "AQActivityIndicator.h"

@interface ESSViewController ()

- (IBAction)registerUser:(id)sender;
@end

@implementation ESSViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBar.hidden = YES;
    _usrName.delegate = self;
    _password.delegate = self;
    _usrName.returnKeyType = UIReturnKeyDone;
    _password.returnKeyType = UIReturnKeyDone;
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buddyList) name:@"buddyList" object:nil];
   // _usrName.text = @"ios";
   // _password.text = @"ios";
    
  //  [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(autoSignIn) userInfo:nil repeats:NO];

    [self autoSignIn];
}

- (void)autoSignIn{
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID] ;
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    if (myJID != nil && myPassword != nil) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        _loginView.hidden = YES;
        [AQActivityIndicator sharedInstance:@"Please wait.."];
        [AQActivityIndicator showIndicatorInView:self.view];
        NSString *userName =  [NSString stringWithFormat:@"%@%@%@",myJID,@"@",HostName];
        [[ESSHelper appDelegate ] connectUserName:userName andPassword:myPassword];
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.hidden = YES;
   
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)signIN:(id)sender{
    [_usrName resignFirstResponder];
    [_password resignFirstResponder];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSString *userName = [NSString stringWithFormat:@"%@%@%@",_usrName.text,@"@",HostName];
    if ([_usrName.text length]!=0) {
        if ([_password.text length]!=0) {
            [AQActivityIndicator sharedInstance:@"Signing Please Wait..."];
            [AQActivityIndicator showIndicatorInView:self.view];
            if (![[ESSHelper appDelegate ] connectUserName:userName andPassword:_password.text]) {
                [ESSHelper showAlertWithTitle:@"Error" andMessage:@"Unser Not authenticated/not connected"];
            }
        }else{
            [ESSHelper showAlertWithTitle:@"loging Error" andMessage:@"Please enter the password"];
        }
    }else{
        [ESSHelper showAlertWithTitle:@"loging Error" andMessage:@"Please enter the user name."];
    }
}

- (void)buddyList{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
     _loginView.hidden = NO;
    [AQActivityIndicator hideIndicator];
    if ([_usrName.text length]!=0 && [_password.text length]!=0){
        [[NSUserDefaults standardUserDefaults] setObject:_usrName.text forKey:@"kXMPPmyJID"];
        [[NSUserDefaults standardUserDefaults] setObject:_password.text forKey:@"kXMPPmyPassword"];
    }
    [self performSegueWithIdentifier:@"buddyList" sender:nil];
}
- (IBAction)registerUser:(id)sender{
    [self performSegueWithIdentifier:@"segueToRegistration" sender:nil];
}
@end
