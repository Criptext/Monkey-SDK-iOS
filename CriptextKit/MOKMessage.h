//
//  BLMessage.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKDictionaryBasedObject.h"
#import "MOKutils.h"

@class MOKUser;

typedef enum {
	MOKMessageDefault = 0,
	MOKMessageTyping = 2,
	MOKMessageStatus = 3,
	MOKMessageAvatar = 4,
	MOKMessageGroupAdd = 5,
	MOKMessageGroupRemove = 6,
	MOKMessageGroupUpdate = 7,
	MOKMessageGroupDelete = 8,
	MOKMessageGroupMessage = 9,
	MOKMessageDeleteFriend = 13,
	MOKMessageAnonymous = 14,
	MOKMessageConversationOpen = 15,
	MOKMessageConversationClose = 16,
    MOKMessageAudioAttach = 17,
	MOKMessageAudioAttachNew = 54,
	MOKMessagePhotoAttach = 18,
    MOKMessagePhotoAttachNew = 55,
	MOKMessageFile = 19,//19
	MOKMessageUntyping=20,
	MOKMessageNewContactRegistered=21,
	MOKMessageOnline=22,
    MOKEmailInbox=23,
    MOKMessageUpdates=27,
    MOKEmailUpdates=28,
    MOKMessageResend=30,
    MOKMessageFriendRequest = 31,
    MOKMessageInviteAccepted = 32,
	//blMessageInviteDenied = 33,
    MOKMessageEmailOpen = 33,
	MOKMessageInviteCanceled = 34,
    MOKMessageFriendDirect = 36,
    MOKMessageFriendActivate =37,
    MOKMessageremoteLogout =38,
//    MOKMessageEmailOpen=40,
    MOKMessageGroupDefault=41,
    MOKMessageGroupCreate=42,
    MOKMessageGroupRemoveMember=43,
    MOKMessageRecall=44,
    MOKMessageAlert=45,
    MOKMessageUserGroupsUpdate=46,
    MOKMessagesUserOffline=47,
    MOKMessagesUserOnline=48,
    MOKMessageNotifyOpen=49,
    MOKMessageNotDelivered = 50,
	MOKMessageDelivered = 51,
	MOKMessageNotView = 52,
    MOKEmailSendFailure=53,
    MOKWarningUserTookScreenShot = 60,
    MOKCleanBadges=80,
    MOKActivatePush=81,
    MOKCodeExecution=82,
    MOKOldBroadcastMessage=35,
    MOKBroadcastMessage=39,
    MOKJoinChannel=25,
    MOKChannelMessage=61,
    MOKForceAllowPush=83,
    MOKblMessageOpenSession = 104
	
} MOKMessageType;

@interface MOKMessage : MOKDictionaryBasedObject {
	NSString *messageText;
	NSString *messageTextToShow;
    NSString *iv;
	NSTimeInterval timestamp;
	NSString * userIdTo;
	NSString * userIdFrom;
	MOKMessageId messageId;
	BOOL readByUser;
	MOKMessageType type;
	int stringsCount;
	float stringLength;
	BOOL isSending;
	NSString *dateTimeAsString;
	NSArray *__unsafe_unretained emoticons;	
	int deliveredMessage;
    NSString *param;
    NSString *filePathDesencriptado;
}

@property (nonatomic, strong) NSString *messageText;
@property (unsafe_unretained, nonatomic, readonly) NSString *messageTextToShow;
@property (nonatomic, strong) NSString * iv;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, strong) NSString * userIdTo;
@property (nonatomic, strong) NSString * userIdFrom;
@property (nonatomic, strong) NSString * param;
@property (nonatomic, assign) MOKMessageId oldMessageId;
@property (nonatomic, assign) MOKMessageId messageId;
//@property (nonatomic, assign) BLMessageId groupMessageId;
@property (nonatomic, assign) BOOL readByUser;
@property (nonatomic, assign) MOKMessageType type;
@property (nonatomic, readonly) int stringsCount;
@property (nonatomic, readonly) float stringLength;
@property (nonatomic, assign) BOOL isSending;
@property (nonatomic, assign) BOOL needsResend;
//@property (nonatomic, assign) BLGroupId groupId;
@property (unsafe_unretained, nonatomic, readonly) NSString *dateTimeAsString;
@property (unsafe_unretained, nonatomic, readonly) NSString *conversationTime;
//@property (unsafe_unretained, nonatomic, readonly) NSArray *emoticons;

@property (nonatomic, assign) int deliveredMessage;

- (id)initWithObjectStore:(NSDictionary*)dictionary;
- (id)initWithArgs:(NSDictionary*)dictionary;
- (id)initWithDictionary:(NSDictionary*)dictionary;
//- (id)initWithGroupDictionary:(NSDictionary*)dictionary;
- (id)initWithMessage:(NSString*)_messageText messageId:(MOKMessageId)_messageId  messageIV:(NSString *)_iv timestamp:(NSTimeInterval)_timestamp userId:(NSString *)_userId;
- (id)initWithMyMessage:(NSString*)_messageText userTo:(NSString *)_userId;
- (id)initWithMyMessageAnonymous:(NSString*)_messageText userTo:(NSString *)_userId;
//- (id)initWithShareFriend:(BLUserExtended*)user toUser:(BLUserId)toUser;
//- (id)initWithShareFriend:(BLUserExtended*)user toGroup:(BLGroupId)toGroup;
- (BOOL)isSending;
- (BOOL)isMessageFromMe;
//- (BOOL)isGroupMessage;
//+ (BLMessage*)retainedMessage:(NSString*)messageText toGroup:(BLGroupId)groupId;
//- (NSString*)shareAFriendText;
//- (BLUserId)shareAFriendUserId;
//- (void)checkForShareAFriend;
//- (BOOL)isOpenEye;
- (BOOL)haveAttach;
- (NSString*)audioPath;
- (NSString*)photoPath;
- (NSString*)videoPath;
- (NSString*)filePath;

- (NSTimeInterval )getTimePassed;
	
+ (MOKMessageType)typeForString:(NSString*)str;

//+(NSString *) getUniqueMessageId;

-(void) messageOn;

-(BOOL)isErrorSending;

+ (NSString*)conversationTime:(NSTimeInterval)time;

-(id) mutableCopyWithZone: (NSZone *) zone;

- (BOOL)isBroadcastMessage;
- (BOOL)isGroupMessage;
- (NSString *)getIdForConversation;

@end

