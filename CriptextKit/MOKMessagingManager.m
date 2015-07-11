//
//  Messagingmanager.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "MOKMessagingManager.h"
#import "MOKAPIConnector.h"
#import "MOKMessage.h"
#import "MOKComMessageProtocol.h"
#import "MOKComServerConnection.h"
#import "MOKSecurityManager.h"
#import "MOKSessionManager.h"
#import "MOKAlertsManager.h"
#import "MOKUser.h"
#import "MOKWatchdog.h"
#import "NSData+Compression.h"
#import "MOKDBManager.h"
#import "MOKSBJSON.h"
#import "NSData+Base64.h"

@interface MOKMessagingManager ()
@property (nonatomic, strong) MOKSBJsonWriter *jsonWriter;
@property (nonatomic, strong) MOKSBJsonParser *jsonParser;
@end

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
        self.jsonWriter = [MOKSBJsonWriter new];
        self.jsonParser = [MOKSBJsonParser new];
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
        NSLog(@"removieng keeper: %@", keeper);
        [self.receivers removeObject:keeper];
        keeper = nil;
    }
}

-(MOKMessage *)sendString:(NSString *)plaintext toUser:(NSString *)sessionId{ 
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:plaintext userTo:sessionId];
    [[MOKSecurityManager sharedInstance]aesEncryptOutgoingMessage:message];
    return [self sendMessage:message];
}

-(MOKMessage *)sendFileWithURL:(NSURL *)fileURL ofType:(MOKFileType)documentType toUser:(NSString *)sessionId andParams:(NSDictionary *)params{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:@"" userTo:sessionId];
    message.protocolCommand = MOKProtocolMessage;
    message.protocolType = MOKFile;

    if (params == nil) {
        NSDictionary *defaultparams = @{@"eph" : @"0",
                                        @"encr" : @"1",
                                        @"str" : @"0",
                                        @"cmpr" : @"gzip",
                                        @"device" : @"ios"
                                        };
        message.mkProperties = [defaultparams mutableCopy];
    }else{
        message.mkProperties = [params mutableCopy];
    }

    [message.mkProperties setObject:[NSNumber numberWithInt:documentType] forKey:@"file_type"];
    
    NSString *tmp = [fileURL path];
    NSMutableString *newFileName = [tmp mutableCopy];
    
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    
    //check if should compress
    if ([message.mkProperties objectForKey:@"cmpr"]) {
        NSLog(@"MONKEY - antes compress: %lu",(unsigned long)[fileData length]);
        fileData = [fileData mok_gzipDeflate];
        NSLog(@"MONKEY - despues compress: %lu",(unsigned long)[fileData length]);
    }
    
    
    [newFileName insertString:@"_mok" atIndex:[newFileName rangeOfString:@"."].location];
    NSLog(@"MONKEY - nombre archivo: %@", newFileName);
    
    [[NSFileManager defaultManager]createFileAtPath:newFileName contents:nil attributes:nil];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:newFileName];
    
    //check if should encrypt
    if([[message.mkProperties objectForKey:@"encr"] intValue]==1){
        NSData *encryptedData = [[MOKSecurityManager sharedInstance]aesEncryptFileData:fileData fromUser:[MOKSessionManager sharedInstance].sessionId];
        [fileHandler writeData:encryptedData];
    }else{
        [fileHandler writeData:fileData];
    }
    
    message.encryptedText = newFileName;
    
    [[MOKWatchdog sharedInstance]mediaInTransit:message];
    [[MOKDBManager sharedInstance]storeMessage:message];
    [[MOKAPIConnector sharedInstance]sendFile:message delegate:self];
    
    return message;
}
-(MOKMessage *)sendFile:(MOKMessage *)message ofType:(MOKFileType)documentType{
    message.protocolType = MOKFile;
    [message.mkProperties setObject:[NSNumber numberWithInt:documentType] forKey:@"file_type"];
    
    NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    documentDirectory = [documentDirectory stringByAppendingPathComponent:message.messageText];
    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:documentDirectory];
    
    if (fileData == nil) {
        [[MOKDBManager sharedInstance]deleteMessageSent:message];
        return nil;
    }
    
    NSLog(@"MONKEY - tamaño data: %lu",(unsigned long)[fileData length]);
    NSMutableString *newFileName = [documentDirectory mutableCopy];
    
    //check if should compress
    if ([message.mkProperties objectForKey:@"cmpr"]) {
        NSLog(@"MONKEY - antes compress: %lu",(unsigned long)[fileData length]);
        fileData = [fileData mok_gzipDeflate];
        NSLog(@"MONKEY - despues compress: %lu",(unsigned long)[fileData length]);
    }
    
    
    [newFileName insertString:@"_mok" atIndex:[newFileName rangeOfString:@"."].location];
    NSLog(@"MONKEY - nombre archivo: %@", newFileName);
    
    [[NSFileManager defaultManager]createFileAtPath:newFileName contents:nil attributes:nil];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:newFileName];
    
    //check if should encrypt
    if([[message.mkProperties objectForKey:@"encr"] intValue]==1){
        NSData *encryptedData = [[MOKSecurityManager sharedInstance]aesEncryptFileData:fileData fromUser:[MOKSessionManager sharedInstance].sessionId];
        [fileHandler writeData:encryptedData];
    }else{
        [fileHandler writeData:fileData];
    }
    
    message.encryptedText = newFileName;
    
    [[MOKWatchdog sharedInstance]mediaInTransit:message];
    [[MOKDBManager sharedInstance]storeMessage:message];
    [[MOKAPIConnector sharedInstance]sendFile:message delegate:self];
    
    return message;

}
-(MOKMessage *)sendMessage:(MOKMessage *)message{
    
    //check if should encrypt
    if ([[message.mkProperties objectForKey:@"encr"] intValue]==1) {
        [[MOKSecurityManager sharedInstance]aesEncryptOutgoingMessage:message];
    }
    
    message.protocolCommand = MOKProtocolMessage;
    message.isSending = true;
    message.needsResend = false;
    
    [[MOKWatchdog sharedInstance]messageInTransit:message];
    [[MOKDBManager sharedInstance]storeMessage:message];
    
    [self sendMessageCommandFromMessage:message];
    
    return message;
}

