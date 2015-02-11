//
//  Message.h
//  Criptext
//
//  Created by Alvaro Ortiz on 11/19/14.
//  Copyright (c) 2014 Nicolas VERINAUD. All rights reserved.
//

#import <Realm/Realm.h>

@interface Message : RLMObject

@property NSInteger messageId;
@property NSString *userIdFrom;
@property NSString *userIdTo;
@property NSInteger type;
@property double timestamp;
@property NSString *messageText;
@property BOOL readByUser;
@property NSString *param;
@property NSString *iv;

@end