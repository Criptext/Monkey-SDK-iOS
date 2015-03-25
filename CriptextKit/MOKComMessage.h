//
//  ComMessage.h
//  Blip
//
//  Created by Mac on 08/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MOKComMessage : NSObject {
	int cmd;
	NSString *json;
	

}

@property int cmd;
@property (nonatomic, retain) NSString * json;

+(short)identifyReceiverProtocol:(NSString *)recieverString;
+(MOKComMessage *) createMessageWithCommand:(int )cmd AndArgs:(NSDictionary *)args;
- (id)initWithCmd:(int)vcmd andJson:(NSString *)vjson;

@end
