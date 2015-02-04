//
//  ComServerConnection.h
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//@required

#import "SGSContext.h"
#import "SGSConnection.h"
#import "SGSChannel.h"

#import "BLMessage.h"

@protocol ComConnectionDelegate

@optional
- (void) messagesRecived:(NSArray*)messages;
- (void) errorConnection:(NSString *)errorMessage;
- (void) disconnected;
- (void) loggedIn;
- (void) onLoadPendingMessages;

@end

@interface ComServerConnection : NSObject <SGSContextDelegate, SGSChannelDelegate>{
	
	NSString * userId;
	int connectionRetry;
	
	NSString *fb_id;
	Boolean firstTime;
    
	SGSConnection *connection;
	BOOL connected;
	UIViewController<ComConnectionDelegate> *connectionDelegate;
	
    BOOL calculatingLatency;
    
    NSTimeInterval timeSentPack;
    NSTimeInterval timeRecievePack;
    int id_package_test;
    
//    return [[NSDate date] timeIntervalSince1970]-self.timestamp;
}


@property (nonatomic, retain) UIViewController<ComConnectionDelegate> *connectionDelegate;
@property (nonatomic, strong) SGSConnection *connection;

@property (nonatomic, retain) NSString *fb_id;
@property  (nonatomic, strong) NSString *userId;
@property  int connectionRetry;


+ (ComServerConnection*) sharedInstance;

-(void) deliverDisconnectionState;
- (void)connectWithDelegate:(UIViewController<ComConnectionDelegate> *) conDelegate;
- (void)connectWithDelegate:(UIViewController<ComConnectionDelegate> *) conDelegate isFirst:(Boolean)isFirst;

-(BOOL)sendMessage:(NSString *)jsonMessage;
- (void)parseMessage:(NSDictionary *)message;
- (void)processAllMessages:(NSArray *)messages;

-(void)logOut;

-(void)resetConnection;

-(void)sendSignalOpenConvMenu:(NSString *) userId;

-(BOOL) isConnected;

-(void)delayedMessageGot:(BLMessage *)message ;

@end
