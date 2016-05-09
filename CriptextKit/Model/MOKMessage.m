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
#import "NSString+Random.h"
#include "MOKCriptext.h"
@interface MOKMessage()

@end

@implementation MOKMessage
@synthesize props = _props;

- (id)initWithArgs:(NSDictionary*)dictionary{
	
	if (self = [super init]) {
		self.messageText = @"";
        if ([dictionary objectForKey:@"props"]) {
            self.props = [[NSJSONSerialization JSONObjectWithData:[[self stringFromDictionary:dictionary key:@"props"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] mutableCopy];
        }else{
            self.props = [@{} mutableCopy];
        }
        
        if ([dictionary objectForKey:@"params"]) {
            self.params = [NSJSONSerialization JSONObjectWithData:[[self stringFromDictionary:dictionary key:@"params"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }else{
            self.params = [@{}mutableCopy];
        }
        
        self.encryptedText = [self stringFromDictionary:dictionary key:@"msg"];
        self.protocolType  = [self integerFromDictionary:dictionary key:@"type"];
        self.monkeyType = [self integerFromDictionary:self.props key:@"monkey_action"];
		
		self.timestampCreated = [self doubleFromDictionary:dictionary key:@"datetime"];
        self.timestampOrder = [[NSDate date] timeIntervalSince1970];
		
		self.userIdFrom = [self stringFromDictionary:dictionary key:@"sid"];
        
		if([dictionary objectForKey:@"rid"]!=nil){
            self.userIdTo=[self stringFromDictionary:dictionary key:@"rid"];
        }else{
            self.userIdTo = [MOKSessionManager sharedInstance].sessionId;
        }
		
        if ([self stringFromDictionary:dictionary key:@"readBy"] != nil) {
            self.readBy = [[[self stringFromDictionary:dictionary key:@"readBy"] componentsSeparatedByString:@","] mutableCopy];
        }
		
        self.messageId = [self stringFromDictionary:dictionary key:@"id"];
        self.oldMessageId = [self stringFromDictionary:self.props key:@"old_id"];
        
		self.readByUser = NO;
        
        self.needsResend = NO;
        
        self.pushMessage = @"";

	}
	
	return self;
	
}

- (id)init {
    return [self initWithMessage:nil
                 protocolCommand:MOKProtocolMessage
                    protocolType:MOKText
                      monkeyType:0
                       messageId:[self generateRandomId]
                    oldMessageId:@"0"
                       timestampCreated:[[NSDate date] timeIntervalSince1970]
                  timestampOrder:[[NSDate date] timeIntervalSince1970]
                        fromUser:nil
                          toUser:nil
                    mkProperties:[@{@"encr": @"1"} mutableCopy]
                          params:nil];
}

- (id)initWithMessage:(NSString*)messageText
      protocolCommand:(MOKProtocolCommand)cmd
         protocolType:(int)protocolType
           monkeyType:(int)monkeyType
            messageId:(NSString *)messageId
         oldMessageId:(NSString *)oldMessageId
     timestampCreated:(NSTimeInterval)timestampCreated
            timestampOrder:(NSTimeInterval)timestampOrder
             fromUser:(NSString *)sessionIdFrom
               toUser:(NSString *)sessionIdTo
         mkProperties:(NSMutableDictionary *)mkprops
               params:(NSMutableDictionary *)params
{
    if (self = [super init]) {
        self.messageText = messageText;
        self.encryptedText = @"";
        self.timestampCreated = timestampCreated;
        self.timestampOrder = timestampOrder;
        self.userIdFrom = sessionIdFrom;
        self.userIdTo = sessionIdTo;
        self.messageId = messageId;
        self.oldMessageId = oldMessageId;
        self.readByUser = NO;
        self.protocolCommand = cmd;
        self.protocolType = protocolType;
        self.monkeyType = monkeyType;
        self.needsResend = NO;
        self.props = mkprops;
        self.params = params;
        self.pushMessage = @"";
        self.readBy = [@[] mutableCopy];
    }
    return self;
}


- (id)initWithMyMessage:(NSString*)messageText userTo:(NSString *)sessionId {
    if (self = [super init]) {
        self.messageText = messageText;
        self.encryptedText = @"";
        self.messageId = [self generateRandomId];
        self.oldMessageId = self.messageId;
        self.timestampCreated = [[NSDate date] timeIntervalSince1970];
        self.timestampOrder = self.timestampCreated;
        self.userIdTo = sessionId;
        self.userIdFrom = [MOKSessionManager sharedInstance].sessionId;
        self.readByUser = NO;
        self.protocolCommand = MOKProtocolMessage;
        self.protocolType = MOKText;
        self.monkeyType = 0;
        self.needsResend = NO;
        self.props = [@{@"str":@"0",
                        @"old_id": self.messageId,
                        @"device":@"ios",
                        @"encr":@"1"} mutableCopy];
        self.params = [@{} mutableCopy];
        self.pushMessage = @"";
        self.readBy = [@[] mutableCopy];
    }
    return self;
}

- (void)updateMessageIdFromACK{
    self.messageId = [self.props objectForKey:@"message_id"];
    if([self.props objectForKey:@"new_id"]!=nil){
        self.messageId = [self.props objectForKey:@"new_id"];
    }
    self.oldMessageId = [self.props objectForKey:@"old_id"];
}

- (NSString*)messageTextToShow {
    return @"";
}

- (BOOL)isMessageFromMe {
	return [self.userIdFrom isEqualToString:[MOKSessionManager sharedInstance].sessionId];
}

- (BOOL)isGroupMessage {
    return ([self.userIdTo rangeOfString:@"G:"].location!=NSNotFound || [self.userIdFrom rangeOfString:@"G:"].location!=NSNotFound);
}
- (BOOL)isBroadCastMessage {
    return ([self.userIdTo rangeOfString:@","].location!=NSNotFound || [self.userIdFrom rangeOfString:@","].location!=NSNotFound);
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
    messCopy.props = self.props;
    
    return messCopy;
}
-(NSString *)generateRandomId{
    return [NSString stringWithFormat:@"%lld%@",(long long)([[NSDate date] timeIntervalSince1970]* -1), [NSString mok_randomStringOfLength:3]];
}
-(NSMutableDictionary *)props{
    return _props;
}
-(void)setProps:(NSMutableDictionary *)newProps{
    _props = newProps;
}
- (void)setEncrypted:(BOOL)shouldEncrypt{
    [self.props setObject:shouldEncrypt?@"1":@"0" forKey:@"encr"];
}
- (BOOL)isEncrypted{
    return [[self.props objectForKey:@"encr"] intValue] ==1;
}

- (void)setCompression:(BOOL)shouldCompress{
    if (shouldCompress) {
        [self.props setObject:@"gzip" forKey:@"cmpr"];
    }
}
- (BOOL)isCompressed{
    NSString *compressed = [self.props objectForKey:@"cmpr"];
    
    if ([compressed isEqualToString:@"gzip"]) {
        return true;
    }
    
    return false;
}
-(BOOL)isEqual:(id)object{
    MOKMessage *otherMsg = object;
    if ([self.messageId isEqualToString:otherMsg.messageId]) {
        return true;
    }
    return false;
}
@end
