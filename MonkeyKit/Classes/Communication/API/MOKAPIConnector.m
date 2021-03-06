//
//  APIConnector.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/2/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "MOKAPIConnector.h"
#import "MOKJSON.h"
#import "MOKSecurityManager.h"
#import "UICKeyChainStore.h"
#import "MOKMessage.h"
#import "AFNetworking.h"
#import "NSData+Base64.h"
#import "NSData+GZIP.h"
#import <MobileCoreServices/MobileCoreServices.h>

//String identifiers
#define AUTHENTICATION_PUBKEY       @"authentication_pubKey"
#define SYNC_PUBKEY                 @"mok_sync_pubKey"
#define SYNC_PRIVKEY                @"mok_sync_privKey"

NSString * const MonkeyErrorFileDownloading = @"com.criptext.networking.file.downloading";

@interface MOKAPIConnector ()
@property (strong, nonatomic) NSMutableDictionary *downloadHash;
@end

@implementation MOKAPIConnector

#pragma mark - Subscribe to Push
- (void)pushSubscribeDevice:(NSString *)deviceToken
                forMonkeyId:(NSString *)monkeyId
               inProduction:(BOOL)flag
                    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure{

    NSDictionary *requestObject = @{@"token": deviceToken,
                                    @"device": @"ios",
                                    @"mode": flag? @"1" : @"0",
                                    @"userid": monkeyId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/push/subscribe"] parameters:parameters progress:nil success:success failure:failure];
}
#pragma mark - Secure Authentication Request
- (void)secureAuthenticationWithAppId:(NSString *)appID
                               appKey:(NSString *)appKey
                                 user:(NSDictionary *)user
                        ignoredParams:(nullable NSArray<NSString *> *)params
                        andExpiration:(BOOL)expires
                              success:(void (^)(NSDictionary * _Nonnull data))success
                              failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    BOOL isSync = false;
    NSString *endpoint = @"/user/session";
    NSString *expiration = expires? @"1": @"0";
    
    NSMutableDictionary *requestObject = [@{@"expiring": expiration,
                                            @"user_info": user} mutableCopy];
    
    NSString *providedMonkeyId = nil;
    
    if (user[@"monkeyId"] != nil && ![user[@"monkeyId"] isEqualToString:@""]) {
        providedMonkeyId = user[@"monkeyId"];
        requestObject[@"monkey_id"] = providedMonkeyId;
        requestObject[@"public_key"] = [[MOKSecurityManager sharedInstance] exportPublicKeyRSA];
        isSync = true;
        endpoint = @"/user/key/sync";
    }
    
    //status handshake

    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    #ifdef DEBUG
    NSLog(@"MONKEY - first handshake parameters: %@", parameters);
	#endif
    
    [self POST:[self.baseurl stringByAppendingPathComponent:endpoint] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *responseDict = responseObject[@"data"];
        
        if (isSync) {
#ifdef DEBUG
            NSLog(@"MONKEY - Reusing Monkey Id: %@", providedMonkeyId);
#endif
            
            NSString *encryptedKeys = responseDict[@"keys"];
            NSString *decryptedKeys = [[MOKSecurityManager sharedInstance]rsaDecryptString:encryptedKeys];
            [[MOKSecurityManager sharedInstance] storeObject:decryptedKeys withIdentifier:providedMonkeyId];
            
            success(responseDict);
            return;
        }
        
        NSString *monkeyId = responseDict[@"monkeyId"];
        
        NSString *myAES = [[MOKSecurityManager sharedInstance] generateAESKeyAndIV];
        [[MOKSecurityManager sharedInstance] storeObject:myAES withIdentifier:monkeyId];
        
        NSString *stringToSend = [[MOKSecurityManager sharedInstance] rsaEncryptString:myAES publicKey:responseDict[@"publicKey"]];
        
#ifdef DEBUG
        NSLog(@"MONKEY - my monkey id: %@", monkeyId);
#endif
        
        /************************************ Starting Second Request ****************************************/
        NSDictionary * requestConnectObject = @{@"monkey_id": monkeyId,
                                                @"usk": stringToSend,
                                                @"ignore_params": params? : @[]
                                                };
        
        NSDictionary *secondparameters = @{@"data": [self.jsonWriter stringWithObject:requestConnectObject]};
        #ifdef DEBUG
        NSLog(@"MONKEY - second handshake parameters: %@", secondparameters);
		#endif
        [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/connect"] parameters:secondparameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *responseDict2 = responseObject[@"data"];
            
            success(responseDict2);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"MONKEY - fail second handshake");
            failure(task, error);
        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - fail first handshake: %@", error);
        failure(task, error);
    }];
}

