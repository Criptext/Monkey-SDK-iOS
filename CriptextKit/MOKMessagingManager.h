//
//  Messagingmanager.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKMessage.h"
#import "MOKAPIConnector.h"

@protocol MOKMessageReceiver <NSObject>
@required
- (void)messageReceived:(MOKMessage*)message;
@optional
- (void)messageSent:(MOKMessage*)msg;
- (void)groupMessageSent:(MOKMessage*)msg;
- (void)didGroupUpdate;
- (void)userUpdated:(int)userId;
- (void)notificationReceived:(MOKMessage *)notificationMessage;
- (void)acknowledgeReceived:(MOKMessage *)ackMessage;
@end

@interface MOKMessagingManager : NSObject <MOKAPIConnectorDelegate>
@property BOOL shouldResendAutomatically;
@property (nonatomic,strong) NSMutableArray *receivers;

+(instancetype)sharedInstance;

//200
//type: 1
-(MOKMessage *)sendMessage:(MOKMessage *)message;
-(MOKMessage *)sendString:(NSString *)plaintext toUser:(NSString *)sessionId;
//type: 2
-(MOKMessage *)sendFile:(MOKMessage *)message ofType:(MOKFileType)documentType;
-(MOKMessage *)sendFileWithURL:(NSURL *)fileURL ofType:(MOKFileType)documentType toUser:(NSString *)sessionId andParams:(NSDictionary *)params;
//type: 3
-(MOKMessage *)sendNotificationToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push;
//type: 4
-(MOKMessage *)sendTemporalNotificationToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push;
//type: 5
-(MOKMessage *)sendAlertToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push;

//201
-(void)sendGetCommandWithArgs:(NSDictionary *)args;

//203
-(void)sendOpenCommandToUser:(NSString *)sessionId;

//204
-(void)sendSetCommandWithArgs:(NSDictionary *)args;

//201 and 204
-(void)sendCommand:(MOKProtocolCommand)protocolCommand WithArgs:(NSDictionary *)args;

//207
-(void)sendDeleteCommandForMessage:(NSString *)messageId ToUser:(NSString *)sessionId;

//208
-(void)sendCloseCommandToUser:(NSString *)sessionId;

-(void)sendOneMessageAgain:(NSString *)messageId;

-(void)sendAttachComplete:(NSDictionary *)param msgId:(MOKMessage *)msg toids:(NSString *)ids;
-(void)forceNotificationRecived:(MOKMessage *)message;

- (void)addReceiver:(id <MOKMessageReceiver>)receiver;
- (void)removeReceiver:(id <MOKMessageReceiver>)receiver;

- (void)incomingMessage:(MOKMessage *)message;
- (void)fileReceivedNotification:(MOKMessage *)message;
- (void)acknowledgeNotification:(MOKMessage *)message;
- (void)notify:(MOKMessage *)message withcommand:(int)command;
- (void)logout;
- (void)notifyUpdatesToWatchdog;

- (void)sendMessagesAgain;
@end

@interface MOKReceiverKeeper : NSObject <MOKMessageReceiver> {
    id <MOKMessageReceiver> receiver;
}
@property (nonatomic, strong) id <MOKMessageReceiver> receiver;
+ (MOKReceiverKeeper*)keeperWithReceiverAndRetain:(id <MOKMessageReceiver>)receiver;
@end