//
//  MOKDBManager.m
//  MonkeyKit
//
//  Created by Gianni Carlo on 3/24/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "MOKDBManager.h"
#import "MOKMessage.h"
#import "MOKDBMessage.h"
#import "MOKDBSession.h"
#import "MOKUserDictionary.h"
#import "MOKJSON.h"
#import <Realm/Realm.h>

@interface MOKDBManager ()
@property (nonatomic, strong) MOKSBJsonWriter *jsonWriter;
@property (nonatomic, strong) MOKSBJsonParser *jsonParser;
@property (nonatomic, strong) RLMRealmConfiguration *config;
@property (nonatomic, strong) NSString *privateRealmPath;
@end

@implementation MOKDBManager
#pragma mark - initialization
+ (instancetype)sharedInstance
{
    static MOKDBManager *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initPrivate];
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MOKDBManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        //init properties
        self.jsonWriter = [MOKSBJsonWriter new];
        self.jsonParser = [MOKSBJsonParser new];
        
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"private_MOKdb"];
        self.privateRealmPath = [documentsDirectory stringByAppendingString:@".realm"];
        
        
        
        self.config = [RLMRealmConfiguration defaultConfiguration];
        self.config.path = self.privateRealmPath;
        self.config.objectClasses = @[MOKDBSession.class, MOKDBMessage.class];
        self.config.schemaVersion = 9;
        #ifndef DEBUG
        self.config.encryptionKey = [self getKey];
		#endif
        self.config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
            if (oldSchemaVersion < 1) {
                [migration enumerateObjects:MOKDBMessage.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    newObject[@"timestampCreated"] = oldObject[@"timestamp"];
                    newObject[@"timestampOrder"] = oldObject[@"timestamp"];
                }];
            }
            if (oldSchemaVersion < 2) {
                [migration enumerateObjects:MOKDBMessage.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    newObject[@"protocolCommand"] = [NSNumber numberWithInt:200];
                    if ((int)oldObject[@"type"] == 54 || (int)oldObject[@"type"] == 55) {
                        newObject[@"protocolType"] = [NSNumber numberWithInt:2];
                    }else{
                        newObject[@"protocolType"] = [NSNumber numberWithInt:1];
                    }
                }];
            }
        };
    }
    return self;
}

