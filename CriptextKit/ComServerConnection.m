//
//  ComServerConnection.m
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "ComServerConnection.h"
#import "SGSMessage.h"
#import "SGSChannel.h"
#import "BLUserExtended.h"
#import "JSON.h"
#import "ComMessageProtocol.h"
#import "SessionManager.h"
#import "UserDefaultsManager.h"

#import "SGSContext.h"
#import "SGSConnection.h"
#import "SGSChannel.h"

#import "BLMessage.h"

//#import "AppDelegate.h"

#import "MessagingManager.h"

#import "DateUtils.h"
//#import "AudioUtils.h"

//#import "MenuViewController.h"
//#import "LoginMenuViewController.h"

//#import "AlertsManager.h"
//#import "ImageCache.h"
static ComServerConnection* sharedInstance_;


#pragma mark -
#pragma mark Anonyms category

// Anonymus category for some private methods
@interface ComServerConnection() <SGSContextDelegate, SGSChannelDelegate>

@end


@implementation ComServerConnection

@synthesize connection, userId,fb_id, connectionRetry;
@synthesize connectionDelegate;


+ (ComServerConnection*) sharedInstance
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


- (void)connectWithDelegate:(UIViewController<ComServerConnectionDelegate> *) conDelegate
{
    [self connectWithDelegate:conDelegate isFirst:NO];
}
- (void)connectWithDelegate:(UIViewController<ComServerConnectionDelegate> *) conDelegate isFirst:(Boolean)isFirst
{
	if(connection)
	{
		
        if(connection.state!=SGSConnectionStateDisconnected){
            [self logOut];
            //NSLog(@"-------connection obj already exist, resetting OUT");
        }

	}
	/*else{
		NSLog(@"Connection obj NOT EXIST so Trying to connect .. ");
	}*/
    self.connectionDelegate=conDelegate;
    self.userId=[SessionManager sharedInstance].userId;
    firstTime=isFirst;
    
    SGSContext *context = [[SGSContext alloc] initWithHostname:@"central.criptext.com" port:[@"80" integerValue]];
	context.delegate = self;
	/*
	 * Create a connection.  The connection will not actually connect to
	 * the server until a call to loginWithUsername:password: is made. 
	 * All connection messages are sent to the con5text delegate. */
    connection = [[SGSConnection alloc] initWithContext:context];

    //NSLog(@"verificacion6:%@",[[DBManager instance] getPassword]);
    [connection loginWithUsername:userId password:[SessionManager sharedInstance].userPassword];
}



-(BOOL) isConnected{
    //NSLog(@"estado:%u",connection.state);
	if(connection.state== SGSConnectionStateConnected || connection.state==SGSConnectionStateConnecting)
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

	if (connection.state!= SGSConnectionStateConnected) {
		//NSLog(@"conexion no disponible");
        /// si pasa esto debes llamar afuera a funcion desconectado
		return NO;
	}
	@synchronized(connection) {
		SGSMessage *mess=[SGSMessage  sessionMessage];
        NSLog(@"msg a  %@",jsonMessage);
		[mess appendString:jsonMessage];
		[connection sendMessage:mess];
		return YES;
	}
}

/** notifies that joins a channel. */
- (void)sgsContext:(SGSContext *)context channelJoined:(SGSChannel *)channel forConnection:(SGSConnection *)connection {
	//NSLog(@"-----------------------------channel JOINING---------------------- %@",channel.name);
	
	/* To receive channel messages, we must set the channel delegate upon joining a
	 * channel.  The channel delegate must implement the SGSChannelDelegate protocol
	 * defined in SGSChannel.h. */
	
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:@"-12" forKey:@"id"];
    [args setObject:@"hashchan" forKey:@"c"];
    [args setObject:@"testing"  forKey:@"msg"];
    [args setObject:[NSNumber numberWithShort:0] forKey:@"type"];
    ComMessage *messCOM=[ComMessage createMessageWithCommand:ChannelMessage AndArgs:args];
    
    [self sendMessage:[messCOM json]];
    
}

