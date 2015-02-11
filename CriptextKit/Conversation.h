//
//  Conversation.h
//  Criptext
//
//  Created by Alvaro Ortiz on 11/19/14.
//  Copyright (c) 2014 Nicolas VERINAUD. All rights reserved.
//

#import <Realm/Realm.h>

@interface Conversation : RLMObject

@property NSString *conversationUserId;
@property NSInteger timestamp;
@property NSInteger type;
@property NSString *groupName;
@property NSString *groupIds;

@end