//
//  Messagingmanager.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "MessagingManager.h"
#import "BLMessage.h"
#import "ComMessageProtocol.h"
#import "ComServerConnection.h"

@interface MessagingManager ()
@property (nonatomic,strong) NSMutableArray *receivers;
@end

@implementation MessagingManager

+ (instancetype)sharedInstance
{
    static MessagingManager *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initPrivate];
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MessagingManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        //initialize property
        _receivers = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)addReceiver:(id <MessageReceiver>)receiver {
    @synchronized (self) {
        ReceiverKeeper *keeper = [ReceiverKeeper keeperWithReceiverAndRetain:receiver];
        if (![self.receivers containsObject:keeper]) {
            [self.receivers addObject:keeper];
        }
    }
}

- (void)removeReceiver:(id <MessageReceiver>)receiver {
    @synchronized (self) {
        ReceiverKeeper *keeper = [ReceiverKeeper keeperWithReceiverAndRetain:receiver];
        [self.receivers removeObject:keeper];
    }
}

-(BLMessage *)sendMessage:(BLMessage *)message{
    ComMessage *messCOM=[ComMessageProtocol createMessageFromBlMessageAndReceiver:message];
    [[ComServerConnection sharedInstance] sendMessage:[messCOM json]];
    return message;
}

-(void)sendString:(NSString *)plaintext toUser:(NSString *)userId{
    BLMessage *message = [[BLMessage alloc]initWithMyMessage:plaintext userTo:userId];
    ComMessage *messCOM=[ComMessageProtocol createMessageFromBlMessageAndReceiver:message];
    [[ComServerConnection sharedInstance] sendMessage:[messCOM json]];
}

@end


@implementation ReceiverKeeper
@synthesize receiver;

+ (ReceiverKeeper*)keeperWithReceiverAndRetain:(id <MessageReceiver>)receiver {
    ReceiverKeeper *keeper = [[ReceiverKeeper alloc] init];
    keeper.receiver = receiver;
    return keeper;
}

- (void)messageSent:(BLMessage*)msg {
    if ([self.receiver respondsToSelector:@selector(messageSent:)]) {
        [self.receiver messageSent:msg];
    }
}

- (void)userUpdated:(BLUserId)userId {
    [self.receiver userUpdated:userId];
}

- (void)messageReceived:(BLMessage*)message {
    
    [self.receiver messageReceived:message];
}

- (void)notificationReceived:(BLMessage*)notificationMessage{
    
    [self.receiver notificationRecived:notificationMessage];
}

- (void)didGroupUpdate {
    [self.receiver didGroupUpdate];
}

- (void)groupMessageSent:(BLMessage *)msg {
    [self.receiver groupMessageSent:msg];
}

- (BOOL)isEqual:(id)object {
    
    @try{
        BOOL isEqual = [object receiver] == self.receiver;
        return isEqual;
    }
    @catch(NSException *exception){
        NSLog(@"Exception de recivers isEqual: %@", exception);
        return false;
    }
}

- (void)didUpdate {
    
    
}

@end