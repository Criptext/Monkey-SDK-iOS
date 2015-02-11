//
//  DBManager.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/10/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "DBManager.h"
#import <Realm/Realm.h>
#import "User.h"
#import "Message.h"
#import "Conversation.h"
#import "Invite.h"
#import "BLMessage.h"
#import "BLConversation.h"

#import "SessionManager.h"

@interface DBManager ()
@property (strong, nonatomic)NSString *customRealmPath;
@end

@implementation DBManager
#pragma mark - initialization
+ (instancetype)sharedInstance
{
    static DBManager *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initPrivate];
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[DBManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        //init properties
    }
    return self;
}

- (void)setCustomRealm: (NSString *)realm{
    self.customRealmPath = realm;
}

- (NSString *)getCustomRealm{
    return self.customRealmPath;
}

#pragma mark - Users

- (void)storeOrUpdateAllUsers:(NSArray *)users isfriend:(NSString *)isFriend {
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    [realm beginWriteTransaction];
    for (BLUserExtended *user in users) {
        //    if ([User objectInRealm:realm forPrimaryKey:user.userId]) {
        //      continue;
        //    }
        User *newUser = [[User alloc] init];
        newUser.userId = user.userId;
        newUser.firstName = user.firstName;
        newUser.lastName = user.lastName;
        newUser.email = user.email;
        newUser.phone = user.phone;
        newUser.iv = user.iv;
        newUser.isFriend = [isFriend boolValue];
        newUser.active = user.active;
        if (user.companyName == [NSNull null] || [user.companyName isEqualToString:@"N/A"]) {
            newUser.company = @"";
        }else{
            newUser.company = user.companyName;
        }
        newUser.role = user.rol;
        [User createOrUpdateInRealm:realm withObject:newUser];
    }
    [realm commitWriteTransaction];
}


- (void)storeOrUpdateUser:(BLUserExtended*)user isfriend:(NSString *)isFriend{
    NSArray *array = [[NSArray alloc] initWithObjects:user, nil];
    [self storeOrUpdateAllUsers:array isfriend:isFriend];
}

- (BLUserExtended*)userById:(NSString *)userId {
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    BLUserExtended *blUser = [[BLUserExtended alloc] init];
    User *user = [User objectInRealm:realm forPrimaryKey:userId];
    if (user ==nil) {
        blUser.userId= user.userId;
        blUser.firstName = @"unknown modafoka";//NSLocalizedString(@"userDesconocido", @"");
        blUser.lastName = @"unknown modafoka";//NSLocalizedString(@"userDesconocido", @"");
        return blUser;
    }else{
        blUser.userId = user.userId;
        blUser.firstName = user.firstName;
        blUser.lastName = user.lastName;
        blUser.iv = user.iv;
        blUser.email = user.email;
        blUser.userName = user.email;
        blUser.phone = user.phone;
        blUser.active = user.active;
        blUser.companyName = user.company;
        blUser.rol = user.role;
        return blUser;
    }
}

- (NSMutableArray*)usersByIdExceptMe:(NSString *)usersId {
    NSMutableArray *usersToReturn=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    NSArray *usersIds = [usersId componentsSeparatedByString:@","];
    
    for (NSString * userId in usersIds) {
        if ([userId isEqual:[SessionManager sharedInstance].userId]) {
            continue;
        }
        User *user = [User objectInRealm:realm forPrimaryKey:userId];
        if (user == nil) {
            continue;
        }
        BLUserExtended *bluser = [[BLUserExtended alloc]init];
        bluser.userId = user.userId;
        bluser.userName = user.email;
        bluser.firstName = user.firstName;
        bluser.lastName = user.lastName;
        bluser.iv = user.iv;
        bluser.email = user.email;
        bluser.phone = user.phone;
        bluser.active = user.active;
        bluser.companyName = user.company;
        bluser.rol = user.role;
        
        [usersToReturn addObject:bluser];
    }
    
    return usersToReturn;
    
}

- (NSArray *)usersByIds:(NSString *)usersId except:(NSString *)exceptionUserId{
    NSMutableArray *users=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    for (User *user in [User allObjectsInRealm:realm]) {
        if (![user.userId isEqualToString:exceptionUserId]) {
            BLUserExtended *bluser = [[BLUserExtended alloc]init];
            bluser.userId = user.userId;
            bluser.userName = user.email;
            bluser.firstName = user.firstName;
            bluser.lastName = user.lastName;
            bluser.iv = user.iv;
            bluser.email = user.email;
            bluser.phone = user.phone;
            bluser.active = user.active;
            bluser.companyName = user.company;
            bluser.rol = user.role;
            
            [users addObject:bluser];
        }
    }
    
    return users;
}

