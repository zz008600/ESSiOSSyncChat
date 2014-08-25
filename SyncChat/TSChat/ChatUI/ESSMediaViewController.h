//
//  ESSMediaViewController.h
//  SyncChat
//
//  Created by essadmin on 8/13/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESSMediaViewController : UIViewController
@property(nonatomic,strong) NSString *mediaType;
@property(nonatomic,strong) NSString *mediaFileName;
@property(nonatomic,strong) IBOutlet UIImageView *imageView;
@end
