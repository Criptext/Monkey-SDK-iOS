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
#import "MOKComServerConnection.h"
#import "MOKSocketConnectionManager.h"
#import "MOKUserDictionary.h"
#import "UICKeyChainStore.h"
#import "MOKSessionManager.h"
#import "MOKUser.h"
#import "MOKMessage.h"
#import "AFNetworking.h"
#import "NSData+Base64.h"
#import "NSData+Compression.h"
#import "MOKDBManager.h"


//String identifiers
#define AUTHENTICATION_PUBKEY       @"authentication_pubKey"
#define SYNC_PUBKEY                 @"mok_sync_pubKey"
#define SYNC_PRIVKEY                @"mok_sync_privKey"
#define OPEN_TICKET					@"http://secure.criptext.com/user/call"

@interface MOKAPIConnector () <MOKComServerConnectionDelegate>

@end

@implementation MOKAPIConnector

#pragma mark - Subscribe to Push
- (void)pushSubscribeDevice:(NSData *)deviceToken forSessionId:(NSString *)sessionId withAppID:(NSString *)appID andAppKey:(NSString *)appKey inProduction:(BOOL)flag{
    
    NSString *tokenStr = [deviceToken description];
    NSString *pushToken = [[[[tokenStr stringByReplacingOccurrencesOfString:@"" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""]stringByReplacingOccurrencesOfString:@"<" withString:@""]stringByReplacingOccurrencesOfString:@">" withString:@""];

    NSDictionary *requestObject = @{@"token": pushToken,
                                    @"device": @"ios",
                                    @"mode": flag? @"1" : @"0",
                                    @"userid": sessionId
                                    };
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:appID password:appKey];
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/push/subscribe"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        #ifdef DEBUG
        NSLog(@"MONKEY - %@", responseObject);
		#endif
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - %@", error);
    }];
}
#pragma mark - Secure Authentication Request
- (void)secureAuthenticationWithAppId:(NSString *)appID
                               appKey:(NSString *)appKey
                                 user:(NSMutableDictionary *)user
                        andExpiration:(BOOL)expires
                             delegate:(id)delegate{
    NSString *expiration = expires? @"": @"0";
    
    [[MOKSessionManager sharedInstance].user replaceDictionary:user];
    [MOKSessionManager sharedInstance].appId = appID;
    [MOKSessionManager sharedInstance].appKey = appKey;

    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:appID password:appKey];
    
    NSDictionary *requestObject;
    if ([MOKSessionManager sharedInstance].sessionId) {
        requestObject = @{@"username":appID,
                          @"password":appKey,
                          @"expiring": expiration,
                          @"session_id": [MOKSessionManager sharedInstance].sessionId
                          };
    }else{
        requestObject = @{@"username":appID,
                          @"password":appKey,
                          @"expiring": expiration
                          };
    }
    

    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    #ifdef DEBUG
    NSLog(@"MONKEY - first handshake parameters: %@", parameters);
	#endif
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/session"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        #ifdef DEBUG
        NSLog(@"MONKEY - response first handshake: %@", responseObject);
		#endif
        
        [[MOKSecurityManager sharedInstance] storeObject:[responseDict objectForKey:@"publicKey"] withIdentifier:AUTHENTICATION_PUBKEY];
        
        NSString *stringToSend;
        //check if it's necessary to generate keys
        if (!([[MOKSessionManager sharedInstance].sessionId length]> 0)) {
            [MOKSessionManager sharedInstance].sessionId = [responseDict objectForKey:@"sessionId"];
            stringToSend = [[MOKSecurityManager sharedInstance] generateAndEncryptAESKey];
        }else{
            #ifdef DEBUG
            NSLog(@"MONKEY - my session: %@", [MOKSessionManager sharedInstance].sessionId);
            NSLog(@"MONKEY - my keys: %@", [[MOKSecurityManager sharedInstance].keychainStore stringForKey:[MOKSessionManager sharedInstance].sessionId]);
			#endif
            NSString *mygeneratedKeys = [[MOKSecurityManager sharedInstance].keychainStore stringForKey:[MOKSessionManager sharedInstance].sessionId];
            
            if (!(mygeneratedKeys.length >2)) {
                stringToSend = [[MOKSecurityManager sharedInstance] generateAndEncryptAESKey];
            }else{
                stringToSend =[[MOKSecurityManager sharedInstance]rsaEncryptBase64String:[[MOKSecurityManager sharedInstance].keychainStore stringForKey:[MOKSessionManager sharedInstance].sessionId] withPublicKeyIdentifier:AUTHENTICATION_PUBKEY];
            }
        }
        
        /************************************ Starting Second Request ****************************************/
        NSDictionary * requestConnectObject = @{@"session_id": [MOKSessionManager sharedInstance].sessionId,
                                                @"usk": stringToSend,
                                                @"session_name": [[MOKSessionManager sharedInstance].user getDictionary]
                                                };
        
        NSDictionary *secondparameters = @{@"data": [self.jsonWriter stringWithObject:requestConnectObject]};
        #ifdef DEBUG
        NSLog(@"MONKEY - second handshake parameters: %@", secondparameters);
		#endif
        [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/connect"] parameters:secondparameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *responseDict2 = [responseObject objectForKey:@"data"];
            #ifdef DEBUG
            NSLog(@"MONKEY - second handshake response: %@", responseDict2);
			#endif
            
            NSString *storedLastMessageId = [responseDict2 objectForKey:@"last_message_id"];
            
            if (storedLastMessageId == [NSNull null]) {
                storedLastMessageId = @"0";
            }
            
            if ([storedLastMessageId intValue] > [[MOKSessionManager sharedInstance].lastMessageId intValue]) {
                [MOKSessionManager sharedInstance].lastMessageId = storedLastMessageId;
            }
            
            [MOKSessionManager sharedInstance].sessionId = [responseDict2 objectForKey:@"sessionId"];
            [MOKSessionManager sharedInstance].domain = [responseDict2 objectForKey:@"sdomain"];
            [MOKSessionManager sharedInstance].port = [responseDict2 objectForKey:@"sport"];
            
            [delegate onAuthenticationOkWithSessionId:[responseDict2 objectForKey:@"sessionId"] publicKey:[[MOKSecurityManager sharedInstance]getObjectForIdentifier:AUTHENTICATION_PUBKEY]];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"MONKEY - fail second handshake");
            [delegate onAuthenticationWrong];
        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - fail first handshake: %@", error);
        [delegate onAuthenticationWrong];
    }];
}

