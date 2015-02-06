//
//  SessionManager.m
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SessionManager.h"
#import "UserDefaultsManager.h"

@implementation SessionManager
@synthesize sessionKey,userName,userPassword,idUser,lastMessageId,passCode;

static SessionManager *sessionManagerInstance = nil;

+ (SessionManager*)sharedInstance {
	@synchronized (sessionManagerInstance) {
		if (sessionManagerInstance == nil) {
			sessionManagerInstance = [[SessionManager alloc] init];
		}
	}
	return sessionManagerInstance;
}

- (id)init {
	if (self = [super init]) {
		self.sessionKey = [[UserDefaultsManager instance] loadSessionKey];
        self.idUser = [[UserDefaultsManager instance] loadUserId];
        self.userName = [[UserDefaultsManager instance] loadUserName];
        self.userPassword = [[UserDefaultsManager instance] loadUserPassword];
        self.lastMessageId = [[UserDefaultsManager instance] loadLastMessageId];
        self.passCode = [[UserDefaultsManager instance] loadPassCode];
	}
	return self;
}

- (void)setPassCode:(NSString *)passcode {
	passCode = passcode;
	[[UserDefaultsManager instance] storePassCode:passCode];
}

- (void)setSessionKey:(NSString*)key {
	sessionKey = key;
	[[UserDefaultsManager instance] storeSessionKey:sessionKey];
}

- (void)setIdUser:(NSString *)iduser{
	idUser=iduser;
	[[UserDefaultsManager instance] storeUserId:idUser];
}

- (void)setUserName:(NSString *)username {
	userName=username;
	[[UserDefaultsManager instance] storeUserName:userName];
}

- (void)setUserPassword:(NSString *)userpassword {
	userPassword=userpassword;
	[[UserDefaultsManager instance] storeUserPassword:userPassword];
}

- (void)setLastMessageId:(NSString *)lastmessageid{
    lastMessageId=lastmessageid;
	[[UserDefaultsManager instance] storeLastMessageId:lastMessageId];
}

- (void)logout {
	self.sessionKey = nil;
    //self.idUser= nil;
    self.userName= nil;
    self.userPassword= nil;
    self.passCode=nil;
    //self.lastMessageId=nil;
    
    //hay que testear esto de aki
    [[UserDefaultsManager instance] cleanAll];
}

@end
