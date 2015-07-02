//
//  MOKDBSession.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 4/6/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Realm/Realm.h>

@interface MOKDBSession : RLMObject
@property NSString *sessionId;
@property NSString *appId;
@property NSString *appKey;
@property NSString *lastMessageId;
@property NSString *user;
@end
