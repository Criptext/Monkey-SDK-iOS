//
//  SGSContext.h
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGSSession;
@class SGSContext;
@class SGSChannel;
@class SGSConnection;
@class SGSMessage;

@protocol SGSContextDelegate <NSObject>

@optional
- (void)sgsContext:(SGSContext *)context channelJoined:(SGSChannel *)channel forConnection:(SGSConnection *)connection;
- (void)sgsContext:(SGSContext *)context messageReceived:(SGSMessage *)msg forConnection:(SGSConnection *)connection;
- (void)channelMessageReceived:(SGSMessage *)message;

- (void)sgsContext:(SGSContext *)context disconnected:(SGSConnection *)connection;
- (void)sgsContext:(SGSContext *)context reconnected:(SGSConnection *)connection;
- (void)sgsContext:(SGSContext *)context loggedIn:(SGSSession *)session forConnection:(SGSConnection *)connection;
- (void)sgsContext:(SGSContext *)context loginFailed:(SGSSession *)session forConnection:(SGSConnection *)connection withMessage:(NSString *)message;

@end


@interface SGSContext : NSObject {
	NSString *hostname;
	NSInteger port;
	
	id<SGSContextDelegate> delegate;
}
@property (nonatomic, retain) NSString *hostname;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) id<SGSContextDelegate> delegate;

- (id)initWithHostname:(NSString *)hostname port:(NSInteger)port;

@end
