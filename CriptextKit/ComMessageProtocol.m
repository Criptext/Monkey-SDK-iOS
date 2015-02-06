//
//  ComMessageProtocol.m
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ComMessageProtocol.h"
#import "ComMessage.h"

#import "BLUserExtended.h"
#import "SessionManager.h"
#import "JSON.h"
#import "UserDefaultsManager.h"

@implementation ComMessageProtocol


//MessageDefault commands in protocol unified with BLMEssageProtocol for sending commands to the server

+(ComMessage *) createMsgFromBlMessage:(BLMessage *)message{
	// aqui hacer createasicMsg primero y de ahi cambiar con el timestamp.
	return [ComMessageProtocol createBasicMsg:message.userIdTo ofType:message.type andMessage:message.messageText andId:message.messageId andParam:message.param];

}

+(ComMessage *) createMessageFromBlMessageAndReceiver:(BLMessage*)message  {
    
    //short cmd=
    [ComMessage identifyReceiverProtocol:message.userIdTo];
    
    ComMessage* messCOM;
    
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:[NSString stringWithFormat:@"%lli",message.messageId] forKey:@"id"];
    [args setObject:[self identifierToUser:message.userIdTo] forKey:@"rid"];
    [args setObject:message.messageText  forKey:@"msg"];
    
    if(message.param!=nil)
        [args setObject:message.param forKey:@"p"];
    
    if([message isBroadcastMessage]){
        [args setObject:[NSNumber numberWithShort:message.type] forKey:@"type"];
        messCOM=[ComMessage createMessageWithCommand:BroadcastMessage AndArgs:args];
    }
    else if([message isGroupMessage]){
        [args setObject:[NSNumber numberWithShort:message.type] forKey:@"type"];
        messCOM=[ComMessage createMessageWithCommand:MessageGroupDefault AndArgs:args];
    }
    else if ([message haveAttach]){
        
        messCOM=[ComMessage createMessageWithCommand:message.type AndArgs:args];
    }
    else
        messCOM=[ComMessageProtocol createMsgFromBlMessage:message];
    
    return messCOM;
}

+(ComMessage *) createResendMsgFromBlMessage:(BLMessage *)message ofTypeResend:(int)messageTypeResend{
    
	return [ComMessageProtocol createBasicResendMsg:message.userIdTo ofType:blMessageResend andMessage:message.messageText andId:message.messageId ofTypeResend:(int)messageTypeResend];
}

+(NSString *) convertToUTF8:(NSString *)texto{


	const char *utf8string = [texto UTF8String];
	return [NSString stringWithUTF8String:utf8string];
}

+(ComMessage *) createChatMsg:(NSString *)msg forUser:(NSString *)idUser andId:(long long int)mid{
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	if(mid>0)
		[args setObject:[NSString stringWithFormat:@"%lli",mid] forKey:@"id"];

	
	[args setObject:msg forKey:@"msg"];
	[args setObject:idUser forKey:@"rid"];//reciever id
		
	return [ComMessage createMessageWithCommand:blMessageDefault AndArgs:args];
}

//Create message group
+(ComMessage *) createGroupMsg:(NSString *)msg forGroup:(int)idGroup andId:(long long int)mid{
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	if(mid>0)
		[args setObject:[NSString stringWithFormat:@"%lli",mid] forKey:@"id"];

	[args setObject:msg forKey:@"msg"];
	[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"gid"];//reciever id
	
	

	
	return [ComMessage createMessageWithCommand:blMessageGroupMessage AndArgs:args];
}

+(NSString *)identifierToUser:(NSString *) userId{
    return [NSString stringWithFormat:@"201:%@", userId];
}
//	[ComMessageProtocol createBasicMsg:-1 ofType:type andMessage:@"poner mensaje" toGroup:-1]

//[ComMessageProtocol createBasicMsg:ofType:andMessage:toGroup:andId:]:


// this kinf of message goes by the request
+(ComMessage *) createBasicMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg andId:(long long int)mid andParam:(NSString *)param{
	
	
// los argumentos del protocolo establecido nuevo deben cambiar al protocolo viejo si de esta manera es mejor	

	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:[NSString stringWithFormat:@"%lli",mid] forKey:@"id"];
//	if(idUser!=NIL && idUser.length>0)
		[args setObject:idUser forKey:@"rid"];//reciever id
	if(msg!=nil)
		[args setObject:msg forKey:@"msg"];
	//if(idGroup>0)
	//	[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"gid"];//group to send
	if(param!=nil)
        [args setObject:param forKey:@"p"];
	
	ComMessage *finalMessage=[ComMessage createMessageWithCommand:messageType AndArgs:args];
	
	return finalMessage;
}

