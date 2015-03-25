//
//  BLUser.m
//  Blip
//
//  Created by G V on 14.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKUser.h"
#import "MOKDateUtils.h"

@implementation MOKUser
@synthesize params = _params;
-(instancetype)init{
    return [self initWithUserId:@"default user" andParams:nil];
}

-(instancetype)initWithUserId:(NSString *)userID andParams:(NSDictionary *)params{
    
    if (self = [super init])
    {
        _userId = userID;
        _params = params;
    }
    return self;
}

- (void)dealloc {

}

- (NSString *)description {
    return [NSString stringWithFormat:@"userid; %@ with params: %@",self.userId, self.params];
}

@end
