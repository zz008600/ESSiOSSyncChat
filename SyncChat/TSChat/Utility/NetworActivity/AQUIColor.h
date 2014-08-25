//
//  AQUIColor.h
//  activityIndicatorDemo
//
//  Created by Vishnu Reddy on 08/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AQUIColor : NSObject

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length;

+ (UIColor *) colorWithHexString: (NSString *) hexString ;

@end
