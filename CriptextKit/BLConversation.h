//
//  BLConversation.h
//  Blip
//
//  Created by G V on 20.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLUserExtended.h"

@class BLMessage;

@interface BLConversation : BLDictionaryBasedObject {

    NSString * groupIds;
    NSString * groupName;
	NSString * userId;
    NSTimeInterval timestamp;
    NSMutableArray *mensajes;
    NSMutableArray *mensajesSent;
    
    int state;//si esta en input para responder o en estado de lectura
    int type;
    
    NSString * userIdLastAction;
    
    BLMessage *lastMessageSent;
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
@property (nonatomic, strong) BLMessage *lastMessageSent;
@property (nonatomic, strong) BLUserExtended *userConv;

- (id)initWithObjectStore:(NSDictionary*)dictionary;
//- (id)initWithRealm:(Conversation *)conversation;
- (id)initWithUserId:(NSString *)userId_ ;
- (id)initWithUser:(BLUserExtended *)userExt;
- (id)initWithUserAnonymous:(NSString *)userId_;
- (id)initWithId:(NSString *)convId andType:(int)paramType gname:(NSString *)gname;
- (id)initWithMail:(NSString *)correo;
- (BLMessage *)getLastMessage;
- (BLMessage *)lastMessageWithoutRead;
- (void)removeLastMessage;
- (int)getTotalMessagesWithoutRead;
- (NSMutableArray *)getMessagesWithoutRead;
- (bool)hasUser;
- (BOOL)isBroadcastConv;
- (BOOL)isGroupConv;
- (NSString*)avatarGroupImageWebPath;

@end
