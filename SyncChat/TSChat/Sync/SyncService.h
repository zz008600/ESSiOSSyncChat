//
//  SyncService.h
//  SyncService
//
//  Created by essadmin on 5/15/14.
//  Copyright (c) 2014 ESS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLink/AppLink.h>


#define PLACEHOLDER_APPNAME @"SyncChat"
#define PLACEHOLDER_APPID @"65537"
#define PREFS_MTU_SIZE @"mtuSize"
#define PREFS_SEND_DELAY @"sendDelay"
#define PREFS_FIRST_RUN @"firstRun"
#define PREFS_PROTOCOL @"protocol"
#define PREFS_IPADDRESS @"ipaddress"
#define PREFS_PORT @"port"
#define PREFS_TYPE @"type"




@interface SyncService : NSObject<FMCProxyListener,FMCTransportListener> {
    
    FMCSyncProxy* proxy;
    int autoIncCorrID;
    BOOL isLocked;
    BOOL isDD;
    int cmdID;
    BOOL syncInitialized;
}

@property (strong, nonatomic)NSMutableDictionary * allVoiceCommand;
@property (strong, nonatomic)NSMutableData *audioPassThruData;

+(void) testMethod;

#pragma mark -Proxy Life Management Functions
+(SyncService *)sharedInstance;
-(void) setupProxy;
-(void) setup;
-(void) sendRPCMessage:(FMCRPCRequest *)rpcMsg;
-(void) savePreferences;

#pragma mark - RPC Function Calls
-(void) showPressed:(NSString *)messageF1  messageF2:(NSString *)messageF2;
-(void) showAdvancedPressedWithLine1Text:(NSString *)line1Text
                                   line2:(NSString *)line2Text
                                   line3:(NSString *)line3Text
                                   line4:(NSString *)line4Text
                               statusBar:(NSString *)statusBar
                              mediaClock:(NSString *)mediaClock
                              mediaTrack:(NSString *)mediaTrack
                               alignment:(FMCTextAlignment *)textAlignment;
- (void) showPressed:(NSString *)message
      WithSubMessage:(NSString *)subMessage
      andSoftButtons:(NSMutableArray *)softButtons;

#pragma mark - RPC Speak Function Calls
-(void) speakPressed:(NSString *)message;

#pragma mark - RPC Alert Function Calls
-(void) alertPressed:(NSString *)message;
-(void) alertAdvancedPressedwithTTSChunks:(NSArray *)ttsChucks
                               alertText1:(NSString *)alertText1
                               alertText2:(NSString *)alertText2
                               alertText3:(NSString *)alertText3
                                 playTone:(NSNumber *)playTone
                                 duration:(NSNumber *)duration
                              softButtons:(NSArray *)softButtons ;

#pragma mark - RPC ScrollableMessage Function Calls
-(void) scrollableMessagePressedWithScrollableMessageBody:(NSString *)scrollableMessageBody
                                                 timeOut :(NSNumber *)timeOut
                                              softButtons:(NSArray *)softbuttons;

#pragma mark - RPC Command Function Calls
-(void) addCommand:(NSString *)message;
-(void) addAdvancedCommandPressedwithMenuName:(NSString *)menuName
                                     position:(NSNumber *)position
                                     parentID:(NSNumber *)parentID
                                   vrCommands:(NSArray *)vrCommands
                                    iconValue:(NSString *)iconValue
                                     iconType:(FMCImageType *)iconType;

-(void) deleteCommandPressed:(NSNumber *)cmdID;

#pragma mark - RPC TTS Function Calls
-(void) speakStringUsingTTS:(NSString *)stringValue;
-(void) speakStringUsingTTSChunks:(NSArray *)Chunks;

#pragma mark - RPC SubMenu Function Calls
-(void) addSubMenuPressedwithID:(NSNumber *)menuID
                       menuName:(NSString *)menuName
                       position:(NSNumber *)position;
-(void) deleteSubMenuPressedwithID:(NSNumber *)menuID;

#pragma mark - RPC Interaction Choice Function Calls
-(void) createInteractionChoiceSetPressedWithID:(NSNumber *)interactionChoiceSetID
                                      choiceSet:(NSArray *)choices;

-(void) deleteInteractionChoiceSetPressedWithID:(NSNumber *)interactionChoiceSetID;

#pragma mark - RPC Perform Interaction  Function Calls
-(void) performInteractionPressedwithInitialPrompt:(NSArray*)initialChunks
                                       initialText:(NSString*)initialText
                        interactionChoiceSetIDList:(NSArray*)interactionChoiceSetIDList
                                        helpChunks:(NSArray*)helpChunks
                                     timeoutChunks:(NSArray*)timeoutChunks
                                   interactionMode:(FMCInteractionMode*)interactionMode
                                           timeout:(NSNumber*)timeout
                                            vrHelp:(NSArray*)vrHelp ;


#pragma mark - RPC Subscribe Button  Function Calls
-(void) subscribeButtonPressed:(FMCButtonName *)buttonName;
-(void) unsubscribeButtonPressed:(FMCButtonName *)buttonName;

