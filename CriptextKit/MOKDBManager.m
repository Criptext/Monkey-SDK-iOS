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
#import <Realm/Realm.h>

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
        [RLMRealm setEncryptionKey:[self getKey] forRealmsAtPath:[self getCustomRealm]];
    }
    return self;
}

- (NSString *)getCustomRealm{
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"private_MOKdb"];
    NSString *customRealmPath = [documentsDirectory stringByAppendingString:@".realm"];
    return customRealmPath;
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
              (__bridge id)kSecValueData: keyData};
    
    status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    NSAssert(status == errSecSuccess, @"Failed to insert new key in the keychain");
    
    return keyData;
}
#pragma mark - Messages
- (void)storeMessage:(MOKMessage *)msg{
    
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
    
    
    [MOKDBMessage createOrUpdateInRealm:realm withObject:object];
    [realm commitWriteTransaction];
}
- (BOOL)existMessage:(MOKMessageId)messageId{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    return [MOKDBMessage objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:messageId]] != nil;
}
- (MOKMessage *)getMessageById:(MOKMessageId )messageId{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    MOKDBMessage *msg = [MOKDBMessage objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:messageId]];
    
    if (msg !=nil) {
        MOKMessage *mensaje = [[MOKMessage alloc]init];
        mensaje.messageText = msg.messageText;
        mensaje.type = msg.type;
        mensaje.timestamp = msg.timestamp;
        mensaje.messageId = msg.messageId;
        mensaje.userIdFrom = msg.userIdFrom;
        mensaje.userIdTo = msg.userIdTo;
        mensaje.readByUser = msg.readByUser;
        mensaje.oldMessageId = msg.oldmessageId;
        mensaje.param = msg.param;
        return mensaje;
    }else{
        return nil;
    }
}
- (void)deleteMessageSent:(MOKMessage *)msg{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    MOKDBMessage *mensaje = [MOKDBMessage objectInRealm:realm forPrimaryKey:[NSNumber numberWithLongLong:msg.oldMessageId]];
    if (!mensaje) {
        return;
    }
    [realm beginWriteTransaction];
    
    [realm deleteObject:mensaje];
    
    [realm commitWriteTransaction];
    
}
- (MOKMessage *)getOldestMessageNotSent{
    RLMRealm *realm = [RLMRealm realmWithPath:[self getCustomRealm]];
    for (MOKDBMessage *msg in [MOKDBMessage allObjectsInRealm:realm]) {
        if (msg.messageId<0 && msg.type != MOKMessageAudioAttachNew && msg.type != MOKMessagePhotoAttachNew && msg.type != MOKMessageAudioAttach && msg.type != MOKMessagePhotoAttach) {
            MOKMessage *message = [[MOKMessage alloc]init];
            message.messageId = msg.messageId;
            message.userIdTo = msg.userIdTo;
            message.userIdFrom = msg.userIdFrom;
            message.type = msg.type;
            message.timestamp = msg.timestamp;
            message.messageText = msg.messageText;
            message.readByUser = msg.readByUser;
            message.param = msg.param;
            message.oldMessageId = msg.oldmessageId;
            return message;
        }
    }
    return nil;
}
@end