-(MOKMessage *)sendNotificationToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:@"" userTo:sessionId];
    message.protocolCommand = MOKProtocolMessage;
    message.protocolType = MOKNotif;
    message.pushMessage = push;
    message.params = [params mutableCopy];
    [self sendMessageCommandFromMessage:message];
    
    return message;
}

-(MOKMessage *)sendTemporalNotificationToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:@"" userTo:sessionId];
    message.protocolCommand = MOKProtocolMessage;
    message.protocolType = MOKTempNote;
    message.pushMessage = push;
    message.params = [params mutableCopy];
    [self sendMessageCommandFromMessage:message];
    
    return message;
}

-(MOKMessage *)sendAlertToUser:(NSString *)sessionId withParams:(NSDictionary *)params{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:@"" userTo:sessionId];
    message.protocolCommand = MOKProtocolMessage;
    message.protocolType = MOKAlert;
    message.params = [params mutableCopy];
    [self sendMessageCommandFromMessage:message];
    
    return message;
}

-(void)strip201fromMessage:(MOKMessage *)message{
    if ([message.userIdTo rangeOfString:@":"].location != NSNotFound  && [message.userIdTo rangeOfString:@"G"].location==NSNotFound) {
        message.userIdTo=[[message.userIdTo componentsSeparatedByString:@":"] objectAtIndex:1];
    }
}

