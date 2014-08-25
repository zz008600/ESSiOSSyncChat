//
//  ESSMediaViewController.m
//  SyncChat
//
//  Created by essadmin on 8/13/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSMediaViewController.h"

@implementation ESSMediaViewController
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    NSData *pngData = [NSData dataWithContentsOfFile:_mediaFileName];
    UIImage *image =  [UIImage imageWithData:pngData];

    _imageView.image = image;
}
@end