- (NSArray*)getStoredFriends {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSString *userId = [SessionManager sharedInstance].userId;
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    RLMResults *results = [User objectsInRealm:realm where:@"userId != %@ AND isFriend = YES", userId];
    for (User *user in results) {
        BLUserExtended *blUser = [[BLUserExtended alloc] init];
        blUser.userId = user.userId;
        blUser.firstName = user.firstName;
        blUser.lastName = user.lastName;
        blUser.iv = user.iv;
        blUser.email = user.email;
        blUser.phone = user.phone;
        blUser.active = user.active;
        blUser.companyName = user.company;
        blUser.rol = user.role;
        [result addObject:blUser];
    }
    return result;
}

- (BOOL)isFriend:(NSString *)username{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    RLMResults *results = [User objectsInRealm:realm where:@"email == %@",username];
    if ([results count]>0) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)isFriendById:(NSString *)userid{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    return [User objectInRealm:realm forPrimaryKey:userid] != nil;
}
#pragma mark - Messages
- (void)storeMessage:(BLMessage *)msg{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    NSLog(@"%@", msg);

    [realm beginWriteTransaction];
    NSDictionary *object = @{
                             @"messageId": @(msg.messageId),
                             @"userIdFrom": msg.userIdFrom,
                             @"userIdTo": msg.userIdTo,
                             @"type": @(msg.type),
                             @"timestamp": @(msg.timestamp),
                             @"messageText": msg.messageText,
                             @"iv": msg.iv,
                             @"readByUser": @(msg.readByUser),
                             @"param": msg.param ? msg.param : @"0"
                             };
    
    
    [Message createOrUpdateInRealm:realm withObject:object];
    [realm commitWriteTransaction];
}

- (BLMessage *)getMessageById:(BLMessageId )messageId{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    Message *msg = [Message objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:messageId]];
    
    if (msg !=nil) {
        BLMessage *mensaje = [[BLMessage alloc]init];
        mensaje.messageText = msg.messageText;
        mensaje.type = msg.type;
        mensaje.iv = msg.iv;
        mensaje.timestamp = msg.timestamp;
        mensaje.messageId = msg.messageId;
        mensaje.userIdFrom = msg.userIdFrom;
        mensaje.userIdTo = msg.userIdTo;
        mensaje.readByUser = msg.readByUser;
        mensaje.param = msg.param;
        return mensaje;
    }else{
        return nil;
    }
}

- (NSMutableArray*)getMessagesByConversation:(NSString *)userId{
    NSMutableArray *messages=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    
    for (Message *msg in [Message objectsInRealm:realm where:@"userIdFrom == %@",userId]) {
        BLMessage *message = [[BLMessage alloc]init];
        message.messageId = msg.messageId;
        message.userIdTo = msg.userIdTo;
        message.userIdFrom = msg.userIdFrom;
        message.timestamp = msg.timestamp;
        message.messageText = msg.messageText;
        message.readByUser = msg.readByUser;
        message.iv = msg.iv;
        message.param = msg.param;
        message.type = msg.type;
        
        if ([message.userIdTo rangeOfString:@"G"].location == NSNotFound) {
            [messages addObject:message];
        }
    }
    
    return messages;
}

- (NSMutableArray*)getMessagesByGroupConversation:(NSString *)userId{
    NSMutableArray *messages=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    
    for (Message *msg in [Message objectsInRealm:realm where:@"userIdTo == %@ AND userIdFrom != %@",userId, [SessionManager sharedInstance].userId]) {
        BLMessage *message = [[BLMessage alloc]init];
        message.messageId = msg.messageId;
        message.userIdTo = msg.userIdTo;
        message.userIdFrom = msg.userIdFrom;
        message.timestamp = msg.timestamp;
        message.messageText = msg.messageText;
        message.readByUser = msg.readByUser;
        message.param = msg.param;
        message.iv = msg.iv;
        message.type = msg.type;
        
        [messages addObject:message];
    }
    
    return messages;
}

