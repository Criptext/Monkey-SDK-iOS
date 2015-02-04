//
//  SGSSession.h
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGSConnection;
@class SGSMessage;

@interface SGSSession : NSObject {
	SGSConnection *connection;
	NSData *reconnectKey;
	NSMutableDictionary *channels;
	NSString *login;
	NSString *password;
}
@property (nonatomic, assign) SGSConnection *connection;
@property (nonatomic, retain) NSData *reconnectKey;
@property (nonatomic, retain) NSMutableDictionary *channels;
@property (nonatomic, retain) NSString *login;
@property (nonatomic, retain) NSString *password;

- (id)initWithConnection:(SGSConnection *)connection;

- (void)receiveMessage:(SGSMessage *)message;

- (void)loginWithLogin:(NSString *)username password:(NSString *)password;
- (void)logout;

@end
