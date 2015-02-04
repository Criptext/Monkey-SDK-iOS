//
//  APIConnector.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/2/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIHTTPRequest;

@protocol APIConnectorDelegate <NSObject>
@optional
-(void)onLoginOkWithSessionId:(NSString *)sessionId publicKey:(NSString *)publicKey;
-(void)onLoginFail;
-(void)onLoginWrong;


@end

@interface APIConnector : NSObject{
    NSMutableArray *requests;
}

- (void)secureLoginWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id<APIConnectorDelegate>)delegate;

@end
