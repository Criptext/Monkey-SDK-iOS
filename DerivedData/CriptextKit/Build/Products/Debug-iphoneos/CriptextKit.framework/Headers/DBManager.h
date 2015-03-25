//
//  DBManager.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/10/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "utils.h"
@class BLMessage;
@class BLUser;
@class BLConversation;

@interface DBManager : NSObject

+(instancetype)sharedInstance;
- (void)setCustomRealm:(NSString *)realm;

#pragma mark Users and Friends

- (void)storePassword:(NSString *)pass forUserId:(NSString *)userId;
- (NSString *)getPasswordForUserId:(NSString *)userId;
- (void)storeOrUpdateUser:(BLUser*)user;//listo (no hubo cambio)
- (BLUser*)userById:(NSString *)userId;//listo
- (NSMutableArray*)usersByIdExceptMe:(NSString *)usersId;//listo
- (NSArray *)usersByIds:(NSString *)usersId except:(NSString *)exceptionUserId;//listo

- (void)storePassword:(NSString *)pass;//no hay que tocar
- (NSString *)getPassword;//no hay que tocar
//- (void)removeAllUsers; //listo
//- (void)deleteUser:(NSString *)userId; //listo

#pragma mark Conversations

- (void)createConversation:(BLConversation *)conversation;//listo
//- (BLConversation *)createGroupConversation:(NSString *)idConv groupids:(NSString *)groupIds nombre:(NSString *)nombreGrupo;
- (NSArray*)getConversations;//antes conversationList //listo
- (BLConversation *)getConversationsByUserId:(NSString *)userid;//listo
//- (void)deleteConversation:(BLConversation *)conversation;//listo (revisar último)
- (void)updateConversationTime:(NSString *)userId;//listo
- (void)updateConversationTime:(NSString *)userId time:(NSTimeInterval)timeStamp;//listo
//- (void)updateConversationGroupMembers:(NSString *)userId members:(NSString *)members;//listo
//- (void)updateConversationGroupNameMembs:(NSString *)userId members:(NSString *)members name:(NSString *)name; //listo




#pragma mark Messages
- (void)storeMessage:(BLMessage *)msg;
- (BOOL)existMessage:(BLMessageId)messageId;
- (BLMessage *)getMessageById:(BLMessageId )messageId;
- (NSMutableArray*)getMessagesByConversation:(NSString *)userId;
- (NSMutableArray*)getMessagesByGroupConversation:(NSString *)userId;
- (NSMutableArray*)getMessagesSentByConversation:(NSString *)userId;
- (NSMutableArray*)getMessagesSentByGroupConversation:(NSString *)userId;
- (void)markMessageAsRead:(BLMessage *)message;
- (void)markMessageRecievedAsRead:(BLMessage *)message;
- (void)markAllMessagesReadOfConversation:(NSString *)conversationId;
- (void)updateMessageSent:(BLMessage *)msg;
- (BLMessage *)getLastMessageSent:(NSString *)userIdTo;
- (NSArray *)getMessagesNotSent;



@end
