//
//  NSString+Emotion.m
//  SyncChat
//
//  Created by essadmin on 8/5/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "NSString+Emotion.h"

@implementation NSString (Emotion)
- (NSString *) substituteEmoticons {
    
    //See http://www.easyapns.com/iphone-emoji-alerts for a list of emoticons available
    
    NSString *res = [self stringByReplacingOccurrencesOfString:@":)" withString:@"\ue415"];
    res = [res stringByReplacingOccurrencesOfString:@":(" withString:@"\ue403"];
    res = [res stringByReplacingOccurrencesOfString:@";-)" withString:@"\ue405"];
    res = [res stringByReplacingOccurrencesOfString:@":-x" withString:@"\ue418"];
    
    return res;
    
}

@end
