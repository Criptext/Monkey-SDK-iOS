//
//  MOKDBManager.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 3/24/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKutils.h"
@class MOKMessage;
@class MOKUserDictionary;
@class MOKDBSession;
@interface MOKDBManager : NSObject
+ (MOKDBManager*) sharedInstance;

//ongoing msgs
- (void)storeMessage:(MOKMessage *)msg;
- (BOOL)existMessage:(NSString *)messageId;
- (MOKMessage *)getMessageById:(NSString *)messageId;
- (void)deleteMessageSent:(MOKMessage *)msg;
- (void)deleteMessageSentWithId:(NSString *)messageId;
- (MOKMessage *)getOldestMessageNotSent;

- (void)storeSessionId:(NSString *)sessionId;
- (NSString *)loadSessionId;
- (void)storeAppId:(NSString *)appId;
- (NSString *)loadAppId;
- (void)storeAppKey:(NSString *)appKey;
- (NSString *)loadAppKey;
- (void)storeUser:(MOKUserDictionary *)user;
- (MOKUserDictionary *)loadUser;
@end
