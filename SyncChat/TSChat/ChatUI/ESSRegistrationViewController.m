//
//  TSRegistrationViewController.m
//  SyncChat
//
//  Created by essadmin on 6/5/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSRegistrationViewController.h"

@interface ESSRegistrationViewController ()
{
    BOOL isUP;
}

- (IBAction)back:(id)sender;
- (IBAction)signUP:(id)sender;
@end

@implementation ESSRegistrationViewController


- (ESSAppDelegate *)appDelegate
{
	return (ESSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _name.delegate = self;
    _pwd.delegate = self;
    _confirmPwd.delegate = self;
    _email.delegate = self;
    _userName.delegate = self;
    isUP = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    isUP = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame=CGRectMake(self.view.frame.origin.x,0,self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished){
    }];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldDidBeginEditing");
    if (!isUP) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame=CGRectMake(self.view.frame.origin.x,self.view.frame.origin.y-50,self.view.frame.size.width, self.view.frame.size.height);
        } completion:^(BOOL finished){
        }];
        isUP = YES;
    }
    
    
}

- (IBAction)back:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)signUP:(id)sender{
    //    iPhoneXMPPAppDelegate *appDelegate =(iPhoneXMPPAppDelegate *)[[UIApplication sharedApplication]delegate];
    NSError *error = nil;
    //[[ESSHelper appDelegate] setupXMPPStream
    
    //[[[self appDelegate] xmppStream] connectWithTimeout:XMPPStreamTimeoutNone error:nil];
    NSString *username = [NSString stringWithFormat:@"%@@%@", self.userName.text,HostName];
    NSString *password = ([self.pwd.text isEqualToString:self.confirmPwd.text])?self.pwd.text:self.userName.text;
    NSString *name = _name.text;
    NSString *email=self.email.text;
    
    NSMutableArray *elements = [NSMutableArray array];
    [elements addObject:[NSXMLElement elementWithName:@"username" stringValue:username]];
    [elements addObject:[NSXMLElement elementWithName:@"password" stringValue:password]];
    [elements addObject:[NSXMLElement elementWithName:@"name" stringValue:name]];
    
    [elements addObject:[NSXMLElement elementWithName:@"email" stringValue:email]];
    [[ESSHelper xmppStream] setMyJID:[XMPPJID jidWithString:username]];
    if (![[ESSHelper xmppStream] connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        NSLog(@"Error While connecting");
    }else{
        
       /* BOOL isRegistred = [[[ESSHelper appDelegate] xmppStream] registerWithElements:elements error:nil];
        if (isRegistred) {
            NSLog(@"Success Registration of user");
        }else{
            NSLog(@"Fail Registration of user");
        }*/
        
        if (ESSHelper.xmppStream.supportsInBandRegistration)
        {
           NSError *err=nil;
            if (![ESSHelper.xmppStream registerWithPassword:password error:&err])
            {
                DDLogError(@"Oops, I forgot something: %@", error);
            }
        }
        else
        {
            DDLogError(@"Inband registration is not supported");
        }

    }/*
    if ([ESSHelper createUser:username password:password name:name email:email]) {
        NSLog(@"Success");
    }else{
        NSLog(@"Fail");
    }
    */
    NSLog(@"Register ====%@",[[self appDelegate] xmppStream]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
