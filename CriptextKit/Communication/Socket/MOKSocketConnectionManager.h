//
//  SocketConnectionManager.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/5/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MOKSocketConnectionDelegate
@optional
- (void) errorConnection:(NSString *)errorMessage;
- (void) disconnected;
- (void) loggedIn;
- (void) onLoadPendingMessages;

@end

@interface MOKSocketConnectionManager : NSObject

-(void)connect;
-(void)disconnect;

@end