-(void)getRegisteredAESkeysForSessionId:(NSString *)sessionId withAppId:(NSString *)appId andAppKey:(NSString *)appKey delegate:(id<MOKAPIConnectorDelegate>)delegate{
    
    [MOKSessionManager sharedInstance].appId = appId;
    [MOKSessionManager sharedInstance].appKey = appKey;
    
    NSDictionary *requestObject = @{@"session_id" : sessionId,
                                    @"public_key" : [[MOKSecurityManager sharedInstance] getObjectForIdentifier:SYNC_PUBKEY]
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:appId password:appKey];
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/key/sync"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        #ifdef DEBUG
        NSLog(@"MONKEY - old Key response: %@", responseObject);
        #endif
        NSString *encryptedKeys = [responseDict objectForKey:@"keys"];

        NSString *decryptedKeys = [[MOKSecurityManager sharedInstance]rsaDecryptBase64String:encryptedKeys withPrivateKeyIdentifier:SYNC_PRIVKEY];
        #ifdef DEBUG
        NSLog(@"MONKEY - decrypted old keys: %@", decryptedKeys);
        #endif
        [[MOKSecurityManager sharedInstance] storeBase64AESKeyAndIV:decryptedKeys forUser:sessionId];
        
        NSString *storedLastMessageId = [responseDict objectForKey:@"last_message_received"];
        
        if (storedLastMessageId == [NSNull null]) {
            storedLastMessageId = @"0";
        }
        
        if ([storedLastMessageId intValue] > [[MOKSessionManager sharedInstance].lastMessageId intValue]) {
            [MOKSessionManager sharedInstance].lastMessageId = storedLastMessageId;
        }
        NSString *sdomain = [responseDict objectForKey:@"sdomain"];
        NSString *sport = [responseDict objectForKey:@"sport"];
        
        if (sdomain == nil || sdomain == [NSNull null] || [sdomain isEqualToString:@""]) {
            [MOKSessionManager sharedInstance].domain = @"secure.criptext.com";
        }else{
            [MOKSessionManager sharedInstance].domain = sdomain;
        }
        
        if (sport == nil || sport == [NSNull null] || [sport isEqualToString:@""]) {
            [MOKSessionManager sharedInstance].port = @"1139";
        }else{
            [MOKSessionManager sharedInstance].port = sport;
        }
        
        [delegate onAuthenticationOkWithSessionId:sessionId publicKey:nil];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [delegate onAuthenticationFail];
    }];
}

