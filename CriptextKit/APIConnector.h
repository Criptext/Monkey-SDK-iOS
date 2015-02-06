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
/**
 * These callbacks must be
 * @callback
 */
-(void)onLoginOkWithSessionId:(NSString *)sessionId publicKey:(NSString *)publicKey;
-(void)onLoginFail;
-(void)onLoginWrong;


@end

@interface APIConnector : NSObject{
    NSMutableArray *requests;
}

/**
 * Authenticate with Criptext Servers
 * @param developerID	Token provided by Criptext
 * @param password		Password provided by Criptext
 * @callback
 */
- (void)secureLoginWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id)delegate;

@end
