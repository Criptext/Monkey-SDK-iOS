//
//  SGSChannel.m
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import "SGSChannel.h"

#import "SGSSession.h"
#import "SGSConnection.h"
#import "SGSMessage.h"
#import "SGSId.h"

@implementation SGSChannel

@synthesize delegate;
@synthesize session;
@synthesize sgsId;
@synthesize name;

- (id)initWithSession:(SGSSession *)aSession channelId:(SGSId *)aSgsId name:(NSString *)aName {
	if(self = [super init]) {
		self.session = aSession;
		self.sgsId = aSgsId;
		self.name = [aName copy];
	}
	return self;
}

- (void)dealloc {
	[sgsId release];
	[name release];
	
	[super dealloc];
}

- (void)sendMessage:(SGSMessage *)msg {
	// Wrap the passed message with a new message which adds the
	// channel attributes
	SGSMessage *channelMsg = [SGSMessage channelMessage:self];
	[channelMsg appendArbitraryBytes:[msg bytes] length:[msg length]];
	
	[session.connection sendMessage:channelMsg];
}

@end
