//
//  Monkey.m
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/1/16.
//  Copyright © 2016 Criptext. All rights reserved.
//

#import "Monkey.h"
#import "MOKAPIConnector.h"
#import "MOKSecurityManager.h"
#import "MOKComServerConnection.h"
#import "MOKSBJSON.h"

////////

#import "MOKAPIConnector.h"
#import "MOKMessage.h"
#import "MOKComServerConnection.h"
#import "MOKSecurityManager.h"
#import "MOKSessionManager.h"
#import "MOKWatchdog.h"
#import "NSData+GZIP.h"
#import "NSData+Base64.h"

NSString * const MonkeyRegistrationDidCompleteNotification = @"com.criptext.networking.register.success";
NSString * const MonkeyRegistrationDidFailNotification = @"com.criptext.networking.register.fail";
NSString * const MonkeySocketDidConnectNotification = @"com.criptext.networking.socket.resume";
NSString * const MonkeySocketDidDisconnectNotification = @"com.criptext.networking.socket.close";
NSString * const MonkeyMessageStoreNotification = @"com.criptext.message.store";
NSString * const MonkeyMessageDeleteNotification = @"com.criptext.message.delete";
NSString * const MonkeyMessageNotification = @"com.criptext.message.delete";

@interface Monkey () <MOKComServerConnectionDelegate>
@property (nonatomic,strong) NSMutableArray *receivers;
@property (nonatomic, strong) MOKSBJsonWriter *jsonWriter;
@property (nonatomic, strong) MOKSBJsonParser *jsonParser;
@end

@implementation Monkey
+ (instancetype)sharedInstance
{
    static Monkey *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initPrivate];
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[Monkey sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _receivers = [[NSMutableArray alloc]init];
        _appId = nil;
        _appKey = nil;
        _session = [@{
                     @"id":@"",
                     @"user": @{},
                     @"lastTimestamp": @"0",
                     } mutableCopy];
    }
    return self;
}

-(void)initWithApp:(NSString *)appId
            secret:(NSString *)appKey
              user:(NSDictionary *)user
     expireSession:(BOOL)shouldExpire
         debugging:(BOOL)isDebugging
          autoSync:(BOOL)autoSync
     lastTimestamp:(NSNumber*)lastTimestamp{
    
    _appId = [appId copy];
    _appKey = [appKey copy];
    _session = [@{@"expireSession": @(shouldExpire),
                  @"debuggingMode": @(isDebugging),
                  @"autoSync": @(autoSync)
                  }mutableCopy];
    
    user = user ? [user copy] : @{};
    _session[@"user"] = user;
    
    _session[@"lastTimestamp"] = lastTimestamp ? [lastTimestamp stringValue] : @"0";
    
    NSString *myKeys = nil;
    NSString *providedMonkeyId = user[@"monkeyId"];
    
    if (providedMonkeyId != nil) {
        _session[@"id"] = providedMonkeyId;
        myKeys = [[MOKSecurityManager sharedInstance]getAESbase64forUser:_session[@"id"]];
    }
    
    
    if (myKeys != nil) {
        // connect and be done with it
        [self connect];
        return;
    }
    
    // secure handshake
    [[MOKAPIConnector sharedInstance] secureAuthenticationWithAppId:_appId appKey:_appKey user:user andExpiration:shouldExpire success:^(NSDictionary * _Nonnull data) {
        
        _session[@"id"] = data[@"monkeyId"];
        
        NSString *storedLastTimeSynced = data[@"last_time_synced"];
        
        if (storedLastTimeSynced == (id)[NSNull null]) {
            storedLastTimeSynced = @"0";
        }
    
        if ([storedLastTimeSynced intValue] > [_session[@"lastTimestamp"] intValue]) {
            _session[@"lastTimestamp"] = storedLastTimeSynced;
        }
        
        //notify whoever's listening
        [[NSNotificationCenter defaultCenter] postNotificationName:MonkeyRegistrationDidCompleteNotification object:[_session copy]];
        //start socket connection
        [self connect];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError *error) {
        //notify failure
        [[NSNotificationCenter defaultCenter] postNotificationName:MonkeyRegistrationDidFailNotification object:error];
    }];

}

