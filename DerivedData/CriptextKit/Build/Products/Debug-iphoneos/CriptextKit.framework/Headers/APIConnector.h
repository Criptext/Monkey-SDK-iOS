//
//  APIConnector.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/2/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIHTTPRequest;
@class BLUser;

@protocol APIConnectorDelegate <NSObject>
@optional
/**
 * These callbacks must be
 * @callback
 */
-(void)onAuthenticationOkWithSessionId:(NSString *)sessionId publicKey:(NSString *)publicKey;
-(void)onAuthenticationFail;
-(void)onAuthenticationWrong;

-(void)onOpenConversationOK:(NSString *)key;
-(void)onOpenConversationWrong;

-(void)onOpenServiceTicketOK;
-(void)onOpenServiceTicketWrong;

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
- (void)secureAuthenticationWithDeveloperId:(NSString *)developerID password:(NSString *)password andUser:(BLUser *)user delegate:(id)delegate;

-(void)openConversation:(NSString *)conversationId delegate:(id<APIConnectorDelegate>)delegate;

-(void)openServiceTicket:(NSString *)conversationId to:(NSString *)companyid delegate:(id<APIConnectorDelegate>)delegate;

//- (void)authenticateAndConnectWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id)delegate;

@end