- (NSMutableArray*)getMessagesSentByConversation:(NSString *)userId{
    
    NSMutableArray *messages=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    
    for (Message *msg in [Message objectsInRealm:realm where:@"userIdTo CONTAINS %@",userId]) {
        BLMessage *message = [[BLMessage alloc]init];
        message.messageId = msg.messageId;
        message.userIdTo = msg.userIdTo;
        message.userIdFrom = msg.userIdFrom;
        message.timestamp = msg.timestamp;
        message.messageText = msg.messageText;
        message.iv = msg.iv;
        message.readByUser = msg.readByUser;
        message.param = msg.param;
        message.type = msg.type;
        
        [messages addObject:message];
    }
    
    return messages;
}

- (NSMutableArray*)getMessagesSentByGroupConversation:(NSString *)userId{
    
    NSMutableArray *messages=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    
    for (Message *msg in [Message objectsInRealm:realm where:@"userIdTo CONTAINS %@ AND userIdFrom == %@",userId, [SessionManager sharedInstance].userId]) {
        BLMessage *message = [[BLMessage alloc]init];
        message.messageId = msg.messageId;
        message.userIdTo = msg.userIdTo;
        message.userIdFrom = msg.userIdFrom;
        message.timestamp = msg.timestamp;
        message.messageText = msg.messageText;
        message.readByUser = msg.readByUser;
        message.iv = msg.iv;
        message.param = msg.param;
        message.type = msg.type;
        
        [messages addObject:message];
    }
    
    return messages;
}

- (void)markMessageAsRead:(BLMessage *)message {
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    Message *readMessage = [Message objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:message.messageId]];
    [realm beginWriteTransaction];
    readMessage.readByUser = YES;
    [realm commitWriteTransaction];
    [self updateConversationTime:message.userIdFrom];
}

- (void)markMessageRecievedAsRead:(BLMessage *)message {
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    
    [realm beginWriteTransaction];
    Message *readMessage = [Message objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:message.messageId]];
    readMessage.readByUser = YES;
    [realm commitWriteTransaction];
    [self updateConversationTime:message.userIdFrom];
}

- (void)markAllMessagesReadOfConversation:(NSString *)conversationId{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    
    for (Message *msg in [self getMessagesByConversation:conversationId]) {
        if (msg.readByUser) {
            continue;
        }
        if(![msg.param isEqualToString:@"1"]){
            [realm beginWriteTransaction];
            Message *readMessage = [Message objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:msg.messageId]];
            readMessage.readByUser = YES;
            [realm commitWriteTransaction];
        }
    }
}

- (void)updateMessageSent:(BLMessage *)msg{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    Message *mensaje = [Message objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:msg.oldMessageId]];
    if (!mensaje) {
        return;
    }
    NSDictionary *object = @{
                             @"messageId": @(msg.messageId),
                             @"userIdFrom": msg.userIdFrom,
                             @"userIdTo": msg.userIdTo,
                             @"type": @(msg.type),
                             @"iv": mensaje.iv,
                             @"messageText": mensaje.messageText,
                             @"readByUser": @(msg.readByUser),
                             @"timestamp": @(mensaje.timestamp),
                             @"param": mensaje.param ? mensaje.param : @"0"
                             };
    [realm beginWriteTransaction];

    [realm deleteObject:mensaje];
    [Message createOrUpdateInRealm:realm withObject:object];
    
    [realm commitWriteTransaction];
    
}

- (BLMessage *)getLastMessageSent:(NSString *)userIdTo {
    
    /*NSString *keyLastTo=  [NSString stringWithFormat:@"Messages:LastTo:%@",userIdTo];
     NSDictionary *msgDict=     [[UserDefaultsManager instance] objectForKeyFree:keyLastTo];*/
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    RLMResults *results = [[Message objectsInRealm:realm where:@"userIdTo == %@",userIdTo] sortedResultsUsingProperty:@"timestamp" ascending:YES];
    
    Message *lastMessage = [results lastObject];
    
    if (lastMessage !=nil) {
        BLMessage *mensaje = [[BLMessage alloc]init];
        mensaje.messageText = lastMessage.messageText;
        mensaje.type = lastMessage.type;
        mensaje.timestamp = lastMessage.timestamp;
        mensaje.messageId = lastMessage.messageId;
        mensaje.userIdFrom = lastMessage.userIdFrom;
        mensaje.userIdTo = lastMessage.userIdTo;
        mensaje.readByUser = lastMessage.readByUser;
        mensaje.iv = lastMessage.iv;
        mensaje.param = lastMessage.param;
        return mensaje;
    }else{
        return nil;
    }
}

