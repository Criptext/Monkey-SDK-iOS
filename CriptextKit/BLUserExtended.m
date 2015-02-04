//
//  BLUserExtended.m
//  Blip
//
//  Created by G V on 14.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BLUserExtended.h"
#import "DateUtils.h"

@implementation BLUserExtended
@synthesize userName, userId, email, phone, firstName, lastName, session, active, companyName,rol;

static BLUserExtended *defaultUser = nil;

+ (BLUserExtended*)defaultUser {
    
	@synchronized (self) {
		if (defaultUser == nil) {
			defaultUser = [[BLUserExtended alloc] init];
			defaultUser.firstName = NSLocalizedString(@"userDesconocido", @"");
			defaultUser.lastName = @"";
			defaultUser.userName = @"nn";
			defaultUser.userId = @"-10";
			defaultUser.phone = @"";
			defaultUser.session = @"";
            defaultUser.active = false;
            defaultUser.companyName = @"";
            defaultUser.rol=CRDefault;
		}
	}
	return defaultUser;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {

	if (self = [super init]) {

        
		self.email = [self stringFromDictionary:dictionary key:@"email"];
        self.userName = [self stringFromDictionary:dictionary key:@"username"];
		self.userId = [self stringFromDictionary:dictionary key:@"id"];
		self.phone = [self stringFromDictionary:dictionary key:@"phone"];
		self.firstName = [self stringFromDictionary:dictionary key:@"full_name"];
        
		self.lastName = [self stringFromDictionary:dictionary key:@"last_name"];
        self.session = [self stringFromDictionary:dictionary key:@"session"];
        self.active = [self booleanFromDictionary:dictionary key:@"active"];
        self.companyName = [self stringFromDictionary:dictionary key:@"company_name"];
        if([dictionary objectForKey:@"rol"]!=nil)
            self.rol = [self integerFromDictionary:dictionary key:@"rol"];
        else
            self.rol = CRDefault;
        
    }
	return self;	
}

- (NSString*)nameLastnameString {
    if([self.firstName isEqualToString:@""])
        return self.userName;
	return [NSString stringWithFormat:@"%@ %@", self.firstName,self.lastName];
}

- (NSString*)month:(NSString*)ms {
	switch ([ms intValue]) {
		case 1: return @"Jan";
		case 2: return @"Feb";
		case 3: return @"Mar";			
		case 4: return @"Apr";
		case 5: return @"May";
		case 6: return @"June";
		case 7: return @"July";
		case 8: return @"Aug";
		case 9: return @"Sep";
		case 10: return @"Oct";
		case 11: return @"Nov";
		case 12: return @"Dec";			
		default:
			return @"?";
			break;
	}
}

- (NSString*)avatarThumbImageWebPath {
	return [NSString stringWithFormat:@"https://api.criptext.com/avatars/avatar_%@.png", self.userId];
}

+ (NSString*)avatarThumbImageWebPathWithId:(NSString *) id_user{
	return [NSString stringWithFormat:@"https://api.criptext.com/avatars/avatar_%@.png",id_user];
}

+ (NSString*)avatarGroupThumbImageWebPathWithId:(NSString *) id_user{
    return [NSString stringWithFormat:@"https://api.criptext.com/avatars/avatar_%@.png", [id_user stringByReplacingOccurrencesOfString:@":" withString:@""]];
    //return [NSString stringWithFormat:@"http://criptext.com:4080/groupvatar?ids=%@",id_user];
}

- (void)dealloc {

}

- (NSString *)description {
    return self.userId;
}

@end