+(ComMessage *) createBasicResendMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg  andId:(long long int)mid ofTypeResend:(int)messageTypeResend{
	
	
    // los argumentos del protocolo establecido nuevo deben cambiar al protocolo viejo si de esta manera es mejor
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];

	[args setObject:[NSString stringWithFormat:@"%lli",mid] forKey:@"id"];
    //	if(idUser!=NIL && idUser.length>0)
    [args setObject:idUser forKey:@"rid"];//reciever id
	if(msg!=nil)
		[args setObject:msg forKey:@"msg"];
	//if(idGroup>0)
	//	[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"gid"];//group to send
    [args setObject:[NSString stringWithFormat:@"%d",messageTypeResend] forKey:@"type"];
	
	ComMessage *finalMessage=[ComMessage createMessageWithCommand:messageType AndArgs:args];
	
	return finalMessage;
}

+(ComMessage *) createRecallMsg:(NSString *)idUser msgId:(BLMessageId)msgId{
    
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:idUser forKey:@"rid"];
    [args setObject:[NSString stringWithFormat:@"%lld",msgId] forKey:@"msg"];
    
    return [ComMessage createMessageWithCommand:MessageRecall AndArgs:args];
}

+(ComMessage *) createGroupRecallMsg:(NSString *)idUser msgId:(BLMessageId)msgId{
    
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:idUser forKey:@"rid"];
    [args setObject:[NSString stringWithFormat:@"%lld",msgId] forKey:@"msg"];
    [args setObject:[NSString stringWithFormat:@"%d",MessageRecall] forKey:@"type"];
    
    return [ComMessage createMessageWithCommand:MessageGroupDefault AndArgs:args];
}

/*
+(ComMessage *) createShareFriendToUserMsg:(NSString *)idUser withName:(NSString *)fname lastName:(NSString *)lname toUser:(NSString *)idDestin andId:(long long int)mid{
	
	SBJSON *json = [SBJSON new];
	
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
						  idUser, @"uid",
						  fname, @"first_name",
						  lname, @"last_name",							  
						  nil];

	 NSString *messageText = [json stringWithObject:dict];
	
	return [ComMessageProtocol createBasicMsg:idDestin ofType:blMessageAnonymous andMessage:messageText toGroup:-1 andId:mid ];

}

+(ComMessage *) createShareFriendToGroupMsg:(int)idUser withName:(NSString *)fname lastName:(NSString *)lname toGroup:(int)idGroup andId:(long long int)mid{
	
	SBJSON *json = [SBJSON new];
	
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
						  [NSNumber numberWithInt:idUser], @"uid",
						  fname, @"first_name",
						  lname, @"last_name",							  
						  nil];
	 NSString *messageText = [json stringWithObject:dict];
	
	return [ComMessageProtocol createBasicMsg:@"-1" ofType:blMessageAnonymous andMessage:messageText toGroup:idGroup andId:mid ];
	
}
*/
//param idUser: user to send the typing message
+(ComMessage *) createNotificationMsg:(NSString *) idUser ofStringType:(NSString *) messageType{
	
	int type  = [BLMessage typeForString:messageType];
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:idUser forKey:@"rid"];//reciever id
	[args setObject:messageType forKey:@"r"];//type
	
	return [ComMessage createMessageWithCommand:type AndArgs:args];
}