-(void)getPendingMessages{
    [self getMessages:@"15" sinceTimestamp:_session[@"lastTimestamp"] andGetGroups:false];
}

-(void)getPendingMessagesWithGroups{
    [self getMessages:@"15" sinceTimestamp:_session[@"lastTimestamp"] andGetGroups:true];
}
#pragma mark - MOKComServerConnection Delegate
-(void)connect {
    if([MOKComServerConnection sharedInstance].networkStatus == AFNetworkReachabilityStatusNotReachable) {
        NSLog(@"Monkey - Connection not available");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MonkeyUnavailable" object:nil];
        [MOKComServerConnection sharedInstance].connection.state = MOKSGSConnectionStateNoNetwork;
    }
    else{
        [[MOKComServerConnection sharedInstance] connectWithDelegate:self];
    }
}

-(void)loggedIn{
    NSString *lastMessageId = _session[@"lastTimestamp"];
    
    if (lastMessageId == (id)[NSNull null]) {
        lastMessageId = @"0";
    }

    //if the app is active, set online
    if([UIApplication sharedApplication].applicationState != UIApplicationStateBackground){
        [self sendCommand:MOKProtocolSet WithArgs:@{@"online" : @"1"}];
    }
    if ([_session[@"lastTimestamp"] boolValue]) {
        [self getPendingMessages];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MonkeySocketDidConnectNotification object:[_session copy]];
}

- (void) disconnected{
    NSLog(@"Monkey - Disconnect");
    [[NSNotificationCenter defaultCenter] postNotificationName:MonkeySocketDidDisconnectNotification object:nil];
    [self connect];
}



#pragma mark - Messaging manager

- (void)addReceiver:(id <MOKMessageReceiver>)receiver {
    @synchronized (self) {
        if (![self.receivers containsObject:receiver]) {
            [self.receivers addObject:receiver];
        }
    }
}

- (void)removeReceiver:(id <MOKMessageReceiver>)receiver {
    @synchronized (self) {
        [self.receivers removeObject:receiver];
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
        NSDictionary *defaultparams = @{@"encr" : @"1",
                                        @"str" : @"0",
                                        @"cmpr" : @"gzip",
                                        @"device" : @"ios"
                                        };
        message.props = [defaultparams mutableCopy];
    }else{
        message.props = [params mutableCopy];
    }
    
    [message.props setObject:[NSNumber numberWithInt:documentType] forKey:@"file_type"];
    
    NSString *tmp = [fileURL path];
    NSMutableString *newFileName = [tmp mutableCopy];
    
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    
    //check if should compress
    if ([message.props objectForKey:@"cmpr"]) {
#ifdef DEBUG
        NSLog(@"MONKEY - antes compress: %lu",(unsigned long)[fileData length]);
#endif
        fileData = [fileData gzippedData];
#ifdef DEBUG
        NSLog(@"MONKEY - despues compress: %lu",(unsigned long)[fileData length]);
#endif
    }
    
    
    [newFileName insertString:@"_mok" atIndex:[newFileName rangeOfString:@"."].location];
#ifdef DEBUG
    NSLog(@"MONKEY - nombre archivo: %@", newFileName);
#endif
    
    [[NSFileManager defaultManager]createFileAtPath:newFileName contents:nil attributes:nil];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:newFileName];
    
    //check if should encrypt
    if([message isEncrypted]){
        NSData *encryptedData = [[MOKSecurityManager sharedInstance]aesEncryptFileData:fileData fromUser:[MOKSessionManager sharedInstance].sessionId];
        [fileHandler writeData:encryptedData];
    }else{
        [fileHandler writeData:fileData];
    }
    
    message.encryptedText = newFileName;
    
    [[MOKWatchdog sharedInstance]mediaInTransit:message];
    [[MOKAPIConnector sharedInstance]sendFile:message delegate:self];
    
    return message;
}
-(MOKMessage *)sendFile:(MOKMessage *)message ofType:(MOKFileType)documentType{
    message.protocolType = MOKFile;
    [message.props setObject:[NSNumber numberWithInt:documentType] forKey:@"file_type"];
    
    NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    documentDirectory = [documentDirectory stringByAppendingPathComponent:message.messageText];
    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:documentDirectory];
    
    if (fileData == nil) {
        return nil;
    }
    
    [message.props setObject:@([fileData length]) forKey:@"size"];
    
    if ([message.props objectForKey:@"filename"] == nil) {
        [message.props setObject:[message.messageText lastPathComponent] forKey:@"filename"];
    }
    
