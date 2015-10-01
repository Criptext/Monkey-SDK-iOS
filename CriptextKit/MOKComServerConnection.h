//
//  ComServerConnection.h
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//@required

#import <Foundation/Foundation.h>
#import "MOKSGSConnection.h"
@class MOKSGSContext;
@class MOKSGSChannel;

@class MOKMessage;


@protocol MOKComServerConnectionDelegate

@optional
- (void) errorConnection:(NSString *)errorMessage;
- (void) disconnected;
- (void) loggedIn;
- (void) onLoadPendingMessages;

@end

@class UIViewController;
@interface MOKComServerConnection : NSObject {
	
	NSString * userId;
	int connectionRetry;
	
	NSString *fb_id;
	Boolean firstTime;
    
	MOKSGSConnection *connection;
	BOOL connected;
	UIViewController<MOKComServerConnectionDelegate> *connectionDelegate;
	
    BOOL calculatingLatency;
    
    NSTimeInterval timeSentPack;
    NSTimeInterval timeRecievePack;
    int id_package_test;
    
//    return [[NSDate date] timeIntervalSince1970]-self.timestamp;
}


@property (nonatomic, retain) UIViewController<MOKComServerConnectionDelegate> *connectionDelegate;
@property (nonatomic, strong) MOKSGSConnection *connection;

@property (nonatomic, retain) NSString *fb_id;
@property  (nonatomic, strong) NSString *userId;
@property  int connectionRetry;


+ (MOKComServerConnection*) sharedInstance;

-(void) deliverDisconnectionState;
- (void)connectWithDelegate:(UIViewController<MOKComServerConnectionDelegate> *) conDelegate;
- (void)connectWithDelegate:(UIViewController<MOKComServerConnectionDelegate> *) conDelegate isFirst:(Boolean)isFirst;

-(BOOL)sendMessage:(NSString *)jsonMessage;
- (void)parseMessage:(NSDictionary *)message;

-(void)logOut;

-(void)resetConnection;

-(BOOL) isConnected;

@end
