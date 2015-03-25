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
@interface MOKDBManager : NSObject
+ (MOKDBManager*) sharedInstance;
- (void)storeMessage:(MOKMessage *)msg;
- (BOOL)existMessage:(MOKMessageId)messageId;
- (MOKMessage *)getMessageById:(MOKMessageId )messageId;
- (void)deleteMessageSent:(MOKMessage *)msg;
- (MOKMessage *)getOldestMessageNotSent;
@end
