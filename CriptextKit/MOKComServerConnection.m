//
//  ComServerConnection.m
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "MOKComServerConnection.h"
#import "MOKSGSMessage.h"
#import "MOKSGSChannel.h"
#import "MOKUser.h"
#import "MOKJSON.h"
#import "MOKSessionManager.h"
#import "UICKeyChainStore.h"
#import "MOKSGSContext.h"
#import "MOKSGSChannel.h"

#import "MOKMessage.h"
//#import "AppDelegate.h"

#import "MOKMessagingManager.h"
#import "MOKSecurityManager.h"


#pragma mark -
#pragma mark Anonyms category

// Anonymus category for some private methods
@interface MOKComServerConnection() <MOKSGSContextDelegate, MOKSGSChannelDelegate, MOKAPIConnectorDelegate>

@end


@implementation MOKComServerConnection

@synthesize connection, userId,fb_id, connectionRetry;
@synthesize connectionDelegate;


+ (MOKComServerConnection*) sharedInstance
{
    static MOKComServerConnection* sharedInstance;
    
	@synchronized(self)
	{
        if (!sharedInstance) {
            sharedInstance = [[self alloc] initPrivate];
        }
	}

	return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MOKComServerConnection sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.connectionDelegate=nil;
        self.connectionRetry=-1;
        self.connection=nil;
        firstTime=NO;
    }
    return self;
}


// Nobody should be able to copy 
// the shared instance.
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

//// Retaining the shared instance should not
//// effect the retain count.
//- (id)retain
//{
//	return self;
//}
//
//
//// Auto-releasing the shared instance should not
//// effect the retain count.
//- (id)autorelease
//{
//	return self;
//}
//
//// Retain count should not go to zero.
//- (NSUInteger)retainCount
//{
//	return NSUIntegerMax;
//}


- (void)connectWithDelegate:(UIViewController<MOKComServerConnectionDelegate> *) conDelegate
{
    [self connectWithDelegate:conDelegate isFirst:NO];
}
- (void)connectWithDelegate:(UIViewController<MOKComServerConnectionDelegate> *) conDelegate isFirst:(Boolean)isFirst
{
	if(connection)
	{
		
        if(connection.state!=MOKSGSConnectionStateDisconnected){
            [self logOut];
            //NSLog(@"MONKEY - -------connection obj already exist, resetting OUT");
        }

	}

    self.connectionDelegate=conDelegate;
    self.userId=[MOKSessionManager sharedInstance].sessionId;
    firstTime=isFirst;
    
    MOKSGSContext *context = [[MOKSGSContext alloc] initWithHostname:[MOKSessionManager sharedInstance].domain port:[[MOKSessionManager sharedInstance].port integerValue]];
	context.delegate = self;
	/*
	 * Create a connection.  The connection will not actually connect to
	 * the server until a call to loginWithUsername:password: is made. 
	 * All connection messages are sent to the con5text delegate. */
    connection = [[MOKSGSConnection alloc] initWithContext:context];

    [connection loginWithUsername:userId password:[NSString stringWithFormat:@"%@:%@", [MOKSessionManager sharedInstance].appId, [MOKSessionManager sharedInstance].appKey]];
}



-(BOOL) isConnected{
	if(connection.state== MOKSGSConnectionStateConnected || connection.state==MOKSGSConnectionStateConnecting)
		return YES;
	else
        return NO;
    
	//return [connection isConnectionAvailable];
}

-(NSTimeInterval)getLastLatency{
    NSTimeInterval time=-1;
    
    if(id_package_test>0){
        if(timeRecievePack>0){
            time= timeRecievePack-timeSentPack;
            id_package_test=0;
            timeRecievePack=0;
        }
        else{// sino ha llegado aun el mesnaje y si es mayor a 6 segundos entonces dale se setea
            time=[[NSDate date] timeIntervalSince1970]-timeSentPack;
            if(time<6)
                time=-1;
        }
        
    }

    return time;
        
}

-(void)resetConnection{
	[connection resetBuffers];
}

-(void)logOut{
	//send before logout
	if(connection!=nil ){
		[connection logout:YES];

	}
	[self resetConnection];
    id_package_test=0;
    timeRecievePack=0;
    timeSentPack=0;
}

//sending a session message not a group message
-(BOOL)sendMessage:(NSString *)jsonMessage{

	if (connection.state!= MOKSGSConnectionStateConnected) {
        /// si pasa esto debes llamar afuera a funcion desconectado
		return NO;
	}
	@synchronized(connection) {
		MOKSGSMessage *mess=[MOKSGSMessage  sessionMessage];
        
        NSLog(@"MONKEY - msg to  %@",jsonMessage);
        
		[mess appendString:jsonMessage];
		[connection sendMessage:mess];
		return YES;
	}
}

