//
//  Messagingmanager.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "MOKMessagingManager.h"
#import "MOKMessage.h"
#import "MOKComMessageProtocol.h"
#import "MOKComServerConnection.h"
#import "MOKSecurityManager.h"
#import "MOKSessionManager.h"
#import "MOKAlertsManager.h"
#import "MOKUser.h"
#import "MOKWatchdog.h"
#import "NSData+Compression.h"
#import "MOKAPIConnector.h"
#import "MOKDBManager.h"

@implementation MOKMessagingManager

+ (instancetype)sharedInstance
{
    static MOKMessagingManager *sharedInstance;
    
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
        _shouldResendAutomatically = true;
    }
    return self;
}

- (void)addReceiver:(id <MOKMessageReceiver>)receiver {
    @synchronized (self) {
        MOKReceiverKeeper *keeper = [MOKReceiverKeeper keeperWithReceiverAndRetain:receiver];
        if (![self.receivers containsObject:keeper]) {
            [self.receivers addObject:keeper];
        }
    }
}

- (void)removeReceiver:(id <MOKMessageReceiver>)receiver {
    @synchronized (self) {
        MOKReceiverKeeper *keeper = [MOKReceiverKeeper keeperWithReceiverAndRetain:receiver];
        [self.receivers removeObject:keeper];
        keeper = nil;
    }
}

-(MOKMessage *)sendString:(NSString *)plaintext toUser:(NSString *)userId{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:plaintext userTo:userId];
    [[MOKSecurityManager sharedInstance]aesEncryptOutgoingMessage:message];
    return [self sendMessage:message];
}

-(MOKMessage *)sendFileDataWithPath:(NSURL *)fileURL ofType:(MOKMessageType)moktype toUser:(NSString *)userId{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:@"" userTo:userId];
    message.type = moktype;
    NSString *tmp = [fileURL path];
    NSMutableString *newFileName = [tmp mutableCopy];
    NSData *rawData = [NSData dataWithContentsOfURL:fileURL];
    NSLog(@"antes compress: %lu",(unsigned long)[rawData length]);
    NSData *compressedData = [rawData mok_gzipDeflate];
    NSLog(@"despues compress: %lu",(unsigned long)[compressedData length]);
    NSData *encryptedData = [[MOKSecurityManager sharedInstance]aesEncryptFileData:compressedData fromUser:[MOKSessionManager sharedInstance].userId];
    [newFileName insertString:@"cdtest" atIndex:[newFileName rangeOfString:@".3gp"].location];
    NSLog(@"nombre archivo: %@", newFileName);
    [[NSFileManager defaultManager]createFileAtPath:newFileName contents:nil attributes:nil];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:newFileName];
    [fileHandler writeData:encryptedData];
    
    NSURL *newFileURL = [NSURL fileURLWithPath:newFileName];
    
    [[MOKAPIConnector sharedInstance]sendFileWithPath:newFileURL toUser:userId messageId:message.messageId ephemeral:@"0" andType:@"audio" delegate:nil];

    
    return message;
//    return [self sendMessage:message];
}

-(MOKMessage *)sendMessage:(MOKMessage *)message{
    message.isSending = true;
    message.needsResend = false;
    
    [self sendMessageWithComServerFromBlMessage:message];
    
    if([message.userIdTo rangeOfString:@","].location==NSNotFound){//for one-to-one
        [self strip201fromMessage:message];

    }
    else{//for groups
        NSMutableArray *userIds=[[NSMutableArray alloc] initWithArray:[message.userIdTo componentsSeparatedByString:@","]];
        for (NSString *elid in userIds) {
            MOKMessage *tmpMessage=[[MOKMessage alloc] initWithMyMessage:message.messageText userTo:elid];
            tmpMessage.messageId=message.messageId;
            tmpMessage.timestamp=message.timestamp;
            tmpMessage.oldMessageId=message.oldMessageId;
            tmpMessage.userIdTo=elid;
            
            [self strip201fromMessage:message];
            
            //TODO: msg add to conversation
//            [[MenuViewController instance].conversationsVC addLastMessageToConversation:tmpMessage];
        }
    
    }
    return message;
}

