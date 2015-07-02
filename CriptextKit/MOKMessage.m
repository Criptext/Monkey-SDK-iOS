//
//  MOKMessage.m
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKMessage.h"
#import "MOKUser.h"
#import "MOKJSON.h"
#import "MOKSessionManager.h"
#include "MOKCriptext.h"

@implementation MOKMessage

- (id)initWithArgs:(NSDictionary*)dictionary{
	
	if (self = [super init]) {
		self.messageText = @"";
        self.params = [NSJSONSerialization JSONObjectWithData:[(NSString *)[dictionary objectForKey:@"params"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        self.encryptedText = [self stringFromDictionary:dictionary key:@"msg"];
        self.protocolType  = [self integerFromDictionary:dictionary key:@"type"];
        self.monkeyActionType = [self integerFromDictionary:self.params key:@"monkey_action"];
        self.iv = [self stringFromDictionary:dictionary key:@"iv"];
		
		self.timestampCreated = [self doubleFromDictionary:dictionary key:@"datetime"];
        self.timestampOrder = [[NSDate date] timeIntervalSince1970];
		
		self.userIdFrom = [self stringFromDictionary:dictionary key:@"sid"];
		if([dictionary objectForKey:@"rid"]!=nil){
            self.userIdTo=[self stringFromDictionary:dictionary key:@"rid"];
        }
        else
            self.userIdTo = [MOKSessionManager sharedInstance].sessionId;
		
		
        self.messageId = [self integerFromDictionary:dictionary key:@"id"];
        
		self.readByUser = NO;
		
		self.isSending = NO;
        
        self.needsResend = NO;
				
		self.deliveredMessage=-1;

	}
	
	return self;
	
}
- (id)init {
    return [self initWithMessage:nil
                 protocolCommand:MOKProtocolMessage
                    protocolType:MOKText
                monkeyActionType:0
                       messageId:([[NSDate date] timeIntervalSince1970]* -1)
                    oldMessageId:0
                       messageIV:nil
                       timestampCreated:[[NSDate date] timeIntervalSince1970]
                  timestampOrder:[[NSDate date] timeIntervalSince1970]
                        fromUser:nil toUser:nil params:nil];
}

- (id)initWithMessage:(NSString*)messageText
      protocolCommand:(MOKProtocolCommand)cmd
         protocolType:(int)protocolType
     monkeyActionType:(int)monkeyActionType
            messageId:(MOKMessageId)messageId
         oldMessageId:(MOKMessageId)oldMessageId
            messageIV:(NSString *)iv
     timestampCreated:(NSTimeInterval)timestampCreated
            timestampOrder:(NSTimeInterval)timestampOrder
             fromUser:(NSString *)sessionIdFrom
               toUser:(NSString *)sessionIdTo
               params:(NSMutableDictionary *)params
{
    if (self = [super init]) {
        self.messageText = messageText;
        self.encryptedText = @"";
        self.timestampCreated = timestampCreated;
        self.timestampOrder = timestampOrder;
        self.userIdFrom = sessionIdFrom;
        self.iv = iv;
        self.userIdTo = sessionIdTo;
        self.messageId = messageId;
        self.oldMessageId = oldMessageId;
        self.readByUser = NO;
        self.protocolCommand = cmd;
        self.protocolType = protocolType;
        self.monkeyActionType = monkeyActionType;
        self.isSending = NO;
        self.needsResend = NO;
        self.params = params;
        self.deliveredMessage=-1;
    }
    return self;
}


- (id)initWithMyMessage:(NSString*)messageText userTo:(NSString *)sessionId {
    if (self = [super init]) {
        //NSLog(@"MONKEY - modo2");
        
        self.messageText = messageText;
        self.encryptedText = @"";
        self.messageId = [[NSDate date] timeIntervalSince1970]* -1;
        self.oldMessageId = self.messageId;
        self.timestampCreated = [[NSDate date] timeIntervalSince1970];
        self.timestampOrder = self.timestampCreated;
        self.userIdTo = sessionId;
        self.userIdFrom = [MOKSessionManager sharedInstance].sessionId;
        self.readByUser = NO;
        self.protocolCommand = MOKProtocolMessage;
        self.protocolType = MOKText;
        self.monkeyActionType = 0;
        self.isSending = NO;
        self.needsResend = NO;
        self.params = [@{@"eph":@"0",
                        @"str":@"0",
                         @"type":@"0",
                         @"device":@"ios",
                        @"encr":@"1"} mutableCopy];
        self.pushMessage = @"";
        
        self.deliveredMessage=-1;
    }
    return self;
}

- (void)updateMessageIdFromACK{
    self.messageId = [self integerFromDictionary:self.params key:@"message_id"];
    if([self.params objectForKey:@"new_id"]!=nil || [((NSString *)[self.params objectForKey:@"new_id"]) isEqualToString:@"null"])
        self.messageId = [self integerFromDictionary:self.params key:@"new_id"];
    self.oldMessageId = [self integerFromDictionary:self.params key:@"old_id"];
}

- (NSString*)messageTextToShow {
    return @"";
}

- (BOOL)isMessageFromMe {
	return self.userIdFrom == [MOKSessionManager sharedInstance].sessionId;
}

- (BOOL)isGroupMessage {
    return [self.userIdTo rangeOfString:@"G"].location!=NSNotFound;
}

-(id) mutableCopyWithZone: (NSZone *) zone
{
    MOKMessage *messCopy = [[MOKMessage allocWithZone: zone] init];
    
    messCopy.userIdTo=self.userIdTo;
    messCopy.userIdFrom=self.userIdFrom;
    messCopy.messageId=self.messageId;
    messCopy.messageText=self.messageText;
    
    messCopy.timestampCreated=self.timestampCreated;
    messCopy.timestampOrder = self.timestampOrder;
    messCopy.protocolType=self.protocolType;
    messCopy.readByUser=self.readByUser;
    messCopy.oldMessageId=self.oldMessageId;
    messCopy.params = self.params;
    
    return messCopy;
}


@end