- (void)sendCommand:(MOKProtocolCommand)protocolCommand WithArgs:(NSDictionary *)args{
    NSDictionary *messCom = @{@"cmd":[NSNumber numberWithInt:protocolCommand],
                              @"args": args};
    
    [[MOKComServerConnection sharedInstance] sendMessage:[self.jsonWriter stringWithObject:messCom]];
}
-(void)sendCloseCommandToUser:(NSString *)sessionId{
    [self sendCommand:MOKProtocolClose WithArgs:@{@"rid": sessionId}];
}
-(void)sendDeleteCommandForMessage:(MOKMessageId)messageId ToUser:(NSString *)sessionId{
    
    
    [self sendCommand:MOKProtocolDelete WithArgs:@{@"id": [NSNumber numberWithLongLong:messageId],
                                                   @"rid":sessionId}];
}
- (void)notify:(MOKMessage *)message withcommand:(int)command {
    
    //Tipos de menajes: invites, openConversation, isTyping.
    switch (command) {
        case MOKProtocolMessage:
            [[MOKDBManager sharedInstance]deleteMessageSent:message];
            [self sendMessagesAgain];
            break;
        case MOKProtocolGet:
            [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:message];
            return;
            break;
        default: {
            
            break;
        }
    }
    
    MOKMessageId msgId =message.messageId;
    if(msgId>0)
        [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    
    
    if(self.receivers!=NULL){
        
        if([message.userIdTo rangeOfString:@","].location!=NSNotFound){
            message.userIdTo = [MOKSessionManager sharedInstance].sessionId;
        }
        
        [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:message];
    }
}
- (void)incomingMessage:(MOKMessage *)message {
    MOKMessageId msgId =message.messageId;
    
    //check if encrypted
    if ([[message.mkProperties objectForKey:@"encr"] intValue] ==1) {
        @try {
        [[MOKSecurityManager sharedInstance] aesDecryptIncomingMessage:message];
        }
        @catch (NSException *exception) {
            NSLog(@"MONKEY - couldn't decrypt with current key, retrieving new keys");
            [[MOKAPIConnector sharedInstance]keyExchangeWith:message.userIdFrom delegate:self];
            [self performSelector:@selector(incomingMessage:) withObject:message afterDelay:2];
            return;
        }
        
        if (message.messageText == nil) {
            NSLog(@"MONKEY - couldn't decrypt with current key, retrieving new keys");
            [[MOKAPIConnector sharedInstance]keyExchangeWith:message.userIdFrom delegate:self];
            [self performSelector:@selector(incomingMessage:) withObject:message afterDelay:2];
            return;
        }
    }else{
        message.messageText = message.encryptedText;
    }
    
    
    if(msgId>0){
        [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    }
    
//    if([[DBManager sharedInstance] existMessage:msgId])
//        return;
    
    
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

- (void)fileReceivedNotification:(MOKMessage *)message {
    MOKMessageId msgId =message.messageId;
    
    if(msgId>0){
        [[MOKSessionManager sharedInstance] setLastMessageId:[NSString stringWithFormat:@"%lli",msgId]];
    }

    [[MOKAPIConnector sharedInstance]downloadFile:message withDelegate:self];
    
}
-(void)acknowledgeNotification:(MOKMessage *)message{
    
    switch (message.protocolType) {
        case MOKText: case MOKFile: case 50: case 51: case 52:
            [[MOKDBManager sharedInstance]deleteMessageSent:message];
            break;
        default: {
            
            break;
        }
    }
    
    @synchronized (self) {
        [self.receivers makeObjectsPerformSelector:@selector(acknowledgeReceived:) withObject:message];
    }
}
-(void)onDownloadFileOK:(MOKMessage *)message{
    @autoreleasepool {
        //check if should decrypt
        if([[message.mkProperties objectForKey:@"encr"] intValue] ==1){
            NSData *decryptedData;
            //check if web
            if ([[message.mkProperties objectForKey:@"device"] isEqualToString:@"web"]) {
                NSLog(@"MONKEY - decriptando archivo de web");
                
                NSString *contenido = [NSString stringWithContentsOfFile:message.messageText encoding:NSUTF8StringEncoding error:nil];
                
                
                @try {
                    decryptedData = [[MOKSecurityManager sharedInstance]aesDecryptFileData:[NSData mok_dataFromBase64String:contenido] fromUser:message.userIdFrom];
                }
                @catch (NSException *exception) {
                    [self requestNewKeysForMessage:message];
                    return;
                }
                
                if (decryptedData == nil) {
                    [self requestNewKeysForMessage:message];
                    return;
                }
                [decryptedData writeToFile:message.messageText atomically:YES];
                
                NSString *newcontenido = [NSString stringWithContentsOfFile:message.messageText encoding:NSUTF8StringEncoding error:nil];
                newcontenido = [newcontenido substringFromIndex:[newcontenido rangeOfString:@","].location+1];
                
                NSData *newData = [NSData mok_dataFromBase64String:newcontenido];
                
                
                //check for extension (and replace)
                if ([message.mkProperties objectForKey:@"ext"] != nil) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [fileManager removeItemAtPath:message.messageText error:NULL];
                    message.messageText = [[message.messageText stringByDeletingPathExtension] stringByAppendingPathExtension:[message.mkProperties objectForKey:@"ext"]];
                }

                //check for file compression
                if ([message.mkProperties objectForKey:@"cmpr"]) {
                    newData = [newData mok_gzipInflate];
                }
                
                [newData writeToFile:message.messageText atomically:YES];
                
            }else{
                NSLog(@"MONKEY - decriptando archivo de movil");
            
                @try {
                    decryptedData = [[MOKSecurityManager sharedInstance]aesDecryptFileData:[NSData dataWithContentsOfFile:message.messageText] fromUser:message.userIdFrom];
                }
                @catch (NSException *exception) {
                    [self requestNewKeysForMessage:message];
                    return;
                }
                
                if (decryptedData == nil) {
                    [self requestNewKeysForMessage:message];
                    return;
                }
                //check for file compression
                if ([message.mkProperties objectForKey:@"cmpr"]) {
                    decryptedData = [decryptedData mok_gzipInflate];
                }
                
                [decryptedData writeToFile:message.messageText atomically:YES];
            }
        }
    }
    
    message.messageText = [message.messageText lastPathComponent];
    @synchronized (self) {
        [self.receivers makeObjectsPerformSelector:@selector(messageReceived:) withObject:message];
        
    }
}
- (void)requestNewKeysForMessage:(MOKMessage *)message{
    NSLog(@"MONKEY - couldn't decrypt with current key, retrieving new keys");
    [[MOKAPIConnector sharedInstance]keyExchangeWith:message.userIdFrom delegate:self];
    [self performSelector:@selector(onDownloadFileOK:) withObject:message afterDelay:2];
}
-(void)onOpenConversationOK:(NSString *)key{
    
}
-(void)onOpenConversationWrong{
    
}
-(void)onDownloadFileFail:(MOKMessage *)message{
    NSLog(@"MONKEY - MONKEY - Download Fail");
}
-(void)onUploadFileOK:(MOKMessage *)message{
    [[MOKDBManager sharedInstance] deleteMessageSent:message];
    [[MOKWatchdog sharedInstance] removeMediaInTransitWithId:[NSString stringWithFormat:@"%lld", message.oldMessageId]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:message.encryptedText error:NULL];
    if (self.receivers != NULL) {
        [self.receivers makeObjectsPerformSelector:@selector(acknowledgeReceived:) withObject:message];
    }
}
-(void)onUploadFileFail:(MOKMessage *)message{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:message.encryptedText error:NULL];
    NSLog(@"MONKEY - MONKEY - Upload Fail");
}
- (void)sendMessagesAgain {
    if (!self.shouldResendAutomatically) {
        return;
    }
//    NSArray *allMessages=[[DBManager sharedInstance] getMessagesNotSent];
//    // allMessages = [allMessages arrayByAddingObjectsFromArray:[messagesWithAttach allValues]];
    MOKMessage *message= [[MOKDBManager sharedInstance] getOldestMessageNotSent];
    
    if (message == nil) {
        return;
    }
    message.isSending = YES;
    message.timestampCreated = [[NSDate date] timeIntervalSince1970];
    message.timestampOrder = message.timestampCreated;
    
    switch (message.protocolType) {
        case MOKText:
            [self sendMessage:message];
            break;
        case MOKFile:
            NSLog(@"MONKEY - MONKEY - file type resend: %@",[message.mkProperties objectForKey:@"file_type"]);
            [self sendFile:message ofType:[[message.mkProperties objectForKey:@"file_type"] intValue]];
//            [self sendFileWithURL:[NSURL fileURLWithPath:message.encryptedText] ofType:(MOKFileType)[message.params objectForKey:@"file_type"] toUser:message.userIdTo andParams:message.params];
            break;
            
        default:
            break;
    }
    
}
-(void)sendGetCommandWithArgs:(NSDictionary *)args{
    [self sendCommand:MOKProtocolGet WithArgs:args];
}
-(void)sendOpenCommandToUser:(NSString *)sessionId{

    [self sendCommand:MOKProtocolOpen WithArgs:@{@"rid" : sessionId}];

}
-(void)sendSetCommandWithArgs:(NSDictionary *)args{

    [self sendCommand:MOKProtocolSet WithArgs:args];
}
- (void) sendMessageCommandFromMessage:(MOKMessage *)message{
    
    NSDictionary *args;
    
    if ([message.pushMessage isEqualToString:@""] || message.pushMessage == nil) {
        args = @{@"id": [NSString stringWithFormat:@"%lli",message.messageId],
                 @"sid": message.userIdFrom,
                 @"rid": message.userIdTo,
                 @"msg": message.encryptedText,
                 @"type": [NSNumber numberWithInt:message.protocolType],
                 @"props": [self.jsonWriter stringWithObject:message.mkProperties],
                 @"params": [self.jsonWriter stringWithObject:message.params]
                 };
    }else{
        args = @{@"id": [NSString stringWithFormat:@"%lli",message.messageId],
                 @"sid": message.userIdFrom,
                 @"rid": message.userIdTo,
                 @"msg": message.encryptedText,
                 @"type": [NSNumber numberWithInt:message.protocolType],
                 @"props": [self.jsonWriter stringWithObject:message.mkProperties],
                 @"params": [self.jsonWriter stringWithObject:message.params],
                 @"push": message.pushMessage? message.pushMessage : @""
                   };
    }
    
    [self sendCommand:message.protocolCommand WithArgs:args];
}

- (void)notifyUpdatesToWatchdog{
    [[MOKWatchdog sharedInstance] updateFinished];
}
- (void)logout {
        [self.receivers removeAllObjects];
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

- (void)acknowledgeReceived:(MOKMessage *)ackMessage{
    
    [self.receiver acknowledgeReceived:ackMessage];
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
        NSLog(@"MONKEY - Exception de recivers isEqual: %@", exception);
        return false;
    }
}

- (void)didUpdate {
}



@end