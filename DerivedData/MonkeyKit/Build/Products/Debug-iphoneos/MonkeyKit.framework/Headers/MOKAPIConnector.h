//
//  APIConnector.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/2/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"
#import "MOKutils.h"
@class MOKUser;

@protocol MOKAPIConnectorDelegate <NSObject>
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

@interface MOKAPIConnector : AFHTTPSessionManager
+(MOKAPIConnector *)sharedInstance;
/**
 * Authenticate with Criptext Servers
 * @param developerID	Token provided by Criptext
 * @param password		Password provided by Criptext
 * @callback
 */
- (void)secureAuthenticationWithDeveloperId:(NSString *)developerID password:(NSString *)password andUser:(MOKUser *)user delegate:(id)delegate;

-(void)openConversation:(NSString *)conversationId delegate:(id<MOKAPIConnectorDelegate>)delegate;

-(void)openServiceTicket:(NSString *)conversationId to:(NSString *)companyid delegate:(id<MOKAPIConnectorDelegate>)delegate;

-(void)sendFileWithPath:(NSURL *)path toUser:(NSString *)userIdTo messageId:(MOKMessageId)messageId ephemeral:(NSString *)ephemeral andType:(NSString *)fileType delegate:(id<MOKAPIConnectorDelegate>)delegate;
-(void)downloadFile:(NSString *)fileName;

- (NSString*)postBodyForMethod:(NSString*)method data:(id)dataAsJsonComparableObject;

//- (void)authenticateAndConnectWithDeveloperId:(NSString *)developerID password:(NSString *)password delegate:(id)delegate;

@end