/** notifies that joins a channel. */
- (void)sgsContext:(MOKSGSContext *)context channelJoined:(MOKSGSChannel *)channel forConnection:(MOKSGSConnection *)connection {
	//NSLog(@"MONKEY - -----------------------------channel JOINING---------------------- %@",channel.name);
	
	/* To receive channel messages, we must set the channel delegate upon joining a
	 * channel.  The channel delegate must implement the SGSChannelDelegate protocol
	 * defined in SGSChannel.h. */
	
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:@"-12" forKey:@"id"];
    [args setObject:@"hashchan" forKey:@"c"];
    [args setObject:@"testing"  forKey:@"msg"];
    [args setObject:[NSNumber numberWithShort:0] forKey:@"type"];
//    MOKMessage *messCOM=[MOKMessage createMessageWithCommand:MOKChannelMessage AndArgs:args];
    
//    [self sendMessage:[messCOM json]];
    
}

- (void)channelLeft:(MOKSGSChannel *)channel{
	//	NSLog(@"MONKEY - -----------------------------leave the channel-----------------------");
}

- (void)channelMessageReceived:(MOKSGSMessage *)message{
	NSString *stringMes=[message readString];
    
	 //ARREGLOGRUPO saco 3 caracteres del inicio
	NSRange startRange = [stringMes rangeOfString:@"{"];
	NSString *substring = [stringMes substringFromIndex:startRange.location];
	

	NSDictionary * parsedData = (NSDictionary *) ([substring mok_JSONValue]); //parse to NSDICtionary
    


	[self parseMessage:parsedData];
}

- (void)sgsContext:(MOKSGSContext *)context messageReceived:(MOKSGSMessage *)msg forConnection:(MOKSGSConnection *)connection{
	//handle the message in a manager th,at behaves as a proxy to the UI message

	NSString *stringMes=[msg readString];

	NSLog(@"MONKEY - Message received %@",stringMes);

//    NSLog(@"MONKEY - json value: %@", [stringMes mok_JSONValue]);
	NSDictionary * parsedData = (NSDictionary *) ([stringMes mok_JSONValue]); //parse to NSDICtionary
	[self parseMessage:parsedData];
	
}


- (void)parseMessage:(NSDictionary *)message {
	int cmd=[[message objectForKey:@"cmd"] intValue];
	NSDictionary *args=[message objectForKey:@"args"];
    
    switch (cmd) {
        case MOKProtocolMessage:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            msg.protocolCommand = MOKProtocolMessage;
            
            [self processMOKProtocolMessage:msg];

            if(self.connectionDelegate!=nil)
                [self.connectionDelegate onLoadPendingMessages];
            
            break;
        }
        case MOKProtocolACK:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            msg.protocolCommand = MOKProtocolACK;
            msg.monkeyType = [[msg.props objectForKey:@"status"] intValue];
            [self processMOKProtocolACK:msg];
            
            break;
        }
        case MOKProtocolGet:{
            [[MOKMessagingManager sharedInstance] notifyUpdatesToWatchdog];

            
            NSDecimalNumber *type = [args objectForKey:@"type"];
            
            switch ([type intValue]) {
                case MOKMessagesHistory:{
                    #ifdef DEBUG
                    NSLog(@"MONKEY - ******** GET Command Message History ********");
					#endif
                    NSArray *messages = [args objectForKey:@"messages"];
                    NSString *remaining = [args objectForKey:@"remaining_messages"];
                    [self processGetMessages:messages withRemaining:remaining];
                    break;
                }
                case MOKGroupsString:{
                    #ifdef DEBUG
                    NSLog(@"MONKEY - ******** GET Command Groups ********");
					#endif
                    MOKMessage *msg = [[MOKMessage alloc] init];
                    msg.protocolCommand = MOKProtocolGet;
                    msg.protocolType = MOKNotif;
                    msg.monkeyType = MOKGroupsJoined;
                    msg.messageText = [args objectForKey:@"messages"];
                    [[MOKMessagingManager sharedInstance] notify:msg withcommand:msg.protocolCommand];
                    
                    break;
                }
                default:
                    break;
            }
            
            break;
        }
        case MOKProtocolSet:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            msg.protocolCommand = MOKProtocolSet;
            #ifdef DEBUG
            NSLog(@"MONKEY - ******** SET Command ********");
			#endif
            break;
        }
        case MOKProtocolOpen:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            msg.protocolCommand = MOKProtocolOpen;

            [[MOKMessagingManager sharedInstance] notify:msg withcommand:cmd];
            #ifdef DEBUG
            NSLog(@"MONKEY - ******** OPEN Command ********");
			#endif
            break;
        }
        case MOKProtocolTransaction:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            msg.protocolCommand = MOKProtocolTransaction;
            #ifdef DEBUG
            NSLog(@"MONKEY - ******** TRANSACTION Command ********");
			#endif
            break;
        }
        default:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            [[MOKMessagingManager sharedInstance] notify:msg withcommand:cmd];
            
            break;
        }
    }
}
- (void)processGetMessages:(NSArray *)messages withRemaining:(NSString *)numberOfRemaining{
    for (NSDictionary *msgdict in messages) {
        MOKMessage *msg = [[MOKMessage alloc] initWithArgs:msgdict];
        msg.protocolCommand = MOKProtocolMessage;
        [self processMOKProtocolMessage:msg];
    }
    //check if there are still pending messages
    if (![numberOfRemaining isEqualToString:@"0"]) {
        [[MOKMessagingManager sharedInstance]getMessages:@"15" since:[MOKSessionManager sharedInstance].lastMessageId andGetGroups:false];
    }
}
- (void)processMOKProtocolMessage:(MOKMessage *)msg {
    #ifdef DEBUG
    NSLog(@"MONKEY - Message in process: %@, %@, %d", msg.messageText,msg.messageId, msg.protocolType);
	#endif
    switch (msg.protocolType) {
        case MOKText:{
            //Check if we have the user key
            [[MOKMessagingManager sharedInstance] incomingMessage:msg];
            
            break;
        }
        case MOKFile:{
            msg.messageText = msg.encryptedText;
            [[MOKMessagingManager sharedInstance] fileReceivedNotification:msg];
            break;
        }
        case MOKNotif:
            #ifdef DEBUG
            NSLog(@"MONKEY - monkey action: %d", msg.monkeyType);
			#endif
            [[MOKMessagingManager sharedInstance] notify:msg withcommand:msg.protocolType];
            break;
        case MOKProtocolDelete:{
            msg.protocolType = MOKProtocolDelete;
            [[MOKMessagingManager sharedInstance] notify:msg withcommand:msg.protocolType];
            break;
        }
        default:
            [[MOKMessagingManager sharedInstance] notify:msg withcommand:msg.protocolType];
            break;
            
    }
    
    
}