#pragma mark - Open conversation
-(void)keyExchangeWith:(NSString *)sessionId withPendingMessage:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate{
    
    NSDictionary *requestObject = @{@"session_id": [MOKSessionManager sharedInstance].sessionId,
                                    @"user_to": sessionId
                                    };
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    #ifdef DEBUG
    NSLog(@"MONKEY - parameters key exchange: %@", parameters);
	#endif
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/user/key/exchange"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        #ifdef DEBUG
//        NSLog(@"MONKEY - %@", responseObject);
		#endif
        
        NSString *oldKey = [[MOKSecurityManager sharedInstance] getObjectForIdentifier:[responseDict objectForKey:@"session_to"]];
        NSString *decryptedKey = [[MOKSecurityManager sharedInstance]aesDecryptAndStoreKeyFromStringBase64:[responseDict objectForKey:@"convKey"] fromUser:[responseDict objectForKey:@"session_to"]];
        
        #ifdef DEBUG
        NSLog(@"MONKEY - stored decryptedkey:%@ for session id:%@", decryptedKey, [responseDict objectForKey:@"session_to"]);
        NSLog(@"MONKEY - verifying stored aes: %@", [[MOKSecurityManager sharedInstance]getAESbase64forUser:[responseDict objectForKey:@"session_to"]]);
        NSLog(@"MONKEY - verifying stored iv: %@", [[MOKSecurityManager sharedInstance]getIVbase64forUser:[responseDict objectForKey:@"session_to"]]);
        #endif
        if (delegate != nil) {
            if (oldKey == nil || ![oldKey isEqualToString:decryptedKey]) {
                [delegate onNewKeysReceived:decryptedKey withPendingMessage:message];
            }else{
                [delegate onSameKeysReceivedWithPendingMessage:message];
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        if (delegate != nil) {
            [delegate onKeysExchangeFailWithPendingMessage:message];
        }
    }];
    
}

#pragma mark - Open message
-(void)getEncryptedTextForMessage:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate{
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    NSString *urlSufix = [NSString stringWithFormat:@"/message/%@/open/secure", message.messageId];
    [self GET:[self.baseurl stringByAppendingPathComponent:urlSufix] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        
        message.encryptedText = [responseDict objectForKey:@"message"];
        [[MOKSecurityManager sharedInstance] aesDecryptOutgoingMessage:message];
        if (message.messageText == nil) {
            [delegate onKeysExchangeFailWithPendingMessage:message];
            return;
        }
        message.encryptedText = message.messageText;
        [message setEncrypted:false];
        [delegate onNewKeysReceived:nil withPendingMessage:message];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        [delegate onKeysExchangeFailWithPendingMessage:message];
    }];

}

#pragma mark - Send File
-(void)sendFile:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate{
    NSString *fileExtension = message.encryptedText.pathExtension;
    
    [message.props setObject:fileExtension forKey:@"ext"];
    NSDictionary *requestObject =@{@"id":message.messageId,
                                   @"sid":message.userIdFrom,
                                   @"rid":message.userIdTo,
                                   @"props":message.props,
                                   @"params":message.params,
                                   @"push":message.pushMessage};
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    #ifdef DEBUG
    NSLog(@"MONKEY - parameters del send file: %@", parameters);
    #endif
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
//    [self.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/file/new"] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:message.encryptedText] name:@"file" error:nil];
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        #ifdef DEBUG
        NSLog(@"MONKEY - %@ %@", task, responseObject);
		#endif
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        
//        message.oldMessageId = message.messageId;
        message.messageId = [[responseDict objectForKey:@"messageId"] stringValue];
        [[MOKDBManager sharedInstance]deleteMessageSent:message];
        
        [delegate onUploadFileOK:message];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        [delegate onUploadFileFail:message];
    }];
    
}

