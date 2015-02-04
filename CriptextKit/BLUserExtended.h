//
//  BLUserExtended.h
//  Blip
//
//  Created by G V on 14.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLDictionaryBasedObject.h"

typedef enum {
	CRAfiliate = 0,
    CRDefault = 1,
    CRCanInvite = 2,
	CRAdmin = 3,
	CRReseller = 4,
    CRGod = 5
} CRRolType;

@interface BLUserExtended : BLDictionaryBasedObject {

	NSString *userId;
	NSString *userName;
	NSString *email;
	NSString *phone;
	NSString *firstName;
	NSString *lastName;
	NSString *session;
	BOOL active;
    NSString *companyName;
    CRRolType rol;
}

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *session;
@property BOOL active;
@property (nonatomic, strong) NSString *companyName;
@property (nonatomic, assign) CRRolType rol;

+ (BLUserExtended*)defaultUser;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSString*)nameLastnameString;
- (NSString *)description;
- (NSString*)avatarThumbImageWebPath;
+ (NSString*)avatarThumbImageWebPathWithId:(NSString *) id_user;
+ (NSString*)avatarGroupThumbImageWebPathWithId:(NSString *) id_user;

@end
