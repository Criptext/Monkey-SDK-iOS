//
//  ComMessageProtocol.h
//  Blip
//
//  Created by Mac on 01/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MOKutils.h"
@class MOKJSON;
@class MOKMessage;

//typedef enum {
//	// JOSE
//	//MessageNotDelivered = 50,
//	//MessageDelivered = 51,
//	//MessageNotView = 52,
////	MessageOpenCloseNotification=53,
//	
////	SuscribeToChannels = 25,
//	MessagesUpdates = 27,
//    
//    //MessagesUserOnline=28,
//    //MessagesUserOffline=29
//    
//	
//} ComMessageType;



@interface MOKComMessageProtocol : NSObject
+(MOKMessage *) createSyncUpdatenMsg:(MOKMessageId)last_message_id type:(int) type;

@end