#pragma mark - Open conversation
-(void)keyExchange:(NSString *)me
              with:(NSString *)monkeyId
withPendingMessage:(MOKMessage *)message
           success:(void (^)(NSDictionary * _Nonnull data))success
           failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSDictionary *requestObject = @{@"monkey_id": me,
                                    @"user_to": monkeyId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    #ifdef DEBUG
    NSLog(@"MONKEY - parameters key exchange: %@", parameters);
	#endif
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/key/exchange"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        #ifdef DEBUG
//        NSLog(@"MONKEY - %@", responseObject);
		#endif
        
        NSString *currentKey = [[MOKSecurityManager sharedInstance] getObjectForIdentifier:responseDict[@"session_to"]];
        NSString *decryptedKey = nil;
        @try {
             decryptedKey = [[MOKSecurityManager sharedInstance]aesDecryptKeyAndClean:responseDict[@"convKey"] fromUser:me];
            [[MOKSecurityManager sharedInstance] storeObject:decryptedKey withIdentifier:responseDict[@"session_to"]];
        } @catch (NSException *exception) {
            failure(nil, [NSError errorWithDomain:@"Error decrypting text"
                                             code:-57
                                         userInfo:nil]);
        }
        
        if (currentKey == nil) {
            success(responseDict);
            return;
        }
        
        if (decryptedKey == nil) {
            failure(nil, [NSError errorWithDomain:@"Decrypted keys are nil"
                                             code:-57
                                         userInfo:nil]);
        }
        
        if (![currentKey isEqualToString:decryptedKey] && decryptedKey != nil) {
            success(responseDict);
            return;
        }

        failure(nil, [NSError errorWithDomain:@"Same keys received"
                                         code:-57
                                     userInfo:nil]);
//        [self getEncryptedTextForMessage:message success:^(NSDictionary * _Nonnull data) {
//            success(responseDict);
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            failure(task, error);
//        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        failure(task, error);
    }];
    
}

-(void)deleteConversationBetween:(NSString *)monkeyId1
                             and:(NSString *)monkeyId2
                         success:(void (^)(NSDictionary * _Nonnull data))success
                         failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSDictionary *requestObject =@{@"monkey_id":monkeyId1,
                                   @"conversation_id":monkeyId2};
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
#ifdef DEBUG
    NSLog(@"MONKEY - parameters delete conversations: %@", parameters);
#endif
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/delete/conversation"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
#ifdef DEBUG
        NSLog(@"MONKEY - %@ %@", task, responseObject);
#endif
        NSDictionary *responseDict = responseObject[@"data"];
        
        success(responseDict);
    } failure:failure];
    
}

-(void)getConversationsOf:(NSString *)monkeyId
                    since:(double)timestamp
                 quantity:(int)qty
                  success:(nullable void (^)(NSArray<MOKConversation *> * _Nonnull conversations))success
                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSMutableDictionary *requestObject = [@{@"monkeyId": monkeyId,
                                          @"qty":[@(qty) stringValue]} mutableCopy];
    
    if (timestamp > 0) {
        requestObject[@"timestamp"] =[@(timestamp) stringValue];
    }
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
#ifdef DEBUG
    NSLog(@"MONKEY - parameters get conversations: %@", parameters);
#endif
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/conversations"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {

        NSDictionary *responseDict = responseObject[@"data"];
        
        success(responseDict[@"conversations"]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        failure(task, error);
    }];
    
}

