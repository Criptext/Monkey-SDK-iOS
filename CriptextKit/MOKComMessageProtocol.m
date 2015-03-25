//
//  ComMessageProtocol.m
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKComMessageProtocol.h"
#import "MOKComMessage.h"

#import "MOKUser.h"
#import "MOKSessionManager.h"
#import "MOKJSON.h"
#import "MOKUserDefaultsManager.h"

@implementation MOKComMessageProtocol


//MessageDefault commands in protocol unified with BLMEssageProtocol for sending commands to the server

+(MOKComMessage *) createMsgFromBlMessage:(MOKMessage *)message{
	// aqui hacer createasicMsg primero y de ahi cambiar con el timestamp.
	return [MOKComMessageProtocol createBasicMsg:message.userIdTo ofType:message.type andMessage:message.messageText andId:message.messageId andParam:message.param];

}

+(MOKComMessage *) createMessageFromBlMessageAndReceiver:(MOKMessage*)message  {
    
    //short cmd=
    [MOKComMessage identifyReceiverProtocol:message.userIdTo];
    
    MOKComMessage* messCOM;
    
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:[NSString stringWithFormat:@"%lli",message.messageId] forKey:@"id"];
    [args setObject:[self identifierToUser:message.userIdTo] forKey:@"rid"];
    [args setObject:message.messageText  forKey:@"msg"];
    
    if(message.param!=nil)
        [args setObject:message.param forKey:@"p"];
    
    if([message isBroadcastMessage]){
        [args setObject:[NSNumber numberWithShort:message.type] forKey:@"type"];
        messCOM=[MOKComMessage createMessageWithCommand:MOKBroadcastMessage AndArgs:args];
    }
    else if([message isGroupMessage]){
        [args setObject:[NSNumber numberWithShort:message.type] forKey:@"type"];
        messCOM=[MOKComMessage createMessageWithCommand:MOKMessageGroupDefault AndArgs:args];
    }
    else if ([message haveAttach]){
        
        messCOM=[MOKComMessage createMessageWithCommand:message.type AndArgs:args];
    }
    else
        messCOM=[MOKComMessageProtocol createMsgFromBlMessage:message];
    
    return messCOM;
}

+(MOKComMessage *) createResendMsgFromBlMessage:(MOKMessage *)message ofTypeResend:(int)messageTypeResend{
    
	return [MOKComMessageProtocol createBasicResendMsg:message.userIdTo ofType:MOKMessageResend andMessage:message.messageText andId:message.messageId ofTypeResend:(int)messageTypeResend];
}

+(NSString *) convertToUTF8:(NSString *)texto{


	const char *utf8string = [texto UTF8String];
	return [NSString stringWithUTF8String:utf8string];
}

+(MOKComMessage *) createChatMsg:(NSString *)msg forUser:(NSString *)idUser andId:(long long int)mid{
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	if(mid>0)
		[args setObject:[NSString stringWithFormat:@"%lli",mid] forKey:@"id"];

	
	[args setObject:msg forKey:@"msg"];
	[args setObject:idUser forKey:@"rid"];//reciever id
		
	return [MOKComMessage createMessageWithCommand:MOKMessageDefault AndArgs:args];
}

//Create message group
+(MOKComMessage *) createGroupMsg:(NSString *)msg forGroup:(int)idGroup andId:(long long int)mid{
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	if(mid>0)
		[args setObject:[NSString stringWithFormat:@"%lli",mid] forKey:@"id"];

	[args setObject:msg forKey:@"msg"];
	[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"gid"];//reciever id
	
	

	
	return [MOKComMessage createMessageWithCommand:MOKMessageGroupMessage AndArgs:args];
}

+(NSString *)identifierToUser:(NSString *) userId{
    return [NSString stringWithFormat:@"201:%@", userId];
}
//	[ComMessageProtocol createBasicMsg:-1 ofType:type andMessage:@"poner mensaje" toGroup:-1]

//[ComMessageProtocol createBasicMsg:ofType:andMessage:toGroup:andId:]:


// this kinf of message goes by the request
+(MOKComMessage *) createBasicMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg andId:(long long int)mid andParam:(NSString *)param{
	
	
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
	
	MOKComMessage *finalMessage=[MOKComMessage createMessageWithCommand:messageType AndArgs:args];
	
	return finalMessage;
}

+(MOKComMessage *) createBasicResendMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg  andId:(long long int)mid ofTypeResend:(int)messageTypeResend{
	
	
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
	
	MOKComMessage *finalMessage=[MOKComMessage createMessageWithCommand:messageType AndArgs:args];
	
	return finalMessage;
}

+(MOKComMessage *) createRecallMsg:(NSString *)idUser msgId:(MOKMessageId)msgId{
    
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:idUser forKey:@"rid"];
    [args setObject:[NSString stringWithFormat:@"%lld",msgId] forKey:@"msg"];
    
    return [MOKComMessage createMessageWithCommand:MOKMessageRecall AndArgs:args];
}

