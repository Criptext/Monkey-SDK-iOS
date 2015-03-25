//
//  SessionManager.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLUser;
@interface SessionManager : NSObject
@property (nonatomic, strong) NSString *lastMessageId;
@property (nonatomic, strong) NSString *sessionKey;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userPassword;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *passCode;
@property (nonatomic, strong) BLUser *me;

+ (SessionManager*)sharedInstance;
- (void)logout;

@end
