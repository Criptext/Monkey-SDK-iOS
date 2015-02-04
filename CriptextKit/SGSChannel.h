//
//  SGSChannel.h
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGSSession;
@class SGSId;

@class SGSChannel;
@class SGSMessage;

@protocol SGSChannelDelegate <NSObject>

@optional
- (void)channel:(SGSChannel *)channel messageReceived:(SGSMessage *)message;
- (void)channelLeft:(SGSChannel *)channel;

@end


@interface SGSChannel : NSObject {
	id<SGSChannelDelegate> delegate;
	
	SGSSession *session;
	SGSId *sgsId;
	NSString *name;
}
@property (nonatomic, assign) id<SGSChannelDelegate> delegate;

@property (nonatomic, assign) SGSSession *session;
@property (nonatomic, retain) SGSId *sgsId;
@property (nonatomic, retain) NSString *name;

- (id)initWithSession:(SGSSession *)session channelId:(SGSId *)sgsId name:(NSString *)name;
- (void)sendMessage:(SGSMessage *)message;

@end