#pragma mark - RPC AudioPassThru  Function Calls
- (void) performAudioPassThruPressedWithInitialPrompt:(NSString *)initialPrompt
                                         disPlayText1:(NSString *)disPlayText1
                                         disPlayText2:(NSString *)disPlayText2
                                         samplingRate:(FMCSamplingRate *)samplingRate
                                          maxDuration:(NSNumber *)maxDuration
                                        bitsPerSample:(FMCBitsPerSample *)bitsPerSample
                                            audioType:(FMCAudioType *)audioType
                                            muteAudio:(NSNumber *)muteAudio;
- (void)endAudioPassThruPressed;

#pragma mark - RPC VehicleData  Function Calls
- (void)subscribeVehicleDataPressedWithGps:(NSNumber *)gps speed:(NSNumber *)speed rpm:(NSNumber *)rpm fuelLevel:(NSNumber *)fuelLevel
                            fuelLevelState:(NSNumber *)fuelLevelState  instantFuelConsumption:(NSNumber *)instantFuelConsumption
                      externalTemperature :(NSNumber *)externalTemperature prndl:(NSNumber *)prndl tirePressure:(NSNumber *)tirePressure
                                  odometer:(NSNumber *)odometer
                                beltStatus:(NSNumber *)beltStatus
                           bodyInformation:(NSNumber *)bodyInformation
                              deviceStatus:(NSNumber *)deviceStatus
                             driverBraking:(NSNumber *)driverBraking
                               wiperStatus:(NSNumber *)wiperStatus
                            headLampStatus:(NSNumber *)headLampStatus
                              engineTorque:(NSNumber *)engineTorque
                          accPedalPosition:(NSNumber *)accPedalPosition
                        steeringWheelAngle:(NSNumber *)steeringWheelAngle;
-(void) getVehicleDataPressedWithGps:(NSNumber *)gps
                               speed:(NSNumber *)speed
                                 rpm:(NSNumber *)rpm
                           fuelLevel:(NSNumber *)fuelLevel
                      fuelLevelState:(NSNumber *)fuelLevelState
              instantFuelConsumption:(NSNumber *)instantFuelConsumption
                externalTemperature :(NSNumber *)externalTemperature
                                 vin:(NSNumber *)vin
                               prndl:(NSNumber *)prndl
                        tirePressure:(NSNumber *)tirePressure
                            odometer:(NSNumber *)odometer
                          beltStatus:(NSNumber *)beltStatus
                     bodyInformation:(NSNumber *)bodyInformation
                        deviceStatus:(NSNumber *)deviceStatus
                       driverBraking:(NSNumber *)driverBraking
                         wiperStatus:(NSNumber *)wiperStatus
                      headLampStatus:(NSNumber *)headLampStatus
                        engineTorque:(NSNumber *)engineTorque
                    accPedalPosition:(NSNumber *)accPedalPosition
                  steeringWheelAngle:(NSNumber *)steeringWheelAngle;

- (void) unSubscribeVehicleDataPressedWithGps:(NSNumber *)gps
                                        speed:(NSNumber *)speed
                                          rpm:(NSNumber *)rpm
                                    fuelLevel:(NSNumber *)fuelLevel
                               fuelLevelState:(NSNumber *)fuelLevelState
                       instantFuelConsumption:(NSNumber *)instantFuelConsumption
                         externalTemperature :(NSNumber *)externalTemperature
                                        prndl:(NSNumber *)prndl
                                 tirePressure:(NSNumber *)tirePressure
                                     odometer:(NSNumber *)odometer
                                   beltStatus:(NSNumber *)beltStatus
                              bodyInformation:(NSNumber *)bodyInformation
                                 deviceStatus:(NSNumber *)deviceStatus
                                driverBraking:(NSNumber *)driverBraking
                                  wiperStatus:(NSNumber *)wiperStatus
                               headLampStatus:(NSNumber *)headLampStatus
                                 engineTorque:(NSNumber *)engineTorque
                             accPedalPosition:(NSNumber *)accPedalPosition
                           steeringWheelAngle:(NSNumber *)steeringWheelAngle;

#pragma mark - RPC GlobalProperties  Function Calls
-(void) setGlobalPropertiesPressedWithHelpText:(NSString *)helpText
                                   timeoutText:(NSString *)timeoutText;
-(void) resetGlobalPropertiesPressedwithProperties:(NSArray *)properties;


#pragma mark - RPC ChangeRegistration  Function Calls
- (void)changeRegistrationPressedWithLanguage:(FMCLanguage *)language WithHmiDisplayLanguage:(FMCLanguage *)hmiDisplayLanguage;
-(void) unregisterAppInterfacePressed;

#pragma mark - RPC Set Media Time Function Calls
-(void) setMediaClockTimerPressedwithHours:(NSNumber *)hours
                                   minutes:(NSNumber *)minutes
                                   seconds:(NSNumber *)seconds
                                updateMode:(FMCUpdateMode *)updateMode;



-(void) initProperties;







#pragma mark -Sync Custom Method
-(void) alert:(NSString *)msg;
-(void) postToConsoleLog:(id)object;
-(void) welcomeToSyncChat;
-(void) registerAcessory;

@end