- (void)channelLeft:(SGSChannel *)channel{
	//	NSLog(@"-----------------------------leave the channel-----------------------");
}

- (void)channelMessageReceived:(SGSMessage *)message{
	NSString *stringMes=[message readString];
    
	 //ARREGLOGRUPO saco 3 caracteres del inicio
	NSRange startRange = [stringMes rangeOfString:@"{"];
	NSString *substring = [stringMes substringFromIndex:startRange.location];
	

	NSDictionary * parsedData = (NSDictionary *) ([substring JSONValue]); //parse to NSDICtionary
    


	[self parseMessage:parsedData];
}

- (void)sgsContext:(SGSContext *)context messageReceived:(SGSMessage *)msg forConnection:(SGSConnection *)connection{
	//handle the message in a manager th,at behaves as a proxy to the UI message

	NSString *stringMes=[msg readString];
	NSLog(@"Message recieved %@",stringMes);
	NSDictionary * parsedData = (NSDictionary *) ([stringMes JSONValue]); //parse to NSDICtionary
	[self parseMessage:parsedData];
	
}


- (void)parseMessage:(NSDictionary *)message {
	int cmd=[[message objectForKey:@"cmd"] intValue];
	NSDictionary *args=[message objectForKey:@"args"];
    
    switch (cmd) {
        case blMessageConversationOpen: case blMessageEmailOpen: case blMessageFriendRequest: case blMessageInviteAccepted: case blMessageInviteCanceled: case blMessageFriendDirect: case MessageNewContactRegistered: case WarningUserTookScreenShot: case MessageFriendActivate: case MessageremoteLogout: case EmailSendFailure: case MessageGroupCreate: case MessageGroupRemoveMember: case EmailUpdates: case blMessageTyping: case blMessageUntyping: case MessageAlert: case MessageUserGroupsUpdate: case MessageRecall: case MessagesUserOffline: case MessagesUserOnline:{
            
            BLMessage *msg = [[BLMessage alloc] initWithArgs:args];
            [[MessagingManager sharedInstance] notify:msg withcommand:msg.type];
            break;
        }
        case MessagesUpdates:{
        
            NSArray *messages=[args objectForKey:@"messages"];
            [self processAllMessages:messages];
            
            if(self.connectionDelegate!=nil)
                [self.connectionDelegate onLoadPendingMessages];
            
            break;
        }
        case blMessageDefault: case blMessagePhotoAttach: case blMessagePhotoAttachNew: case blMessageAudioAttach: case blMessageAudioAttachNew: case blMessageFile: case EmailInbox:{
            
            NSArray *messages=[[NSArray alloc] initWithObjects:args,nil];
            [self processAllMessages:messages];
            break;
        }
        case CodeExecution: //recieve to execute a code inside app
        {
            //BLMessage *msg = [[BLMessage alloc] initWithArgs:args];
            
            
            break;
        }
        case blMessageAvatar:
        {
             BLMessage *msg = [[BLMessage alloc] initWithArgs:args];
            [self removeFromCache:msg];
            
            [[SessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msg.messageId]];
            
            break;
        }
        case ForceAllowPush: //recieve to execute a code inside app
        {
            
//            [(AppDelegate *)[UIApplication sharedApplication].delegate registerForPushNotifications];
            
            break;
        }

        default:{
            BLMessage *msg = [[BLMessage alloc] initWithArgs:args];
            [[MessagingManager sharedInstance] notify:msg withcommand:cmd];
            
            break;
        }
    }
}

