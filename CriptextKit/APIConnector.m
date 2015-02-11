//
//  APIConnector.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/2/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "APIConnector.h"
#import "ASIFormDataRequest.h"
#import "ASIHTTPRequest.h"
#import "JSON.h"
#import "SecurityManager.h"
#import "ComServerConnection.h"
#import "SocketConnectionManager.h"
#import "SessionManager.h"

//String identifiers
#define AUTHENTICATION_SESSION_URL  @"http://com.criptext.com:3030/user/session"
#define AUTHENTICATION_CONNECT_URL  @"http://com.criptext.com:3030/user/connect"
#define AUTHENTICATION_PUBKEY       @"authentication_pubKey"
#define OPEN_CONVERSATION			@"http://com.criptext.com:3030/user/openconversation"

@interface APIConnector () <ComServerConnectionDelegate>

@end

@implementation APIConnector
typedef enum {
    responseCodeNoData = -4,
    responseCodeNotJsonFormat = -3,
    responseCodeEmptyResponse = -2,
    responseCodeNilRequest = -1,
    responseCodeOk = 0,
    responseCodeWrongSession = 1,
    responseCodeNotWrongRegistration = 10,
    responseCodeNotAgree = 11,
    responseCodeNoFbAccessToken = 12,
} ResponseCode;

typedef enum{
    request_login_authentication,
    request_login_session,
    request_open_conversation
} requestType;

typedef struct {
    NSString *sessionId;
    NSString *sessionIdTo;
    NSString *key;
    int errorCode;
    NSString *descriptionerror;
} StructedResponse;

#pragma mark - --- Create Requests ---
- (NSDictionary*)getSessionRequestObject:(NSString *)mail password:(NSString *)password  {
    
    return [NSDictionary dictionaryWithObjectsAndKeys:mail, @"username", password, @"password", nil];
}
- (NSDictionary*)secureAuthenticationRequestObject:(NSString *)sessionId aesKey:(NSString *)aesKey  {
    
    return [NSDictionary dictionaryWithObjectsAndKeys:sessionId, @"session_id", aesKey, @"usk", nil];
}
- (void)sendGetRequestWithCustomDomainAndAuth:(id)requestObject urlService:(NSString*)urlService okSelector:(SEL)okSelecor failSelector:(SEL)failSelector delegate:(id<APIConnectorDelegate>)delegate {
    [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:urlService developerId:nil password:nil okSelector:okSelecor failSelector:failSelector delegate:delegate];
}

- (void)sendGetRequestWithCustomDomainAndAuth:(id)requestObject urlService:(NSString*)urlService developerId:(NSString *)developerID password:(NSString *)password okSelector:(SEL)okSelecor failSelector:(SEL)failSelector delegate:(id<APIConnectorDelegate>)delegate {
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlService]];
    request.delegate = self;
    
    if (developerID != nil && password != nil) {
        [request setUsername:developerID];
        [request setPassword:password];
    }
    
    [request setRequestMethod:@"POST"];
    
    SBJsonWriter *jsonWriter = [SBJsonWriter new];
    
    //NSLog(@"sendBlipRequest auth %@", [jsonWriter stringWithObject:requestObject]);
    
    if(requestObject!=nil){
        [request addPostValue:[jsonWriter stringWithObject:requestObject] forKey:@"data"];
    }
    
    [request setDidFinishSelector:okSelecor];
    [request setDidFailSelector:failSelector];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setCacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    [self addRequest:request];
    [self setDelegate:delegate forRequest:request];
    
    [request startAsynchronous];
}


#pragma mark - --- Send Requests ---
#pragma mark - Secure Session Request (first handshake)


- (void)onGetSessionOK:(ASIHTTPRequest *)request{
    StructedResponse response = [self parseResponse:request withRequestType:request_login_session];
    
    //    NSLog(@"LOGIN data %@", response.data);
    
    if (response.errorCode == responseCodeOk) {
        [SessionManager sharedInstance].userPassword = request.password;
                [SessionManager sharedInstance].userId = response.sessionId;
//        [SessionManager sharedInstance].idUser = @"i5zxy8padjvy4pj1el2qpvi";
        [[SecurityManager sharedInstance] storeKey:response.key withIdentifier:AUTHENTICATION_PUBKEY];
        NSString *stringToSend = [[SecurityManager sharedInstance] generateAndEncryptAESKey];
        
        NSLog(@"stringtosend: %@",stringToSend);
        
        id requestObject = [self secureAuthenticationRequestObject:response.sessionId aesKey:stringToSend];
        SEL okSelector = @selector(onSecureAuthenticationOK:);
        SEL failSelector = @selector(onSecureAuthenticationError:);
        
        [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:AUTHENTICATION_CONNECT_URL developerId:request.username password:request.password okSelector:okSelector failSelector:failSelector delegate:[self delegateForRequest:request]];
        
    } else {
        NSLog(@"error: getSession failed");
        switch (response.errorCode) {
            default:
                [[self finalizeRequestAndGetDelegate:request] onAuthenticationWrong];
                break;
        }
        
    }
}

