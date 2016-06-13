//
//  MOKUser.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/8/16.
//  Copyright © 2016 Gianni Carlo. All rights reserved.
//

#import <Realm/Realm.h>

@interface MOKUser : RLMObject
@property NSString *monkeyId;
@property NSString *name;
@end
