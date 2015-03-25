//
//  UserDefaultsController.h
//  Blip
//
//  Created by G V on 25.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	udKeySessionId = 0,
    udKeyUserName = 1,
    udKeyUserPassword = 2,
    udKeyUserId = 3,
	udKeyDeviceToken = 5,
    udKeyLastMessageId = 4,
    udKeyPassCode = 6
} UDKey;

@interface MOKUserDefaultsManager : NSObject {
	NSDictionary *keys;
}

+ (MOKUserDefaultsManager*)instance;

- (void)storeObject:(id)object forKey:(UDKey)key;
- (NSString*)stringForKey:(UDKey)key;
- (id)objectForKey:(UDKey)key;
- (void)storeInt:(int)object forKey:(UDKey)key;
- (int)intForKey:(UDKey)key;


- (NSString*)loadPassCode;
- (NSString*)loadSessionKey;
- (NSString *)loadUserId;
- (NSString *)loadUserName;
- (NSString *)loadUserPassword;
- (NSString*)loadDeviceToken;
- (NSString *)loadLastMessageId;

- (void)storePassCode:(NSString*)passcode;
- (void)storeSessionKey:(NSString*)sessionKey;
- (void)storeUserId:(NSString*)name;
- (void)storeUserName:(NSString*)name;
- (void)storeUserPassword:(NSString*)name;
- (void)storeDeviceToken:(NSString*)name;
- (void)storeLastMessageId:(NSString*)lastMessageId;

- (void)storeObjectFree:(id)object forKey:(NSString *)keyString;
- (id)objectForKeyFree:(NSString *)keyString;
- (void)removeObjectFreeforKey:(NSString *)keyString;
- (void)updateObjectFree:(id)object forKey:(NSString *)keyString;

-(void)cleanAll;

@end