- (void)processMOKProtocolGet:(MOKMessage *)message {

}

- (void)processMOKProtocolTransaction:(MOKMessage *)message {
    
}

- (void)processMOKProtocolOpen:(MOKMessage *)message {
    
}

- (void)processMOKProtocolSet:(MOKMessage *)message {
    
}

- (void)processMOKProtocolACK:(MOKMessage *)message {
    
    switch (message.protocolType) {
        case MOKProtocolMessage: case MOKText:
            [message updateMessageIdFromACK];
            
            break;
        case MOKProtocolOpen:
            
            break;
        default:
            break;
    }
    
    [[MOKMessagingManager sharedInstance] acknowledgeNotification:message];
}

-(void)onOpenConversationOK:(NSString *)key{
    
}
-(void)onOpenConversationWrong{

}


- (void)sgsContext:(MOKSGSContext *)context disconnected:(MOKSGSConnection *)connection{
    
    NSLog(@"MONKEY - --------- disconnected callback ---------");
	
    [self performSelector:@selector(deliverDisconnectionState) withObject:nil afterDelay:0.5];
}

-(void) deliverDisconnectionState{
	
    if(self.connectionDelegate!=nil)
        [self.connectionDelegate disconnected];
}

- (void)sgsContext:(MOKSGSContext *)context loggedIn:(MOKSGSSession *)session forConnection:(MOKSGSConnection *)connection{
	NSLog(@"MONKEY - -----------------------------already in-----------------------");
    
    
    //aqui va lo de loading da server release dialog
    if(self.connectionDelegate!=nil)
		[self.connectionDelegate loggedIn];
    
    //if(!firstTime)
    //{[SessionManager instance].lastMessageId
    
//    [self sendMessage:[[MOKComMessageProtocol createSyncUpdatenMsg:[[MOKSessionManager sharedInstance].lastMessageId longLongValue] type:27 ] json]];
    
    //}
    
    //testing channels join
   // [self sendMessage:[[ComMessageProtocol createNotificationMsg:@"200:1" type:JoinChannel] json]];
    
    
    //comment
    
    [[MOKMessagingManager sharedInstance] sendMessagesAgain];
}

- (void)sgsContext:(MOKSGSContext *)context loginFailed:(MOKSGSSession *)session forConnection:(MOKSGSConnection *)connection withMessage:(NSString *)message{
	NSLog(@"MONKEY - disconnection login Failed: %@", message);
    
    //LOGOUT SCREEN TO LOGIN
//    [AppDelegate logout];
    
    //ALERT your account is disabled
//    [AlertsManager alert:NSLocalizedString(@"avisoKey", @"") message:NSLocalizedString(@"revisaTuConexionKey", @"")];
}

#pragma mark -
#pragma mark Memory management

//- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
//    /*
//     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
//     */
//    
////	[self logOut];
//	//[connection release];
//
//}

- (void)dealloc {
        NSLog(@"MONKEY - COMSERVERCONN dealloc");
//    [super dealloc];
	//[connection dealloc];
}


@end
