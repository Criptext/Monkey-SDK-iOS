//
//  ComMessage.m
//  Blip
//
//  Created by Mac on 08/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ComMessage.h"
#import "JSON.h"

#import "ComMessageProtocol.h"

@implementation ComMessage

@synthesize cmd,json;

- (id)initWithCmd:(int)vcmd andJson:(NSString *)vjson{
    self.cmd=vcmd;
	self.json=vjson;
	
	[self init];
	
	return self;
}

+(short)identifyReceiverProtocol:(NSString *)recieverString{
    NSArray *isAlist = [recieverString componentsSeparatedByString:@","];
    if([isAlist count]>1)
        return BroadcastMessage;
    else
        return 0;
    
}

+(ComMessage *) createMessageWithCommand:(int)cmd AndArgs:(NSDictionary *)args{
	
	//add time stamp to the args
	//	[args setValue:time forKey:@"time"];
	
	NSString *cmdS=[NSString stringWithFormat:@"%i",cmd];
	
	NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
	[dict setValue:cmdS forKey:@"cmd"];
	[dict setValue:args forKey:@"args"];
	
	SBJsonWriter *jsonWriter = [SBJsonWriter new];
	NSString *jsonString = [jsonWriter stringWithObject:dict];
	
	//NSLog(@"utf8 -  es %@",[ComMessageProtocol convertToUTF8:jsonString]);
	
	ComMessage *mess=[[ComMessage alloc] initWithCmd:cmd andJson:jsonString];
	
	return mess;
}


//+(BLMessage *) toBLMessage

@end
