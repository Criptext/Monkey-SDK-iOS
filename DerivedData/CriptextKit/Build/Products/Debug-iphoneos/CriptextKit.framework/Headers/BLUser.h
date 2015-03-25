//
//  BLUser.h
//  Blip
//
//  Created by G V on 14.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLDictionaryBasedObject.h"

@interface BLUser : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSDictionary *params;

-(instancetype)initWithUserId:(NSString *)userID andParams:(NSDictionary *)params;

@end
