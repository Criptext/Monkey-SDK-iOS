//
//  APIConnector.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/2/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import "MOKutils.h"
@class MOKUser;
@class MOKMessage;
@class MOKSBJsonWriter;

@protocol MOKAPIConnectorDelegate <NSObject>
@optional
/**
 * These callbacks must be
 * @callback
 */

-(void)onDownloadFileOK;
-(void)onDownloadFileDecryptionWrong;
-(void)onDownloadFileFail:(NSString *)error;

-(void)onUploadFileOK:(MOKMessage *)message;
-(void)onUploadFileFail:(MOKMessage *)message;

-(void)onAuthenticationOkWithSessionId:(NSString *)sessionId publicKey:(NSString *)publicKey;
-(void)onAuthenticationFail;
-(void)onAuthenticationWrong;

-(void)onNewKeysReceived:(NSString *)aesKeys withPendingMessage:(MOKMessage *)message;
-(void)onSameKeysReceivedWithPendingMessage:(MOKMessage *)message;
-(void)onKeysExchangeWrongWithPendingMessage:(MOKMessage *)message;
-(void)onKeysExchangeFailWithPendingMessage:(MOKMessage *)message;

-(void)onOpenServiceTicketOK;
-(void)onOpenServiceTicketWrong;

-(void)onCreateGroupOK:(NSString *)groupId;
-(void)onCreateGroupFail:(NSString *)descriptionError;

-(void)onAddMemberToGroupOK:(NSString *)newMemberId;
-(void)onAddMemberToGroupFail:(NSString *)descriptionError;

-(void)onRemoveMemberFromGroupOK:(NSString *)ok;
-(void)onRemoveMemberFromGroupFail:(NSString *)descriptionError;

-(void)onGetGroupInfoOK:(NSDictionary *)groupInfo andMembers:(NSArray *)members;
-(void)onGetGroupInfoFail:(NSString *)descriptionError;

@end

@interface MOKAPIConnector : AFHTTPSessionManager
@property (nonatomic, strong) MOKSBJsonWriter *jsonWriter;
@property (nonatomic, strong) NSString *baseurl;
+(MOKAPIConnector *)sharedInstance;
/**
 * Authenticate with Criptext Servers
 * @param developerID	Token provided by Criptext
 * @param password		Password provided by Criptext
 * @callback
 */
- (void)pushSubscribeDevice:(NSData *)deviceToken forSessionId:(NSString *)sessionId withAppID:(NSString *)appID andAppKey:(NSString *)appKey inProduction:(BOOL)flag;

- (void)secureAuthenticationWithAppId:(NSString *)appID
                               appKey:(NSString *)appKey
                                 user:(NSMutableDictionary *)username
                        andExpiration:(BOOL)expires
                             delegate:(id)delegate;

-(void)getRegisteredAESkeysForSessionId:(NSString *)sessionId withAppId:(NSString *)appId andAppKey:(NSString *)appKey delegate:(id<MOKAPIConnectorDelegate>)delegate;

-(void)keyExchangeWith:(NSString *)sessionId withPendingMessage:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate;

-(void)getEncryptedTextForMessage:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate;
-(void)sendFile:(MOKMessage *)message delegate:(id<MOKAPIConnectorDelegate>)delegate;

//-(void)downloadFile:(MOKMessage *)message withDelegate:(id<MOKAPIConnectorDelegate>)delegate;
-(void)downloadFile:(NSString *)name
      fileExtension:(NSString *)extension
           fromUser:(NSString *)userIdFrom
  folderDestination:(NSString *)folderName
          encrypted:(BOOL)encrypted
         compressed:(BOOL)compressed
             device:(NSString *)device
       withDelegate:(id<MOKAPIConnectorDelegate>)delegate;

-(void)createGroupWithMembers:(NSArray *)members
                   withParams:(NSDictionary *)params
                      andPush:(NSString *)push
                     delegate:(id<MOKAPIConnectorDelegate>)delegate;

- (void)addMember:(NSString *)sessionId
          toGroup:(NSString *)groupId
withPushToNewMember:(NSString *)pushNewMember
andPushToAllMembers:(NSString *)pushAllMembers
         delegate:(id <MOKAPIConnectorDelegate>)delegate;

- (void)removeMember:(NSString *)sessionId fromGroup:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate;

-(void)getGroupInfo:(NSString *)groupId delegate:(id <MOKAPIConnectorDelegate>)delegate;

- (NSString*)postBodyForMethod:(NSString*)method data:(id)dataAsJsonComparableObject;

-(void)logout;

@end