-(void)getMessagesOf:(NSString *)monkeyId
               since:(NSString *)timestamp
            quantity:(int)qty
             success:(void (^)(NSDictionary * _Nonnull data))success
             failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
  
  NSString *path = [NSString stringWithFormat:@"/user/messages/%@/%@/%d", monkeyId, timestamp, qty];
  
#ifdef DEBUG
  NSLog(@"MONKEY - parameters get messages of: %@", path);
#endif
  
  [self GET:[self.baseurl stringByAppendingPathComponent:path] parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
    NSDictionary *responseDict = responseObject[@"data"];
    success(responseDict);
    
  } failure:^(NSURLSessionDataTask *task, NSError *error) {
    NSLog(@"MONKEY - Error: %@", error);
    failure(task, error);
  }];
  
}

-(void)getMessagesBetween:(NSString *)monkeyId1
                      and:(NSString *)monkeyId2
                    since:(NSInteger)timestamp
                 quantity:(int)qty
                  success:(nullable void (^)(NSMutableArray<MOKMessage *> * _Nonnull messages))success
                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSString *path = [NSString stringWithFormat:@"/conversation/messages/%@/%@/%d/%@", monkeyId1,monkeyId2, qty, @(timestamp)];
    
#ifdef DEBUG
    NSLog(@"MONKEY - parameters get messages: %@", path);
#endif
    
    [self GET:[self.baseurl stringByAppendingPathComponent:path] parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *responseDict = responseObject[@"data"];
        NSDictionary *messagesDict = responseDict[@"messages"];
        NSMutableArray *messageArray = [@[] mutableCopy];
        
        for (NSDictionary *message in messagesDict) {
            MOKMessage *msg = [[MOKMessage alloc] initWithArgs:message];
            msg.protocolCommand = ProtocolMessage;
            
            [messageArray addObject:msg];
        }
        
        success(messageArray);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        failure(task, error);
    }];
    
}

#pragma mark - Open message
-(void)getEncryptedTextForMessage:(MOKMessage *)message
                          success:(void (^)(NSDictionary * _Nonnull data))success
                          failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSString *urlSufix = [NSString stringWithFormat:@"/message/%@/open/secure", message.messageId];
    [self GET:[self.baseurl stringByAppendingPathComponent:urlSufix] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        
        message.encryptedText = responseDict[@"message"];
        message.plainText = [[MOKSecurityManager sharedInstance] aesDecryptText:message.encryptedText fromUser:message.recipient];
        
        
        if (message.plainText == nil) {
            failure(nil, [NSError errorWithDomain:@"decrypted message nil"
                                        code:-57
                                    userInfo:nil]);
            return;
        }
        
        [message setEncrypted:false];
        
        success(responseDict);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        failure(task, error);
    }];

}

#pragma mark - Send File

-(void)sendFile:(NSData *)data
        message:(MOKMessage *)message
        success:(void (^)(NSDictionary * _Nonnull data))success
        failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{

    NSDictionary *requestObject =@{@"id":message.messageId,
                                   @"sid":message.sender,
                                   @"rid":message.recipient,
                                   @"props":message.props,
                                   @"params":message.params,
                                   @"push":message.pushMessage};
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    #ifdef DEBUG
    NSLog(@"MONKEY - parameters del send file: %@", parameters);
    #endif

    [self POST:[self.baseurl stringByAppendingPathComponent:@"/file/new"] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        NSURL *fileurl = [NSURL fileURLWithPath:message.encryptedText];
        [formData appendPartWithFileData:data name:@"file" fileName:[[fileurl lastPathComponent] stringByDeletingPathExtension] mimeType:message.props[@"mime_type"]];
//        [formData appendPartWithFileURL:fileurl name:@"file" fileName:[[fileurl lastPathComponent] stringByDeletingPathExtension] mimeType:message.props[@"mime_type"] error:nil];
        
    } progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        #ifdef DEBUG
        NSLog(@"MONKEY - %@ %@", task, responseObject);
		#endif
        NSDictionary *responseDict = responseObject[@"data"];
        
        success(responseDict);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        failure(task, error);
    }];
    
}

