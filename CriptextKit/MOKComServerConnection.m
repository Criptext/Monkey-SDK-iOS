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
#import "MOKComMessageProtocol.h"
#import "MOKSessionManager.h"
#import "MOKUserDefaultsManager.h"

#import "MOKSGSContext.h"
#import "MOKSGSConnection.h"
#import "MOKSGSChannel.h"

#import "MOKMessage.h"

//#import "AppDelegate.h"

#import "MOKMessagingManager.h"

#import "MOKDateUtils.h"
//#import "AudioUtils.h"

//#import "MenuViewController.h"
//#import "LoginMenuViewController.h"

//#import "AlertsManager.h"
//#import "ImageCache.h"
static MOKComServerConnection* sharedInstance_;


#pragma mark -
#pragma mark Anonyms category

// Anonymus category for some private methods
@interface MOKComServerConnection() <MOKSGSContextDelegate, MOKSGSChannelDelegate>

@end


@implementation MOKComServerConnection

@synthesize connection, userId,fb_id, connectionRetry;
@synthesize connectionDelegate;


+ (MOKComServerConnection*) sharedInstance
{
	@synchronized(self)
	{
		[[self alloc] init];
	}

	return sharedInstance_;
}

- (id) init
{
	self = [super init];
	self.connectionDelegate=nil;
	self.connectionRetry=-1;
	self.connection=nil;
    firstTime=NO;
	return self;
    
}

// Overwrite allocWithZone to be sure to 
// allocate memory only once.
+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {//mutual exclusion
		if (sharedInstance_ == nil) {
			sharedInstance_ = [super allocWithZone:zone];
			return sharedInstance_;
		}
	}
	
	return nil;
}

// Nobody should be able to copy 
// the shared instance.
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

// Retaining the shared instance should not
// effect the retain count.
- (id)retain
{
	return self;
}


// Auto-releasing the shared instance should not
// effect the retain count.
- (id)autorelease
{
	return self;
}

// Retain count should not go to zero.
- (NSUInteger)retainCount
{
	return NSUIntegerMax;
}


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
            //NSLog(@"-------connection obj already exist, resetting OUT");
        }

	}
	/*else{
		NSLog(@"Connection obj NOT EXIST so Trying to connect .. ");
	}*/
    self.connectionDelegate=conDelegate;
    self.userId=[MOKSessionManager sharedInstance].userId;
    firstTime=isFirst;
    
    MOKSGSContext *context = [[MOKSGSContext alloc] initWithHostname:@"central.criptext.com" port:[@"80" integerValue]];
	context.delegate = self;
	/*
	 * Create a connection.  The connection will not actually connect to
	 * the server until a call to loginWithUsername:password: is made. 
	 * All connection messages are sent to the con5text delegate. */
    connection = [[MOKSGSConnection alloc] initWithContext:context];

    //NSLog(@"verificacion6:%@",[[DBManager instance] getPassword]);
    [connection loginWithUsername:userId password:[MOKSessionManager sharedInstance].userPassword];
}



-(BOOL) isConnected{
    //NSLog(@"estado:%u",connection.state);
	if(connection.state== MOKSGSConnectionStateConnected || connection.state==MOKSGSConnectionStateConnecting)
		return YES;
	else
        return NO;
    
	//return [connection isConnectionAvailable];
}

-(void)messageToSend:(int)id_temp_message withId:(long long int)messageId andType:(int)type{
	
	//converrt a BLMessaage to ComMeesage to send with id
	//get from messageManager
    /*
    BLMessage *msgToSend=[[MessagingManager instance]sendingMessageById:id_temp_message];
    [self sendMessage:[[ComMessageProtocol createMsgFromBlMessage:msgToSend ] json]];
	*/
	

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
		//NSLog(@"conexion no disponible");
        /// si pasa esto debes llamar afuera a funcion desconectado
		return NO;
	}
	@synchronized(connection) {
		MOKSGSMessage *mess=[MOKSGSMessage  sessionMessage];
        NSLog(@"msg a  %@",jsonMessage);
		[mess appendString:jsonMessage];
		[connection sendMessage:mess];
		return YES;
	}
}

