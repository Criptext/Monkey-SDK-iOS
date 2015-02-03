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

typedef struct {
    NSString *sessionId;
    NSString *publicKey;
    int errorCode;
    NSString *descriptionerror;
} StructedResponse;

#pragma mark - --- Create Requests ---

- (void)sendGetRequestWithCustomDomainAndAuth:(id)requestObject urlService:(NSString*)urlService developerId:(NSString *)developerID password:(NSString *)password okSelector:(SEL)okSelecor failSelector:(SEL)failSelector delegate:(id<APIConnectorDelegate>)delegate {
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlService]];
    request.delegate = self;
    
    [request setRequestMethod:@"POST"];
    [request setUsername:developerID];
    [request setPassword:password];
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

#pragma mark - Secure Login Request
- (NSDictionary*)secureLoginRequestObject:(NSString *)mail password:(NSString *)password  {
    
    return [NSDictionary dictionaryWithObjectsAndKeys:mail, @"username", password, @"password", nil];
}

- (void)secureLoginWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id<APIConnectorDelegate>)delegate{
    
    id requestObject = [self secureLoginRequestObject:developerID password:password];
    SEL okSelector = @selector(onSecureLoginOK:);
    SEL failSelector = @selector(onSecureLoginError:);
    
    [self sendGetRequestWithCustomDomainAndAuth:requestObject urlService:@"http://com.criptext.com:3030/user/session" developerId:developerID password:password okSelector:okSelector failSelector:failSelector delegate:delegate];
}

- (void)onSecureLoginOK:(ASIHTTPRequest *)request {
    StructedResponse response = [self parseSecureLoginResponse:request];
    
    //    NSLog(@"LOGIN data %@", response.data);
    
    if (response.errorCode == responseCodeOk) {
        
        [[self finalizeRequestAndGetDelegate:request] onLoginWithSessionId:response.sessionId publicKey:response.publicKey];
        
    } else {
        //NSLog(@"error:%@",response.descriptionerror);
        switch (response.errorCode) {
            default:
                [[self finalizeRequestAndGetDelegate:request] onLoginWrong];
                break;
        }
        
    }
}

- (void)onSecureLoginError:(ASIHTTPRequest *)request {
    NSLog(@"REQ login error");
    [[self finalizeRequestAndGetDelegate:request] onLoginFail];
}

#pragma mark - --- Parsing Responses ---

- (StructedResponse)parseSecureLoginResponse:(ASIHTTPRequest*)request {
    StructedResponse response;
    response.sessionId = nil;
    response.publicKey = nil;
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
    response.sessionId = [dictionary objectForKey:@"sessionId"];
    response.publicKey = [dictionary objectForKey:@"publicKey"];
    response.errorCode = [[dictionary objectForKey:@"error"] intValue];
    if (response.errorCode == 0) {
        if (response.sessionId == nil) {
            response.errorCode = responseCodeNoData;
        }
    } else {
        response.descriptionerror=[dictionary objectForKey:@"descriptionerror"];
        //NSLog(@"description error:%@",[dictionary objectForKey:@"descriptionerror"]);
        switch (response.errorCode) {
            case responseCodeWrongSession:
                //[[MainMenuViewController appController] logout];
                //[BlipAppDelegate activityReset];
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
