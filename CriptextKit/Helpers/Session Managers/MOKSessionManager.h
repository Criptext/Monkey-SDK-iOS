//
//  SessionManager.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOKUserDictionary.h"

@interface MOKSessionManager : NSObject
@property (nonatomic, strong) NSString *lastMessageId;
@property (nonatomic, strong) NSString *lastTimestamp;
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) MOKUserDictionary *user;

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *port;

@property (nonatomic) BOOL streamChanged;
@property (nonatomic, strong) NSString *delay;
@property (nonatomic, strong) NSString *portions;

+ (MOKSessionManager*)sharedInstance;
- (void)logout;

@end
