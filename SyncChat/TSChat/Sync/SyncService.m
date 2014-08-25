//
//  SyncService.m
//  SyncService
//
//  Created by essadmin on 5/15/14.
//  Copyright (c) 2014 ESS. All rights reserved.
//

#import "SyncService.h"



@implementation SyncService
static SyncService *gInstance = NULL;

+(void)testMethod{
    NSLog(@"Setup Sucsess");
}

#pragma mark -Proxy Life Management Functions

+(SyncService *)sharedInstance{
    @synchronized(self)
	{
		if (gInstance == NULL)
			gInstance = [[self alloc] init];
	}
	return gInstance;
}

-(void)initProperties{
    _allVoiceCommand=[[NSMutableDictionary alloc] init];
}

-(void) setup {
    FMCShow* msg = [FMCRPCRequestFactory buildShowWithMainField1:@"Welcome" mainField2:PLACEHOLDER_APPNAME alignment:[FMCTextAlignment CENTERED] correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
	//msg.mediaTrack = @"Sync Music App";
    [proxy sendRPCRequest:msg];
    _allVoiceCommand = [[NSMutableDictionary alloc]init];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"HMIStatusFullForNavigate" object:nil]];
    
    
}

-(void) sendRPCMessage:(FMCRPCRequest *)rpcMsg {
    
    [proxy sendRPCRequest:rpcMsg];
    
}



// =====================================
// Proxy Life Management Functions
// =====================================



-(void) savePreferences {
    
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //Set to match settings.bundle defaults
    if (![[prefs objectForKey:PREFS_FIRST_RUN] isEqualToString:@"False"]) {
        [prefs setObject:@"False" forKey:PREFS_FIRST_RUN];
        [prefs setObject:@"iap" forKey:PREFS_PROTOCOL];
        [prefs setObject:@"192.168.0.1" forKey:PREFS_IPADDRESS];
        [prefs setObject:@"50007" forKey:PREFS_PORT];
    }
	[prefs synchronize];
}

-(void) setupProxy {
    
    [FMCDebugTool logInfo:@"setupProxy"];
    
    [self savePreferences];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([[prefs objectForKey:PREFS_PROTOCOL] isEqualToString:@"tcpl"]) {
        proxy = [FMCSyncProxyFactory buildSyncProxyWithListener: self
                                                   tcpIPAddress: nil
                                                        tcpPort: [prefs objectForKey:PREFS_PORT]];
    } else if ([[prefs objectForKey:PREFS_PROTOCOL] isEqualToString:@"tcps"]) {
        proxy = [FMCSyncProxyFactory buildSyncProxyWithListener: self
                                                   tcpIPAddress: [prefs objectForKey:PREFS_IPADDRESS]
                                                        tcpPort: [prefs objectForKey:PREFS_PORT]];
    } else
        proxy = [FMCSyncProxyFactory buildSyncProxyWithListener: self];
    
    NSLog(@"%@",[proxy getProxyVersion]);
    
    
    [proxy.getTransport addTransportListener:self];
    
    autoIncCorrID = 101;
}

-(void) onProxyOpened {
    [FMCDebugTool logInfo:@"onProxyOpened"];
    FMCRegisterAppInterface* regRequest = [FMCRPCRequestFactory buildRegisterAppInterfaceWithAppName:PLACEHOLDER_APPNAME languageDesired:[FMCLanguage EN_US] appID:PLACEHOLDER_APPID];
    regRequest.isMediaApplication = [NSNumber numberWithBool:YES];
    regRequest.ngnMediaScreenAppName = nil;
    regRequest.vrSynonyms = nil;
    [proxy sendRPCRequest:regRequest];
}

-(void) onError:(NSException*) e {
	[FMCDebugTool logInfo:@"proxy error occurred: %@", e];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"HMIStatusForNavigateToRootViewController" object:nil]];
}

-(void) onProxyClosed {
    [FMCDebugTool logInfo:@"onProxyClosed"];
    [self tearDownProxy];
	[self setupProxy];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"HMIStatusForNavigateToRootViewController" object:nil]];
   // [self registerAcessory];
}


