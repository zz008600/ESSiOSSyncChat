//
//  AQActivityIndicator.m
//  activityIndicatorDemo
//
//  Created by Vishnu Reddy on 08/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AQActivityIndicator.h"
#import "QuartzCore/QuartzCore.h"
#import "AQUIColor.h"

@implementation AQActivityIndicator
@synthesize loadingView1,loadingLabel1,activityView1;

static AQActivityIndicator *instance;

static UIActivityIndicatorView *activityView;
static UIView *loadingView;
static UILabel *loadingLabel;
static CGFloat activitViewWidth=160;
static CGFloat activityViewHeight=150;
static CGFloat cornerRadius=10;
NSString *message=@"Application \n Loading...";
NSString *activityBackgroundColor=@"99000000";


+ (AQActivityIndicator *)sharedInstance:(NSString *)messageLoding
{
    @synchronized(self)
    {
        if (nil == instance)
        {
            message= (messageLoding != nil)?messageLoding:@"";
            CGRect screen = [[UIScreen mainScreen] bounds];
            CGFloat height = CGRectGetWidth(screen);
            
            instance = [[self alloc] init];
            loadingView = [[UIView alloc] initWithFrame:CGRectMake(100, ((height-activityViewHeight)/3), activitViewWidth, activityViewHeight)];
            loadingView.backgroundColor = [AQUIColor colorWithHexString:activityBackgroundColor];
            loadingView.clipsToBounds = YES;
            loadingView.layer.cornerRadius =cornerRadius;
            
            activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            activityView.center = CGPointMake(loadingView.bounds.size.width / 2.0f, loadingView.bounds.size.height / 2.0f);
            
            
            // activityView.frame = CGRectMake(65, 40, activityView.bounds.size.width, activityView.bounds.size.height);
            [loadingView addSubview:activityView];
            
            loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, activityView.frame.origin.y+40, loadingView.frame.size.width, 44)];
            loadingLabel.backgroundColor = [UIColor clearColor];
            loadingLabel.textColor = [UIColor whiteColor];
            loadingLabel.adjustsFontSizeToFitWidth = YES;
            loadingLabel.textAlignment = NSTextAlignmentCenter;
            loadingLabel.numberOfLines=2;
            loadingLabel.text = ([messageLoding length] != 0)?messageLoding :@"";
            [loadingView addSubview:loadingLabel];
            [instance addSubview:loadingView];
            
            
        }
    }
    return instance;
}

+ (void)showIndicatorInView:(UIView *)parentView
{
    loadingView.frame=CGRectMake((parentView.frame.size.width-activitViewWidth)/2,(parentView.frame.size.height-activityViewHeight)/2,activitViewWidth,activityViewHeight);
    [parentView addSubview:loadingView];
    loadingView.hidden=NO;
    [activityView startAnimating];
    
}
+(void)startAnimating{
    [activityView startAnimating];
}
+ (void)setMessage:(NSString *) title
{
    message=title;
    
}

+ (void)setBackgroundColor:(NSString *) color
{
    activityBackgroundColor=color;
}

+ (void)hideIndicator
{
    loadingView.hidden=YES;
    [loadingView removeFromSuperview];
    [activityView stopAnimating];
    
}
- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}
@end
