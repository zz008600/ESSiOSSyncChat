//  YDChat
//
//  Created by Peter van de Put on 08/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import <Foundation/Foundation.h>
#import"ESSJsonMessageModal.h"

@interface ESSHelper : NSObject<NSFetchedResultsControllerDelegate>{
    id<NSFetchedResultsControllerDelegate> delete;
}

+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;
+(BOOL )createUser:(NSString *)username password:(NSString *)password name:(NSString *)name email:(NSString *)email;
+(NSString *)dayLabelForMessage:(NSDate *)msgDate;
+ (NSString*) createUniqueFileNameWithoutExtension;

+ (UIImage *)scaleAndRotateImage:(UIImage *)image;

+ (void)showAlertWithTitle : (NSString *)title andMessage:(NSString *)message;
+ (ESSAppDelegate *)appDelegate;
+ (XMPPStream *)xmppStream;
+ (UIImage *)loggedInUserProfileImage;
+ (UIBarButtonItem *)loggedInUserProfileImageBarButton;
+ (NSFetchedResultsController *)fetchedResultsController;
+ (NSString *)displayName:(NSString *)name;
+ (NSString *)userFromJid:(NSString *)jidString;
+ (void)setServerName:(NSString *)serverName;
+ (NSString *)hostName;
+ (NSString *)xMPPServer;
+ (NSString *)xmppProxyServer;
+ (NSString *)xmppConferenceServer;
+ (NSString *)xmppSearchServer;
+ (NSString *)generateIDWithPrefix:(NSString *)_prefix;
+ (NSString *)mediaType:(NSString *)fName;
+ (NSMutableDictionary *)makeJSONForFileSending:(NSString *)url type:(NSString *)type;
+ (NSMutableDictionary *)makeJSONForTextSending:(NSString *)text type:(NSString *)type;
+ (ESSJsonMessageModal *)getURLFromJSON:(NSMutableDictionary *)dict;
+ (ESSJsonMessageModal *)getTextFromJSON:(NSMutableDictionary *)dict;
+ (NSString *)fileNameFromFilePath:(NSString *)filePath;
+ (NSString *)mimeType:(NSString *)fileName;
@end
