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
#import "MOKSessionManager.h"
#import "MOKUser.h"
#import "AFNetworking.h"


//String identifiers
#define BASE_URL					@"http://com.criptext.com:3030"
#define OLD_BASE_URL				@"https://api.criptext.com/"
#define SEND_FILE_URL				@"http://com.criptext.com:3030/file/new"
#define DOWNLOAD_FILE_URL			@"http://com.criptext.com:3030/file/open/%@"
#define AUTHENTICATION_SESSION_URL  @"http://com.criptext.com:3030/user/session"
#define AUTHENTICATION_CONNECT_URL  @"http://com.criptext.com:3030/user/connect"

#define AUTHENTICATION_PUBKEY       @"authentication_pubKey"
#define OPEN_CONVERSATION			@"http://com.criptext.com:3030/user/openconversation"
#define OPEN_TICKET					@"http://com.criptext.com:3030/user/call"

@interface MOKAPIConnector () <MOKComServerConnectionDelegate>
@property (nonatomic, strong) MOKSBJsonWriter *jsonWriter;
@end

@implementation MOKAPIConnector
//typedef enum {
//    responseCodeNoData = -4,
//    responseCodeNotJsonFormat = -3,
//    responseCodeEmptyResponse = -2,
//    responseCodeNilRequest = -1,
//    responseCodeOk = 0,
//    responseCodeWrongSession = 1,
//    responseCodeNotWrongRegistration = 10,
//    responseCodeNotAgree = 11,
//    responseCodeNoFbAccessToken = 12,
//} ResponseCode;

#pragma mark - --- Create Requests ---
- (NSDictionary*)getSessionRequestObject:(NSString *)mail password:(NSString *)password  {
    
    return [NSDictionary dictionaryWithObjectsAndKeys:mail, @"username", password, @"password", nil];
}
- (NSDictionary*)secureAuthenticationRequestObject:(NSString *)sessionId aesKey:(NSString *)aesKey withUsername:(NSString *)username  {
    
    return [NSDictionary dictionaryWithObjectsAndKeys:sessionId, @"session_id", aesKey, @"usk", username, @"session_name", nil];
}
- (NSDictionary*)openConversationRequestObject:(NSString *)mySessionid withMyName:(NSString *)fullname to:(NSString *)sessionId {
    return [NSDictionary dictionaryWithObjectsAndKeys:mySessionid, @"session_id", sessionId, @"user_to", fullname, @"name", nil];
}

#pragma mark - --- Send Requests ---

#pragma mark - Secure Authentication Request
- (void)secureAuthenticationWithDeveloperId:(NSString *)developerID password:(NSString *)password andUser:(MOKUser *)user delegate:(id)delegate{
//    
    id requestObject = [self getSessionRequestObject:developerID password:password];
    
    [MOKSessionManager sharedInstance].me = user;
    [MOKSessionManager sharedInstance].userPassword = password;
    
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:developerID password:password];

    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};

    [self POST:AUTHENTICATION_SESSION_URL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        
        [MOKSessionManager sharedInstance].userId = [responseDict objectForKey:@"sessionId"];
        [[MOKSecurityManager sharedInstance] storeObject:[responseDict objectForKey:@"publicKey"] withIdentifier:AUTHENTICATION_PUBKEY];
        NSString *stringToSend = [[MOKSecurityManager sharedInstance] generateAndEncryptAESKey];
        
        NSLog(@"stringtosend: %@",stringToSend);
        
        id requestObject = [self secureAuthenticationRequestObject:[responseDict objectForKey:@"sessionId"] aesKey:stringToSend withUsername:[[MOKSessionManager sharedInstance].me.params objectForKey:@"fullname"]];
        
        NSDictionary *secondparameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
        [self POST:AUTHENTICATION_CONNECT_URL parameters:secondparameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"%@", responseObject);
            NSDictionary *responseDict2 = responseObject;
            [MOKSessionManager sharedInstance].userId = [responseDict2 objectForKey:@"sessionId"];
            [MOKSessionManager sharedInstance].me.userId = [responseDict2 objectForKey:@"sessionId"];
            
            [delegate onAuthenticationOkWithSessionId:[responseDict2 objectForKey:@"sessionId"] publicKey:[[MOKSecurityManager sharedInstance]getObjectForIdentifier:AUTHENTICATION_PUBKEY]];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"fail en segundo handshake");
            [delegate onAuthenticationWrong];
        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error primer handshake: %@", error);
        [delegate onAuthenticationWrong];
    }];
}


