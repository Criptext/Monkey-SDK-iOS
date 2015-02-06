//
//  BLMessage.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLDictionaryBasedObject.h"
#import "utils.h"

@class BLUserExtended;

typedef enum {
	blMessageDefault = 0,
	blMessageTyping = 2,
	blMessageStatus = 3,
	blMessageAvatar = 4,
	blMessageGroupAdd = 5,
	blMessageGroupRemove = 6,
	blMessageGroupUpdate = 7,
	blMessageGroupDelete = 8,
	blMessageGroupMessage = 9,
	blMessageDeleteFriend = 13,
	blMessageAnonymous = 14,
	blMessageConversationOpen = 15,
	blMessageConversationClose = 16,
    blMessageAudioAttach = 17,
	blMessageAudioAttachNew = 54,
	blMessagePhotoAttach = 18,
    blMessagePhotoAttachNew = 55,
	blMessageFile = 19,//19
	blMessageUntyping=20,
	MessageNewContactRegistered=21,
	blMessageOnline=22,
    EmailInbox=23,
    MessageUpdates=27,
    EmailUpdates=28,
    blMessageResend=30,
    blMessageFriendRequest = 31,
    blMessageInviteAccepted = 32,
	//blMessageInviteDenied = 33,
    blMessageEmailOpen = 33,
	blMessageInviteCanceled = 34,
    blMessageFriendDirect = 36,
    MessageFriendActivate =37,
    MessageremoteLogout =38,
    MessageEmailOpen=40,
    MessageGroupDefault=41,
    MessageGroupCreate=42,
    MessageGroupRemoveMember=43,
    MessageRecall=44,
    MessageAlert=45,
    MessageUserGroupsUpdate=46,
    MessagesUserOffline=47,
    MessagesUserOnline=48,
    MessageNotifyOpen=49,
    MessageNotDelivered = 50,
	MessageDelivered = 51,
	MessageNotView = 52,
    EmailSendFailure=53,
    WarningUserTookScreenShot = 60,
    CleanBadges=80,
    ActivatePush=81,
    CodeExecution=82,
    OldBroadcastMessage=35,
    BroadcastMessage=39,
    JoinChannel=25,
    ChannelMessage=61,
    ForceAllowPush=83
	
} BLMessageType;

@interface BLMessage : BLDictionaryBasedObject {
	NSString *messageText;
	NSString *messageTextToShow;
	NSTimeInterval timestamp;
	NSString * userIdTo;
	NSString * userIdFrom;
	BLMessageId messageId;
	BOOL readByUser;
	BLMessageType type;
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
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, strong) NSString * userIdTo;
@property (nonatomic, strong) NSString * userIdFrom;
@property (nonatomic, strong) NSString * param;
@property (nonatomic, assign) BLMessageId oldMessageId;
@property (nonatomic, assign) BLMessageId messageId;
//@property (nonatomic, assign) BLMessageId groupMessageId;
@property (nonatomic, assign) BOOL readByUser;
@property (nonatomic, assign) BLMessageType type;
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
- (id)initWithMessage:(NSString*)messageText messageId:(BLMessageId)messageId timestamp:(NSTimeInterval)timestamp userId:(NSString *)userId;
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
	
+ (BLMessageType)typeForString:(NSString*)str;

//+(NSString *) getUniqueMessageId;

-(void) messageOn;

-(BOOL)isErrorSending;

+ (NSString*)conversationTime:(NSTimeInterval)time;

-(id) mutableCopyWithZone: (NSZone *) zone;

- (BOOL)isBroadcastMessage;
- (BOOL)isGroupMessage;
- (NSString *)getIdForConversation;

@end