/** notifies that joins a channel. */
- (void)sgsContext:(MOKSGSContext *)context channelJoined:(MOKSGSChannel *)channel forConnection:(MOKSGSConnection *)connection {
	//NSLog(@"-----------------------------channel JOINING---------------------- %@",channel.name);
	
	/* To receive channel messages, we must set the channel delegate upon joining a
	 * channel.  The channel delegate must implement the SGSChannelDelegate protocol
	 * defined in SGSChannel.h. */
	
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:@"-12" forKey:@"id"];
    [args setObject:@"hashchan" forKey:@"c"];
    [args setObject:@"testing"  forKey:@"msg"];
    [args setObject:[NSNumber numberWithShort:0] forKey:@"type"];
    MOKComMessage *messCOM=[MOKComMessage createMessageWithCommand:MOKChannelMessage AndArgs:args];
    
    [self sendMessage:[messCOM json]];
    
}

- (void)channelLeft:(MOKSGSChannel *)channel{
	//	NSLog(@"-----------------------------leave the channel-----------------------");
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
	NSLog(@"Message recieved %@",stringMes);
	NSDictionary * parsedData = (NSDictionary *) ([stringMes mok_JSONValue]); //parse to NSDICtionary
	[self parseMessage:parsedData];
	
}


- (void)parseMessage:(NSDictionary *)message {
	int cmd=[[message objectForKey:@"cmd"] intValue];
	NSDictionary *args=[message objectForKey:@"args"];
    
    switch (cmd) {
        case MOKMessageConversationOpen: case MOKMessageEmailOpen: case MOKMessageFriendRequest: case MOKMessageInviteAccepted: case MOKMessageInviteCanceled: case MOKMessageFriendDirect: case MOKMessageNewContactRegistered: case MOKWarningUserTookScreenShot: case MOKMessageFriendActivate: case MOKMessageremoteLogout: case MOKEmailSendFailure: case MOKMessageGroupCreate: case MOKMessageGroupRemoveMember: case MOKEmailUpdates: case MOKMessageTyping: case MOKMessageUntyping: case MOKMessageAlert: case MOKMessageUserGroupsUpdate: case MOKMessageRecall: case MOKMessagesUserOffline: case MOKMessagesUserOnline:{
            
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            [[MOKMessagingManager sharedInstance] notify:msg withcommand:msg.type];
            break;
        }
        case MessagesUpdates:{
        
            NSArray *messages=[args objectForKey:@"messages"];
            [self processAllMessages:messages];
            
            if(self.connectionDelegate!=nil)
                [self.connectionDelegate onLoadPendingMessages];
            
            [[MOKMessagingManager sharedInstance] notifyUpdatesToWatchdog];
            
            break;
        }
        case MOKMessageDefault: case MOKMessagePhotoAttach: case MOKMessagePhotoAttachNew: case MOKMessageAudioAttach: case MOKMessageAudioAttachNew: case MOKMessageFile: case MOKEmailInbox:{
            
            NSArray *messages=[[NSArray alloc] initWithObjects:args,nil];
            [self processAllMessages:messages];
            break;
        }
        case MOKCodeExecution: //recieve to execute a code inside app
        {
            //BLMessage *msg = [[BLMessage alloc] initWithArgs:args];
            
            
            break;
        }
        case MOKMessageAvatar:
        {
             MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            [self removeFromCache:msg];
            
            [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msg.messageId]];
            
            break;
        }
        case MOKForceAllowPush: //recieve to execute a code inside app
        {
            
//            [(AppDelegate *)[UIApplication sharedApplication].delegate registerForPushNotifications];
            
            break;
        }

        default:{
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:args];
            [[MOKMessagingManager sharedInstance] notify:msg withcommand:cmd];
            
            break;
        }
    }
}

