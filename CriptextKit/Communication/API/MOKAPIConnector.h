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
-(void)onDownloadFileFail:( NSString * _Nullable)error;

-(void)onUploadFileOK:(MOKMessage * _Nullable)message;
-(void)onUploadFileFail:(MOKMessage * _Nullable)message;

-(void)onAuthenticationOkWithSessionId:(NSString * _Nullable)sessionId publicKey:(NSString * _Nullable)publicKey;
-(void)onAuthenticationFail;
-(void)onAuthenticationWrong;

-(void)onNewKeysReceived:(NSString * _Nullable)aesKeys withPendingMessage:(MOKMessage * _Nullable)message;
-(void)onSameKeysReceivedWithPendingMessage:(MOKMessage * _Nullable)message;
-(void)onKeysExchangeWrongWithPendingMessage:(MOKMessage * _Nullable)message;
-(void)onKeysExchangeFailWithPendingMessage:(MOKMessage * _Nullable)message;

-(void)onOpenServiceTicketOK;
-(void)onOpenServiceTicketWrong;

-(void)onCreateGroupOK:(NSString * _Nullable)groupId;
-(void)onCreateGroupFail:(NSString * _Nullable)descriptionError;

-(void)onAddMemberToGroupOK:(NSString * _Nullable)newMemberId;
-(void)onAddMemberToGroupFail:(NSString * _Nullable)descriptionError;

-(void)onRemoveMemberFromGroupOK:(NSString * _Nullable)ok;
-(void)onRemoveMemberFromGroupFail:(NSString * _Nullable)descriptionError;

-(void)onGetGroupInfoOK:(NSDictionary * _Nullable)groupInfo andMembers:(NSArray * _Nullable)members;
-(void)onGetGroupInfoFail:(NSString * _Nullable)descriptionError;

@end

@interface MOKAPIConnector : AFHTTPSessionManager
@property (nonatomic, strong) MOKSBJsonWriter * _Nullable jsonWriter;
@property (nonatomic, strong) NSString * _Nullable baseurl;
+(MOKAPIConnector * _Nonnull)sharedInstance;
/**
 * Authenticate with Criptext Servers
 * @param developerID	Token provided by Criptext
 * @param password		Password provided by Criptext
 * @callback
 */
- (void)pushSubscribeDevice:(NSData * _Nonnull)deviceToken forSessionId:(NSString * _Nonnull)sessionId withAppID:(NSString * _Nonnull)appID andAppKey:(NSString * _Nonnull)appKey inProduction:(BOOL)flag;

- (void)secureAuthenticationWithAppId:(NSString * _Nonnull)appID
                               appKey:(NSString * _Nonnull)appKey
                                 user:(NSDictionary * _Nullable)user
                        andExpiration:(BOOL)expires
                              success:(nullable void (^)(NSDictionary * _Nonnull data))success
                              failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error))failure;

-(void)getRegisteredAESkeysForSessionId:(NSString * _Nonnull)sessionId withAppId:(NSString * _Nonnull)appId andAppKey:(NSString * _Nonnull)appKey delegate:(id<MOKAPIConnectorDelegate> _Nullable)delegate;

-(void)keyExchangeWith:(NSString * _Nonnull)sessionId withPendingMessage:(MOKMessage * _Nullable)message delegate:(id<MOKAPIConnectorDelegate> _Nullable)delegate;

-(void)getEncryptedTextForMessage:(MOKMessage * _Nonnull)message delegate:(id<MOKAPIConnectorDelegate> _Nullable)delegate;
-(void)sendFile:(MOKMessage * _Nonnull)message delegate:(id<MOKAPIConnectorDelegate> _Nullable)delegate;

-(void)downloadFileMessage:(MOKMessage * _Nonnull)message
         folderDestination:(NSString * _Nonnull)folderName
              withDelegate:(id<MOKAPIConnectorDelegate> _Nullable)delegate;

-(void)createGroupWithMembers:(NSArray * _Nonnull)members
                   withParams:(NSDictionary * _Nullable)params
                      andPush:(NSString * _Nullable)push
                     delegate:(id<MOKAPIConnectorDelegate> _Nullable)delegate;

- (void)addMember:(NSString * _Nonnull)sessionId
          toGroup:(NSString * _Nonnull)groupId
withPushToNewMember:(NSString * _Nullable)pushNewMember
andPushToAllMembers:(NSString * _Nullable)pushAllMembers
         delegate:(id <MOKAPIConnectorDelegate> _Nullable)delegate;

- (void)removeMember:(NSString * _Nonnull)sessionId fromGroup:(NSString * _Nonnull)groupId delegate:(id <MOKAPIConnectorDelegate> _Nullable)delegate;

-(void)getGroupInfo:(NSString * _Nonnull)groupId delegate:(id <MOKAPIConnectorDelegate> _Nullable)delegate;

- (NSString* _Nullable)postBodyForMethod:(NSString* _Nonnull)method data:(id _Nonnull)dataAsJsonComparableObject;

-(void)logout;

@end
