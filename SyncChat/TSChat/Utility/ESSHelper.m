//
//  GFIHelper.m
//  YDChat
//
//  Created by Peter van de Put on 08/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import "ESSHelper.h"
#import "NSDate-Utilities.h"
@implementation ESSHelper



static NSFetchedResultsController *fetchedResultsController;
static id<NSFetchedResultsControllerDelegate> delete;



+ (UIColor *)colorWithHexString:(NSString *)stringToConvert
{
    NSString *noHashString = [stringToConvert stringByReplacingOccurrencesOfString:@"#" withString:@""]; // remove the #
    NSScanner *scanner = [NSScanner scannerWithString:noHashString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet symbolCharacterSet]]; // remove + and $
    unsigned hex;
    if (![scanner scanHexInt:&hex]) return nil;
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:1.0f];
}

+(BOOL )createUser:(NSString *)username password:(NSString *)password name:(NSString *)name email:(NSString *)email
{
    NSString *urlToCall = [NSString stringWithFormat:kxmppHTTPRegistrationUrl,username,password,name,email];
    NSURL *url = [NSURL URLWithString:urlToCall];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    [theRequest setHTTPMethod:@"GET"];
    NSError* error = nil;
    NSURLResponse* response;
    NSData* result = [NSURLConnection sendSynchronousRequest:theRequest  returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    if ([responseString isEqualToString:@"<result>ok</result>\r\n"])
        {
        return YES;
        }
    else {
        
        return  NO;
    }
}
+(NSString *)dayLabelForMessage:(NSDate *)msgDate
{
    NSString *retStr = @"";
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *time = [formatter stringFromDate:msgDate];
    
    if ([msgDate isToday])
        {
        retStr = [NSString stringWithFormat:@"Today %@",time];
        }
    else if ([msgDate isYesterday])
        {
        retStr = [NSString stringWithFormat:@"Yesterday %@" ,time];
        }
    else
        {
        [formatter setDateFormat:@"yyyy/MM/dd HH:mm"];
        NSString *time = [formatter stringFromDate:msgDate];
        retStr = [NSString stringWithFormat:@"%@" ,time];
        }
    return retStr;
}
+ (NSString*) createUniqueFileNameWithoutExtension {
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ddmmyyyy-HHmmssSSS"];
    NSString *ret = [formatter stringFromDate:[NSDate date]];
    return ret;
    
}


+ (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 640; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}
+ (void)showAlertWithTitle : (NSString *)title andMessage:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}
+(ESSAppDelegate *)appDelegate
{
	return (ESSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

+ (XMPPStream *)xmppStream {
	return [[ESSHelper appDelegate] xmppStream];
}

+ (UIBarButtonItem *)loggedInUserProfileImageBarButton{
    UIImage *image ;
    NSData *photoData = [[[ESSHelper appDelegate] xmppvCardAvatarModule] photoDataForJID:[ESSHelper appDelegate].xmppStream.myJID];
    
    if (photoData != nil){
        image  = [UIImage imageWithData:photoData];
    }
    else{
        image  = [UIImage imageNamed:@"images.png"];
    }
    
    CGRect buttonFrame = CGRectMake(0, 0, 35, 35);
    UIButton* backbtn = [[UIButton alloc] initWithFrame:buttonFrame];
    [backbtn setImage:[UIImage imageNamed:@"Cercular.png"] forState:UIControlStateNormal];
    [backbtn setShowsTouchWhenHighlighted:YES];
    [backbtn setTitle:@"" forState:UIControlStateNormal];
    backbtn.titleLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:14.0];
    backbtn.clipsToBounds = YES;
    backbtn.layer.cornerRadius = 18;
    
    [backbtn setBackgroundImage:image forState:UIControlStateNormal];
    
    UIBarButtonItem* profileImage = [[UIBarButtonItem alloc] initWithCustomView:backbtn];
    // [self.navigationItem setRightBarButtonItem:backButtonItem];
    
    return profileImage;
}

+ (UIImage *)loggedInUserProfileImage{
    UIImage *image ;
    NSData *photoData = [[[ESSHelper appDelegate] xmppvCardAvatarModule] photoDataForJID:[ESSHelper appDelegate].xmppStream.myJID];
    
    if (photoData != nil){
        image  = [UIImage imageWithData:photoData];
    }
    else{
        image  = [UIImage imageNamed:@"images.png"];
    }
    return image;

}

+ (NSString *)displayName:(NSString *)name{
    NSArray *arr = [name componentsSeparatedByString:@"@"];
    return [arr objectAtIndex:0];
}

+ (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [[ESSHelper appDelegate] managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
        fetchedResultsController.delegate = delete;
		//[fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
        
	}
	
	return fetchedResultsController;
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"onListOFSyncChatUser" object :controller]];
}

+ (NSString *)userFromJid:(NSString *)jidString
{
    NSString *cleanName = [jidString stringByReplacingOccurrencesOfString:kXMPPServer withString:@""];
    return [cleanName stringByReplacingOccurrencesOfString:@"@" withString:@""];
}