- (NSString*)postBodyForMethod:(NSString*)method data:(id)dataAsJsonComparableObject {
	NSString *result = [self.jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:method,@"request", dataAsJsonComparableObject, @"data", nil]];
	return result;
}

#pragma mark - Download File
-(void)downloadFile:(NSString *)name
      fileExtension:(NSString *)extension
           fromUser:(NSString *)userIdFrom
  folderDestination:(NSString *)folderName
          encrypted:(BOOL)encrypted
         compressed:(BOOL)compressed
             device:(NSString *)device
       withDelegate:(id<MOKAPIConnectorDelegate>)delegate{
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:[self.baseurl stringByAppendingPathComponent:@"/file/open/%@"],[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    #ifdef DEBUG
    NSLog(@"MONKEY - url %@", URL);
	#endif
    NSMutableString *loginString = (NSMutableString*)[@"" stringByAppendingFormat:@"%@:%@", [MOKSessionManager sharedInstance].appId, [MOKSessionManager sharedInstance].appKey];
    
    // employ the Base64 encoding above to encode the authentication tokens
    NSString *encodedLoginData = [[loginString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    // create the contents of the header
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginData];
    
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    
    
    [requestM addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:requestM progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *folderPath = [documentsDirectoryURL URLByAppendingPathComponent:folderName];
        
        [[NSFileManager defaultManager] createDirectoryAtURL:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *suggestedfilename = [[response suggestedFilename] stringByDeletingPathExtension];
        
        [suggestedfilename stringByAppendingPathExtension:extension];
        
        NSURL *documentsAndFilename = [documentsDirectoryURL URLByAppendingPathComponent:[folderName stringByAppendingPathComponent:[suggestedfilename stringByAppendingPathExtension:extension]]];
        
        return documentsAndFilename;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        if (error) {
            NSLog(@"MONKEY - Error: %@", error);
            [delegate onDownloadFileFail:@"error"];
        }else{
            #ifdef DEBUG
            NSLog(@"MONKEY - File downloaded to: %@", filePath);
			#endif
            
            [self decryptDownloadedFile:[filePath path] fromUser:userIdFrom encrypted:encrypted compressed:compressed device:device withDelegate:delegate];
        }
        
    }];
    
    [downloadTask resume];
}

-(void)decryptDownloadedFile:(NSString *)filePath fromUser:(NSString *)userIdFrom encrypted:(BOOL)encrypted compressed:(BOOL)compressed device:(NSString *)device withDelegate:(id<MOKAPIConnectorDelegate>)delegate{
    @autoreleasepool {
        //check if should decrypt
        if(encrypted){
                
                NSData *decryptedData;
                //check if we
#ifdef DEBUG
                NSLog(@"MONKEY - decriptando archivo de movil");
                NSLog(@"MONKEY - filePath: %@", filePath);
                NSLog(@"MONKEY - fromUser: %@", userIdFrom);
#endif
                @try {
                    long encryptedDataLength = (unsigned long)[[NSData dataWithContentsOfFile:filePath] length];
#ifdef DEBUG
                    NSLog(@"MONKEY - encryptedData: %lu",encryptedDataLength);
#endif
                    decryptedData = [[MOKSecurityManager sharedInstance]aesDecryptFileData:[NSData dataWithContentsOfFile:filePath] fromUser:userIdFrom];
                    
                    long decryptedDataLength = (unsigned long)[decryptedData length];
#ifdef DEBUG
                    NSLog(@"MONKEY - decryptedData: %lu",decryptedDataLength);
#endif
      
                    if ([device isEqualToString:@"web"]) {
                        NSString *mediabase64 = [[NSString alloc]initWithData:decryptedData encoding:NSUTF8StringEncoding];
                        NSArray *realmediabase64 = [mediabase64 componentsSeparatedByString:@","];
                        decryptedData = [NSData mok_dataFromBase64String:[realmediabase64 lastObject]];
                    }
                    
                    if (encryptedDataLength == decryptedDataLength) {
                        [delegate onDownloadFileDecryptionWrong];
                        return;
                    }
                }
                @catch (NSException *exception) {
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                    [delegate onDownloadFileDecryptionWrong];
                    return;
                }
                
                if (decryptedData == nil) {
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                    [delegate onDownloadFileDecryptionWrong];
                    return;
                }
                //check for file compression
                if (compressed) {
                    decryptedData = [decryptedData mok_gzipInflate];
#ifdef DEBUG
                    NSLog(@"MONKEY - compressedData: %lu",(unsigned long)[decryptedData length]);
#endif
                }
                if (decryptedData != nil) {
                    [decryptedData writeToFile:filePath atomically:YES];
                }
        }
    }
    
//    message.messageText = [message.messageText lastPathComponent];
    [delegate onDownloadFileOK];

}

#pragma mark - Groups
-(void)createGroupWithMembers:(NSArray *)members
                   withParams:(NSDictionary *)params
                      andPush:(NSString *)push
          delegate:(id<MOKAPIConnectorDelegate>)delegate{
    NSDictionary *requestObject = @{@"session_id" : [MOKSessionManager sharedInstance].sessionId,
                                    @"members": [members componentsJoinedByString:@","],
                                    @"info":params? params : @{},
                                    @"push_all_members":push
                                    };

    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    #ifdef DEBUG
    NSLog(@"MONKEY - parameters de crear grupo: %@", parameters);
	#endif
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/create"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        #ifdef DEBUG
        NSLog(@"MONKEY - response: %@", responseObject);
        NSLog(@"MONKEY - error: %ld", (long)[[responseObject objectForKey:@"error"] integerValue]);
        NSLog(@"MONKEY - group id: %@", [responseDict objectForKey:@"group_id"]);
		#endif
        
        [delegate onCreateGroupOK:[responseDict objectForKey:@"group_id"]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [delegate onCreateGroupFail:@"fail"];
        NSLog(@"MONKEY - failed to create group, task:%@ error: %@",task, error);
    }];
}

- (void)addMember:(NSString *)sessionId toGroup:(NSString *)groupId withPushToNewMember:(NSString *)pushNewMember andPushToAllMembers:(NSString *)pushAllMembers delegate:(id <MOKAPIConnectorDelegate>)delegate{
    
    NSDictionary *requestObject = @{@"session_id" : [MOKSessionManager sharedInstance].sessionId,
                                    @"new_member": sessionId,
                                    @"group_id":groupId,
                                    @"push_new_member":pushNewMember,
                                    @"push_all_members":pushAllMembers
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/addmember"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;

        [delegate onAddMemberToGroupOK:sessionId];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [delegate onAddMemberToGroupFail:@"error"];
    }];
}

