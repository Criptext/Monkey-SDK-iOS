//
//  MOKMessage.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKDictionaryBasedObject.h"
#import "MOKutils.h"

@class MOKUser;

typedef enum{
    MOKText = 1,
    MOKFile = 2,
    MOKTempNote = 3,
    MOKNotif = 4,
    MOKAlert = 5,
} MOKMessageType;

typedef enum{
    MOKProtocolMessage = 200,
    MOKProtocolGet = 201,
    MOKProtocolTransaction = 202,
    MOKProtocolOpen = 203,
    MOKProtocolSet = 204,
    MOKProtocolACK = 205,
    MOKProtocolDelete = 207,
    MOKProtocolClose = 208
} MOKProtocolCommand;

typedef enum{
    MOKAudio = 1,
    MOKPhoto = 2,
    MOKVideo = 3,
    MOKArchive = 4
} MOKFileType;

typedef enum{
    MOKGroupCreate = 1,
    MOKGroupDelete = 2,
    MOKGroupNewMember = 3,
    MOKGroupRemoveMember = 4,
    MOKGroupsJoined = 5
}MOKGroupActionType;

@interface MOKMessage : MOKDictionaryBasedObject

@property (nonatomic, strong) NSString *messageText;
@property (nonatomic, strong) NSString *encryptedText;
@property (unsafe_unretained, nonatomic, readonly) NSString *messageTextToShow;
@property (nonatomic, strong) NSString * iv;
@property (nonatomic, assign) NSTimeInterval timestampCreated;
@property (nonatomic, assign) NSTimeInterval timestampOrder;
@property (nonatomic, strong) NSString * userIdTo;
@property (nonatomic, strong) NSString * userIdFrom;
@property (nonatomic, strong) NSMutableDictionary * params;
@property (nonatomic, strong) NSMutableDictionary *mkProperties;
@property (nonatomic, assign) MOKMessageId oldMessageId;
@property (nonatomic, assign) MOKMessageId messageId;
@property (nonatomic, assign) BOOL readByUser;
@property (nonatomic, assign) MOKProtocolCommand protocolCommand;
@property (nonatomic, assign) int protocolType;
@property (nonatomic, assign) int monkeyActionType;
@property (nonatomic, strong) NSString *pushMessage;

@property (nonatomic, assign) BOOL isSending;
@property (nonatomic, assign) BOOL needsResend;
//@property (nonatomic, assign) BLGroupId groupId;
@property (unsafe_unretained, nonatomic, readonly) NSString *dateTimeAsString;
@property (unsafe_unretained, nonatomic, readonly) NSString *conversationTime;
//@property (unsafe_unretained, nonatomic, readonly) NSArray *emoticons;

@property (nonatomic, assign) int deliveredMessage;

- (id)initWithArgs:(NSDictionary*)dictionary;
- (id)initWithMessage:(NSString*)messageText
      protocolCommand:(MOKProtocolCommand)cmd
         protocolType:(int)protocolType
     monkeyActionType:(int)monkeyActionType
            messageId:(MOKMessageId)messageId
         oldMessageId:(MOKMessageId)oldMessageId
            messageIV:(NSString *)iv
     timestampCreated:(NSTimeInterval)timestampCreated
       timestampOrder:(NSTimeInterval)timestampOrder
             fromUser:(NSString *)sessionIdFrom
               toUser:(NSString *)sessionIdTo
         mkProperties:(NSMutableDictionary *)mkprops
               params:(NSMutableDictionary *)params;
- (id)initWithMyMessage:(NSString*)messageText userTo:(NSString *)sessionId;
- (void)updateMessageIdFromACK;
- (BOOL)isSending;
- (BOOL)isMessageFromMe;
- (BOOL)isGroupMessage;

-(id) mutableCopyWithZone: (NSZone *) zone;



@end