- (NSString*)postBodyForMethod:(NSString*)method data:(id)dataAsJsonComparableObject {
	NSString *result = [self.jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:method,@"request", dataAsJsonComparableObject, @"data", nil]];
	return result;
}

#pragma mark - Download File
-(void)downloadFileMessage:(MOKMessage *)message
           fileDestination:(NSString *)fileDestination
                   success:(void (^)(NSURL * _Nonnull filePath))success
                   failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{

    NSURLSessionDownloadTask *cachedTask = self.downloadHash[message.messageId];
    if (cachedTask != nil) {
        return failure(nil, [NSError errorWithDomain:@"File already downloading"
                                                code:-60
                                            userInfo:nil]);
    }
    NSString *name = [message.messageText lastPathComponent];
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:[self.baseurl stringByAppendingPathComponent:@"/file/open/%@"],[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    #ifdef DEBUG
    NSLog(@"MONKEY - url %@", URL);
	#endif
    
//    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    
    NSURLRequest *requestM = [self.requestSerializer requestWithMethod:@"GET" URLString:[URL absoluteString] parameters:nil error:nil];
    
//    [requestM addValue:self.requestSerializer.HTTPRequestHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
//
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:requestM progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        
        if (fileDestination == nil) {
            return targetPath;
        }
        NSURL *fileDestinationURL = [NSURL fileURLWithPath:fileDestination];
        [[NSFileManager defaultManager] createDirectoryAtURL:fileDestinationURL withIntermediateDirectories:YES attributes:nil error:nil];
        
        return [fileDestinationURL URLByAppendingPathComponent:[name stringByAppendingPathExtension:message.props[@"ext"]]];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        [self.downloadHash removeObjectForKey:message.messageId];
        
        if (error) {
            NSLog(@"MONKEY - Error: %@", error);
            failure(nil, error);
            return;
        }
#ifdef DEBUG
        NSLog(@"MONKEY - File downloaded to: %@", filePath);
#endif
        success(filePath);
    }];
    
    self.downloadHash[message.messageId] = downloadTask;
    [downloadTask resume];
}

-(void)stopDownload:(nonnull NSString *)identifier
         resumeData:(void (^)(NSData * _Nullable resumeData))resumeData{
    NSURLSessionDownloadTask *downloadTask = self.downloadHash[identifier];
    
    if (downloadTask != nil) {
        [downloadTask cancelByProducingResumeData:resumeData];
    }
}

-(void)resumeDownload:(nonnull NSData *)resumeData
      fileDestination:(NSString *)fileDestination
              success:(void (^)(NSURL * _Nonnull filePath))success
              failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    [self downloadTaskWithResumeData:resumeData progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (fileDestination == nil) {
            return targetPath;
        }
        NSURL *fileDestinationURL = [NSURL fileURLWithPath:fileDestination];
        [[NSFileManager defaultManager] createDirectoryAtURL:fileDestinationURL withIntermediateDirectories:YES attributes:nil error:nil];
        
        return fileDestinationURL;
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error) {
            NSLog(@"MONKEY - Error: %@", error);
            failure(nil, error);
            return;
        }
#ifdef DEBUG
        NSLog(@"MONKEY - File downloaded to: %@", filePath);
#endif
        success(filePath);
    }];
}

#pragma mark - Groups
-(void)createGroup:(nullable NSString *)optionalId
           creator:(nonnull NSString *)monkeyId
           members:(nonnull NSArray *)members
              info:(nullable NSDictionary *)params
              push:(nullable id)push
           success:(nullable void (^)(NSDictionary * _Nonnull groupData))success
           failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSDictionary *requestObject = @{@"group_id" : optionalId,
                                    @"monkey_id" : monkeyId,
                                    @"members": [members componentsJoinedByString:@","],
                                    @"info":params,
                                    @"push_all_members":push? push : @{}
                                    };
    
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
#ifdef DEBUG
    NSLog(@"MONKEY - parameters de crear grupo: %@", parameters);
#endif
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/create"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        success(responseDict);
    } failure:failure];
    
}

