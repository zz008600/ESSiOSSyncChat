//
//  AQActivityIndicator.h
//  activityIndicatorDemo
//
//  Created by Vishnu Reddy on 08/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AQActivityIndicator : UIView
{
    UIActivityIndicatorView *activityView;
    UIView *loadingView;
    UILabel *loadingLabel;
    NSString *loaderMessage;
}

@property (nonatomic, retain) UIActivityIndicatorView * activityView1;
@property (nonatomic, retain) UIView *loadingView1;
@property (nonatomic, retain) UILabel *loadingLabel1;
+ (AQActivityIndicator *)sharedInstance:(NSString *)messageLoding;
//+ (AQActivityIndicator *)sharedInstance;
+ (void)showIndicatorInView:(UIView *)parentView;
+ (void)hideIndicator;
+ (void)setMessage:(NSString *) title;
+ (void)setBackgroundColor:(NSString *) color;
+(void)startAnimating;
@end
