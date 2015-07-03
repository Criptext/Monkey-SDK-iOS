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


//String identifiers
#define BASE_URL					@"http://secure.criptext.com"
#define OLD_BASE_URL				@"https://api.criptext.com/"
#define SEND_FILE_URL				@"http://secure.criptext.com/file/new"
#define DOWNLOAD_FILE_URL			@"http://secure.criptext.com/file/open/%@"
#define AUTHENTICATION_SESSION_URL  @"http://secure.criptext.com/user/session"
#define AUTHENTICATION_CONNECT_URL  @"http://secure.criptext.com/user/connect"
#define CREATE_GROUP_URL			@"http://secure.criptext.com/group/create"
#define ADD_MEMBER_GROUP_URL		@"http://secure.criptext.com/group/addmember"
#define REMOVE_MEMBER_GROUP_URL		@"http://secure.criptext.com/group/delete"
#define GET_GROUP_INFO_URL			@"http://secure.criptext.com/group/info"


#define AUTHENTICATION_PUBKEY       @"authentication_pubKey"
#define OPEN_CONVERSATION			@"http://secure.criptext.com/user/open/secure"
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
    
    [self POST:@"http://secure.criptext.com/push/subscribe" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"MONKEY - %@", responseObject);
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
    NSLog(@"MONKEY - first handshake parameters: %@", parameters);
    [self POST:AUTHENTICATION_SESSION_URL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        NSLog(@"MONKEY - response first handshake: %@", responseObject);
        [[MOKSecurityManager sharedInstance] storeObject:[responseDict objectForKey:@"publicKey"] withIdentifier:AUTHENTICATION_PUBKEY];
        
        NSString *stringToSend;
        //check if it's necessary to generate keys
        if (!([[MOKSessionManager sharedInstance].sessionId length]> 0)) {
            [MOKSessionManager sharedInstance].sessionId = [responseDict objectForKey:@"sessionId"];
            stringToSend = [[MOKSecurityManager sharedInstance] generateAndEncryptAESKey];
        }else{
//                if (!([[MOKSecurityManager sharedInstance].keychainStore stringForKey:msg.userIdFrom].length>2)) {
            NSLog(@"MONKEY - my session: %@", [MOKSessionManager sharedInstance].sessionId);
            NSLog(@"MONKEY - my keys: %@", [[MOKSecurityManager sharedInstance].keychainStore stringForKey:[MOKSessionManager sharedInstance].sessionId]);
            NSString *mygeneratedKeys = [[MOKSecurityManager sharedInstance].keychainStore stringForKey:[MOKSessionManager sharedInstance].sessionId];
            
            if (!(mygeneratedKeys.length >2)) {
                stringToSend = [[MOKSecurityManager sharedInstance] generateAndEncryptAESKey];
            }else{
                stringToSend =[[MOKSecurityManager sharedInstance]rsaEncryptBase64String:[[MOKSecurityManager sharedInstance].keychainStore stringForKey:[MOKSessionManager sharedInstance].sessionId] withPublicKeyIdentifier:AUTHENTICATION_PUBKEY];
            }
        }
        
        NSDictionary * requestConnectObject = @{@"session_id": [MOKSessionManager sharedInstance].sessionId,
                                                @"usk": stringToSend,
                                                @"session_name": [[MOKSessionManager sharedInstance].user getDictionary]
                                                };
        
        NSDictionary *secondparameters = @{@"data": [self.jsonWriter stringWithObject:requestConnectObject]};
        
        NSLog(@"MONKEY - second handshake parameters: %@", secondparameters);
        [self POST:AUTHENTICATION_CONNECT_URL parameters:secondparameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *responseDict2 = responseObject;
            NSLog(@"MONKEY - second handshake response: %@", responseDict2);
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


#pragma mark - Open conversation
- (NSDictionary*)openConversationRequestObject:(NSString *)mySessionid withMyName:(NSString *)fullname to:(NSString *)sessionId {
    return [NSDictionary dictionaryWithObjectsAndKeys:mySessionid, @"session_id", sessionId, @"user_to", fullname, @"name", nil];
}
-(void)keyExchangeWith:(NSString *)sessionId delegate:(id<MOKAPIConnectorDelegate>)delegate{
    
    NSDictionary *requestObject = @{@"session_id": [MOKSessionManager sharedInstance].sessionId,
                                    @"user_to": sessionId
                                    };
//    id requestObject = [self openConversationRequestObject:[[MOKSessionManager sharedInstance] sessionId] withMyName:[MOKSessionManager sharedInstance].userName to:sessionId];
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
//    [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:OPEN_CONVERSATION okSelector:okSelector failSelector:failSelector delegate:delegate];
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    NSLog(@"MONKEY - parameters key exchange: %@", parameters);
    
    [self POST:OPEN_CONVERSATION parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        if([[responseDict objectForKey:@"error"] intValue] != 0){
            [delegate onOpenConversationWrong];
            return;
        }
        NSLog(@"MONKEY - %@", responseObject);
        NSString *decryptedKey = [[MOKSecurityManager sharedInstance]aesDecryptAndStoreKeyFromStringBase64:[responseDict objectForKey:@"convKey"] fromUser:[responseDict objectForKey:@"session_to"]];
        
        NSLog(@"MONKEY - checking session id: %@", [responseDict objectForKey:@"session_to"]);
        NSLog(@"MONKEY - decryptedkey:%@", decryptedKey);
        
        NSLog(@"MONKEY - sessionidto: %@", [responseDict objectForKey:@"session_to"]);
        NSLog(@"MONKEY - stored aes: %@", [[MOKSecurityManager sharedInstance]getAESbase64forUser:[responseDict objectForKey:@"session_to"]]);
        NSLog(@"MONKEY - stored iv: %@", [[MOKSecurityManager sharedInstance]getIVbase64forUser:[responseDict objectForKey:@"session_to"]]);
        
        [delegate onOpenConversationOK:[responseDict objectForKey:@"convKey"]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        [delegate onOpenConversationWrong];
    }];
    
}

#pragma mark - Service Ticket
-(void)openServiceTicket:(NSString *)conversationId to:(NSString *)companyid withUsername:(NSString *)username delegate:(id<MOKAPIConnectorDelegate>)delegate{

    NSDictionary *requestObject = @{@"company_id": companyid,
                                    @"session_id": [MOKSessionManager sharedInstance].sessionId,
                                    @"name": username
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:OPEN_TICKET parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [delegate onOpenServiceTicketOK];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - Error: %@", error);
        [delegate onOpenServiceTicketWrong];
    }];
}

#pragma mark - Send File
-(void)sendFile:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate{
    
    NSDictionary *requestObject =@{@"sid":message.userIdFrom,
                                   @"rid":message.userIdTo,
                                   @"params":message.params};
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    NSLog(@"MONKEY - parameters del send file: %@", parameters);
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    [self POST:SEND_FILE_URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:message.encryptedText] name:@"file" error:nil];
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"MONKEY - %@ %@", task, responseObject);
        NSDictionary *responseDict = responseObject;
        message.oldMessageId = message.messageId;
        message.messageId = [[responseDict objectForKey:@"messageId"] integerValue];
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
-(void)downloadFile:(MOKMessage *)message withDelegate:(id<MOKAPIConnectorDelegate>)delegate{
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:DOWNLOAD_FILE_URL,[message.messageText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
//    NSURLRequest *request = [NSURLRequest requestWithURL:URL];  atFilePath:(NSString *)filePath
    NSLog(@"MONKEY - url %@", URL);
    NSMutableString *loginString = (NSMutableString*)[@"" stringByAppendingFormat:@"%@:%@", [MOKSessionManager sharedInstance].appId, [MOKSessionManager sharedInstance].appKey];
    
    // employ the Base64 encoding above to encode the authentication tokens
    NSString *encodedLoginData = [[loginString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    // create the contents of the header
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginData];
    
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    
    
    [requestM addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:requestM progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSLog(@"MONKEY - destination block");
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        
        NSURL *folderPath;
        NSURL *documentsAndFilename;
        if ([message isGroupMessage]) {
            folderPath = [documentsDirectoryURL URLByAppendingPathComponent:message.userIdTo];
            documentsAndFilename = [documentsDirectoryURL URLByAppendingPathComponent:[message.userIdTo stringByAppendingPathComponent:[response suggestedFilename]]];
        }else{
            folderPath = [documentsDirectoryURL URLByAppendingPathComponent:message.userIdFrom];
            documentsAndFilename = [documentsDirectoryURL URLByAppendingPathComponent:[message.userIdFrom stringByAppendingPathComponent:[response suggestedFilename]]];
        }
        
        
        [[NSFileManager defaultManager] createDirectoryAtURL:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        
        return documentsAndFilename;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSLog(@"MONKEY - Response: %@", response);
        NSLog(@"MONKEY - Error: %@", error);
        NSLog(@"MONKEY - File downloaded to: %@", filePath);
        if (error) {
            [delegate onDownloadFileFail:message];
        }else{
            message.messageText = [filePath path];
            [delegate onDownloadFileOK:message];
        }
        
    }];

    [downloadTask resume];
}
#pragma mark - Groups
-(void)createGroupWithMembers:(NSArray *)members
     andParams:(NSDictionary *)params
          delegate:(id<MOKAPIConnectorDelegate>)delegate{
    NSDictionary *requestObject = @{@"session_id" : [MOKSessionManager sharedInstance].sessionId,
                                    @"members": [members componentsJoinedByString:@","],
                                    @"info":params? params : @{}
                                    };

    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    NSLog(@"MONKEY - parameters de crear grupo: %@", parameters);
    [self POST:CREATE_GROUP_URL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = [responseObject objectForKey:@"resp"];
        NSLog(@"MONKEY - response: %@", responseObject);
        NSLog(@"MONKEY - error: %ld", (long)[[responseObject objectForKey:@"error"] integerValue]);
        NSLog(@"MONKEY - group id: %@", [responseDict objectForKey:@"group_id"]);
        if ([[responseObject objectForKey:@"error"] integerValue] != 0) {
            [delegate onCreateGroupFail:@"fail"];
            return;
        }
        
        [delegate onCreateGroupOK:[responseDict objectForKey:@"group_id"]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [delegate onCreateGroupFail:@"fail"];
        NSLog(@"MONKEY - falló crear grupo, task:%@ error: %@",task, error);
    }];
}

- (void)addMember:(NSString *)sessionId toGroup:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate{
    
    NSDictionary *requestObject = @{@"session_id" : [MOKSessionManager sharedInstance].sessionId,
                                    @"new_member": sessionId,
                                    @"group_id":groupId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    [self POST:ADD_MEMBER_GROUP_URL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        
        if ([[responseDict objectForKey:@"error"] intValue] != 0) {//wrong login
            [delegate onAddMemberToGroupFail:@"error"];
            return;
        }
        [delegate onAddMemberToGroupOK:@"OK"];
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
    
    [self POST:REMOVE_MEMBER_GROUP_URL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        
        if ([[responseDict objectForKey:@"error"] intValue] != 0) {//wrong login
            [delegate onRemoveMemberFromGroupFail:@"error"];
            return;
        }
        [delegate onRemoveMemberFromGroupOK:@"OK"];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [delegate onRemoveMemberFromGroupFail:@"error"];
    }];
}

-(void)getGroupInfo:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate{
    NSDictionary *requestObject = @{@"group_id":groupId
                                    };
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    NSLog(@"MONKEY - getGroupinfo parameters: %@", parameters);
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[MOKSessionManager sharedInstance].appId password:[MOKSessionManager sharedInstance].appKey];
    
    [self POST:GET_GROUP_INFO_URL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"MONKEY - get group response: %@", responseObject);
        NSDictionary *responseDict = responseObject;
        
        if ([[responseDict objectForKey:@"error"] intValue] != 0) {//wrong login
            [delegate onGetGroupInfoFail:@"error"];
            return;
        }
        NSDictionary *response = [responseDict objectForKey:@"resp"];
        
        NSArray *members=[response objectForKey:@"members"];
        NSDictionary *groupinfo=(NSDictionary *)[response objectForKey:@"group_info"];
        
        [delegate onGetGroupInfoOK:groupinfo andMembers:members];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"MONKEY - get group error: %@", error);
        [delegate onGetGroupInfoFail:@"error"];
    }];
    
}
#pragma mark - --- General ---
+ (MOKAPIConnector *)sharedInstance
{
    static MOKAPIConnector *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    }
    
    return sharedInstance;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.responseSerializer.acceptableContentTypes = [self.responseSerializer.acceptableContentTypes setByAddingObject:@"application/octet-stream"];
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.jsonWriter = [MOKSBJsonWriter new];
        AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
        [securityPolicy setAllowInvalidCertificates:YES];
        self.securityPolicy = securityPolicy;
//        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

@end
