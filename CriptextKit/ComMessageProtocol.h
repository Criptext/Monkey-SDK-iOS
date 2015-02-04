//
//  ComMessageProtocol.h
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "JSON.h"
#import "ComMessage.h"
#import "BLMessage.h"

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



@interface ComMessageProtocol : NSObject {

}

+(ComMessage *) createMsgFromBlMessage:(BLMessage *)message;
+(ComMessage *) createMessageFromBlMessageAndReceiver:(BLMessage*)message;
+(ComMessage *) createResendMsgFromBlMessage:(BLMessage *)message ofTypeResend:(int)messageTypeResend;
+(ComMessage *) createChatMsg:(NSString *)msg forUser:(NSString *)idUser andId:(long long int)mid;
+(ComMessage *) createGroupMsg:(NSString *)msg forGroup:(int)idGroup andId:(long long int)mid;

+(ComMessage *) createBasicMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg andId:(long long int)mid andParam:(NSString *)param;
+(ComMessage *) createBasicResendMsg:(NSString *)idUser ofType:(int)messageType andMessage:(NSString *)msg  andId:(long long int)mid ofTypeResend:(int)messageTypeResend;//NUEVO

+(ComMessage *) createShareFriendToUserMsg:(NSString *)idUser withName:(NSString *)fname lastName:(NSString *)lname toUser:(NSString *)idDestin andId:(long long int)mid;
+(ComMessage *) createShareFriendToGroupMsg:(int)idUser withName:(NSString *)fname lastName:(NSString *)lname toGroup:(int)idGroup andId:(long long int)mid;
+(ComMessage *) createNotificationMsg:(NSString *) idUser ofStringType:(NSString *) messageType;
+(ComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type;
+(ComMessage *) createNotification:(int) type;
+(ComMessage *) createNotificationOffline:(int) type cleanbadges:(NSString *)cleanbadges;
+(ComMessage *) createNotificationMsg:(NSString *) idUser type:(int) type msjid:(NSString *)msjId;
+(ComMessage *) createSyncUpdatenMsg:(BLMessageId)last_message_id type:(int) type;
+(ComMessage *) createRecallMsg:(NSString *)idUser msgId:(BLMessageId)msgId;
+(ComMessage *) createGroupRecallMsg:(NSString *)idUser msgId:(BLMessageId)msgId;

+(ComMessage *) createAddRemoveGroupMsg:(BLGroupId)idGroup add:(NSArray*)arrayAdd andRemove:(NSArray*)arrayRemove;
// ARREGLO INVITACIONES envio de groupId
+(ComMessage *) createInvitesNotificationMsg:(int)idUser groupId:(int)gId action:(int)typeNotification;
//+(ComMessage *) createInvitesMsg:(NSArray*)array;
//+(ComMessage *) createCreateGroupMsg:(int)idGroup andName:(NSString *) groupName;
//+(ComMessage *) createSuscribeGroupMsg:(NSArray*)array;

+(ComMessage *) createPrueba;

// ARREGLO INVITACIONES declaracion de metodo
+(ComMessage *) createGroupUpdateMsg:(int)idGroup forUser:(int)idUser;

+(ComMessage *) createGroupDeleteMsg:(int)idGroup;

+(NSString *) convertToUTF8:(NSString *)texto;

@end