//other create notification message 2
+(ComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type{
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:idUser forKey:@"rid"];//reciever id
	return [ComMessage createMessageWithCommand:type AndArgs:args];
}
+(ComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type msjid:(NSString *)msjId{
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:idUser forKey:@"rid"];//reciever id
    if (![msjId isEqualToString:@""]) {
        [args setObject:msjId forKey:@"idm"];
    }
	return [ComMessage createMessageWithCommand:type AndArgs:args];
}
+(ComMessage *) createNotification:(int) type{
	return [ComMessage createMessageWithCommand:type AndArgs:[[NSDictionary alloc] init]];
}
+(ComMessage *) createNotificationOffline:(int) type cleanbadges:(NSString *)cleanbadges{
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:cleanbadges forKey:@"b"];
    return [ComMessage createMessageWithCommand:type AndArgs:args];
}
+(ComMessage *) createSyncUpdatenMsg:(BLMessageId)last_message_id type:(int) type{
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    if ([[UserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"] == nil) {
        [[UserDefaultsManager instance]storeObjectFree:@"2" forKey:@"StreamDelayTime"];
        [[UserDefaultsManager instance]storeObjectFree:@"15" forKey:@"StreamPortions"];
    }
    NSLog(@"se envia delay a:%@ y decrementado porciones a:%@", [[UserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"], [[UserDefaultsManager instance] objectForKeyFree:@"StreamPortions"]);
    [args setObject:[[UserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"] forKey:@"s"];
    [args setObject:[[UserDefaultsManager instance] objectForKeyFree:@"StreamPortions"] forKey:@"p"];
    [[UserDefaultsManager instance]storeObjectFree:@"0" forKey:@"StreamDidChangeValue"];
	[args setObject:last_message_id forKey:@"last_id"];//reciever id
    [args setObject:@"1.4.2" forKey:@"v"];//version del app
    if([[SessionManager sharedInstance].lastMessageId isEqualToString:@"0"] || [[[UserDefaultsManager instance] objectForKeyFree:@"firstLogin"] isEqualToString:@"1"])
        [args setObject:@"1" forKey:@"g"];//Para que me devuelva los grupos
	return [ComMessage createMessageWithCommand:type AndArgs:args];
}

/*
+(ComMessage *) createAddRemoveGroupMsg:(BLGroupId)idGroup add:(NSArray*)arrayAdd andRemove:(NSArray*)arrayRemove{
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	
	if([arrayAdd count]>0){
	
		NSMutableArray *invites = [[NSMutableArray alloc] initWithCapacity:[arrayAdd count]];
	
		for (BLUserExtended *user in arrayAdd) {
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
			if (user.userId != 0) {
				[dict setObject:[NSNumber numberWithInt:user.userId] forKey:@"jiglid"];
			}
			//if (user.fb_id != nil) {
			//	[dict setObject:user.fb_id forKey:@"fb_id"];
			//}
		
			[invites addObject:dict];
			[dict release];
		}
		
		[args setValue:invites forKey:@"invites"];//reciever id
		
		[invites release];
		
	}
	
	if([arrayRemove count]>0){
		NSMutableArray *removes = [[NSMutableArray alloc] initWithCapacity:[arrayRemove count]];
		
		for (BLUserExtended *user in arrayRemove) {
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
			
			if (user.userId != 0) {
				[dict setObject:[NSNumber numberWithInt:user.userId] forKey:@"jiglid"];
			}
			if (user.fb_id != nil) {
				[dict setObject:user.fb_id forKey:@"fb_id"];
			}
			
			[removes addObject:dict];
			[dict release];
		}
		
		[args setValue:removes forKey:@"removes"];//reciever id
		
		[removes release];
	
	}
	
	return [ComMessage createMessageWithCommand:blMessageGroupAdd AndArgs:args];
	
}
*/
// ARREGLO INVITACIONES envio de groupId
// d User is idFrom
+(ComMessage *) createInvitesNotificationMsg:(int)idUser groupId:(int)gId action:(int)typeNotification{
	
	
	int type=0;
	
	switch (typeNotification) {
		//case 0:
			//type=blMessageInviteDenied;
			//break;
		case 1:
			type=blMessageInviteAccepted;
			break;
		case 2:
			type=blMessageInviteCanceled;
			break;
		default:
			break;
	}
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];

	[args setObject:[NSString stringWithFormat:@"%i",idUser] forKey:@"rid"];//reciever id
	[args setObject:[NSString stringWithFormat:@"%i",gId] forKey:@"gid"];//groupId
	
	return [ComMessage createMessageWithCommand:type AndArgs:args];
	
	
}
/*
//when a group is created
+(ComMessage *) createCreateGroupMsg:(int)idGroup andName:(NSString *) groupName{
	NSMutableArray *garr=[[NSMutableArray alloc] initWithCapacity:1];
	
	
	BLGroup *group=[[BLGroup alloc] init];
	
	group.externalId=idGroup;
	group.groupName=groupName;
	
	[garr addObject:group];
	
	return [ComMessageProtocol createSuscribeGroupMsg:garr];
}



+(ComMessage *) createSuscribeGroupMsg:(NSArray*)array{
	
	NSMutableArray *groups = [[NSMutableArray alloc] initWithCapacity:[array count]];
	
	for (BLGroup *group in array) {
		
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		if (group.externalId != 0) {
			[dict setObject:[NSNumber numberWithInt:group.externalId] forKey:@"id"];
		}
		if (group.groupName != nil) {
			[dict setObject:group.groupName forKey:@"name"];
		}
		
		[groups addObject:dict];
		[dict release];
	}
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setValue:groups forKey:@"groups"];//reciever id
	
	[groups release];
	
	return [ComMessage createMessageWithCommand:SuscribeToChannels AndArgs:args];
}*/

+(ComMessage *) createPrueba{
	
	NSMutableArray *invites = [[NSMutableArray alloc] initWithCapacity:5];

	
	for (int i=0;i<5;i++) {
		
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		[dict setObject:@"10" forKey:@"jiglid"];
		
		[invites addObject:dict];
		[dict release];
	}
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setValue:invites forKey:@"invites"];//reciever id
	
	[invites release];
	
	return [ComMessage createMessageWithCommand:blMessageFriendRequest AndArgs:args];
}


// ARREGLO INVITACIONES añadi implementacion para mensaje de blMessageGroupUpdate que no habia
+(ComMessage *) createGroupUpdateMsg:(int)idGroup forUser:(int)idUser {
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	
		[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"groupId"];
	
	
	
	[args setObject:[NSString stringWithFormat:@"%i",idUser] forKey:@"rid"];//reciever id
	
	return [ComMessage createMessageWithCommand:blMessageGroupUpdate AndArgs:args];
}



// ARREGLO INVITACIONES añadi implementacion para mensaje de blMessageGroupUpdate que no habia
+(ComMessage *) createGroupDeleteMsg:(int)idGroup{
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	
	[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"groupId"];
	
	
	
	return [ComMessage createMessageWithCommand:blMessageGroupDelete AndArgs:args];
}




- (void)dealloc {
    [super dealloc];
}


@end
