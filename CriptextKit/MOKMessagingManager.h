//
//  Messagingmanager.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKMessage.h"

@protocol MOKMessageReceiver <NSObject>
@required
- (void)messageReceived:(MOKMessage*)message;
@optional
- (void)messageSent:(MOKMessage*)msg;
- (void)groupMessageSent:(MOKMessage*)msg;
- (void)didGroupUpdate;
- (void)userUpdated:(int)userId;
- (void)notificationReceived:(MOKMessage*)notificationMessage;
@end

@interface MOKMessagingManager : NSObject
@property BOOL shouldResendAutomatically;
@property (nonatomic,strong) NSMutableArray *receivers;

+(instancetype)sharedInstance;
-(MOKMessage *)sendMessage:(MOKMessage *)message;
-(MOKMessage *)sendString:(NSString *)plaintext toUser:(NSString *)userId;
-(MOKMessage *)sendFileDataWithPath:(NSURL *)fileURL ofType:(MOKMessageType)moktype toUser:(NSString *)userId;
//-(void)sendTest:(NSString *)plaintext toUser:(NSString *)userId;

- (void)addReceiver:(id <MOKMessageReceiver>)receiver;
- (void)removeReceiver:(id <MOKMessageReceiver>)receiver;
- (void)messageGot:(MOKMessage *)message;
- (void)fileGot:(MOKMessage *)message;
- (void)notify:(MOKMessage *)message withcommand:(int)command;
- (void)sendMessagesAgain;
@end

@interface MOKReceiverKeeper : NSObject <MOKMessageReceiver> {
    id <MOKMessageReceiver> receiver;
}
@property (nonatomic, strong) id <MOKMessageReceiver> receiver;
+ (MOKReceiverKeeper*)keeperWithReceiverAndRetain:(id <MOKMessageReceiver>)receiver;
@end