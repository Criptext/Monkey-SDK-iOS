//
//  Conversation.m
//  Criptext
//
//  Created by Alvaro Ortiz on 11/19/14.
//  Copyright (c) 2014 Nicolas VERINAUD. All rights reserved.
//

#import "Conversation.h"

@implementation Conversation

+ (NSString *)primaryKey {
  return @"conversationUserId";
}

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

@end