-(void) onOnHMIStatus:(FMCOnHMIStatus*) notification {
    
    if (notification.hmiLevel == FMCHMILevel.HMI_NONE ) {
        [FMCDebugTool logInfo:@"HMI_NONE"];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"HMIStatusForNavigateToRootViewController" object:nil]];
	} else if (notification.hmiLevel == FMCHMILevel.HMI_FULL ) {
        
        [FMCDebugTool logInfo:@"HMI_FULL"];
        if	(syncInitialized)
            return;
        syncInitialized = YES;
        [self setup];
        [NSTimer scheduledTimerWithTimeInterval:0.25
                                         target:self
                                       selector:@selector(welcomeToSyncChat)
                                       userInfo:nil
                                        repeats:NO];
        
        
    } else if (notification.hmiLevel == FMCHMILevel.HMI_BACKGROUND ) {
        
        [FMCDebugTool logInfo:@"HMI_BACKGROUND"];
        
    } else if (notification.hmiLevel == FMCHMILevel.HMI_LIMITED ) {
        
        [FMCDebugTool logInfo:@"HMI_LIMTED"];
	}
}


-(void) tearDownProxy {
  	[FMCDebugTool logInfo:@"tearDownProxy"];
	[proxy dispose];
	proxy = nil;
}

-(void) onOnDriverDistraction:(FMCOnDriverDistraction*)notification {
    NSLog(@"--------------------------------------3");
    
    if (notification.state == FMCDriverDistractionState.DD_OFF ) {
        isDD = NO;
        [FMCDebugTool logInfo:@"DD Off"];
        
	} else if (notification.state == FMCDriverDistractionState.DD_ON ) {
        isDD = YES;
        [FMCDebugTool logInfo:@"DD On"];
        
    }
}

// FMCTransportListener Methods:
- (void) onTransportConnected{
}
- (void) onTransportDisconnected{
    NSLog(@"--------------------------------------2");
    
    [FMCDebugTool logInfo:@"onTransportDisconnected"];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"HMIStatusForNavigateToRootViewController" object:nil]];
    
}
- (void) onBytesReceived:(Byte*)bytes length:(long) length{
    
    
}

#pragma mark - RPC Show Function Calls