- (void)removeMember:(NSString *)sessionId fromGroup:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate{
    
    NSDictionary *requestObject = @{@"session_id" : sessionId,
                                    @"group_id":groupId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/delete"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        

        [delegate onRemoveMemberFromGroupOK:@"OK"];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [delegate onRemoveMemberFromGroupFail:@"error"];
    }];
}

-(void)getGroupInfo:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate{
    NSDictionary *requestObject = @{@"group_id":groupId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    #ifdef DEBUG
    NSLog(@"MONKEY - getGroupinfo parameters: %@", parameters);
	#endif
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    [self POST:[self.baseurl stringByAppendingPathComponent:@"/group/info"] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        #ifdef DEBUG
        NSLog(@"MONKEY - get group response: %@", responseObject);
		#endif
        NSDictionary *responseDict = [responseObject objectForKey:@"data"];
        
        NSArray *members=[responseDict objectForKey:@"members"];
        NSDictionary *groupinfo=(NSDictionary *)[responseDict objectForKey:@"group_info"];
        
        [delegate onGetGroupInfoOK:groupinfo andMembers:members];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - get group error: %@", error);
        [delegate onGetGroupInfoFail:@"error"];
    }];
    
}
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
        self.jsonWriter = [MOKSBJsonWriter new];
        AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
        [securityPolicy setValidatesDomainName:NO];
        [securityPolicy setAllowInvalidCertificates:YES];
        self.securityPolicy = securityPolicy;
//        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

-(void)logout{
    @synchronized(apiConnectorInstance) {
        apiConnectorInstance = nil;
    }
}


@end
