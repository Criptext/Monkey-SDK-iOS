//
//  Messagingmanager.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BLMessage;

@protocol MessageReceiver <NSObject>
@required
- (void)messageReceived:(BLMessage*)message;
@optional
- (void)messageSent:(BLMessage*)msg;
- (void)groupMessageSent:(BLMessage*)msg;
- (void)didGroupUpdate;
- (void)userUpdated:(int)userId;
- (void)notificationRecived:(BLMessage*)notificationMessage;
@end

@interface MessagingManager : NSObject
+(instancetype)sharedInstance;
-(BLMessage *)sendMessage:(BLMessage *)message;
-(void)sendString:(NSString *)plaintext toUser:(NSString *)userId;
- (void)addReceiver:(id <MessageReceiver>)receiver;
- (void)removeReceiver:(id <MessageReceiver>)receiver;
@end

@interface ReceiverKeeper : NSObject <MessageReceiver> {
    id <MessageReceiver> __unsafe_unretained receiver;
}
@property (nonatomic, unsafe_unretained) id <MessageReceiver> receiver;
+ (ReceiverKeeper*)keeperWithReceiverAndRetain:(id <MessageReceiver>)receiver;
@end