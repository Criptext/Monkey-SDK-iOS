//
//  SGSId.m
//  LuckyOnline
//
//  Created by Timothy Braun on 3/15/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import "SGSId.h"


@implementation SGSId

@synthesize data;

+ (id)idWithData:(NSData *)theData {
	return [[[SGSId alloc] initWithData:theData] autorelease];
}

- (id)initWithData:(NSData *)theData {
	if(self = [super init]) {
		data = [[NSData alloc] initWithData:theData];
	}
	return self;
}

- (void)dealloc {
	[data release];
	
	[super dealloc];
}

- (BOOL)isEqual:(id)other {
	if(![other isKindOfClass:[SGSId class]]) {
		return NO;
	}
	
	SGSId *o = other;
	return [self.data isEqualToData:o.data];
}

- (NSUInteger)hash {
	return [data hash];
}

- (id)copyWithZone:(NSZone *)zone {
	return [self retain];
}

@end
