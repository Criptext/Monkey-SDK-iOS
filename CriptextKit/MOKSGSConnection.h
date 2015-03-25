//
//  SGSConnection.h
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MOKSGSContext;
@class MOKSGSSession;
@class MOKSGSMessage;

typedef enum {
	MOKSGSConnectionStateDisconnected,
	MOKSGSConnectionStateConnecting,
	MOKSGSConnectionStateConnected,
    MOKSGSConnectionStateNoNetwork,
} MOKSGSConnectionState;

@interface MOKSGSConnection : NSObject <NSStreamDelegate>{
	CFSocketRef socket;
	MOKSGSConnectionState state;
	MOKSGSContext *context;
	MOKSGSSession *session;
	NSMutableData *inBuf;
	NSMutableData *outBuf;
	
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
	
	BOOL expectingDisconnect;
	BOOL inRedirect;
}
@property (nonatomic, readonly) CFSocketRef socket;
@property (nonatomic, assign) MOKSGSConnectionState state;
@property (nonatomic, retain) MOKSGSContext *context;
@property (nonatomic, retain) MOKSGSSession *session;
@property (nonatomic, readonly) NSMutableData *inBuf;
@property (nonatomic, readonly) NSMutableData *outBuf;
@property (nonatomic, assign) BOOL expectingDisconnect;
@property (nonatomic, assign) BOOL inRedirect;

- (id)initWithContext:(MOKSGSContext *)context;

- (void)disconnect;
    
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;
- (void)logout:(BOOL)force;
-(void) readInputProcess;
- (BOOL)sendMessage:(MOKSGSMessage *)message;

- (void)resetBuffers;
- (BOOL)isConnectionAvailable ;
-(void)notifyConnectionClosed;


@end