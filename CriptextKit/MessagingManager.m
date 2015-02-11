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
#import "SecurityManager.h"
#import "SessionManager.h"
#import "DBManager.h"

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
    [[SecurityManager sharedInstance]aesEncryptOutgoingMessage:message];

    ComMessage *messCOM=[ComMessageProtocol createMessageFromBlMessageAndReceiver:message];
    [[ComServerConnection sharedInstance] sendMessage:[messCOM json]];
    
    [[DBManager sharedInstance]storeMessage:message];
    
    return message;
}

-(void)sendString:(NSString *)plaintext toUser:(NSString *)userId{
    BLMessage *message = [[BLMessage alloc]initWithMyMessage:plaintext userTo:userId];

    [[SecurityManager sharedInstance]aesEncryptOutgoingMessage:message];

    ComMessage *messCOM=[ComMessageProtocol createMessageFromBlMessageAndReceiver:message];
    [[ComServerConnection sharedInstance] sendMessage:[messCOM json]];
    
    [[DBManager sharedInstance]storeMessage:message];
    
}
- (void)notify:(BLMessage *)message withcommand:(int)command {
    
    //Tipos de menajes: invites, openConversation, isTyping.
    switch (command) {
        case MessageDelivered: case MessageNotView: case MessageNotDelivered:{
            
            NSString *tmp=message.userIdTo;
            message.userIdTo=message.userIdFrom;
            message.userIdFrom=tmp;
            //FIX HORAS ADELANTADAS (ANTES ESTABA DESCOMENTADO)
            //message.timestamp = [[NSDate date] timeIntervalSince1970];
            
//            [[DBManager instance] updateLastMessageSent:message];
//            
//            [self sendMessagesAgain];
            
            break;
        }
        case blMessageFriendRequest:{
            
            
            break;
        }
        case blMessageDeleteFriend:{
            
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
        case blMessageInviteAccepted: case blMessageInviteCanceled:
            
//            [[DBManager instance] removeFromInvites:message.userIdFrom];
            
            break;
            
        case blMessageConversationOpen:
            
            message.timestamp = [[NSDate date] timeIntervalSince1970];
//            [[DBManager instance] markAllMessagesReadOfConversation:message.userIdTo];
            //      [[DBManager instance] markMessageAsRead:message];
            
            break;
            
        case MessageNewContactRegistered:{
            
            //            NSArray *array=[message.messageText componentsSeparatedByString:@":"];
            //            if(array!=nil){
            //                MenuViewController *menuVC=[MenuViewController instance];
            //                InvitationsViewController *invitatiosVC=menuVC.invitationsVC;
            //
            //                BLUserExtended *user=[BLUserExtended defaultUser];
            //                user.userId=[array objectAtIndex:0];
            //                user.firstName=[array objectAtIndex:1];
            //                user.userName=[array objectAtIndex:2];
            //                user.phone=[array objectAtIndex:3];
            //
            //                [invitatiosVC onNewContactRegistered:user];
            //            }
            
        }
        case MessageremoteLogout:{
//            [AppDelegate logout];
//            [AlertsManager alert:NSLocalizedString(@"avisoKey", @"") message:NSLocalizedString(@"avisoNoRedis", @"")];
            break;
        }
        case MessageAlert:{
//            [AlertsManager alert:[UsersManager instance].me.companyName
//                         message:message.messageText];
            break;
        }
        default: {
            
            break;
        }
    }
    
    BLMessageId msgId =message.messageId;
    if(msgId>0)
        [[SessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    
    if(self.receivers!=NULL){
        
        if([message.userIdTo rangeOfString:@","].location!=NSNotFound){
            NSMutableArray *userIds=[[NSMutableArray alloc] initWithArray:[message.userIdTo componentsSeparatedByString:@","]];
            for (NSString *elid in userIds) {
                BLMessage *tmpMessage=message;
                tmpMessage.userIdTo=elid;
                [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:tmpMessage];
            }
        }
        else
            [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:message];
    }
}
- (void)messageGot:(BLMessage *)message {
    BLMessageId msgId =message.messageId;
    [[SecurityManager sharedInstance] aesDecryptIncomingMessage:message];
    
    if(msgId>0){
        [[SessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    }
    
//    if([[DBManager instance] existMessage:msgId])
//        return;
    
    //NSTimeInterval  timestamp = [[NSDate date] timeIntervalSince1970];
    
    @synchronized (self) {
//        messagesUpdateStamp += 1;
        
        //message.timestamp=timestamp; //actualizo el timestamp al acutal de mi telefono
        
        [self.receivers makeObjectsPerformSelector:@selector(messageReceived:) withObject:message];
        
        /*Storing message*/
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            if(message.messageId>0){
                    [[DBManager sharedInstance] storeMessage:message];
            }
            
        });
        
        
    }
}

-(void)displayMessage:(BLMessage *)message{

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
    
    [self.receiver notificationReceived:notificationMessage];
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