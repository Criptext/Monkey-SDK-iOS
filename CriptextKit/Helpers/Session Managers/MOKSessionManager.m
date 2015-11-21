//
//  SessionManager.m
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKSessionManager.h"


@implementation MOKSessionManager

static MOKSessionManager *sessionManagerInstance = nil;

+ (MOKSessionManager*)sharedInstance {
	@synchronized (sessionManagerInstance) {
		if (sessionManagerInstance == nil) {
			sessionManagerInstance = [[self alloc] initPrivate];
		}
        return sessionManagerInstance;
	}
	
}
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MOKSessionManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}
- (id)initPrivate {
	if (self = [super init]) {
        self.sessionId = @"";
        self.appId = @"";
        self.appKey = @"";
        self.lastMessageId = @"";
        self.domain = @"";
        self.delay = @"2";
        self.portions = @"15";
        self.streamChanged = false;
        
        self.user = [[MOKUserDictionary alloc] init];
	}
	return self;
}

- (void)logout {
    @synchronized (sessionManagerInstance) {
        sessionManagerInstance = nil;
    }
}

@end
