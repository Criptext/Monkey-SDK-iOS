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
-(void)onAuthenticationOkWithSessionId:(NSString *)sessionId publicKey:(NSString *)publicKey;
-(void)onAuthenticationFail;
-(void)onAuthenticationWrong;


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
- (void)secureAuthenticationWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id)delegate;

//- (void)authenticateAndConnectWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id)delegate;

@end