+(MOKComMessage *) createGroupRecallMsg:(NSString *)idUser msgId:(MOKMessageId)msgId{
    
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:idUser forKey:@"rid"];
    [args setObject:[NSString stringWithFormat:@"%lld",msgId] forKey:@"msg"];
    [args setObject:[NSString stringWithFormat:@"%d",MOKMessageRecall] forKey:@"type"];
    
    return [MOKComMessage createMessageWithCommand:MOKMessageGroupDefault AndArgs:args];
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
+(MOKComMessage *) createNotificationMsg:(NSString *) idUser ofStringType:(NSString *) messageType{
	
	int type  = [MOKMessage typeForString:messageType];
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:idUser forKey:@"rid"];//reciever id
	[args setObject:messageType forKey:@"r"];//type
	
	return [MOKComMessage createMessageWithCommand:type AndArgs:args];
}

//other create notification message 2
+(MOKComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type{
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:idUser forKey:@"rid"];//reciever id
	return [MOKComMessage createMessageWithCommand:type AndArgs:args];
}
+(MOKComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type msjid:(NSString *)msjId{
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	[args setObject:idUser forKey:@"rid"];//reciever id
    if (![msjId isEqualToString:@""]) {
        [args setObject:msjId forKey:@"idm"];
    }
	return [MOKComMessage createMessageWithCommand:type AndArgs:args];
}
+(MOKComMessage *) createNotification:(int) type{
	return [MOKComMessage createMessageWithCommand:type AndArgs:[[NSDictionary alloc] init]];
}
+(MOKComMessage *) createNotificationOffline:(int) type cleanbadges:(NSString *)cleanbadges{
    NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    [args setObject:cleanbadges forKey:@"b"];
    return [MOKComMessage createMessageWithCommand:type AndArgs:args];
}
+(MOKComMessage *) createSyncUpdatenMsg:(MOKMessageId)last_message_id type:(int) type{
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
    if ([[MOKUserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"] == nil) {
        [[MOKUserDefaultsManager instance]storeObjectFree:@"2" forKey:@"StreamDelayTime"];
        [[MOKUserDefaultsManager instance]storeObjectFree:@"15" forKey:@"StreamPortions"];
    }
    NSLog(@"se envia delay a:%@ y decrementado porciones a:%@", [[MOKUserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"], [[MOKUserDefaultsManager instance] objectForKeyFree:@"StreamPortions"]);
    [args setObject:[[MOKUserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"] forKey:@"s"];
    [args setObject:[[MOKUserDefaultsManager instance] objectForKeyFree:@"StreamPortions"] forKey:@"p"];
    [[MOKUserDefaultsManager instance]storeObjectFree:@"0" forKey:@"StreamDidChangeValue"];
	[args setObject:last_message_id forKey:@"last_id"];//reciever id
    [args setObject:@"1.4.2" forKey:@"v"];//version del app
    if([[MOKSessionManager sharedInstance].lastMessageId isEqualToString:@"0"] || [[[MOKUserDefaultsManager instance] objectForKeyFree:@"firstLogin"] isEqualToString:@"1"])
        [args setObject:@"1" forKey:@"g"];//Para que me devuelva los grupos
	return [MOKComMessage createMessageWithCommand:type AndArgs:args];
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
+(MOKComMessage *) createInvitesNotificationMsg:(int)idUser groupId:(int)gId action:(int)typeNotification{
	
	
	int type=0;
	
	switch (typeNotification) {
		//case 0:
			//type=blMessageInviteDenied;
			//break;
		case 1:
			type=MOKMessageInviteAccepted;
			break;
		case 2:
			type=MOKMessageInviteCanceled;
			break;
		default:
			break;
	}
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];

	[args setObject:[NSString stringWithFormat:@"%i",idUser] forKey:@"rid"];//reciever id
	[args setObject:[NSString stringWithFormat:@"%i",gId] forKey:@"gid"];//groupId
	
	return [MOKComMessage createMessageWithCommand:type AndArgs:args];
	
	
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

+(MOKComMessage *) createPrueba{
	
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
	
	return [MOKComMessage createMessageWithCommand:MOKMessageFriendRequest AndArgs:args];
}


// ARREGLO INVITACIONES añadi implementacion para mensaje de blMessageGroupUpdate que no habia
+(MOKComMessage *) createGroupUpdateMsg:(int)idGroup forUser:(int)idUser {
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	
		[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"groupId"];
	
	
	
	[args setObject:[NSString stringWithFormat:@"%i",idUser] forKey:@"rid"];//reciever id
	
	return [MOKComMessage createMessageWithCommand:MOKMessageGroupUpdate AndArgs:args];
}



// ARREGLO INVITACIONES añadi implementacion para mensaje de blMessageGroupUpdate que no habia
+(MOKComMessage *) createGroupDeleteMsg:(int)idGroup{
	
	
	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
	
	[args setObject:[NSString stringWithFormat:@"%i",idGroup] forKey:@"groupId"];
	
	
	
	return [MOKComMessage createMessageWithCommand:MOKMessageGroupDelete AndArgs:args];
}




- (void)dealloc {
    [super dealloc];
}


@end
