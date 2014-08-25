//
//  YDFileReceiver.m
//  YDChat
//
//  Created by Peter van de Put on 16/12/2013.
//  Copyright (c) 2013 YourDeveloper. All rights reserved.
//

#import "ESSFileReceiver.h"
#import "XMPP.h"
#import "XMPPLogging.h"
#import "GCDAsyncSocket.h"
#import "NSData+XMPP.h"
#import "NSNumber+XMPP.h"
//#import "YDDefinitions.h"
#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * Does ARC support support GCD objects?
 * It does if the minimum deployment target is iOS 6+ or Mac OS X 10.8+
 **/
#if TARGET_OS_IPHONE

// Compiling for iOS

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000 // iOS 6.0 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else                                         // iOS 5.X or earlier
#define NEEDS_DISPATCH_RETAIN_RELEASE 1
#endif

#else

// Compiling for Mac OS X

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080     // Mac OS X 10.8 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else
#define NEEDS_DISPATCH_RETAIN_RELEASE 1     // Mac OS X 10.7 or earlier
#endif

#endif

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

// Define various states
#define STATE_INIT                0

#define STATE_PROXY_DISCO_ITEMS  10
#define STATE_PROXY_DISCO_INFO   11
#define STATE_PROXY_DISCO_ADDR   12
#define STATE_REQUEST_SENT       13
#define STATE_INITIATOR_CONNECT  14
#define STATE_ACTIVATE_SENT      15
#define STATE_TARGET_CONNECT     20
#define STATE_DONE               30
#define STATE_FAILURE            31

// Define various socket tags
#define SOCKS_OPEN             101
#define SOCKS_CONNECT          102
#define SOCKS_CONNECT_REPLY_1  103
#define SOCKS_CONNECT_REPLY_2  104
#define SOCKS_FILE_RECEIVE     10000

// Define various timeouts (in seconds)
#define TIMEOUT_DISCO_ITEMS   8.00
#define TIMEOUT_DISCO_INFO    8.00
#define TIMEOUT_DISCO_ADDR    5.00
#define TIMEOUT_CONNECT       8.00
#define TIMEOUT_READ          5.00
#define TIMEOUT_TOTAL        80.00

// Declare private methods
@interface ESSFileReceiver (PrivateAPI)
 
- (void)processDiscoItemsResponse:(XMPPIQ *)iq;
- (void)processDiscoInfoResponse:(XMPPIQ *)iq;
- (void)processDiscoAddressResponse:(XMPPIQ *)iq;
- (void)processRequestResponse:(XMPPIQ *)iq;
- (void)processActivateResponse:(XMPPIQ *)iq;
- (void)performPostInitSetup;
- (void)queryProxyCandidates;
- (void)queryNextProxyCandidate;
- (void)queryCandidateJIDs;
- (void)queryNextCandidateJID;
- (void)queryProxyAddress;
- (void)targetConnect;
- (void)targetNextConnect;
- (void)initiatorConnect;
- (void)setupDiscoTimerForDiscoItems;
- (void)setupDiscoTimerForDiscoInfo;
- (void)setupDiscoTimerForDiscoAddress;
- (void)doDiscoItemsTimeout:(NSString *)uuid;
- (void)doDiscoInfoTimeout:(NSString *)uuid;
- (void)doDiscoAddressTimeout:(NSString *)uuid;
- (void)doTotalTimeout;
- (void)succeed;
- (void)fail;
- (void)cleanup;
@end

@implementation ESSFileReceiver
static NSMutableArray *proxyCandidates;
@synthesize streamID,transferID,fileInfo;
/**
 * Called automatically (courtesy of Cocoa) before the first method of this class is called.
 * It may also be called directly, hence the safety mechanism.
 **/
+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized)
        {
		initialized = YES;
		proxyCandidates = [[NSMutableArray alloc] initWithObjects:kxmppProxyServer, nil];
        }
}


/**
 * Returns a list of proxy candidates.
 *
 * You may want to configure this to include NSUserDefaults stuff, or implement your own static/dynamic list.
 **/
+ (NSArray *)proxyCandidates
{
	NSArray *result = nil;
	
	@synchronized(proxyCandidates)
	{
    XMPPLogTrace();
    result = [proxyCandidates copy];
	}
	return result;
}

