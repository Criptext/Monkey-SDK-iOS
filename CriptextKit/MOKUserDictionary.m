//
//  UserDictionary.m
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/8/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "MOKUserDictionary.h"
#import "MOKDBManager.h"
@implementation MOKUserDictionary
//- (id)initWithCapacity:(NSUInteger)capacity
//{
//    self = [super init];
//    if (self != nil)
//    {
//        dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
//    }
//    return self;
//}
- (id)init{
    self = [super init];
    if (self != nil) {
        dictionary = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}
- (void)replaceDictionary:(NSDictionary *)otherDictionary{
    dictionary = [[NSMutableDictionary alloc] initWithDictionary:otherDictionary];
}
- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (anObject) {
        [dictionary setObject:anObject forKey:aKey];
    }else{
        [dictionary removeObjectForKey:aKey];
    }
}

-(NSMutableDictionary *)getDictionary{
    return dictionary;
}

- (void)removeObjectForKey:(id)aKey
{
    [dictionary removeObjectForKey:aKey];
}

- (NSUInteger)count
{
    return [dictionary count];
}

- (id)objectForKey:(id)aKey
{
    return [dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [dictionary objectEnumerator];
}
@end
