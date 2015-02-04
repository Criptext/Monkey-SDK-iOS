//
//  SessionManager.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionManager : NSObject {
	NSString *sessionKey;
    NSString *userName;
    NSString *userPassword;
    NSString *idUser;
    NSString* lastMessageId;
    NSString *passCode;
}
@property (nonatomic, strong) NSString *lastMessageId;
@property (nonatomic, strong) NSString *sessionKey;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userPassword;
@property (nonatomic, strong) NSString *idUser;
@property (nonatomic, strong) NSString *passCode;

+ (SessionManager*)instance;
- (void)logout;

@end