#pragma mark - Open conversation
-(void)openConversation:(NSString *)conversationId delegate:(id<MOKAPIConnectorDelegate>)delegate{
    
    id requestObject = [self openConversationRequestObject:[[MOKSessionManager sharedInstance] userId] withMyName:[[MOKSessionManager sharedInstance].me.params objectForKey:@"fullname"] to:conversationId];
    
    
//    [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:OPEN_CONVERSATION okSelector:okSelector failSelector:failSelector delegate:delegate];
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:OPEN_CONVERSATION parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *responseDict = responseObject;
        
        NSLog(@"Ok open conversation");
        NSLog(@"response key: %@", [responseDict objectForKey:@"convKey"]);
        NSString *decryptedKey = [[MOKSecurityManager sharedInstance]aesDecryptAndStoreKeyFromStringBase64:[responseDict objectForKey:@"convKey"] fromUser:[responseDict objectForKey:@"session_to"]];
        
        NSLog(@"checking session id: %@", [responseDict objectForKey:@"session_to"]);
        NSLog(@"decryptedkey:%@", decryptedKey);
        
        NSLog(@"sessionidto: %@", [responseDict objectForKey:@"session_to"]);
        NSLog(@"stored aes: %@", [[MOKSecurityManager sharedInstance]getAESbase64forUser:[responseDict objectForKey:@"session_to"]]);
        NSLog(@"stored iv: %@", [[MOKSecurityManager sharedInstance]getIVbase64forUser:[responseDict objectForKey:@"session_to"]]);
        
        [delegate onOpenConversationOK:[responseDict objectForKey:@"convKey"]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
        [delegate onOpenConversationWrong];
    }];
    
}

#pragma mark - Service Ticket
- (NSDictionary*)openServiceTicketRequestObject:(NSString *)mySessionid withName:(NSString *)name to:(NSString *)companyid {
    return [NSDictionary dictionaryWithObjectsAndKeys:companyid, @"company_id", mySessionid, @"session_id", name, @"name", nil];
}
-(void)openServiceTicket:(NSString *)conversationId to:(NSString *)companyid delegate:(id<MOKAPIConnectorDelegate>)delegate{

    id requestObject = [self openServiceTicketRequestObject:[[MOKSessionManager sharedInstance] userId] withName:[[MOKSessionManager sharedInstance].me.params objectForKey:@"fullname"] to:companyid];
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:OPEN_TICKET parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [delegate onOpenServiceTicketOK];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
        [delegate onOpenServiceTicketWrong];
    }];
}

#pragma mark - Send File
- (NSDictionary*)sendFileRequestObject:(NSString *)session toUser:(NSString*)userId withId:(MOKMessageId)idMessage ephemeral:(NSString *)ephemeral andType:(NSString *)fileType {
    return [NSDictionary dictionaryWithObjectsAndKeys: [[MOKSessionManager sharedInstance] userId], @"user", ephemeral, @"ephemeral", fileType, @"file_type",userId,@"to_id",[NSString stringWithFormat:@"%lli",idMessage],@"id_message", nil];
}
-(void)sendFileWithPath:(NSURL *)path toUser:(NSString *)userIdTo messageId:(MOKMessageId)messageId ephemeral:(NSString *)ephemeral andType:(NSString *)fileType delegate:(id<MOKAPIConnectorDelegate>)delegate{
    id requestObject = [self sendFileRequestObject:[[MOKSessionManager sharedInstance] userId] toUser:userIdTo withId:messageId ephemeral:ephemeral andType:fileType];
    
    NSDictionary *parameters = @{@"data": [self.jsonWriter stringWithObject:requestObject]};
    
    [self POST:SEND_FILE_URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSLog(@"path : %@", path);
        [formData appendPartWithFileURL:path name:@"file" error:nil];
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"%@ %@", task, responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}

- (NSString*)postBodyForMethod:(NSString*)method data:(id)dataAsJsonComparableObject {
	NSString *result = [self.jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:method,@"request", dataAsJsonComparableObject, @"data", nil]];
	return result;
}

#pragma mark - Download File
-(void)downloadFile:(NSString *)fileName{
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:DOWNLOAD_FILE_URL,fileName]];
//    NSURLRequest *request = [NSURLRequest requestWithURL:URL];  atFilePath:(NSString *)filePath
    
    NSMutableString *loginString = (NSMutableString*)[@"" stringByAppendingFormat:@"%@:%@", @"a348146dea9461653424e271825041da", @"i6454o3aa1x8pz6rw2whr529"];
    
    // employ the Base64 encoding above to encode the authentication tokens
    NSString *encodedLoginData = [[loginString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    // create the contents of the header
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginData];
    
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    
    [requestM addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
//    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:@"a348146dea9461653424e271825041da" password:@"i6454o3aa1x8pz6rw2whr529"];
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:requestM progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"Error: %@", error);
        NSLog(@"File downloaded to: %@", filePath);
    }];
    
    
    [downloadTask resume];
    
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
        
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.jsonWriter = [MOKSBJsonWriter new];
    }
    
    return self;
}

@end