- (void)processAllMessages:(NSArray *)messages {

    
    for (NSDictionary *dict in messages) {
		MOKMessage *msg = [[MOKMessage alloc] initWithArgs:dict];
        
		switch (msg.type) {
			case MOKMessageDefault: case MOKMessagePhotoAttach: case MOKMessagePhotoAttachNew: case MOKMessageAudioAttach: case MOKMessageAudioAttachNew:  case MOKEmailInbox:{
                
                if([msg.userIdFrom isEqualToString:@"1"])
                {
                    [self performSelector:@selector(delayedMessageGot:) withObject:msg afterDelay:2.5];
                    break;
                }
                
                [[MOKMessagingManager sharedInstance] messageGot:msg];
                //esto debe ir en otro lado
//                [[AudioUtils instance] playReceived];
				break;
			}
            case MOKMessageFile:{
                [[MOKMessagingManager sharedInstance] fileGot:msg];
                break;
            }
            case MOKMessageConversationOpen: case MOKMessageEmailOpen: case MOKMessageFriendRequest: case MOKMessageInviteAccepted: case MOKMessageInviteCanceled: case MOKMessageDeleteFriend: case MOKMessageFriendDirect: case MOKWarningUserTookScreenShot: case MOKMessageNewContactRegistered: case MOKMessageFriendActivate: case MOKMessageremoteLogout: case MOKEmailSendFailure: case MOKMessageGroupCreate:case MOKMessageGroupRemoveMember: case MOKEmailUpdates: case MOKMessageTyping: case MOKMessageUntyping: case MOKMessageAlert: case MOKMessageUserGroupsUpdate: case MOKMessageRecall: case MOKMessagesUserOffline: case MOKMessagesUserOnline:{
                
//                [[MessagingManager instance] notify:msg withcommand:msg.type];
                break;
            }
            case MOKMessageAvatar:
            {
                [self removeFromCache:msg];
                

                [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msg.messageId]];
                
                break;
            }

            case MOKForceAllowPush: //recieve to execute a code inside app
            {                
                
//                [(AppDelegate *)[UIApplication sharedApplication].delegate registerForPushNotifications];
                
                break;
            }
                
		}
        
	}
    
}


-(void)removeFromCache:(MOKMessage *)msg {
    
    ///the one that sends is the one the that needs to clean avatar
    
    //NSLog(@"deleting cache image %@",msg.userIdFrom);
    
    NSString *url=[NSString stringWithFormat:@"https://api.criptext.com/avatars/avatar_%@.png", msg.userIdFrom];
    
//    [[ImageCache instance] removeFileFromCache:url];
    
    //reload tableview of messages
//    
//    MenuViewController *menuVC=[MenuViewController instance];
//    ConversationsViewController *conversationsVC=menuVC.conversationsVC;
//    if(conversationsVC!=nil)
//        [conversationsVC reloadTable];

    
}
-(void)delayedMessageGot:(MOKMessage *)message {
    [[MOKMessagingManager sharedInstance] messageGot:message];
//    [[AudioUtils instance] playReceived];
}

-(void)sendSignalOpenConvMenu:(NSString *) id_user {
	/*
    MainMenuViewController *controller=(MainMenuViewController *)self.connectionDelegate;
	[controller updateMessagesAsDeliveredFrom:id_user];*/
}


- (void)sgsContext:(MOKSGSContext *)context disconnected:(MOKSGSConnection *)connection{
    
    NSLog(@"--------- disconnected callback ---------");
	
    [self performSelector:@selector(deliverDisconnectionState) withObject:nil afterDelay:0.5];
}

-(void) deliverDisconnectionState{
	
    if(self.connectionDelegate!=nil)
        [self.connectionDelegate disconnected];
}

- (void)sgsContext:(MOKSGSContext *)context loggedIn:(MOKSGSSession *)session forConnection:(MOKSGSConnection *)connection{
	NSLog(@"-----------------------------already in-----------------------");
    
    
    //aqui va lo de loading da server release dialog
    if(self.connectionDelegate!=nil)
		[self.connectionDelegate loggedIn];
    
    //sending update message for offline messages
    if([MOKSessionManager sharedInstance].lastMessageId==nil){
        [[MOKSessionManager sharedInstance] setLastMessageId:@"122899"];
    }
    
    //if(!firstTime)
    //{[SessionManager instance].lastMessageId
    
    [self sendMessage:[[MOKComMessageProtocol createSyncUpdatenMsg:[MOKSessionManager sharedInstance].lastMessageId type:MOKMessageUpdates ] json]];
    
    if([[MOKSessionManager sharedInstance].lastMessageId isEqualToString:@"0"]){
//            [[MenuViewController instance] showNoNetwork:NO];
//            [[MenuViewController instance] showConnectings:NO];
        }
    //}
    
    //testing channels join
   // [self sendMessage:[[ComMessageProtocol createNotificationMsg:@"200:1" type:JoinChannel] json]];
    
    
    //comment
    
    [[MOKMessagingManager sharedInstance] sendMessagesAgain];
}

- (void)sgsContext:(MOKSGSContext *)context loginFailed:(MOKSGSSession *)session forConnection:(MOKSGSConnection *)connection withMessage:(NSString *)message{
	NSLog(@"disconnection login Failed");
    
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
        NSLog(@"COMSERVERCONN TAMBIEEEEEN? te desaolcaste we");
  //  [super dealloc];
	//[connection dealloc];
}


@end
