//
//  Invite.h
//  Criptext
//
//  Created by Alvaro Ortiz on 11/19/14.
//  Copyright (c) 2014 Nicolas VERINAUD. All rights reserved.
//

#import <Realm/Realm.h>

@interface Invite : RLMObject

@property NSString *userIdFrom;
@property NSString *userIdTo;

@end