//-(void)sendTest:(NSString *)plaintext toUser:(NSString *)userId{
//    BLMessage *message = [[BLMessage alloc]initWithMyMessage:plaintext userTo:userId];
//    message.isSending = true;
//    message.needsResend = false;
//    message.messageId = [[NSDate date] timeIntervalSince1970]* -1;
//    message.timestamp = [[NSDate date] timeIntervalSince1970];
//    [self sendMessageWithComServerFromBlMessage:message];
//}

-(void)strip201fromMessage:(MOKMessage *)message{
    if ([message.userIdTo rangeOfString:@":"].location != NSNotFound  && [message.userIdTo rangeOfString:@"G"].location==NSNotFound) {
        message.userIdTo=[[message.userIdTo componentsSeparatedByString:@":"] objectAtIndex:1];
    }
}

- (void)notify:(MOKMessage *)message withcommand:(int)command {
    
    //Tipos de menajes: invites, openConversation, isTyping.
    switch (command) {
        case MOKMessageDelivered: case MOKMessageNotView: case MOKMessageNotDelivered:{
            
            NSString *tmp=message.userIdTo;
            message.userIdTo=message.userIdFrom;
            message.userIdFrom=tmp;
            
            [self sendMessagesAgain];
            
            break;
        }
        case MOKMessageFriendRequest:{
            
            
            break;
        }
        case MOKMessageDeleteFriend:{
            
            //NSString *userIdWithout=[[message.userIdFrom componentsSeparatedByString:@":"] objectAtIndex:1];
            
            //Borro la conversacion si existe en Conversations
//            MenuViewController *menuVC=[MenuViewController instance];
//            ConversationsViewController *conversationsVC=menuVC.conversationsVC;
//            [conversationsVC deleteConversationFromFriendView:message.userIdFrom];
            
            
            //Lo borro de la lista de amigos del view
//            FriendsViewController *friendsVC=menuVC.friendsVC;
//            [friendsVC deleteFriendFromOtherView:message.userIdFrom];
            
            
            //eliminar de la base de datos al amigo
//            [[DBManager instance] deleteUser:message.userIdFrom];
            
            //Para que me vuelva a aparecer como AddressBook friend
            //            InvitationsViewController *inviteVC=menuVC.invitationsVC;
            //            [inviteVC reloadContactsAndCompareWithFriends];
            
            break;
        }
        case MOKMessageInviteAccepted: case MOKMessageInviteCanceled:
            
//            [[DBManager instance] removeFromInvites:message.userIdFrom];
            
            break;
            
        case MOKMessageConversationOpen:
            
            message.timestamp = [[NSDate date] timeIntervalSince1970];
//            [[DBManager instance] markAllMessagesReadOfConversation:message.userIdTo];
            //      [[DBManager instance] markMessageAsRead:message];
            
            break;
            
        case MOKMessageNewContactRegistered:{
            
        }
        case MOKMessageremoteLogout:{
//            [AppDelegate logout];
//            [AlertsManager alert:NSLocalizedString(@"avisoKey", @"") message:NSLocalizedString(@"rem", @"")];
            break;
        }
        case MOKMessageAlert:{

            break;
        }
        default: {
            
            break;
        }
    }
    
    MOKMessageId msgId =message.messageId;
    if(msgId>0)
        [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    
    if(self.receivers!=NULL){
        
        if([message.userIdTo rangeOfString:@","].location!=NSNotFound){
            NSMutableArray *userIds=[[NSMutableArray alloc] initWithArray:[message.userIdTo componentsSeparatedByString:@","]];
            for (NSString *elid in userIds) {
                MOKMessage *tmpMessage=message;
                tmpMessage.userIdTo=elid;
                [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:tmpMessage];
            }
        }
        else
            [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:message];
    }
}
- (void)messageGot:(MOKMessage *)message {
    MOKMessageId msgId =message.messageId;
    [[MOKSecurityManager sharedInstance] aesDecryptIncomingMessage:message];
    
    if(msgId>0){
        [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    }
    
//    if([[DBManager sharedInstance] existMessage:msgId])
//        return;
    
    [[MOKDBManager sharedInstance]deleteMessageSent:message];
    @synchronized (self) {
        
        [self.receivers makeObjectsPerformSelector:@selector(messageReceived:) withObject:message];
        
        /*Storing message*/
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
//            if(message.messageId>0){
//                    [[DBManager sharedInstance] storeMessage:message];
//            }
            
//        });
        
        
    }
}
- (void)fileGot:(MOKMessage *)message {
    MOKMessageId msgId =message.messageId;
    //    [[SecurityManager sharedInstance] aesDecryptIncomingMessage:message];
    
    if(msgId>0){
        [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    }
    
    //    if([[DBManager sharedInstance] existMessage:msgId])
    //        return;
    
    @synchronized (self) {
        
        [self.receivers makeObjectsPerformSelector:@selector(messageReceived:) withObject:message];
        
        /*Storing message*/
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            //            if(message.messageId>0){
            //                    [[DBManager sharedInstance] storeMessage:message];
            //            }
            
        });
        
        
    }
}
- (void)sendMessagesAgain {
    if (!self.shouldResendAutomatically) {
        return;
    }
//    NSArray *allMessages=[[DBManager sharedInstance] getMessagesNotSent];
//    // allMessages = [allMessages arrayByAddingObjectsFromArray:[messagesWithAttach allValues]];
    MOKMessage *message= [[MOKDBManager sharedInstance] getOldestMessageNotSent];
    
    message.isSending = YES;
    message.timestamp = [[NSDate date] timeIntervalSince1970];
    
    [self sendMessage:message];
////    NSLog(@"messages not sent are %lu",(unsigned long)[allMessages count]);
//    
//    //for(BLMessage *message in allMessages){
//    if([allMessages count]>0){
//        BLMessage *message=[allMessages objectAtIndex:0];
//        //int typeResend=message.type;
//        
//        message.isSending = YES;
//        message.timestamp = [[NSDate date] timeIntervalSince1970];
//        //message.type = blMessageResend;
//        if(![message isGroupMessage] && ![message isBroadcastMessage])
//            message.userIdTo=[NSString stringWithFormat:@"201:%@",message.userIdTo];
//        
//        //NSLog(@"message type %i and text %@ and userrid %@ ",message.type,message.messageText,message.userIdTo);
//        
//        @synchronized (self.messagesToSend) {
//            [self sendMessageWithComServerFromBlMessage:message];
//        }
//        
//    }
    
}
- (void) sendMessageWithComServerFromBlMessage:(MOKMessage *)message{
    MOKComMessage *messCOM=[MOKComMessageProtocol createMessageFromBlMessageAndReceiver:message];
    [[MOKComServerConnection sharedInstance] sendMessage:[messCOM json]];
    [[MOKWatchdog sharedInstance]messageInTransit:message];
}
- (void)notifyUpdatesToWatchdog{
    [[MOKWatchdog sharedInstance] updateFinished];
}
- (void)logout {
//    [connector cancelAllRequests];
//    self.attachMessage = nil;
//    [self.messagesToSend removeAllObjects];
//    [self.receivers removeAllObjects];

//    [unreadMessages removeAllObjects];
//    [conversations removeAllObjects];
//    [messagesWithAttachToCheck removeAllObjects];
//    conversationsUpdateStamp = 0;
//    messagesUpdateStamp = 0;
//    
//    messagingManagerInstance=nil;
    
    //dispatch_release(backgroundQueue);
}
@end


@implementation MOKReceiverKeeper
@synthesize receiver;

+ (MOKReceiverKeeper*)keeperWithReceiverAndRetain:(id <MOKMessageReceiver>)receiver {
    MOKReceiverKeeper *keeper = [[MOKReceiverKeeper alloc] init];
    keeper.receiver = receiver;
    return keeper;
}

- (void)messageSent:(MOKMessage*)msg {
    if ([self.receiver respondsToSelector:@selector(messageSent:)]) {
        [self.receiver messageSent:msg];
    }
}

- (void)userUpdated:(MOKUserId)userId {
    [self.receiver userUpdated:userId];
}

- (void)messageReceived:(MOKMessage*)message {
    
    [self.receiver messageReceived:message];
}

- (void)notificationReceived:(MOKMessage*)notificationMessage{
    
    [self.receiver notificationReceived:notificationMessage];
}

- (void)didGroupUpdate {
    [self.receiver didGroupUpdate];
}

- (void)groupMessageSent:(MOKMessage *)msg {
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