//
//  BLConversation.h
//  Blip
//
//  Created by G V on 20.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKUser.h"

@class MOKMessage;

@interface MOKConversation : MOKDictionaryBasedObject {

    NSString * groupIds;
    NSString * groupName;
	NSString * userId;
    NSTimeInterval timestamp;
    NSMutableArray *mensajes;
    NSMutableArray *mensajesSent;
    
    int state;//si esta en input para responder o en estado de lectura
    int type;
    
    NSString * userIdLastAction;
    
    MOKMessage *lastMessageSent;
//    WebConnector *connector;
}

@property (nonatomic, strong) NSString * groupIds;
@property (nonatomic, strong) NSString * groupName;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * userIdLastAction;
@property int state;
@property int type;
@property BOOL isLoadingPhoto;
@property NSTimeInterval timestamp;
@property (nonatomic, strong) NSMutableArray *mensajes;
@property (nonatomic, strong) NSMutableArray *mensajesSent;
@property (nonatomic, strong) MOKMessage *lastMessageSent;
@property (nonatomic, strong) MOKUser *userConv;

- (id)initWithObjectStore:(NSDictionary*)dictionary;
//- (id)initWithRealm:(Conversation *)conversation;
- (id)initWithUserId:(NSString *)userId_ ;
- (id)initWithUser:(MOKUser *)userExt;
- (id)initWithUserAnonymous:(NSString *)userId_;
- (id)initWithId:(NSString *)convId andType:(int)paramType gname:(NSString *)gname;
- (MOKMessage *)getLastMessage;
- (MOKMessage *)lastMessageWithoutRead;
- (void)removeLastMessage;
- (int)getTotalMessagesWithoutRead;
- (NSMutableArray *)getMessagesWithoutRead;
- (bool)hasUser;
- (BOOL)isBroadcastConv;
- (BOOL)isGroupConv;
- (NSString*)avatarGroupImageWebPath;

@end