- (void)logout{
    [[NSFileManager defaultManager] removeItemAtPath:self.config.path error:nil];
}
- (NSData *)getKey {
    // Identifier for our keychain entry - should be unique for your application
    static const uint8_t kKeychainIdentifier[] = "com.criptext.monkeykit";
    NSData *tag = [[NSData alloc] initWithBytesNoCopy:(void *)kKeychainIdentifier
                                               length:sizeof(kKeychainIdentifier)
                                         freeWhenDone:NO];
    
    // First check in the keychain for an existing key
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassKey,
                            (__bridge id)kSecAttrApplicationTag: tag,
                            (__bridge id)kSecAttrKeySizeInBits: @512,
                            (__bridge id)kSecReturnData: @YES};
    
    CFTypeRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef);
    if (status == errSecSuccess) {
        return (__bridge NSData *)dataRef;
    }
    
    // No pre-existing key from this application, so generate a new one
    uint8_t buffer[64];
    SecRandomCopyBytes(kSecRandomDefault, 64, buffer);
    NSData *keyData = [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
    
    // Store the key in the keychain
    query = @{(__bridge id)kSecClass: (__bridge id)kSecClassKey,
              (__bridge id)kSecAttrApplicationTag: tag,
              (__bridge id)kSecAttrKeySizeInBits: @512,
              (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
              (__bridge id)kSecValueData: keyData};
    
    status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    NSAssert(status == errSecSuccess, @"Failed to insert new key in the keychain");
    
    return keyData;
}

-(RLMRealm *)getRealmWithMyConfiguration:(RLMRealmConfiguration *)config{
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if (error) {
        NSLog(@"error:%@", [error localizedDescription]);
        [[NSFileManager defaultManager] removeItemAtPath:self.config.path error:nil];
        return [self getRealmWithMyConfiguration:self.config];
    }
    
    return realm;
}
#pragma mark - Messages
- (void)storeMessage:(MOKMessage *)msg{
    
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    
    [realm beginWriteTransaction];
    NSDictionary *object = @{
                             @"messageId": msg.messageId,
                             @"oldmessageId": msg.oldMessageId,
                             @"userIdFrom": msg.userIdFrom,
                             @"userIdTo": msg.userIdTo,
                             @"protocolCommand": @(msg.protocolCommand),
                             @"protocolType": @(msg.protocolType),
                             @"timestampCreated": @(msg.timestampCreated),
                             @"timestampOrder": @(msg.timestampOrder),
                             @"messageText": msg.messageText,
                             @"readByUser": @(msg.readByUser),
                             @"mkprops": [self.jsonWriter stringWithObject:msg.props],
                             @"param": [self.jsonWriter stringWithObject:msg.params]
                             };
    
    
    [MOKDBMessage createOrUpdateInRealm:realm withValue:object];
    [realm commitWriteTransaction];
}
- (BOOL)existMessage:(NSString *)messageId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    return [MOKDBMessage objectInRealm:realm forPrimaryKey:messageId] != nil;
}
- (MOKMessage *)getMessageById:(NSString *)messageId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBMessage *msg = [MOKDBMessage objectInRealm:realm forPrimaryKey:messageId];
    
    if (msg !=nil) {
        MOKMessage *mensaje = [[MOKMessage alloc]init];
        mensaje.messageText = msg.messageText;
        mensaje.protocolCommand = (int)msg.protocolCommand;
        mensaje.protocolType = (int)msg.protocolType;
        mensaje.timestampCreated = msg.timestampCreated;
        mensaje.timestampOrder = msg.timestampOrder;
        mensaje.messageId = msg.messageId;
        mensaje.userIdFrom = msg.userIdFrom;
        mensaje.userIdTo = msg.userIdTo;
        mensaje.readByUser = msg.readByUser;
        mensaje.oldMessageId = msg.oldmessageId;
        mensaje.params = [self.jsonParser objectWithString:msg.param];
        mensaje.props = [self.jsonParser objectWithString:msg.mkprops];
        return mensaje;
    }else{
        return nil;
    }
}
- (void)deleteMessageSentWithId:(NSString *)messageId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBMessage *mensaje = [MOKDBMessage objectInRealm:realm forPrimaryKey:messageId];
    if (mensaje == nil) {
        return;
    }
    [realm beginWriteTransaction];
    
    [realm deleteObject:mensaje];
    
    [realm commitWriteTransaction];
    
}
- (void)deleteMessageSent:(MOKMessage *)msg{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBMessage *mensaje = [MOKDBMessage objectInRealm:realm forPrimaryKey:msg.oldMessageId];
    if (mensaje == nil) {
        return;
    }
    [realm beginWriteTransaction];
    
    [realm deleteObject:mensaje];
    
    [realm commitWriteTransaction];
    
}
- (MOKMessage *)getOldestMessageNotSent{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    for (MOKDBMessage *msg in [MOKDBMessage allObjectsInRealm:realm]) {
        if ([msg.messageId intValue]<0) {
            MOKMessage *message = [[MOKMessage alloc]init];
            message.messageId = msg.messageId;
            message.userIdTo = msg.userIdTo;
            message.userIdFrom = msg.userIdFrom;
            message.protocolCommand = (int)msg.protocolCommand;
            message.protocolType = (int)msg.protocolType;
            message.timestampCreated = msg.timestampCreated;
            message.timestampOrder = msg.timestampOrder;
            message.messageText = msg.messageText;
            message.readByUser = msg.readByUser;
            message.params = [self.jsonParser objectWithString:msg.param];
            if (message.params == nil) {
                message.params = [@{} mutableCopy];
            }
            message.props = [self.jsonParser objectWithString:msg.mkprops];
            if (message.props == nil) {
                message.props = [@{} mutableCopy];
            }
            message.oldMessageId = msg.oldmessageId;
            return message;
        }
    }
    return nil;
}

- (MOKDBSession *)checkSession:(RLMRealm *)realm{
    RLMResults *sessionresults = [MOKDBSession allObjectsInRealm:realm];
    MOKDBSession *session;
    
    if(sessionresults.count == 0){
        session = [[MOKDBSession alloc]init];
    }else{
        session = sessionresults.firstObject;
    }
    return session;
}

- (void)storeSessionId:(NSString *)sessionId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    [realm beginWriteTransaction];
    session.sessionId = sessionId;
    [MOKDBSession createOrUpdateInRealm:realm withValue:session];
    [realm commitWriteTransaction];
}
- (NSString *)loadSessionId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    return session.sessionId;

}
- (void)storeAppId:(NSString *)appId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    [realm beginWriteTransaction];
    session.appId = appId;
    [MOKDBSession createOrUpdateInRealm:realm withValue:session];
    [realm commitWriteTransaction];
}
- (NSString *)loadAppId{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    return session.appId;
}
- (void)storeAppKey:(NSString *)appKey{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    [realm beginWriteTransaction];
    session.appKey = appKey;
    [MOKDBSession createOrUpdateInRealm:realm withValue:session];
    [realm commitWriteTransaction];
}
- (NSString *)loadAppKey{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    return session.appKey;
}
- (void)storeUser:(MOKUserDictionary *)user{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    
    [realm beginWriteTransaction];
    session.user = [self.jsonWriter stringWithObject:user];
    [MOKDBSession createOrUpdateInRealm:realm withValue:session];
    [realm commitWriteTransaction];
}
- (MOKUserDictionary *)loadUser{
    RLMRealm *realm = [self getRealmWithMyConfiguration:self.config];
    MOKDBSession *session = [self checkSession:realm];
    MOKUserDictionary *user = [self.jsonParser objectWithString:session.user];
    return user;
}
@end