- (void)addMember:(NSString *)newMonkeyId
          toGroup:(NSString *)groupId
           byUser:(NSString *)monkeyId
withPushToNewMember:(NSString *)pushNewMember
andPushToAllMembers:(NSString *)pushAllMembers
          success:(nullable void (^)(NSDictionary * _Nonnull groupData))success
          failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSDictionary *requestObject = @{@"monkey_id" : monkeyId,
                                    @"new_member": newMonkeyId,
                                    @"group_id":groupId,
                                    @"push_new_member":pushNewMember,
                                    @"push_all_members":pushAllMembers
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/addmember"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        success(responseDict);
    } failure:failure];
}

- (void)removeMember:(NSString *)monkeyId
           fromGroup:(NSString *)groupId
             success:(nullable void (^)(NSDictionary * _Nonnull groupData))success
             failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSDictionary *requestObject = @{@"monkey_id" : monkeyId,
                                    @"group_id":groupId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/delete"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        success(responseDict);
    } failure:failure];
}

- (void)getInfo:(NSString *)conversationId
        success:(nullable void (^)(NSDictionary * _Nonnull info))success
        failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    
    NSMutableString *endpoint = [NSMutableString new];
    
    if ([conversationId rangeOfString:@"G:"].location != NSNotFound) {
        [endpoint appendString:@"/group/info/"];
    }else{
        [endpoint appendString:@"/user/info/"];
    }
    
    [endpoint appendString:conversationId];
    
    [self GET:[self.baseurl stringByAppendingPathComponent:endpoint] parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        success(responseDict);
    } failure:failure];
}

- (void)getInfoByIds:(NSArray *)idList
        success:(nullable void (^)(NSDictionary * _Nonnull infos))success
        failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure{
    NSDictionary *requestObject = @{@"monkey_ids" : [idList componentsJoinedByString:@","]
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/users/info"] parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject[@"data"];
        success(responseDict);
    } failure:failure];
}

//-(void)getGroupInfo:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate{
//    
//    #ifdef DEBUG
//    NSLog(@"MONKEY - getGroupinfo parameters: %@", groupId);
//	#endif
//    
//    NSString *urlSufix = [NSString stringWithFormat:@"/group/info/%@", groupId];
//    [self GET:[self.baseurl stringByAppendingPathComponent:urlSufix] parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
//        #ifdef DEBUG
//        NSLog(@"MONKEY - get group response: %@", responseObject);
//		#endif
//        NSDictionary *responseDict = responseObject[@"data"];
//        
//        NSArray *members=responseDict[@"members"];
//        NSDictionary *groupinfo=(NSDictionary *)responseDict[@"info"];
//        
//        [delegate onGetGroupInfoOK:groupinfo andMembers:members];
//    } failure:^(NSURLSessionDataTask *task, NSError *error) {
//        NSLog(@"MONKEY - get group error: %@", error);
//        [delegate onGetGroupInfoFail:@"error"];
//    }];
//    
//}
#pragma mark - --- General ---
static MOKAPIConnector *apiConnectorInstance = nil;
+ (MOKAPIConnector *)sharedInstance
{
    
    @synchronized(apiConnectorInstance) {
        if (apiConnectorInstance == nil) {
            apiConnectorInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:@""]];
        }
        
        return apiConnectorInstance;
    }
}
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MOKAPIConnector sharedInstance]"
                                 userInfo:nil];
    return nil;
}
- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.baseurl = @"http://secure.criptext.com";
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.responseSerializer.acceptableContentTypes = [self.responseSerializer.acceptableContentTypes setByAddingObject:@"application/octet-stream"];
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
//        self.requestSerializer setAuthorizationHeaderFieldWithUsername:<#(nonnull NSString *)#> password:<#(nonnull NSString *)#>
        self.jsonWriter = [MOKSBJsonWriter new];
        
        self.downloadHash = [@{} mutableCopy];
    }
    
    return self;
}

-(void)logout{
    @synchronized(apiConnectorInstance) {
        apiConnectorInstance = nil;
    }
}


@end