- (void)onGetSessionError:(ASIHTTPRequest *)request {
    NSLog(@"REQ session error");
    [[self finalizeRequestAndGetDelegate:request] onAuthenticationFail];
}

#pragma mark - Secure Authentication Request (second handshake)


- (void)secureAuthenticationWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id)delegate{
    
    id requestObject = [self getSessionRequestObject:developerID password:password];
    SEL okSelector = @selector(onGetSessionOK:);
    SEL failSelector = @selector(onGetSessionError:);
    
    [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:AUTHENTICATION_SESSION_URL developerId:developerID password:password okSelector:okSelector failSelector:failSelector delegate:delegate];
}



- (void)onSecureAuthenticationOK:(ASIHTTPRequest *)request{
    StructedResponse response = [self parseResponse:request withRequestType:request_login_authentication];
    NSLog(@"response errorcode: %d", response.errorCode);
    //        NSLog(@"response key: %@", response.key);
    NSLog(@"response sessionId mio: %@", response.sessionId);
    if (response.errorCode == responseCodeOk) {
        NSLog(@"CONNECT to socket");
        
        [SessionManager sharedInstance].userName = response.sessionId;
//        [SessionManager sharedInstance].userName = @"i5zxy8padjvy4pj1el2qpvi";
        [SessionManager sharedInstance].userId = response.sessionId;
//        [SessionManager sharedInstance].idUser = @"i5zxy8padjvy4pj1el2qpvi";
        NSLog(@"sessionid: %@", response.sessionId);
        
        //        [[ComServerConnection sharedInstance] connectWithDelegate:[self delegateForRequest:request] isFirst:YES];
        [[self finalizeRequestAndGetDelegate:request] onAuthenticationOkWithSessionId:response.sessionId publicKey:response.key];
    } else {
        NSLog(@"error: securelogin failed");
        switch (response.errorCode) {
            default:
                [[self finalizeRequestAndGetDelegate:request] onAuthenticationWrong];
                break;
        }
    }
    
}



- (void)onSecureAuthenticationError:(ASIHTTPRequest *)request{
    NSLog(@"REQ login error");
    [[self finalizeRequestAndGetDelegate:request] onAuthenticationFail];
}








#pragma mark - Open conversation
- (NSDictionary*)openConversationRequestObject:(NSString *)mySessionid to:(NSString *)sessionId {
    return [NSDictionary dictionaryWithObjectsAndKeys:mySessionid, @"session_id", sessionId, @"user_to", nil];
}
-(void)openConversation:(NSString *)conversationId delegate:(id<APIConnectorDelegate>)delegate{
    
    id requestObject = [self openConversationRequestObject:[[SessionManager sharedInstance] userId] to:conversationId];
    SEL okSelector = @selector(onOpenConversationOK:);
    SEL failSelector = @selector(onOpenConversationError:);
    
    [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:OPEN_CONVERSATION okSelector:okSelector failSelector:failSelector delegate:delegate];
}

