//
//  ComMessageProtocol.h
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "MOKJSON.h"
#import "MOKComMessage.h"
#import "MOKMessage.h"

typedef enum {
	// JOSE
	//MessageNotDelivered = 50,
	//MessageDelivered = 51,
	//MessageNotView = 52,
	MessageOpenCloseNotification=53,
	
	SuscribeToChannels = 25,
	MessagesUpdates = 27,
    
    //MessagesUserOnline=28,
    //MessagesUserOffline=29
    
	
} ComMessageType;



@interface MOKComMessageProtocol : NSObject {

}

+(MOKComMessage *) createMsgFromBlMessage:(MOKMessage *)message;
+(MOKComMessage *) createMessageFromBlMessageAndReceiver:(MOKMessage*)message;
+(MOKComMessage *) createResendMsgFromBlMessage:(MOKMessage *)message ofTypeResend:(int)messageTypeResend;
+(MOKComMessage *) createChatMsg:(NSString *)msg forUser:(NSString *)idUser andId:(long long int)mid;
+(MOKComMessage *) createGroupMsg:(NSString *)msg forGroup:(int)idGroup andId:(long long int)mid;

+(MOKComMessage *) createBasicMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg andId:(long long int)mid andParam:(NSString *)param;
+(MOKComMessage *) createBasicResendMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg  andId:(long long int)mid ofTypeResend:(int)messageTypeResend;//NUEVO

+(MOKComMessage *) createShareFriendToUserMsg:(NSString *)idUser withName:(NSString *)fname lastName:(NSString *)lname toUser:(NSString *)idDestin andId:(long long int)mid;
+(MOKComMessage *) createShareFriendToGroupMsg:(int)idUser withName:(NSString *)fname lastName:(NSString *)lname toGroup:(int)idGroup andId:(long long int)mid;
+(MOKComMessage *) createNotificationMsg:(NSString *) idUser ofStringType:(NSString *) messageType;
+(MOKComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type;
+(MOKComMessage *) createNotification:(int) type;
+(MOKComMessage *) createNotificationOffline:(int) type cleanbadges:(NSString *)cleanbadges;
+(MOKComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type msjid:(NSString *)msjId;
+(MOKComMessage *) createSyncUpdatenMsg:(MOKMessageId)last_message_id type:(int) type;
+(MOKComMessage *) createRecallMsg:(NSString *)idUser msgId:(MOKMessageId)msgId;
+(MOKComMessage *) createGroupRecallMsg:(NSString *)idUser msgId:(MOKMessageId)msgId;

+(MOKComMessage *) createAddRemoveGroupMsg:(MOKGroupId)idGroup add:(NSArray*)arrayAdd andRemove:(NSArray*)arrayRemove;
// ARREGLO INVITACIONES envio de groupId
+(MOKComMessage *) createInvitesNotificationMsg:(int)idUser groupId:(int)gId action:(int)typeNotification;
//+(ComMessage *) createInvitesMsg:(NSArray*)array;
//+(ComMessage *) createCreateGroupMsg:(int)idGroup andName:(NSString *) groupName;
//+(ComMessage *) createSuscribeGroupMsg:(NSArray*)array;

+(MOKComMessage *) createPrueba;

// ARREGLO INVITACIONES declaracion de metodo
+(MOKComMessage *) createGroupUpdateMsg:(int)idGroup forUser:(int)idUser;

+(MOKComMessage *) createGroupDeleteMsg:(int)idGroup;

+(NSString *) convertToUTF8:(NSString *)texto;

@end
