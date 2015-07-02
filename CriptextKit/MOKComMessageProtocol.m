//
//  ComMessageProtocol.m
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKComMessageProtocol.h"

#import "MOKUser.h"
#import "MOKSessionManager.h"
#import "MOKJSON.h"

#import "MOKMessage.h"

@implementation MOKComMessageProtocol

//+(MOKMessage *) createSyncUpdatenMsg:(MOKMessageId)last_message_id type:(int) type{
//	NSMutableDictionary * args=[[NSMutableDictionary alloc] init];
//    if ([[MOKUserDefaultsManager instance] objectForKeyFree:@"mok_StreamDelayTime"] == nil) {
//        [[MOKUserDefaultsManager instance]storeObjectFree:@"2" forKey:@"mok_StreamDelayTime"];
//        [[MOKUserDefaultsManager instance]storeObjectFree:@"15" forKey:@"mok_StreamPortions"];
//    }
//    NSLog(@"MONKEY - se envia delay a:%@ y decrementado porciones a:%@", [[MOKUserDefaultsManager instance] objectForKeyFree:@"mok_StreamDelayTime"], [[MOKUserDefaultsManager instance] objectForKeyFree:@"mok_StreamPortions"]);
//    [args setObject:[[MOKUserDefaultsManager instance] objectForKeyFree:@"mok_StreamDelayTime"] forKey:@"s"];
//    [args setObject:[[MOKUserDefaultsManager instance] objectForKeyFree:@"mok_StreamPortions"] forKey:@"p"];
//    [[MOKUserDefaultsManager instance]storeObjectFree:@"0" forKey:@"mok_StreamDidChangeValue"];
//    [args setObject:[NSString stringWithFormat:@"%llu", last_message_id] forKey:@"last_id"];//reciever id
//    [args setObject:@"2.0" forKey:@"v"];//version del app
//    if([[MOKSessionManager sharedInstance].lastMessageId isEqualToString:@"0"] || [[[MOKUserDefaultsManager instance] objectForKeyFree:@"mok_firstLogin"] isEqualToString:@"1"])
//        [args setObject:@"1" forKey:@"g"];//Para que me devuelva los grupos
//	return [MOKMessage createMessageWithCommand:type AndArgs:args];
//}

- (void)dealloc {
    [super dealloc];
}


@end
