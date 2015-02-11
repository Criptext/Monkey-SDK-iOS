//
//  User.h
//  Criptext
//
//  Created by Alvaro Ortiz on 11/19/14.
//  Copyright (c) 2014 Nicolas VERINAUD. All rights reserved.
//

#import <Realm/Realm.h>

@interface User : RLMObject

@property NSString *userId;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *iv;
@property NSString *password;
@property NSString *email;
@property NSString *phone;
@property BOOL isFriend;
@property BOOL active;
@property NSString *company;
@property NSInteger role;

@end