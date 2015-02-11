//
//  Message.m
//  Criptext
//
//  Created by Alvaro Ortiz on 11/19/14.
//  Copyright (c) 2014 Nicolas VERINAUD. All rights reserved.
//

#import "Message.h"

@implementation Message

+ (NSString *)primaryKey {
  return @"messageId";
}

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    return @{
             @"param": @"0",
             @"readByUser": @NO
             };
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

@end
