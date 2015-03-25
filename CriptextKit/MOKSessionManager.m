//
//  SessionManager.m
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKSessionManager.h"
#import "MOKUserDefaultsManager.h"
#import "MOKUser.h"

@implementation MOKSessionManager

static MOKSessionManager *sessionManagerInstance = nil;

+ (MOKSessionManager*)sharedInstance {
	@synchronized (sessionManagerInstance) {
		if (sessionManagerInstance == nil) {
			sessionManagerInstance = [[MOKSessionManager alloc] init];
		}
	}
	return sessionManagerInstance;
}

- (id)init {
	if (self = [super init]) {
		self.sessionKey = [[MOKUserDefaultsManager instance] loadSessionKey];
        self.userId = [[MOKUserDefaultsManager instance] loadUserId];
        self.userName = [[MOKUserDefaultsManager instance] loadUserName];
        self.userPassword = [[MOKUserDefaultsManager instance] loadUserPassword];
        self.lastMessageId = [[MOKUserDefaultsManager instance] loadLastMessageId];
        self.passCode = [[MOKUserDefaultsManager instance] loadPassCode];
        self.me = [[MOKUser alloc] initWithUserId:@"nil" andParams:nil];
	}
	return self;
}

- (void)setPassCode:(NSString *)passcode {
	_passCode = passcode;
	[[MOKUserDefaultsManager instance] storePassCode:_passCode];
}

- (void)setSessionKey:(NSString*)key {
	_sessionKey = key;
	[[MOKUserDefaultsManager instance] storeSessionKey:_sessionKey];
}

- (void)setUserId:(NSString *)userId{
	_userId=userId;
	[[MOKUserDefaultsManager instance] storeUserId:_userId];
}

- (void)setUserName:(NSString *)username {
	_userName=username;
	[[MOKUserDefaultsManager instance] storeUserName:_userName];
}

- (void)setUserPassword:(NSString *)userpassword {
	_userPassword=userpassword;
	[[MOKUserDefaultsManager instance] storeUserPassword:_userPassword];
}

- (void)setLastMessageId:(NSString *)lastmessageid{
    _lastMessageId=lastmessageid;
	[[MOKUserDefaultsManager instance] storeLastMessageId:_lastMessageId];
}

- (void)logout {
//	self.sessionKey = nil;
    //self.idUser= nil;
//    self.userName= nil;
//    self.userPassword= nil;
//    self.passCode=nil;
//    self.me = nil;
    //self.lastMessageId=nil;
    
    //hay que testear esto de aki
//    [[UserDefaultsManager instance] cleanAll];
}

@end