- (void)onOpenConversationOK:(ASIHTTPRequest *)request{
    StructedResponse response = [self parseResponse:request withRequestType:request_open_conversation];
    
//    NSLog(@"response errorcode: %d", response.errorCode);
//    NSLog(@"response key: %@", response.key);
//    NSLog(@"response sessionIdTo: %@", response.sessionIdTo);
    
    if (response.errorCode == responseCodeOk) {
        
        NSLog(@"Ok open conversation");
        NSLog(@"response key: %@", response.key);
        NSString *decryptedKey = [[SecurityManager sharedInstance]aesDecryptAndStoreKeyFromStringBase64:response.key fromUser:response.sessionIdTo];

        NSLog(@"checking session id: %@", response.sessionIdTo);
        NSLog(@"decryptedkey:%@", decryptedKey);
//        [[SecurityManager sharedInstance]storeBase64AESKeyAndIV:decryptedKey forUser:response.sessionIdTo];
//        [[SecurityManager sharedInstance]storeBase64AESKeyAndIV:decryptedKey forUser:response.sessionIdTo];
        NSLog(@"sessionidto: %@", response.sessionIdTo);
        NSLog(@"stored aes: %@", [[SecurityManager sharedInstance]getAESbase64forUser:response.sessionIdTo]);
        NSLog(@"stored iv: %@", [[SecurityManager sharedInstance]getIVbase64forUser:response.sessionIdTo]);
        
        [[self finalizeRequestAndGetDelegate:request] onOpenConversationOK: response.key];
        
        
    } else {
        NSLog(@"error: openconversation failed");
        switch (response.errorCode) {
            default:
                [[self finalizeRequestAndGetDelegate:request] onOpenConversationWrong];
                break;
        }
        
    }
}

-(void)onOpenConversationError:(ASIHTTPRequest *)request{
    NSLog(@"murió el open");
}
#pragma mark - --- Parsing Responses ---
- (StructedResponse)parseResponse:(ASIHTTPRequest*)request withRequestType:(requestType)requestType{
    StructedResponse response;
    response.sessionId = nil;
    response.key = nil;
    response.errorCode = responseCodeOk;
    if (request == nil) {
        response.errorCode = responseCodeNilRequest;
        return response;
    }
    NSString *responseString = [request responseString];
    if ([responseString length] == 0) {
        response.errorCode = responseCodeEmptyResponse;
        return response;
    }
    SBJSON *jsonParser = [SBJSON new];
    NSDictionary *dictionary = [jsonParser objectWithString:responseString error:nil];
    [jsonParser release];
    if (dictionary == nil) {
        response.errorCode = responseCodeNotJsonFormat;
        return response;
    }
    
    //extract data
    switch (requestType) {
        case request_login_authentication: case request_login_session:
            response.sessionId = [dictionary objectForKey:@"sessionId"];
            response.key = [dictionary objectForKey:@"publicKey"];
            response.errorCode = [[dictionary objectForKey:@"error"] intValue];
            break;
            
        case request_open_conversation:
            response.sessionId = [dictionary objectForKey:@"sessionId"];
            response.sessionIdTo = [dictionary objectForKey:@"session_to"];
            response.key = [dictionary objectForKey:@"convKey"];
            response.errorCode = [[dictionary objectForKey:@"error"] intValue];
            break;
        default:
            break;
    }
    
    if (response.errorCode == 0) {
        if (response.sessionId == nil) {
            response.errorCode = responseCodeNoData;
        }
    } else {
        response.descriptionerror=[dictionary objectForKey:@"descriptionerror"];
        switch (response.errorCode) {
            case responseCodeWrongSession:
                break;
            default:
                break;
        }
    }
    
    return response;
    

}

#pragma mark - --- General ---

- (id)init {
    if (self = [super init]) {
        requests = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addRequest:(ASIHTTPRequest*)request {
    @synchronized (self) {
        [requests addObject:request];
        [request release];
    }
}

- (void)removeRequest:(ASIHTTPRequest*)request {
    @synchronized (self) {
        request.delegate = nil;
        request.userInfo = nil;
        [requests removeObject:request];
    }
}

- (void)cancelAllRequests {
    @synchronized (self) {
        for (int i = [requests count] - 1; i >= 0; i--) {
            ASIHTTPRequest *request = [requests objectAtIndex:i];
            request.delegate = nil;
            request.userInfo = nil;
            [request cancel];
            [requests removeLastObject];
        }
    }
}

- (id <APIConnectorDelegate>)finalizeRequestAndGetDelegate:(ASIHTTPRequest*)request {
    id <APIConnectorDelegate> requestDelegate = [self delegateForRequest:request];
    request.userInfo = nil;
    [self removeRequest:request];
    return requestDelegate;
}

- (void)setDelegate:(id <APIConnectorDelegate>)delegate forRequest:(ASIHTTPRequest*)request {
    [request setUserInfo:[NSMutableDictionary dictionaryWithObject:delegate forKey:@"wd"]];
}

- (id <APIConnectorDelegate>)delegateForRequest:(ASIHTTPRequest*)request {
    return (id <APIConnectorDelegate>)[request.userInfo objectForKey:@"wd"];
}

- (void)die {
    [self cancelAllRequests];
    [self release];
}

- (void)dealloc {
    [super dealloc];
}
@end