+ (void)setServerName:(NSString *)serverName{
/*#define HostName                                @"jabber.ru.com"//
#define kXMPPServer                           @"jabber.ru.com"//
#define kxmppProxyServer                    @"jabber.ru.com"//
#define kxmppConferenceServer           @"conference.jabber.ru.com"//
#define kxmppSearchServer                   @"search.jabber.ru.com"//*/
    hostName = [[NSString alloc] initWithString:serverName];
    xMPPServer = [[NSString alloc] initWithString:serverName];
    xmppProxyServer = [[NSString alloc] initWithString:serverName];
    xmppConferenceServer = [[NSString alloc] initWithFormat:@"conference.%@" ,xmppConferenceServer];
    xmppSearchServer = [[NSString alloc] initWithFormat:@"search.%@" ,xmppSearchServer];
    
}
static NSString *hostName;
static NSString *xMPPServer;
static NSString *xmppProxyServer;
static NSString *xmppConferenceServer;
static NSString *xmppSearchServer;

+ (NSString *)hostName{
    return hostName;
}

+ (NSString *)xMPPServer{
     return xMPPServer;
}

+ (NSString *)xmppProxyServer{
    return xmppProxyServer;
}

+ (NSString *)xmppConferenceServer{
    return xmppConferenceServer;
}
+ (NSString *)xmppSearchServer{
    return xmppSearchServer;
}

+(NSString *)generateIDWithPrefix:(NSString *)_prefix
{
    int x = arc4random() % 10000;
    return [NSString stringWithFormat:@"%@%i",_prefix,x ];
}
+ (NSString *)mediaType:(NSString *)fName{
    NSString *extension= @"";
    NSString *mediaType = @"";
    extension = [fName pathExtension];
    if ([extension isEqualToString:@"m4a"])
    { mediaType = @"audio";}
    else   if ([extension isEqualToString:@"mp4"])
    { mediaType = @"video";}
    else   if ([extension isEqualToString:@"m4v"])
    { mediaType = @"video";}
    else   if ([extension isEqualToString:@"mp3"])
    { mediaType = @"audio";}
    if ([extension isEqualToString:@"wav"])
    { mediaType = @"audio";}
    else   if ([extension isEqualToString:@"3gp"])
    { mediaType = @"audio";}
    else   if ([extension isEqualToString:@"png"])
    { mediaType = @"image";}
    else   if ([extension isEqualToString:@"jpg"])
    { mediaType = @"image";}
    else   if ([extension isEqualToString:@"jpeg"])
    { mediaType = @"image";}
    else   if ([extension isEqualToString:@"gif"])
    {  mediaType = @"image";}
    
    return mediaType;
}


+(NSMutableDictionary *)makeJSONForFileSending:(NSString *)url type:(NSString *)type{
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *temJsonDict = [NSMutableDictionary dictionary];
    [temJsonDict setObject:type forKey:@"type"];
    [temJsonDict setObject:url forKey:@"filePath"];
    //[temJsonDict setObject:thumbnailImage forKey:@"thumbnailPath"];
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithObjects:temJsonDict, nil];
    [jsonDict setValue:tempArray forKey:@"messageList"];
    return jsonDict;
}

+(NSMutableDictionary *)makeJSONForTextSending:(NSString *)text type:(NSString *)type {
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *temJsonDict = [NSMutableDictionary dictionary];
    [temJsonDict setObject:type forKey:@"type"];
    [temJsonDict setObject:text forKey:@"content"];
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithObjects:temJsonDict, nil];
    [jsonDict setValue:tempArray forKey:@"messageList"];
    return jsonDict;
}

+(ESSJsonMessageModal *)getURLFromJSON:(NSMutableDictionary *)dict {
    
    NSMutableArray *jsonArray = [dict objectForKey:@"messageList"];
    NSLog(@"jsonArray %@", jsonArray);
    if([jsonArray count]) {
        ESSJsonMessageModal *decoder = [[ESSJsonMessageModal alloc] init];
        NSMutableDictionary *temJsonDict = [jsonArray objectAtIndex:0];
        [decoder setType:[temJsonDict objectForKey:@"type"]];
        [decoder setUrl:[temJsonDict objectForKey:@"filePath"]];
        return decoder;
    }
    return nil;
}

+(ESSJsonMessageModal *)getTextFromJSON:(NSMutableDictionary *)dict {
    
    NSMutableArray *jsonArray = [dict objectForKey:@"messageList"];
    NSLog(@"jsonArray in text%@", jsonArray);
    if([jsonArray count]) {
        ESSJsonMessageModal *decoder = [[ESSJsonMessageModal alloc] init];
        NSMutableDictionary *temJsonDict = [jsonArray objectAtIndex:0];
        [decoder setType:[temJsonDict objectForKey:@"type"]];
        [decoder setUrl:[temJsonDict objectForKey:@"content"]];
        return decoder;
    }
    return nil;
}
@end