+ (void)setProxyCandidates:(NSArray *)candidates
{
	@synchronized(proxyCandidates)
	{
    XMPPLogTrace();
    [proxyCandidates removeAllObjects];
    [proxyCandidates addObjectsFromArray:candidates];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Init, Dealloc
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Initializes a new  socket to create a TCP connection by routing through a proxy.
 * This constructor configures the object to be the server accepting a connection from a client.
 **/
- (id)initWithStream:(XMPPStream *)stream incomingRequest:(XMPPIQ *)iq
{
	if ((self = [super init]))
        {
		XMPPLogTrace();
		
		// Store references
		xmppStream = stream;
		jid = [iq from];
		
		// Store a copy of the ID (which will be our uuid)
		uuid = [[iq elementID] copy];
		
		// Setup initial state for a server connection
		state = STATE_INIT;
		// Extract streamhost information from turn request
		NSXMLElement *query = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/bytestreams"];
		streamhosts = [[query elementsForName:@"streamhost"] mutableCopy];
		
		// Configure everything else
		[self performPostInitSetup];
        }
	return self;
}

/**
 * Common initialization tasks shared by all init methods.
 **/
- (void)performPostInitSetup
{
	// Create dispatch queue.
	turnQueue = dispatch_queue_create("FileReceiver", NULL);
}

/**
 * Standard deconstructor.
 * Release any objects we may have retained.
 * These objects should all be defined in the header.
 **/
- (void)dealloc
{
	XMPPLogTrace();
	
	if ((state > STATE_INIT) && (state < STATE_DONE))
        {
		XMPPLogWarn(@"%@: Deallocating prior to completion or cancellation. "
					@"You should explicitly cancel before releasing.", THIS_FILE);
        }
	
	if (turnTimer)
		dispatch_source_cancel(turnTimer);
	
	if (discoTimer)
		dispatch_source_cancel(discoTimer);
	
#if NEEDS_DISPATCH_RETAIN_RELEASE
	if (turnQueue)
		dispatch_release(turnQueue);
	
	if (delegateQueue)
		dispatch_release(delegateQueue);
	
	if (turnTimer)
		dispatch_release(turnTimer);
	
	if (discoTimer)
		dispatch_release(discoTimer);
#endif
	
	if ([asyncSocket delegate] == self)
        {
		[asyncSocket setDelegate:nil delegateQueue:NULL];
        if ([asyncSocket isConnected])
            [asyncSocket disconnect];
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Correspondence Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Starts  with the given delegate.
 * If  already been started, this method does nothing, and the existing delegate is not changed.
 **/
- (void)startWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)aDelegateQueue
{
	NSParameterAssert(aDelegate != nil);
	NSParameterAssert(aDelegateQueue != NULL);
	
	dispatch_async(turnQueue, ^{ @autoreleasepool {
		
		if (state != STATE_INIT)
            {
			XMPPLogWarn(@"%@: Ignoring start request. Turn procedure already started.", THIS_FILE);
			return;
            }
		
		// Set reference to delegate and delegate's queue.
		// Note that we do NOT retain the delegate.
		
		delegate = aDelegate;
		delegateQueue = aDelegateQueue;
		
#if NEEDS_DISPATCH_RETAIN_RELEASE
		dispatch_retain(delegateQueue);
#endif
		
		// Add self as xmpp delegate so we'll get message responses
		[xmppStream addDelegate:self delegateQueue:turnQueue];
		
		// Start the timer to calculate how long the procedure takes
		startTime = [[NSDate alloc] init];
		
		// Schedule timer to cancel the turn procedure.
		// This ensures that, in the event of network error or crash,
		
		turnTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, turnQueue);
		
		dispatch_source_set_event_handler(turnTimer, ^{ @autoreleasepool {
			
			[self doTotalTimeout];
			
		}});
		
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (TIMEOUT_TOTAL * NSEC_PER_SEC));
		
		dispatch_source_set_timer(turnTimer, tt, DISPATCH_TIME_FOREVER, 0.1);
		dispatch_resume(turnTimer);
        [self targetConnect];
		
	}});
}

 

/**
 * Aborts the  connection attempt.
 * The status will be changed to failure, and no delegate messages will be posted.
 **/
- (void)abort
{
	dispatch_block_t block = ^{ @autoreleasepool {
		
		if ((state > STATE_INIT) && (state < STATE_DONE))
            {
			// The only thing we really have to do here is move the state to failure.
			// This simple act should prevent any further action from being taken in this TUNRSocket object,
			// since every action is dictated based on the current state.
			state = STATE_FAILURE;
			
			// And don't forget to cleanup after ourselves
			[self cleanup];
            }
	}};
	
	if (dispatch_get_current_queue() == turnQueue)
		block();
	else
		dispatch_async(turnQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Communication
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * Sends the reply, from target to initiator, notifying the initiator of the streamhost we connected to.
 **/
- (void)sendReply
{
  	XMPPLogTrace();
	
	// <iq type="result" to="initiator" id="123">
	//   <query xmlns="http://jabber.org/protocol/bytestreams" sid="123">
	//     <streamhost-used jid="proxy.domain"/>
	//   </query>
	// </iq>
	
	NSXMLElement *streamhostUsed = [NSXMLElement elementWithName:@"streamhost-used"];
	[streamhostUsed addAttributeWithName:@"jid" stringValue:[proxyJID full]];
	
	NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/bytestreams"];
	[query addAttributeWithName:@"sid" stringValue:streamID];
	[query addChild:streamhostUsed];
	
	XMPPIQ *iq = [XMPPIQ iqWithType:@"result" to:jid elementID:uuid child:query];
	
	[xmppStream sendElement:iq];;
}

/**
 * Sends the error, from target to initiator, notifying the initiator we were unable to connect to any streamhost.
 **/
- (void)sendError
{
	XMPPLogTrace();
	
	// <iq type="error" to="initiator" id="123">
	//   <error code="404" type="cancel">
	//     <item-not-found xmlns="urn:ietf:params:xml:ns:xmpp-stanzas">
	//   </error>
	// </iq>
	
	NSXMLElement *inf = [NSXMLElement elementWithName:@"item-not-found" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"];
	
	NSXMLElement *error = [NSXMLElement elementWithName:@"error"];
	[error addAttributeWithName:@"code" stringValue:@"404"];
	[error addAttributeWithName:@"type" stringValue:@"cancel"];
	[error addChild:inf];
	
	XMPPIQ *iq = [XMPPIQ iqWithType:@"error" to:jid elementID:uuid child:error];
	
	[xmppStream sendElement:iq];
}

/**
 * Invoked by XMPPClient when an IQ is received.
 * We can determine if the IQ applies to us by checking its element ID.
 **/
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	// Disco queries (sent to jabber server) use id=discoUUID
	// P2P queries (sent to other Mojo app) use id=uuid
	
	if (state <= STATE_PROXY_DISCO_ADDR)
        {
		if (![discoUUID isEqualToString:[iq elementID]])
            {
			// Doesn't apply to us, or is a delayed response that we've decided to ignore
			return NO;
            }
        }
	else
        {
		if (![uuid isEqualToString:[iq elementID]])
            {
			// Doesn't apply to us
			return NO;
            }
        }
	
	XMPPLogTrace2(@"%@: %@ - state(%i)", THIS_FILE, THIS_METHOD, state);
	
	if (state == STATE_PROXY_DISCO_ITEMS)
        {
		[self processDiscoItemsResponse:iq];
        }
	else if (state == STATE_PROXY_DISCO_INFO)
        {
		[self processDiscoInfoResponse:iq];
        }
	else if (state == STATE_PROXY_DISCO_ADDR)
        {
		[self processDiscoAddressResponse:iq];
        }
	else if (state == STATE_REQUEST_SENT)
        {
		[self processRequestResponse:iq];
        }
	else if (state == STATE_ACTIVATE_SENT)
        {
		[self processActivateResponse:iq];
        }
	
	return YES;
}

- (void)processDiscoItemsResponse:(XMPPIQ *)iq
{
	XMPPLogTrace();
	
	// We queried the current proxy candidate for all known JIDs in it's disco list.
	//
	// <iq from="domain.org" to="initiator" id="123" type="result">
	//   <query xmlns="http://jabber.org/protocol/disco#items">
	//     <item jid="conference.domain.org"/>
	//     <item jid="proxy.domain.org"/>
	//   </query>
	// </iq>
	
	NSXMLElement *query = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/disco#items"];
	NSArray *items = [query elementsForName:@"item"];
	
	candidateJIDs = [[NSMutableArray alloc] initWithCapacity:[items count]];
	
	NSUInteger i;
	for(i = 0; i < [items count]; i++)
        {
		NSString *itemJidStr = [[[items objectAtIndex:i] attributeForName:@"jid"] stringValue];
		XMPPJID *itemJid = [XMPPJID jidWithString:itemJidStr];
		
		if(itemJid)
            {
			[candidateJIDs addObject:itemJid];
            }
        }
	
	[self queryCandidateJIDs];
}

- (void)processDiscoInfoResponse:(XMPPIQ *)iq
{
	XMPPLogTrace();
	
	// We queried a potential proxy server to see if it was indeed a proxy.
	//
	// <iq from="domain.org" to="initiator" id="123" type="result">
	//   <query xmlns="http://jabber.org/protocol/disco#info">
	//     <identity category="proxy" type="bytestreams" name="SOCKS5 Bytestreams Service"/>
	//     <feature var="http://jabber.org/protocol/bytestreams"/>
	//   </query>
	// </iq>
	
	NSXMLElement *query = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/disco#info"];
	NSArray *identities = [query elementsForName:@"identity"];
	
	BOOL found = NO;
	
	NSUInteger i;
	for(i = 0; i < [identities count] && !found; i++)
        {
		NSXMLElement *identity = [identities objectAtIndex:i];
		
		NSString *category = [[identity attributeForName:@"category"] stringValue];
		NSString *type = [[identity attributeForName:@"type"] stringValue];
		
		if([category isEqualToString:@"proxy"] && [type isEqualToString:@"bytestreams"])
            {
			found = YES;
            }
        }
	
	if(found)
        {
		// We found a proxy service!
		// Now we query the proxy for its public IP and port.
		[self queryProxyAddress];
        }
	else
        {
		// There are many jabber servers out there that advertise a proxy service via JID proxy.domain.tld.
		// However, not all of these servers have an entry for proxy.domain.tld in the DNS servers.
		// Thus, when we try to query the proxy JID, we end up getting a 404 error because our
		// jabber server was unable to connect to the given JID.
		//
		// We could ignore the 404 error, and try to connect anyways,
		// but this would be useless because we'd be unable to activate the stream later.
		
		XMPPJID *candidateJID = [candidateJIDs objectAtIndex:candidateJIDIndex];
		
		// So the service was not a useable proxy service, or will not allow us to use its proxy.
		//
		// Now most servers have serveral services such as proxy, conference, pubsub, etc.
		// If we queried a JID that started with "proxy", and it said no,
		// chances are that none of the other services are proxies either,
		// so we might as well not waste our time querying them.
		
		if([[candidateJID domain] hasPrefix:@"proxy"])
            {
			// Move on to the next server
			[self queryNextProxyCandidate];
            }
		else
            {
			// Try the next JID in the list from the server
			[self queryNextCandidateJID];
            }
        }
}

- (void)processDiscoAddressResponse:(XMPPIQ *)iq
{
	XMPPLogTrace();
	
	// We queried a proxy for its public IP and port.
	//
	// <iq from="domain.org" to="initiator" id="123" type="result">
	//   <query xmlns="http://jabber.org/protocol/bytestreams">
	//     <streamhost jid="proxy.domain.org" host="100.200.300.400" port="7777"/>
	//   </query>
	// </iq>
	
	NSXMLElement *query = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/bytestreams"];
	NSXMLElement *streamhost = [query elementForName:@"streamhost"];
	
	NSString *jidStr = [[streamhost attributeForName:@"jid"] stringValue];
	XMPPJID *streamhostJID = [XMPPJID jidWithString:jidStr];
	
	NSString *host = [[streamhost attributeForName:@"host"] stringValue];
	UInt16 port = [[[streamhost attributeForName:@"port"] stringValue] intValue];
	
	if(streamhostJID != nil || host != nil || port > 0)
        {
		[streamhost detach];
		[streamhosts addObject:streamhost];
        }
	
	// Finished with the current proxy candidate - move on to the next
	[self queryNextProxyCandidate];
}

- (void)processRequestResponse:(XMPPIQ *)iq
{
	XMPPLogTrace();
	
	// Target has replied - hopefully they've been able to connect to one of the streamhosts
	
	NSXMLElement *query = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/bytestreams"];
	NSXMLElement *streamhostUsed = [query elementForName:@"streamhost-used"];
	
	NSString *streamhostUsedJID = [[streamhostUsed attributeForName:@"jid"] stringValue];
	
	BOOL found = NO;
	NSUInteger i;
	for(i = 0; i < [streamhosts count] && !found; i++)
        {
		NSXMLElement *streamhost = [streamhosts objectAtIndex:i];
		
		NSString *streamhostJID = [[streamhost attributeForName:@"jid"] stringValue];
		
		if([streamhostJID isEqualToString:streamhostUsedJID])
            {
			NSAssert(proxyJID == nil && proxyHost == nil, @"proxy and proxyHost are expected to be nil");
			
			proxyJID = [XMPPJID jidWithString:streamhostJID];
			
			proxyHost = [[streamhost attributeForName:@"host"] stringValue];
			if([proxyHost isEqualToString:@"0.0.0.0"])
                {
				proxyHost = [proxyJID full];
                }
			
			proxyPort = [[[streamhost attributeForName:@"port"] stringValue] intValue];
			
			found = YES;
            }
        }
	
	if(found)
        {
		// The target is connected to the proxy
		// Now it's our turn to connect
		[self initiatorConnect];
        }
	else
        {
		// Target was unable to connect to any of the streamhosts we sent it
		[self fail];
        }
}

- (void)processActivateResponse:(XMPPIQ *)iq
{
	XMPPLogTrace();
	NSString *type = [[iq attributeForName:@"type"] stringValue];
	
	BOOL activated = NO;
	if (type)
        {
		activated = [type caseInsensitiveCompare:@"result"] == NSOrderedSame;
        }
	
	if (activated) {
		[self succeed];
	}
	else {
		[self fail];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Proxy Discovery
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Each query we send during the proxy discovery process has a different element id.
 * This allows us to easily use timeouts, so we can recover from offline servers, and overly slow servers.
 * In other words, changing the discoUUID allows us to easily ignore delayed responses from a server.
 **/
- (void)updateDiscoUUID
{
	discoUUID = [xmppStream generateUUID];
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Proxy Connection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)targetConnect
{
	XMPPLogTrace();
 	// Update state
	state = STATE_TARGET_CONNECT;
	
	// Start trying to connect to each streamhost in order
	streamhostIndex = -1;
	[self targetNextConnect];
}

- (void)targetNextConnect
{
	XMPPLogTrace();
 	streamhostIndex++;
	if(streamhostIndex < [streamhosts count])
        {
		NSXMLElement *streamhost = [streamhosts objectAtIndex:streamhostIndex];
		
		
		proxyJID = [XMPPJID jidWithString:[[streamhost attributeForName:@"jid"] stringValue]];
		
		proxyHost = [[streamhost attributeForName:@"host"] stringValue];
		if([proxyHost isEqualToString:@"0.0.0.0"])
            {
			proxyHost = [proxyJID full];
            }
		
		proxyPort = [[[streamhost attributeForName:@"port"] stringValue] intValue];
		
		if (asyncSocket == nil)
            {
			asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:turnQueue];
            }
		else
            {
			NSAssert([asyncSocket isDisconnected], @"Expecting the socket to be disconnected at this point...");
            }
		
		XMPPLogVerbose(@"FileReceiver: targetNextConnect: %@(%@:%hu)", [proxyJID full], proxyHost, proxyPort);
		
		NSError *err = nil;
		if (![asyncSocket connectToHost:proxyHost onPort:proxyPort withTimeout:TIMEOUT_CONNECT error:&err])
            {
			XMPPLogError(@"FileReceiver: targetNextConnect: err: %@", err);
			[self targetNextConnect];
            }
        }
	else
        {
		[self sendError];
		[self fail];
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark SOCKS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Sends the SOCKS5 open/handshake/authentication data, and starts reading the response.
 * We attempt to gain anonymous access (no authentication).
 **/
- (void)socksOpen
{
	XMPPLogTrace();
	
	//      +-----+-----------+---------+
	// NAME | VER | NMETHODS  | METHODS |
	//      +-----+-----------+---------+
	// SIZE |  1  |    1      | 1 - 255 |
	//      +-----+-----------+---------+
	//
	// Note: Size is in bytes
	//
	// Version    = 5 (for SOCKS5)
	// NumMethods = 1
	// Method     = 0 (No authentication, anonymous access)
	
	void *byteBuffer = malloc(3);
	
	UInt8 ver = 5;
	memcpy(byteBuffer+0, &ver, sizeof(ver));
	
	UInt8 nMethods = 1;
	memcpy(byteBuffer+1, &nMethods, sizeof(nMethods));
	
	UInt8 method = 0;
	memcpy(byteBuffer+2, &method, sizeof(method));
	
	NSData *data = [NSData dataWithBytesNoCopy:byteBuffer length:3 freeWhenDone:YES];
	//NSLog (@"FileReceiver: SOCKS_OPEN: %@", data);
	
	[asyncSocket writeData:data withTimeout:-1 tag:SOCKS_OPEN];
	
	//      +-----+--------+
	// NAME | VER | METHOD |
	//      +-----+--------+
	// SIZE |  1  |   1    |
	//      +-----+--------+
	//
	// Note: Size is in bytes
	//
	// Version = 5 (for SOCKS5)
	// Method  = 0 (No authentication, anonymous access)
	
	[asyncSocket readDataToLength:2 withTimeout:TIMEOUT_READ tag:SOCKS_OPEN];
}

/**
 * Sends the SOCKS5 connect data (according to XEP-65), and starts reading the response.
 **/
- (void)socksConnect
{
	XMPPLogTrace();
	
	XMPPJID *myJID = [xmppStream myJID];
	
	// From XEP-0065:
	//
	// The [address] MUST be SHA1(SID + Initiator JID + Target JID) and
	// the output is hexadecimal encoded (not binary).
	

	XMPPJID *initiatorJID = jid;
	XMPPJID *targetJID    = myJID;
	
    
	NSString *hashMe = [NSString stringWithFormat:@"%@%@%@", streamID, [initiatorJID full], [targetJID full]];//uuid
	NSData *hashRaw = [[hashMe dataUsingEncoding:NSUTF8StringEncoding] xmpp_sha1Digest];
 	NSData *hash = [[hashRaw xmpp_hexStringValue] dataUsingEncoding:NSUTF8StringEncoding];
 	//      +-----+-----+-----+------+------+------+
	// NAME | VER | CMD | RSV | ATYP | ADDR | PORT |
	//      +-----+-----+-----+------+------+------+
	// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
	//      +-----+-----+-----+------+------+------+
	//
	// Note: Size is in bytes
	//
	// Version      = 5 (for SOCKS5)
	// Command      = 1 (for Connect)
	// Reserved     = 0
	// Address Type = 3 (1=IPv4, 3=DomainName 4=IPv6)
	// Address      = P:D (P=LengthOfDomain D=DomainWithoutNullTermination)
	// Port         = 0
	
	uint byteBufferLength = (uint)(4 + 1 + [hash length] + 2);
	void *byteBuffer = malloc(byteBufferLength);
	
	UInt8 ver = 5;
	memcpy(byteBuffer+0, &ver, sizeof(ver));
	
	UInt8 cmd = 1;
	memcpy(byteBuffer+1, &cmd, sizeof(cmd));
	
	UInt8 rsv = 0;
	memcpy(byteBuffer+2, &rsv, sizeof(rsv));
	
	UInt8 atyp = 3;
	memcpy(byteBuffer+3, &atyp, sizeof(atyp));
	
	UInt8 hashLength = [hash length];
	memcpy(byteBuffer+4, &hashLength, sizeof(hashLength));
	
	memcpy(byteBuffer+5, [hash bytes], [hash length]);
	
	UInt16 port = 0;
	memcpy(byteBuffer+5+[hash length], &port, sizeof(port));
	
	NSData *data = [NSData dataWithBytesNoCopy:byteBuffer length:byteBufferLength freeWhenDone:YES];
	//NSLog(@"FileReceiver: SOCKS_CONNECT: %@", data);
	
	[asyncSocket writeData:data withTimeout:-1 tag:SOCKS_CONNECT];
	
	//      +-----+-----+-----+------+------+------+
	// NAME | VER | REP | RSV | ATYP | ADDR | PORT |
	//      +-----+-----+-----+------+------+------+
	// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
	//      +-----+-----+-----+------+------+------+
	//
	// Note: Size is in bytes
	//
	// Version      = 5 (for SOCKS5)
	// Reply        = 0 (0=Succeeded, X=ErrorCode)
	// Reserved     = 0
	// Address Type = 3 (1=IPv4, 3=DomainName 4=IPv6)
	// Address      = P:D (P=LengthOfDomain D=DomainWithoutNullTermination)
	// Port         = 0
	//
	// It is expected that the SOCKS server will return the same address given in the connect request.
	// But according to XEP-65 this is only marked as a SHOULD and not a MUST.
	// So just in case, we'll read up to the address length now, and then read in the address+port next.
	
	[asyncSocket readDataToLength:5 withTimeout:TIMEOUT_READ tag:SOCKS_CONNECT_REPLY_1];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark AsyncSocket Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	XMPPLogTrace();
	
	// Start the SOCKS protocol stuff
	[self socksOpen];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	XMPPLogTrace();
    
    if (tag == SOCKS_FILE_RECEIVE)
        {
        [data writeToFile:fileInfo.localFileName atomically:YES];
        if ([delegate respondsToSelector:@selector(fileReceiver:didSucceed:)])
            {
            [delegate fileReceiver:self didSucceed:fileInfo];
            //[asyncSocket disconnect];
            }
        //[asyncSocket disconnect];
        
        }
    
	else if (tag == SOCKS_OPEN)
        {
		// See socksOpen method for socks reply format
		
		UInt8 ver = [NSNumber xmpp_extractUInt8FromData:data atOffset:0];
		UInt8 mtd = [NSNumber xmpp_extractUInt8FromData:data atOffset:1];
		
        //	NSLog(@"FileReceiver: SOCKS_OPEN: ver(%o) mtd(%o)", ver, mtd);
		
		if(ver == 5 && mtd == 0)
            {
			[self socksConnect];
            }
		else
            {
			// Some kind of error occurred.
			// The proxy probably requires some kind of authentication.
			[asyncSocket disconnect];
            }
        }
	else if (tag == SOCKS_CONNECT_REPLY_1)
        {
		// See socksConnect method for socks reply format
		
        //	NSLog(@"FileReceiver: SOCKS_CONNECT_REPLY_1: %@", data);
		
		UInt8 ver = [NSNumber xmpp_extractUInt8FromData:data atOffset:0];
		UInt8 rep = [NSNumber xmpp_extractUInt8FromData:data atOffset:1];
		
        //	NSLog(@"FileReceiver: SOCKS_CONNECT_REPLY_1: ver(%o) rep(%o)", ver, rep);
		
		if(ver == 5 && rep == 0)
            {
			// We read in 5 bytes which we expect to be:
			// 0: ver  = 5
			// 1: rep  = 0
			// 2: rsv  = 0
			// 3: atyp = 3
			// 4: size = size of addr field
			//
			// However, some servers don't follow the protocol, and send a atyp value of 0.
			
			UInt8 atyp = [NSNumber xmpp_extractUInt8FromData:data atOffset:3];
			
			if (atyp == 3)
                {
				UInt8 addrLength = [NSNumber xmpp_extractUInt8FromData:data atOffset:4];
				UInt8 portLength = 2;
				
                //	NSLog(@"FileReceiver: addrLength: %o", addrLength);
                //	NSLog(@"FileReceiver: portLength: %o", portLength);
				
				[asyncSocket readDataToLength:(addrLength+portLength)
								  withTimeout:TIMEOUT_READ
										  tag:SOCKS_CONNECT_REPLY_2];
                }
			else if (atyp == 0)
                {
				// The size field was actually the first byte of the port field
				// We just have to read in that last byte
				[asyncSocket readDataToLength:1 withTimeout:TIMEOUT_READ tag:SOCKS_CONNECT_REPLY_2];
                }
			else
                {
				NSLog(@"FileReceiver: Unknown atyp field in connect reply");
				[asyncSocket disconnect];
                }
            }
		else
            {
			// Some kind of error occurred.
			[asyncSocket disconnect];
            }
        }
	else if (tag == SOCKS_CONNECT_REPLY_2)
        {
		// See socksConnect method for socks reply format
 			[self sendReply];
			[self succeed];
 
        }
    
    
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"%@: %@ %@", THIS_FILE, THIS_METHOD, err);
	
	if (state == STATE_TARGET_CONNECT)
        {
		[self targetNextConnect];
        }
	else if (state == STATE_INITIATOR_CONNECT)
        {
		[self fail];
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Timeouts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupDiscoTimer:(NSTimeInterval)timeout
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");
	
	if (discoTimer == NULL)
        {
		discoTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, turnQueue);
		
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeout * NSEC_PER_SEC));
		
		dispatch_source_set_timer(discoTimer, tt, DISPATCH_TIME_FOREVER, 0.1);
		dispatch_resume(discoTimer);
        }
	else
        {
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeout * NSEC_PER_SEC));
		
		dispatch_source_set_timer(discoTimer, tt, DISPATCH_TIME_FOREVER, 0.1);
        }
}

- (void)setupDiscoTimerForDiscoItems
{
	XMPPLogTrace();
	
	[self setupDiscoTimer:TIMEOUT_DISCO_ITEMS];
	
	NSString *theUUID = discoUUID;
	
	dispatch_source_set_event_handler(discoTimer, ^{ @autoreleasepool {
		
		[self doDiscoItemsTimeout:theUUID];
	}});
}

- (void)setupDiscoTimerForDiscoInfo
{
	XMPPLogTrace();
	
	[self setupDiscoTimer:TIMEOUT_DISCO_INFO];
	
	NSString *theUUID = discoUUID;
	
	dispatch_source_set_event_handler(discoTimer, ^{ @autoreleasepool {
		
		[self doDiscoInfoTimeout:theUUID];
	}});
}

- (void)setupDiscoTimerForDiscoAddress
{
	XMPPLogTrace();
	
	[self setupDiscoTimer:TIMEOUT_DISCO_ADDR];
	
	NSString *theUUID = discoUUID;
	
	dispatch_source_set_event_handler(discoTimer, ^{ @autoreleasepool {
		
		[self doDiscoAddressTimeout:theUUID];
	}});
}

- (void)doDiscoItemsTimeout:(NSString *)theUUID
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");
	
	if (state == STATE_PROXY_DISCO_ITEMS)
        {
		if ([theUUID isEqualToString:discoUUID])
            {
			XMPPLogTrace();
			
			// Server isn't responding - server may be offline
			[self queryNextProxyCandidate];
            }
        }
}

