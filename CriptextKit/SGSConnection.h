//
//  SGSConnection.h
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGSContext;
@class SGSSession;
@class SGSMessage;

typedef enum {
	SGSConnectionStateDisconnected,
	SGSConnectionStateConnecting,
	SGSConnectionStateConnected,
    SGSConnectionStateNoNetwork,
} SGSConnectionState;

@interface SGSConnection : NSObject <NSStreamDelegate>{
	CFSocketRef socket;
	SGSConnectionState state;
	SGSContext *context;
	SGSSession *session;
	NSMutableData *inBuf;
	NSMutableData *outBuf;
	
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
	
	BOOL expectingDisconnect;
	BOOL inRedirect;
}
@property (nonatomic, readonly) CFSocketRef socket;
@property (nonatomic, assign) SGSConnectionState state;
@property (nonatomic, retain) SGSContext *context;
@property (nonatomic, retain) SGSSession *session;
@property (nonatomic, readonly) NSMutableData *inBuf;
@property (nonatomic, readonly) NSMutableData *outBuf;
@property (nonatomic, assign) BOOL expectingDisconnect;
@property (nonatomic, assign) BOOL inRedirect;

- (id)initWithContext:(SGSContext *)context;

- (void)disconnect;
    
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;
- (void)logout:(BOOL)force;
-(void) readInputProcess;
- (BOOL)sendMessage:(SGSMessage *)message;

- (void)resetBuffers;
- (BOOL)isConnectionAvailable ;
-(void)notifyConnectionClosed;


@end