- (NSArray *)getMessagesNotSent{
    NSMutableArray *messages=[[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    for (Message *msg in [Message allObjectsInRealm:realm]) {
        if (msg.messageId<0 && msg.type != blMessageAudioAttachNew) {
            BLMessage *message = [[BLMessage alloc]init];
            message.messageId = msg.messageId;
            message.userIdTo = msg.userIdTo;
            message.userIdFrom = msg.userIdFrom;
            message.type = msg.type;
            message.timestamp = msg.timestamp;
            message.messageText = msg.messageText;
            message.readByUser = msg.readByUser;
            message.iv = msg.iv;
            message.param = msg.param;
            
            [messages addObject:message];
        }
    }
    
    return messages;
}

#pragma mark - Conversations

- (void)createConversation:(BLConversation *)conversation{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    [realm beginWriteTransaction];
    
    Conversation *conv = [[Conversation alloc]init];
    conv.conversationUserId = conversation.userId;
    conv.groupIds = conversation.groupIds ? conversation.groupIds : @"";
    conv.groupName = conversation.groupName ? conversation.groupName : @"";
    conv.timestamp = conversation.timestamp;
    conv.type = conversation.type;
    [Conversation createOrUpdateInRealm:realm withObject:conv];
    [realm commitWriteTransaction];
}

//-(BLConversation *)createGroupConversation:(NSString *)idConv groupids:(NSString *)groupIds nombre:(NSString *)nombreGrupo{
//    
//    BLConversation *convExt=[self existeConversacion:idConv];
//    if(convExt==nil){
//        convExt= [[BLConversation alloc] initWithId:idConv andType:2 gname:nombreGrupo];
//        convExt.groupName=nombreGrupo;
//        convExt.groupIds=groupIds;
//        convExt.timestamp = [[NSDate date] timeIntervalSince1970];
//        if(nombreGrupo.length>0){
//            [[DBManager instance] createConversation:convExt];
//            [self addConversationFirst:convExt];
//        }
//    }
//    else{
//        [self reloadConversationCell:idConv];
//    }
//    
//    return convExt;
//}

- (NSArray*)getConversations {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    for (Conversation *conv in [Conversation allObjectsInRealm:realm]) {
        BLConversation *blconversation = [[BLConversation alloc]init];
        blconversation.groupIds = conv.groupIds;
        blconversation.groupName = conv.groupName;
        blconversation.userId = conv.conversationUserId;
        blconversation.timestamp = conv.timestamp;
        blconversation.type = conv.type;
        blconversation.userConv = [self userById:conv.conversationUserId];
        blconversation.lastMessageSent = [self getLastMessageSent:conv.conversationUserId];
        if ([conv.conversationUserId rangeOfString:@"G:"].location != NSNotFound) {
            blconversation.mensajes = [self getMessagesByGroupConversation:conv.conversationUserId];
            blconversation.mensajesSent = [self getMessagesSentByGroupConversation:conv.conversationUserId];
        }else{
            blconversation.mensajes = [self getMessagesByConversation:conv.conversationUserId];
            blconversation.mensajesSent = [self getMessagesSentByConversation:conv.conversationUserId];
        }
        
        [result addObject:blconversation];
    }
    return result;
    
}

- (BLConversation *)getConversationsByUserId:(NSString *)userid {
    
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    Conversation *conv = [Conversation objectInRealm:realm forPrimaryKey:userid];

    BLConversation *conversation = [[BLConversation alloc]init];
    conversation.userId = conv.conversationUserId;
    conversation.groupName = conv.groupName;
    conversation.groupIds = conv.groupIds;
    conversation.timestamp = conv.timestamp;
    conversation.lastMessageSent = [self getLastMessageSent:userid];
    conversation.mensajes = [self getMessagesByConversation:userid];
    conversation.mensajesSent = [self getMessagesSentByConversation:userid];
    conversation.userConv = [self userById:userid];
    return conversation;
}

- (void)updateConversationTime:(NSString *)userId{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    [realm beginWriteTransaction];
    Conversation *conversation = [Conversation objectInRealm:realm forPrimaryKey:userId];
    conversation.timestamp = [[NSDate date] timeIntervalSince1970];
    [realm commitWriteTransaction];
    
}

- (void)updateConversationTime:(NSString *)userId time:(NSTimeInterval)timeStamp{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    [realm beginWriteTransaction];
    Conversation *conversation = [Conversation objectInRealm:realm forPrimaryKey:userId];
    conversation.timestamp = timeStamp;
    [realm commitWriteTransaction];
    
}
@end