- (void) showPressed:(NSString *)messageF1  messageF2:(NSString *)messageF2{
    FMCShow* msg = [FMCRPCRequestFactory buildShowWithMainField1:messageF1 mainField2:messageF2 alignment:[FMCTextAlignment CENTERED] correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
	//msg.mediaTrack = @"AppLink";
    [proxy sendRPCRequest:msg];
    [self postToConsoleLog:msg];
}

-(void) showAdvancedPressedWithLine1Text:(NSString *)line1Text line2:(NSString *)line2Text line3:(NSString *)line3Text line4:(NSString *)line4Text  statusBar:(NSString *)statusBar mediaClock:(NSString *)mediaClock mediaTrack:(NSString *)mediaTrack alignment:(FMCTextAlignment *)textAlignment {
    FMCShow *msg = [FMCRPCRequestFactory buildShowWithMainField1:line1Text
                                                      mainField2:line2Text
                                                      mainField3:line3Text
                                                      mainField4:line4Text
                                                       statusBar:statusBar
                                                      mediaClock:mediaClock
                                                      mediaTrack:mediaTrack
                                                       alignment:[FMCTextAlignment LEFT_ALIGNED]
                                                         graphic:nil
                                                     softButtons:nil
                                                   customPresets:nil
                                                   correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:msg];
    [self postToConsoleLog:msg];;
}



- (void) showPressed:(NSString *)message  WithSubMessage:(NSString *)subMessage andSoftButtons:(NSMutableArray *)softButtons{
    
    NSMutableArray *softButtonArray = [[NSMutableArray alloc] init];
    for (int sbtmCount = 0; sbtmCount < [softButtons count]; sbtmCount++) {
        FMCSoftButton *softButton = [[FMCSoftButton alloc] init];
        softButton.softButtonID = [NSNumber numberWithInt: [[[softButtons objectAtIndex:sbtmCount] objectForKey:@"Index"]intValue]];
        softButton.text = [[softButtons objectAtIndex:sbtmCount] objectForKey:@"Value"];
        //softButton.image = [[FMCImage alloc] init] ;
        //softButton.image.imageType = [FMCImageType STATIC];
        //softButton.image.value = [NSString stringWithFormat:@"%d", i];
        softButton.type = [FMCSoftButtonType BOTH];
        softButton.isHighlighted = [NSNumber numberWithBool:false];
        softButton.systemAction = [FMCSystemAction KEEP_CONTEXT];
        [softButtonArray addObject:softButton];
    }
    
    FMCShow *msg = [FMCRPCRequestFactory buildShowWithMainField1:message
                                                      mainField2:subMessage
                                                      mainField3:nil
                                                      mainField4:nil
                                                       statusBar:nil
                                                      mediaClock:nil
                                                      mediaTrack:nil
                                                       alignment:[FMCTextAlignment CENTERED]
                                                         graphic:nil
                                                     softButtons:softButtonArray
                                                   customPresets:nil
                                                   correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    
    [proxy sendRPCRequest:msg];
    //[self postToConsoleLog:msg];;
}


-(void) onShowResponse:(FMCShowResponse*) response {
   // [self alert:@"Error"];
	[self postToConsoleLog:response];
}

#pragma mark - RPC Speak Function Calls

- (void) speakPressed:(NSString *)message {
    FMCSpeak* req = [FMCRPCRequestFactory buildSpeakWithTTS:message correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    // [self postToConsoleLog:req];
}

-(void) onSpeakResponse:(FMCSpeakResponse*) response {
	[self postToConsoleLog:response];
}

#pragma mark - RPC Alert Function Calls

- (void) alertPressed:(NSString *)message {
    FMCAlert* req = [FMCRPCRequestFactory buildAlertWithTTS:message alertText1:message alertText2:@"" playTone:[NSNumber numberWithBool:YES] duration:[NSNumber numberWithInt:5000] correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //[self postToConsoleLog:req];
}

-(void) alertAdvancedPressedwithTTSChunks:(NSArray *)ttsChucks alertText1:(NSString *)alertText1 alertText2:(NSString *)alertText2 alertText3:(NSString *)alertText3  playTone:(NSNumber *)playTone duration:(NSNumber *)duration softButtons:(NSArray *)softButtons {
    
    
    FMCAlert *req = [FMCRPCRequestFactory buildAlertWithTTSChunks:ttsChucks alertText1:alertText1 alertText2:alertText2 alertText3:alertText3 playTone:playTone duration:duration softButtons:softButtons correlationID:[NSNumber numberWithInt:autoIncCorrID++] ];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}


-(void) onAlertResponse:(FMCAlertResponse*) response {
	[self postToConsoleLog:response];
}

#pragma mark - RPC ScrollableMessage Function Calls
//
- (void)scrollableMessagePressedWithScrollableMessageBody:(NSString *)scrollableMessageBody timeOut :(NSNumber *)timeOut softButtons:(NSArray *)softbuttons
{
    FMCScrollableMessage *req = [FMCRPCRequestFactory buildScrollableMessage:scrollableMessageBody timeout:timeOut softButtons:softbuttons correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    
    [proxy sendRPCRequest:req];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"consoleLog" object:req]];
}

-(void) onScrollableMessageResponse:(FMCScrollableMessageResponse*) response {
    [self postToConsoleLog:response];
}


#pragma mark - RPC Command Function Calls

-(void) addCommand:(NSString *)message {
    NSArray *vrc = [NSArray arrayWithObjects:message, nil];
    FMCAddCommand *command = [FMCRPCRequestFactory buildAddCommandWithID:[NSNumber numberWithInt:cmdID] menuName:message vrCommands:vrc correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:command];
    //[_allVoiceCommand setObject:message forKey:[NSString stringWithFormat:@"%d",cmdID]];
    NSLog(@"CMDID ---- %i",cmdID);
    cmdID++;
    //[self postToConsoleLog:command];
}

-(void) addCommand:(NSString *)message  vrCommands:(NSMutableArray *)vrCommnds{
    NSArray *vrc = [[NSArray alloc] initWithArray:vrCommnds];
    FMCAddCommand *command = [FMCRPCRequestFactory buildAddCommandWithID:[NSNumber numberWithInt:cmdID] menuName:message vrCommands:vrc correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:command];
    [_allVoiceCommand setObject:message forKey:[NSString stringWithFormat:@"%d",cmdID]];
    NSLog(@"CMDID ---- %i",cmdID);
    cmdID++;
    //[self postToConsoleLog:command];
}

-(void) addAdvancedCommandPressedwithMenuName:(NSString *)menuName position:(NSNumber *)position parentID:(NSNumber *)parentID vrCommands:(NSArray *) vrCommands iconValue:(NSString *)iconValue iconType:(FMCImageType *)iconType {
    [FMCDebugTool logInfo:@"Added addCommand with cmdID = %d and correlationID = %d", cmdID, autoIncCorrID];
    FMCAddCommand *command = [FMCRPCRequestFactory buildAddCommandWithID:[NSNumber numberWithInt:cmdID] menuName:menuName parentID:parentID position:position vrCommands:vrCommands iconValue:iconValue iconType:iconType correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:command];
    cmdID++;
    [self postToConsoleLog:command];
}


-(void) onAddCommandResponse:(FMCAddCommandResponse*) response {
    NSLog(@"Add command Response %i",[self getCMDID]);
    [self postToConsoleLog:response];
}

-(void) deleteCommandPressed:(NSNumber *)commandID {
    FMCDeleteCommand *req = [FMCRPCRequestFactory
                             buildDeleteCommandWithID:commandID
                             correlationID:[NSNumber
                                            numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //[self postToConsoleLog:req];
}

-(void) onDeleteCommandResponse:(FMCDeleteCommandResponse*) response{
    
}

-(void) onOnCommand:(FMCOnCommand*) response {
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"onVoiceCommand" object:response]];
}

#pragma mark - RPC TTS Function Calls

- (void) speakStringUsingTTS:(NSString *)stringValue {
    FMCSpeak* req = [FMCRPCRequestFactory buildSpeakWithTTS:stringValue correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //[self postToConsoleLog:req];
}
- (void) speakStringUsingTTSChunks:(NSArray *)featureChunkArray {
    
    if ([featureChunkArray count]) {
        FMCSpeak* req = [FMCRPCRequestFactory buildSpeakWithTTS:(NSString *)[featureChunkArray objectAtIndex:0]  correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
        [(NSMutableArray*)req.ttsChunks addObject:[FMCTTSChunkFactory buildTTSChunkForString:FMCJingle.INITIAL_JINGLE type:FMCSpeechCapabilities.PRE_RECORDED]];
        for (int i=1; i<[featureChunkArray count]; i++) {
            [(NSMutableArray*)req.ttsChunks addObject:[FMCTTSChunkFactory buildTTSChunkForString:(NSString *)[featureChunkArray objectAtIndex:i] type:FMCSpeechCapabilities.TEXT]];
        }
        [proxy sendRPCRequest:req];
        //[self postToConsoleLog:req];
    }
}

#pragma mark - RPC SubMenu Function Calls

-(void) addSubMenuPressedwithID:(NSNumber *)menuID menuName:(NSString *)menuName
                       position:(NSNumber *)position {
    FMCAddSubMenu *req =
    [FMCRPCRequestFactory buildAddSubMenuWithID:menuID
                                       menuName:menuName
                                       position:position correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onAddSubMenuResponse:(FMCAddSubMenuResponse*) response {
    [self postToConsoleLog:response];
}

-(void) deleteSubMenuPressedwithID:(NSNumber *)menuID {
    FMCDeleteSubMenu *req = [FMCRPCRequestFactory buildDeleteSubMenuWithID:menuID correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onDeleteSubMenuResponse:(FMCDeleteSubMenuResponse*) response {
    [self postToConsoleLog:response];
}

#pragma mark - RPC Interaction Choice Function Calls

-(void) createInteractionChoiceSetPressedWithID:(NSNumber *)interactionChoiceSetID choiceSet:(NSArray *)choices {
    FMCCreateInteractionChoiceSet *req = [FMCRPCRequestFactory buildCreateInteractionChoiceSetWithID:interactionChoiceSetID choiceSet:choices correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onCreateInteractionChoiceSetResponse:(FMCCreateInteractionChoiceSetResponse*) response {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"onCreateInteractionChoiceSetResponse" object:response]];
	[self postToConsoleLog:response];
}


-(void) deleteInteractionChoiceSetPressedWithID:(NSNumber *)interactionChoiceSetID {
    FMCDeleteInteractionChoiceSet *req = [FMCRPCRequestFactory buildDeleteInteractionChoiceSetWithID:interactionChoiceSetID correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onDeleteInteractionChoiceSetRespfhonse:(FMCDeleteInteractionChoiceSetResponse*) response {
    [self postToConsoleLog:response];
}

#pragma mark - RPC Perform Interaction  Function Calls

-(void) performInteractionPressedwithInitialPrompt:(NSArray*)initialChunks initialText:(NSString*)initialText interactionChoiceSetIDList:(NSArray*)interactionChoiceSetIDList helpChunks:(NSArray*)helpChunks timeoutChunks:(NSArray*)timeoutChunks interactionMode:(FMCInteractionMode*) interactionMode timeout:(NSNumber*)timeout vrHelp:(NSArray*)vrHelp {
    FMCPerformInteraction *req = [FMCRPCRequestFactory buildPerformInteractionWithInitialChunks:initialChunks initialText:initialText interactionChoiceSetIDList:interactionChoiceSetIDList helpChunks:helpChunks timeoutChunks:timeoutChunks interactionMode:interactionMode timeout:timeout vrHelp:vrHelp correlationID:[NSNumber numberWithInt:autoIncCorrID++] ];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onPerformInteractionResponse:(FMCPerformInteractionResponse*) response {
    
   // NSLog(@"responce : %i",[response.choiceID intValue]);
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"onPerformInteractionResponse" object:response]];
	[self postToConsoleLog:response];
}


#pragma mark - RPC Subscribe Button  Function Calls

-(void) subscribeButtonPressed:(FMCButtonName *)buttonName {
    FMCSubscribeButton *req = [FMCRPCRequestFactory buildSubscribeButtonWithName:buttonName correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onSubscribeButtonResponse:(FMCSubscribeButtonResponse*) response {
	[self postToConsoleLog:response];
}


-(void) unsubscribeButtonPressed:(FMCButtonName *)buttonName {
    FMCUnsubscribeButton *req = [FMCRPCRequestFactory buildUnsubscribeButtonWithName:buttonName correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onUnsubscribeButtonResponse:(FMCUnsubscribeButtonResponse*) response {
    [self postToConsoleLog:response];
}


#pragma mark - RPC AudioPassThru  Function Calls

- (void)performAudioPassThruPressedWithInitialPrompt:(NSString *)initialPrompt
                                        disPlayText1:(NSString *)disPlayText1
                                        disPlayText2:(NSString *)disPlayText2
                                        samplingRate:(FMCSamplingRate *)samplingRate
                                         maxDuration:(NSNumber *)maxDuration
                                       bitsPerSample:(FMCBitsPerSample *)bitsPerSample
                                           audioType:(FMCAudioType *)audioType
                                           muteAudio:(NSNumber *)muteAudio

{
    //audioPassThruData = [[NSMutableData alloc] init];
    
    FMCPerformAudioPassThru *req = [FMCRPCRequestFactory buildPerformAudioPassThruWithInitialPrompt:initialPrompt
                                                                          audioPassThruDisplayText1:disPlayText1
                                                                          audioPassThruDisplayText2:disPlayText2
                                                                                       samplingRate:samplingRate
                                                                                        maxDuration:maxDuration
                                                                                      bitsPerSample:bitsPerSample
                                                                                          audioType:audioType
                                                                                          muteAudio:muteAudio
                                                                                      correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
}
-(void) onOnAudioPassThru:(FMCOnAudioPassThru*) notification {
    [self postToConsoleLog:notification];
    
    //Fill Buffer
    NSData *test = [NSData dataWithData:notification.bulkData];
    [_audioPassThruData appendData:test];
    //Write Data To File
    
}

-(void) onPerformAudioPassThruResponse:(FMCPerformAudioPassThruResponse*) response {
    [self postToConsoleLog:response];
  
    NSData *dataToWrite = [NSData dataWithData:_audioPassThruData];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savePath = [documentsDirectory stringByAppendingPathComponent:@"Recording.pcm"];
    [dataToWrite writeToFile:savePath atomically:NO];
    
     [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"PerformAudioPassThruResponse" object :response]];
}

- (void)endAudioPassThruPressed
{
    FMCEndAudioPassThru *req = [FMCRPCRequestFactory buildEndAudioPassThruWithCorrelationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onEndAudioPassThruResponse:(FMCEndAudioPassThruResponse*) response {
    [self postToConsoleLog:response];
}


#pragma mark - RPC VehicleData  Function Calls

//
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
                        steeringWheelAngle:(NSNumber *)steeringWheelAngle
{
    FMCSubscribeVehicleData  *req = [FMCRPCRequestFactory  buildSubscribeVehicleDataWithGPS:gps  speed:speed  rpm:rpm
                                                                                  fuelLevel:fuelLevel
                                                                             fuelLevelState:fuelLevelState
                                                                     instantFuelConsumption:instantFuelConsumption
                                                                        externalTemperature:externalTemperature
                                                                                      prndl:prndl
                                                                               tirePressure:tirePressure
                                                                                   odometer:odometer
                                                                                 beltStatus:beltStatus
                                                                            bodyInformation:bodyInformation
                                                                               deviceStatus:deviceStatus
                                                                              driverBraking:driverBraking
                                                                                wiperStatus:wiperStatus
                                                                             headLampStatus:headLampStatus
                                                                               engineTorque:engineTorque
                                                                           accPedalPosition:accPedalPosition
                                                                         steeringWheelAngle:steeringWheelAngle
                                                                              correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onSubscribeVehicleDataResponse:(FMCSubscribeVehicleDataResponse*) response {
    [self postToConsoleLog:response];
}


//UnsubscribeVehicleData
- (void)unSubscribeVehicleDataPressedWithGps:(NSNumber *)gps speed:(NSNumber *)speed rpm:(NSNumber *)rpm fuelLevel:(NSNumber *)fuelLevel
                              fuelLevelState:(NSNumber *)fuelLevelState  instantFuelConsumption:(NSNumber *)instantFuelConsumption
                        externalTemperature :(NSNumber *)externalTemperature prndl:(NSNumber *)prndl
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
                          steeringWheelAngle:(NSNumber *)steeringWheelAngle
{
    FMCUnsubscribeVehicleData *req = [FMCRPCRequestFactory buildUnsubscribeVehicleDataWithGPS:gps speed:speed rpm:rpm
                                                                                    fuelLevel:fuelLevel
                                                                               fuelLevelState:fuelLevelState
                                                                       instantFuelConsumption:instantFuelConsumption
                                                                          externalTemperature:externalTemperature
                                                                                        prndl:prndl
                                                                                 tirePressure:tirePressure
                                                                                     odometer:odometer
                                                                                   beltStatus:beltStatus
                                                                              bodyInformation:bodyInformation
                                                                                 deviceStatus:deviceStatus
                                                                                driverBraking:driverBraking
                                                                                  wiperStatus:wiperStatus
                                                                               headLampStatus:headLampStatus
                                                                                 engineTorque:engineTorque
                                                                             accPedalPosition:accPedalPosition
                                                                           steeringWheelAngle:steeringWheelAngle
                                                                                correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onUnsubscribeVehicleDataResponse:(FMCUnsubscribeVehicleDataResponse*) response {
	[self postToConsoleLog:response];
}


//GetVehicleData
- (void)getVehicleDataPressedWithGps:(NSNumber *)gps speed:(NSNumber *)speed rpm:(NSNumber *)rpm fuelLevel:(NSNumber *)fuelLevel
                      fuelLevelState:(NSNumber *)fuelLevelState  instantFuelConsumption:(NSNumber *)instantFuelConsumption
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
                  steeringWheelAngle:(NSNumber *)steeringWheelAngle
{
    FMCGetVehicleData *req = [FMCRPCRequestFactory buildGetVehicleDataWithGPS:gps
                                                                        speed:speed
                                                                          rpm:rpm
                                                                    fuelLevel:fuelLevel
                                                               fuelLevelState:fuelLevelState
                                                       instantFuelConsumption:instantFuelConsumption
                                                          externalTemperature:externalTemperature
                                                                          vin:vin
                                                                        prndl:prndl
                                                                 tirePressure:tirePressure
                                                                     odometer:odometer
                                                                   beltStatus:beltStatus
                                                              bodyInformation:bodyInformation
                                                                 deviceStatus:deviceStatus
                                                                driverBraking:driverBraking
                                                                  wiperStatus:wiperStatus
                                                               headLampStatus:headLampStatus
                                                                 engineTorque:engineTorque
                                                             accPedalPosition:accPedalPosition
                                                           steeringWheelAngle:steeringWheelAngle
                                                                correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onGetVehicleDataResponse:(FMCGetVehicleDataResponse*) response{
    
}


-(void) onOnVehicleData:(FMCOnVehicleData*) notification {
    [self postToConsoleLog:notification];
}

#pragma mark - RPC GlobalProperties  Function Calls

-(void) setGlobalPropertiesPressedWithHelpText:(NSString *)helpText timeoutText:(NSString *)timeoutText {
    FMCSetGlobalProperties *req = [FMCRPCRequestFactory buildSetGlobalPropertiesWithHelpText:helpText timeoutText:timeoutText correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onSetGlobalPropertiesResponse:(FMCSetGlobalPropertiesResponse*) response {
	[self postToConsoleLog:response];
}

-(void) resetGlobalPropertiesPressedwithProperties:(NSArray *)properties {
    FMCResetGlobalProperties *req = [FMCRPCRequestFactory buildResetGlobalPropertiesWithProperties:properties correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onResetGlobalPropertiesResponse:(FMCResetGlobalPropertiesResponse*) response {
	[self postToConsoleLog:response];
}

#pragma mark - RPC ChangeRegistration  Function Calls
//
- (void)changeRegistrationPressedWithLanguage:(FMCLanguage *)language WithHmiDisplayLanguage:(FMCLanguage *)hmiDisplayLanguage
{
    FMCChangeRegistration *req = [FMCRPCRequestFactory buildChangeRegistrationWithLanguage:language hmiDisplayLanguage:hmiDisplayLanguage correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

- (void) onChangeRegistrationResponse:(FMCChangeRegistrationResponse*) response {
    [self postToConsoleLog:response];
}

-(void) unregisterAppInterfacePressed {
	FMCUnregisterAppInterface* req = [FMCRPCRequestFactory buildUnregisterAppInterfaceWithCorrelationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}

-(void) onUnregisterAppInterfaceResponse:(FMCUnregisterAppInterfaceResponse*) response {
    [self postToConsoleLog:response];
}


#pragma mark - RPC Set Media Time Function Calls

- (void) setMediaClockTimerPressedwithHours:(NSNumber *)hours minutes:(NSNumber *)minutes seconds:(NSNumber *)seconds updateMode:(FMCUpdateMode *)updateMode {
    FMCSetMediaClockTimer *req = [FMCRPCRequestFactory buildSetMediaClockTimerWithHours:hours minutes:minutes seconds:seconds updateMode:updateMode correlationID:[NSNumber numberWithInt:autoIncCorrID++]];
    [proxy sendRPCRequest:req];
    //  [self postToConsoleLog:req];
}
-(void) onSetMediaClockTimerResponse:(FMCSetMediaClockTimerResponse*) response {
	[self postToConsoleLog:response];
}


#pragma mark - Implementation of FMCProxyListener

-(void) onOnButtonEvent:(FMCOnButtonEvent*) response {
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewConsoleControllerObject" object:response]];
    [self postToConsoleLog:response];
}

-(void) onOnButtonPress:(FMCOnButtonPress*) response {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"onButtonPress" object:response]];
    [self postToConsoleLog:response];
    
}

-(void) onGenericResponse:(FMCGenericResponse*) response
{
    [self postToConsoleLog:response];
}

-(void) onOnLanguageChange:(FMCOnLanguageChange*) notification {
    [self postToConsoleLog:notification];
}

-(void) onOnPermissionsChange:(FMCOnPermissionsChange*) notification {
    [self postToConsoleLog:notification];
}


-(void) onOnAppInterfaceUnregistered:(FMCOnAppInterfaceUnregistered*) response {
    [self postToConsoleLog:response];
}


#pragma mark -Sync Custom Method

-(int)getCMDID {
    return cmdID;
}
-(void)setCMID:(int)cmid{
    cmdID=cmid;
}

-(NSNumber*) getNextCorrID {
    autoIncCorrID++;
    return [NSNumber numberWithInt:autoIncCorrID];
}

-(void)registerAcessory{
    [[EAAccessoryManager sharedAccessoryManager]
     connectedAccessories];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:EAAccessoryDidDisconnectNotification object:nil]];
}

- (void)welcomeToSyncChat{
    [self speakPressed:@"Welcome To SyncChat"];
}

- (void)postToConsoleLog:(id)object{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"onRPCResponse" object :object]];
    
}

-(void)alert:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    [alert show];
    
}

@end
