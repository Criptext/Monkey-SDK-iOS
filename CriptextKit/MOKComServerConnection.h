//
//  ComServerConnection.h
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//@required

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
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
- (void) reachabilityDidChange:(AFNetworkReachabilityStatus)reachabilityStatus;

@end

@class UIViewController;
@interface MOKComServerConnection : NSObject {
	
	NSString * userId;
    
	MOKSGSConnection *connection;
	BOOL connected;
	
    BOOL calculatingLatency;
    
    NSTimeInterval timeSentPack;
    NSTimeInterval timeRecievePack;
    int id_package_test;
    
//    return [[NSDate date] timeIntervalSince1970]-self.timestamp;
}


@property (nonatomic, weak) id<MOKComServerConnectionDelegate, NSObject> connectionDelegate;
@property (nonatomic, strong) MOKSGSConnection *connection;
@property AFNetworkReachabilityStatus networkStatus;

@property  (nonatomic, strong) NSString *userId;


+ (MOKComServerConnection*) sharedInstance;

-(void) deliverDisconnectionState;
- (void)connectWithDelegate:(id<MOKComServerConnectionDelegate,NSObject>) conDelegate;

-(BOOL)sendMessage:(NSString *)jsonMessage;
- (void)parseMessage:(NSDictionary *)message;

-(void)logOut;

-(void)destroyInstance;

-(void)resetConnection;

-(BOOL) isConnected;
-(BOOL)isReachable;

@end
