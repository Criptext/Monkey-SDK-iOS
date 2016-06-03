//
//  Monkey.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/1/16.
//  Copyright © 2016 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MOKMessage;

@interface Monkey : NSObject
/*!
 @property appId
 @abstract String that identifies your App Id.
 */
@property (copy, nonatomic, readonly) NSString *appId;

/*!
 @property appKey
 @abstract String that identifies your App Key.
 */
@property (copy, nonatomic, readonly) NSString *appKey;

/*!
 @property domain
 @abstract String that identifies the Monkey domain.
 */
@property (copy, nonatomic, readonly) NSString *domain;

/*!
 @property port
 @abstract String that identifies the Monkey port.
 */
@property (copy, nonatomic, readonly) NSString *port;

/*!
 @property session
 @abstract Dictionary which holds session params: 
 - id -> Monkey Id
 - user -> User metadata
 - lastTimestamp -> Timestamp of last sync of messages
 - expireSession -> Boolean that determines if this monkey id expires with time on server
 - debuggingMode -> Boolean that determines development and production environments
 - autoSync -> Boolean that determines if the sync of messages should be automatic everytime the socket connects.
 */
@property (copy, nonatomic, readonly) NSMutableDictionary * session;

@end

@protocol MOKMessageReceiver <NSObject>
@required
- (void)messageReceived:(MOKMessage*)message;
- (void)notificationReceived:(MOKMessage *)notificationMessage;
- (void)acknowledgeReceived:(MOKMessage *)ackMessage;
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
