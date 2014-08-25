//
//  Room.h
//  YDChat
//
//  Created by Peter van de Put on 18/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XMPPRoom.h"


@interface Room : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * roomJID;
//@property (nonatomic, retain) XMPPRoom * xmppRoom;
@property (nonatomic,strong) NSMutableArray *buddiesList;

@end