#ifdef DEBUG
    NSLog(@"MONKEY - data size: %lu",(unsigned long)[fileData length]);
#endif
    NSMutableString *newFileName = [documentDirectory mutableCopy];
    
    //check if should compress
    if ([message.props objectForKey:@"cmpr"]) {
#ifdef DEBUG
        NSLog(@"MONKEY - before compression: %lu",(unsigned long)[fileData length]);
#endif
        fileData = [fileData gzippedData];
#ifdef DEBUG
        NSLog(@"MONKEY - after compression: %lu",(unsigned long)[fileData length]);
#endif
    }
    
    
    [newFileName insertString:@"_mok" atIndex:[newFileName rangeOfString:@"."].location];
#ifdef DEBUG
    NSLog(@"MONKEY - file name: %@", newFileName);
#endif
    
    [[NSFileManager defaultManager]createFileAtPath:newFileName contents:nil attributes:nil];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:newFileName];
    
    //check if should encrypt
    if([message isEncrypted]){
        NSData *encryptedData = [[MOKSecurityManager sharedInstance]aesEncryptFileData:fileData fromUser:[MOKSessionManager sharedInstance].sessionId];
        [fileHandler writeData:encryptedData];
    }else{
        [fileHandler writeData:fileData];
    }
    
    message.encryptedText = newFileName;
    
    [[MOKWatchdog sharedInstance]mediaInTransit:message];
    [[MOKAPIConnector sharedInstance]sendFile:message delegate:self];
    
    return message;
    
}
-(MOKMessage *)sendMessage:(MOKMessage *)message{
    
    //check if should encrypt
    if ([message isEncrypted]) {
        [[MOKSecurityManager sharedInstance]aesEncryptOutgoingMessage:message];
    }
    
    message.protocolCommand = MOKProtocolMessage;
    message.needsResend = false;
    
    [[MOKWatchdog sharedInstance]messageInTransit:message];
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

-(MOKMessage *)sendAlertToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push{
    MOKMessage *message = [[MOKMessage alloc]initWithMyMessage:@"" userTo:sessionId];
    message.protocolCommand = MOKProtocolMessage;
    message.protocolType = MOKAlert;
    message.pushMessage = push;
    message.params = [params mutableCopy];
    [self sendMessageCommandFromMessage:message];
    
    return message;
}

- (void)sendCommand:(MOKProtocolCommand)protocolCommand WithArgs:(NSDictionary *)args{
    NSDictionary *messCom = @{@"cmd":[NSNumber numberWithInt:protocolCommand],
                              @"args": args};
    
    [[MOKComServerConnection sharedInstance] sendMessage:[self.jsonWriter stringWithObject:messCom]];
}
-(void)sendCloseCommandToUser:(NSString *)sessionId{
    [self sendCommand:MOKProtocolClose WithArgs:@{@"rid": sessionId}];
}
-(void)sendDeleteCommandForMessage:(NSString *)messageId ToUser:(NSString *)sessionId{
    
    
    [self sendCommand:MOKProtocolDelete WithArgs:@{@"id": messageId,
                                                   @"rid":sessionId}];
}
- (void)notify:(MOKMessage *)message withCommand:(int)command {
    
    //Type of messages: invites, openConversation, isTyping.
    switch (command) {
        case MOKProtocolGet:
            
            [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:message];
            return;
            break;
        default: {
            
            break;
        }
    }
    
    
    if (message.timestampCreated > [_session[@"lastTimestamp"] intValue]) {
        _session[@"lastTimestamp"] = [@(message.timestampCreated) stringValue];
    }
    
    if([self.receivers count] > 0){
        
        if([message.userIdTo rangeOfString:@","].location!=NSNotFound){
            message.userIdTo = [MOKSessionManager sharedInstance].sessionId;
        }
        
        [self.receivers makeObjectsPerformSelector:@selector(notificationReceived:) withObject:message];
    }
}
- (void)incomingMessage:(MOKMessage *)message {
    long long int msgId =[message.messageId longLongValue];
    
    //check if encrypted
    if ([message isEncrypted]) {
        @try {
            [[MOKSecurityManager sharedInstance] aesDecryptIncomingMessage:message];
        }
        @catch (NSException *exception) {
            NSLog(@"MONKEY - couldn't decrypt with current key, retrieving new keys");
            [[MOKAPIConnector sharedInstance] keyExchangeWith:message.userIdFrom withPendingMessage:message delegate:self];
            return;
        }
        
        if (message.messageText == nil) {
            NSLog(@"MONKEY - couldn't decrypt with current key, retrieving new keys");
            [[MOKAPIConnector sharedInstance] keyExchangeWith:message.userIdFrom withPendingMessage:message delegate:self];
            return;
        }
    }else{
        message.messageText = message.encryptedText;
    }
    
    
    if(msgId>0){
        [MOKSessionManager sharedInstance].lastMessageId = message.messageId;
        [MOKSessionManager sharedInstance].lastTimestamp = [@(message.timestampCreated) stringValue];
    }
    
    @synchronized (self) {
        
        [self.receivers makeObjectsPerformSelector:@selector(messageReceived:) withObject:message];
        
    }
}

- (void)fileReceivedNotification:(MOKMessage *)message {
    long long int msgId =[message.messageId longLongValue];
    
    if(msgId>0){
        [MOKSessionManager sharedInstance].lastMessageId = message.messageId;
        [MOKSessionManager sharedInstance].lastTimestamp = [@(message.timestampCreated) stringValue];
    }
    
    NSString *filename = [message.props objectForKey:@"filename"];
    if (filename != nil) {
        NSString *extension = filename.pathExtension;
        NSString *extensionless = [filename stringByDeletingPathExtension];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_]+" options:0 error:nil];
        extensionless = [regex stringByReplacingMatchesInString:extensionless options:0 range:NSMakeRange(0, extensionless.length) withTemplate:@"-"];
        
        [message.props setObject:[extensionless stringByAppendingPathExtension:extension] forKey:@"filename"];
    }
    
    //    [[MOKAPIConnector sharedInstance]downloadFile:message withDelegate:self];
    
    @synchronized (self) {
        
        [self.receivers makeObjectsPerformSelector:@selector(messageReceived:) withObject:message];
        
    }
    
}
-(void)acknowledgeNotification:(MOKMessage *)message{
    
    switch (message.protocolType) {
        case MOKText: case 50: case 51: case 52:
//            [[MOKDBManager sharedInstance]deleteMessageSent:message];
//            [self sendMessagesAgain];
            break;
        case MOKFile:
            message.messageId = [message.props objectForKey:@"new_id"];
            message.oldMessageId = [message.props objectForKey:@"old_id"];
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
        if([message isEncrypted]){
            NSData *decryptedData;
            //check if web
            if ([[message.props objectForKey:@"device"] isEqualToString:@"web"]) {
#ifdef DEBUG
                NSLog(@"MONKEY - decrypting web file");
#endif
                
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
                if ([message.props objectForKey:@"ext"] != nil) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [fileManager removeItemAtPath:message.messageText error:NULL];
                    message.messageText = [[message.messageText stringByDeletingPathExtension] stringByAppendingPathExtension:[message.props objectForKey:@"ext"]];
                }
                
                //check for file compression
                if ([message.props objectForKey:@"cmpr"]) {
                    newData = [newData gunzippedData];
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
                if ([message.props objectForKey:@"cmpr"]) {
                    decryptedData = [decryptedData gunzippedData];
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
    [[MOKAPIConnector sharedInstance]keyExchangeWith:message.userIdFrom withPendingMessage:message delegate:self];
    //    [[MOKAPIConnector sharedInstance]keyExchangeWith:message.userIdFrom delegate:self];
    [self performSelector:@selector(onDownloadFileOK:) withObject:message afterDelay:2];
}
-(void)onNewKeysReceived:(NSString *)aesKeys withPendingMessage:(MOKMessage *)message{
    [self incomingMessage:message];
}
-(void)onSameKeysReceivedWithPendingMessage:(MOKMessage *)message{
    
    [[MOKAPIConnector sharedInstance]getEncryptedTextForMessage:message delegate:self];
    
}
-(void)onKeysExchangeFailWithPendingMessage:(MOKMessage *)message{
    if (message != nil) {
        long long int msgId = [message.messageId longLongValue];
        if(msgId>0){
            [MOKSessionManager sharedInstance].lastMessageId = message.messageId;
            [MOKSessionManager sharedInstance].lastTimestamp = [@(message.timestampCreated) stringValue];
        }
    }
}
-(void)onDownloadFileFail:(MOKMessage *)message{
    NSLog(@"MONKEY - Download Fail");
}
-(void)onUploadFileOK:(MOKMessage *)message{
    [[MOKWatchdog sharedInstance] removeMediaInTransitWithId:message.oldMessageId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:message.encryptedText error:NULL];
    if (self.receivers != NULL) {
        [self.receivers makeObjectsPerformSelector:@selector(acknowledgeReceived:) withObject:message];
    }
}
-(void)onUploadFileFail:(MOKMessage *)message{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:message.encryptedText error:NULL];
    NSLog(@"MONKEY - Upload Fail");
}
- (void)sendMessagesAgain {
//    if (!self.shouldResendAutomatically) {
//        return;
//    }
//    
//    MOKMessage *message= [[MOKDBManager sharedInstance] getOldestMessageNotSent];
//    
//    if (message == nil) {
//        return;
//    }
//    message.timestampCreated = [[NSDate date] timeIntervalSince1970];
//    message.timestampOrder = message.timestampCreated;
//    
//    switch (message.protocolType) {
//        case MOKText:
//            [self sendMessage:message];
//            break;
//        case MOKFile:
//#ifdef DEBUG
//            NSLog(@"MONKEY - file type resend: %@",[message.props objectForKey:@"file_type"]);
//#endif
//            [self sendFile:message ofType:[message.props objectForKey:@"file_type"]];
//            //            [self sendFileWithURL:[NSURL fileURLWithPath:message.encryptedText] ofType:(MOKFileType)[message.params objectForKey:@"file_type"] toUser:message.userIdTo andParams:message.params];
//            break;
//            
//        default:
//            break;
//    }
//    
}

-(void)getMessages:(NSString *)quantity sinceId:(NSString *)lastMessageId  andGetGroups:(BOOL)flag{
    NSDictionary *args = flag?
    //ask for groups
    @{@"messages_since" : lastMessageId,
      @"qty" : quantity,
      @"groups" : @"1"} :
    //don't ask for groups
    @{@"messages_since" : lastMessageId,
      @"qty" : quantity};
    
    [self sendCommand:MOKProtocolGet WithArgs:args];
}
-(void)getMessages:(NSString *)quantity sinceTimestamp:(NSString *)lastTimestamp andGetGroups:(BOOL)flag{
    NSDictionary *args = flag?
    //ask for groups
    @{@"since" : lastTimestamp,
      @"qty" : quantity,
      @"groups" : @"1"} :
    //don't ask for groups
    @{@"since" : lastTimestamp,
      @"qty" : quantity};
    
    [self sendCommand:MOKProtocolSync WithArgs:args];
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
        args = @{@"id": message.messageId,
                 @"sid": message.userIdFrom,
                 @"rid": message.userIdTo,
                 @"msg": message.encryptedText,
                 @"type": [NSNumber numberWithInt:message.protocolType],
                 @"props": [self.jsonWriter stringWithObject:message.props],
                 @"params": [self.jsonWriter stringWithObject:message.params]
                 };
    }else{
        args = @{@"id": message.messageId,
                 @"sid": message.userIdFrom,
                 @"rid": message.userIdTo,
                 @"msg": message.encryptedText,
                 @"type": [NSNumber numberWithInt:message.protocolType],
                 @"props": [self.jsonWriter stringWithObject:message.props],
                 @"params": [self.jsonWriter stringWithObject:message.params],
                 @"push": message.pushMessage? message.pushMessage : @""
                 };
    }
    
    [self sendCommand:message.protocolCommand WithArgs:args];
}

- (void)logout {
    [[MOKWatchdog sharedInstance]logout];
}

@end