- (void)processAllMessages:(NSArray *)messages {

    
    for (NSDictionary *dict in messages) {
		BLMessage *msg = [[BLMessage alloc] initWithArgs:dict];
        
		switch (msg.type) {
			case blMessageDefault: case blMessagePhotoAttach: case blMessagePhotoAttachNew: case blMessageAudioAttach: case blMessageAudioAttachNew: case blMessageFile: case EmailInbox:{
                
                if([msg.userIdFrom isEqualToString:@"1"])
                {
                    [self performSelector:@selector(delayedMessageGot:) withObject:msg afterDelay:2.5];
                    break;
                }
                
                [[MessagingManager sharedInstance] messageGot:msg];
                //esto debe ir en otro lado
//                [[AudioUtils instance] playReceived];
				break;
			}
            case blMessageConversationOpen: case blMessageEmailOpen: case blMessageFriendRequest: case blMessageInviteAccepted: case blMessageInviteCanceled: case blMessageDeleteFriend: case blMessageFriendDirect: case WarningUserTookScreenShot: case MessageNewContactRegistered: case MessageFriendActivate: case MessageremoteLogout: case EmailSendFailure: case MessageGroupCreate:case MessageGroupRemoveMember: case EmailUpdates: case blMessageTyping: case blMessageUntyping: case MessageAlert: case MessageUserGroupsUpdate: case MessageRecall: case MessagesUserOffline: case MessagesUserOnline:{
                
//                [[MessagingManager instance] notify:msg withcommand:msg.type];
                break;
            }
            case blMessageAvatar:
            {
                [self removeFromCache:msg];
                

                [[SessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msg.messageId]];
                
                break;
            }

            case ForceAllowPush: //recieve to execute a code inside app
            {                
                
//                [(AppDelegate *)[UIApplication sharedApplication].delegate registerForPushNotifications];
                
                break;
            }
                
		}
        
	}
    
}


-(void)removeFromCache:(BLMessage *)msg {
    
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
-(void)delayedMessageGot:(BLMessage *)message {
//    [[MessagingManager instance] messageGot:message];
//    [[AudioUtils instance] playReceived];
}

-(void)sendSignalOpenConvMenu:(NSString *) id_user {
	/*
    MainMenuViewController *controller=(MainMenuViewController *)self.connectionDelegate;
	[controller updateMessagesAsDeliveredFrom:id_user];*/
}


- (void)sgsContext:(SGSContext *)context disconnected:(SGSConnection *)connection{
    
    NSLog(@"--------- disconnected callback ---------");
	
    [self performSelector:@selector(deliverDisconnectionState) withObject:nil afterDelay:0.5];
}

-(void) deliverDisconnectionState{
	
    if(self.connectionDelegate!=nil)
        [self.connectionDelegate disconnected];
}

- (void)sgsContext:(SGSContext *)context loggedIn:(SGSSession *)session forConnection:(SGSConnection *)connection{
	NSLog(@"-----------------------------already in-----------------------");
    
    
    //aqui va lo de loading da server release dialog
    if(self.connectionDelegate!=nil)
		[self.connectionDelegate loggedIn];
    
    //sending update message for offline messages
    if([SessionManager sharedInstance].lastMessageId==nil){
        [[SessionManager sharedInstance] setLastMessageId:@"122899"];
    }
    
    //if(!firstTime)
    //{[SessionManager instance].lastMessageId
    
    [self sendMessage:[[ComMessageProtocol createSyncUpdatenMsg:[SessionManager sharedInstance].lastMessageId type:MessageUpdates ] json]];
    
    if([[SessionManager sharedInstance].lastMessageId isEqualToString:@"0"]){
//            [[MenuViewController instance] showNoNetwork:NO];
//            [[MenuViewController instance] showConnectings:NO];
        }
    //}
    
    //testing channels join
   // [self sendMessage:[[ComMessageProtocol createNotificationMsg:@"200:1" type:JoinChannel] json]];
    
    
    //comment
//    [[MessagingManager instance] sendMessagesAgain];
}

- (void)sgsContext:(SGSContext *)context loginFailed:(SGSSession *)session forConnection:(SGSConnection *)connection withMessage:(NSString *)message{
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
