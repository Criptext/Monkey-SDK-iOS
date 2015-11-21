//
//  UserDictionary.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/8/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MOKUserDictionary : NSMutableDictionary
{
    NSMutableDictionary *dictionary;
}
-(void)replaceDictionary:(NSDictionary *)otherDictionary;
-(NSMutableDictionary *)getDictionary;
-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;
-(void)removeObjectForKey:(id)aKey;
@end
