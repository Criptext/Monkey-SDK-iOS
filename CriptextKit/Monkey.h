//
//  Monkey.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/1/16.
//  Copyright © 2016 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MOKMessage;

@protocol MOKMessageReceiver <NSObject>
@required
- (void)messageReceived:(MOKMessage*)message;
- (void)notificationReceived:(MOKMessage *)notificationMessage;
- (void)acknowledgeReceived:(MOKMessage *)ackMessage;
@end

@interface Monkey : NSObject

+ (instancetype)sharedInstance;

/**
 *  @property appId
 *  @abstract String that identifies your App Id.
 */
@property (copy, nonatomic, readonly) NSString *appId;

/**
 *  @property appKey
 *  @abstract String that identifies your App Key.
 */
@property (copy, nonatomic, readonly) NSString *appKey;

/**
 *  @property domain
 *  @abstract String that identifies the Monkey domain.
 */
@property (copy, nonatomic, readonly) NSString *domain;

/**
 *  @property port
 *  @abstract String that identifies the Monkey port.
 */
@property (copy, nonatomic, readonly) NSString *port;

/**
 *  @property session
 *  @abstract Dictionary which holds session params:
 *  - id -> Monkey Id
 *  - user -> User metadata
 *  - lastTimestamp -> Timestamp of last sync of messages
 *  - expireSession -> Boolean that determines if this monkey id expires with time on server
 *  - debuggingMode -> Boolean that determines development and production environments
 *  - autoSync -> Boolean that determines if the sync of messages should be automatic everytime the socket connects.
 */
@property (copy, nonatomic, readonly) NSMutableDictionary * session;

/**
 *  @param appId          Monkey App's Id
 *  @param appKey         Monkey App's secret
 *  @param user           User metadata
 *  @param shouldExpire   Flag that determines if the newly created Monkey Id should expire
 *  @param isDebugging    Flag that determines if the app is in Development or Production
 *  @param autoSync       Flag that determines if it should request pending messages upon connection
 *  @param lastTimestamp  Optional timestamp value from which pending messages will be fetched
 *
 
 */
-(void)initWithApp:(NSString *)appId
            secret:(NSString *)appKey
              user:(NSDictionary *)user
     expireSession:(BOOL)shouldExpire
         debugging:(BOOL)isDebugging
          autoSync:(BOOL)autoSync
     lastTimestamp:(NSNumber*)lastTimestamp;

/**
 *  Request pending messages
 */
-(void)getPendingMessages;

/**
 *  Request pending messages and request groups to which this monkey id belongs
 */
-(void)getPendingMessagesWithGroups;

/**
 *  Add listener that conforms to the `MOKMessageReceiver` protocol.
 *  This listener will receive all the incoming messages, notifications and acknowledges
 */
- (void)addReceiver:(id <MOKMessageReceiver>)receiver;

/**
 *  Remove a previously added listener
 */
- (void)removeReceiver:(id <MOKMessageReceiver>)receiver;

/**
 *  Send a text to a user
 */
-(MOKMessage *)sendString:(NSString *)plaintext toUser:(NSString *)sessionId;

/**
 *  Send a notification to a user
 */
-(MOKMessage *)sendNotificationToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push;

/**
 *  Send a temporal notification to a user
 */
-(MOKMessage *)sendTemporalNotificationToUser:(NSString *)sessionId withParams:(NSDictionary *)params andPush:(NSString *)push;

/**
 *  Send a delete command for a given message
 */
-(void)sendDeleteCommandForMessage:(NSString *)messageId ToUser:(NSString *)sessionId;
@end

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when the socket connection is successful.
 */
FOUNDATION_EXPORT NSString * const MonkeySocketDidConnectNotifications;

/**
 Posted when the socket connection was closed.
 */
FOUNDATION_EXPORT NSString * const MonkeySocketDidDisconnectNotification;

/**
 Posted when the registration and secure handshake with the server is successful.
 Comes with the session dictionary.
 */
FOUNDATION_EXPORT NSString * const MonkeyRegistrationDidCompleteNotification;

/**
 Posted when the registration and secure handshake with the server failed.
 */
FOUNDATION_EXPORT NSString * const MonkeyRegistrationDidFailNotification;