- (void)doDiscoInfoTimeout:(NSString *)theUUID
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");
	
	if (state == STATE_PROXY_DISCO_INFO)
        {
		if ([theUUID isEqualToString:discoUUID])
            {
			XMPPLogTrace();
			
			// Move on to the next proxy candidate
			[self queryNextProxyCandidate];
            }
        }
}

- (void)doDiscoAddressTimeout:(NSString *)theUUID
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");
	
	if (state == STATE_PROXY_DISCO_ADDR)
        {
		if ([theUUID isEqualToString:discoUUID])
            {
			XMPPLogTrace();
			
			// Server is taking a long time to respond to a simple query.
			// We could jump to the next candidate JID, but we'll take this as a sign of an overloaded server.
			[self queryNextProxyCandidate];
            }
        }
}

- (void)doTotalTimeout
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");
	
	if ((state != STATE_DONE) && (state != STATE_FAILURE))
        {
		XMPPLogTrace();
		
		// A timeout occured to cancel the entire TURN procedure.
		// This probably means the other endpoint crashed, or a network error occurred.
		// In either case, we can consider this a failure, and recycle the memory associated with this object.
		
		[self fail];
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Finish and Cleanup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)succeed
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");

	XMPPLogTrace();
	
	// Record finish time
	finishTime = [[NSDate alloc] init];
	
	// Update state
	state = STATE_DONE;
	
	dispatch_async(delegateQueue, ^{ @autoreleasepool {
		
		if ([delegate respondsToSelector:@selector(fileReceiver:didSucceed:)])
            {
            [asyncSocket readDataToLength:fileInfo.fileSize withTimeout:-1 tag:SOCKS_FILE_RECEIVE];
            
            }
	}});
	
	[self cleanup];
}

- (void)fail
{
	NSAssert(dispatch_get_current_queue() == turnQueue, @"Invoked on incorrect queue");
	
	XMPPLogTrace();
	
	// Record finish time
	finishTime = [[NSDate alloc] init];
	
	// Update state
	state = STATE_FAILURE;
	
	dispatch_async(delegateQueue, ^{ @autoreleasepool {
		
		if ([delegate respondsToSelector:@selector(fileReceiverDidFail:)])
            {
			[delegate fileReceiverDidFail:self];
            }
		
	}});
	
	[self cleanup];
}

- (void)cleanup
{
    if (turnTimer)
        {
        dispatch_source_cancel(turnTimer);
#if NEEDS_DISPATCH_RETAIN_RELEASE
        dispatch_release(turnTimer);
#endif
        turnTimer = NULL;
        }
    
    if (discoTimer)
        {
        dispatch_source_cancel(discoTimer);
#if NEEDS_DISPATCH_RETAIN_RELEASE
        dispatch_release(discoTimer);
#endif
        discoTimer = NULL;
        }
    
    // Remove self as xmpp delegate
   // [xmppStream removeDelegate:self delegateQueue:turnQueue];
}

@end
