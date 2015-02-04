//
//  UserDefaultsController.m
//  Blip
//
//  Created by G V on 25.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UserDefaultsManager.h"

@implementation UserDefaultsManager
static UserDefaultsManager *userDefaultsManagerInstance = nil;
+ (UserDefaultsManager*)instance {
	@synchronized (self) {
		if (userDefaultsManagerInstance == nil) {
			userDefaultsManagerInstance = [[UserDefaultsManager alloc] init];
		}
	}
	return userDefaultsManagerInstance;
}


- (id)init {
	if (self = [super init]) {
		keys = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"SessionId", [NSNumber numberWithInt:udKeySessionId],
				@"DeviceToken", [NSNumber numberWithInt:udKeyDeviceToken],
				@"UserId", [NSNumber numberWithInt:udKeyUserId],
                @"UserName", [NSNumber numberWithInt:udKeyUserName],
                @"UserPassword", [NSNumber numberWithInt:udKeyUserPassword],
                [NSString stringWithFormat:@"%@:LastMessageId",[self loadUserId]], [NSNumber numberWithInt:udKeyLastMessageId],
                @"PassCode", [NSNumber numberWithInt:udKeyPassCode],
				nil];
	}
	return self;
}

- (NSUserDefaults *)myInstance{
    return [NSUserDefaults standardUserDefaults];
}

- (void)logErrorForKey:(UDKey)key {
	NSLog(@"Key string not found for key %d", key);
}

- (NSString*)keyForKey:(UDKey)key {
	return [keys objectForKey:[NSNumber numberWithInt:key]];
}

/*
- (void)storeObjectFree:(id)object forKey:(NSString *)keyString {
	@synchronized (self) {
			NSUserDefaults *defaults = [self myInstance];
			[defaults setObject:object forKey:keyString];
			[defaults synchronize];
	}
}
*/
- (void)storeObjectFree:(id)object forKey:(NSString *)keyString {
    @synchronized (self) {
        NSUserDefaults *defaults = [self myInstance];
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:object] forKey:keyString];
        [defaults synchronize];
        
    }
}

- (void)removeObjectFreeforKey:(NSString *)keyString {
	@synchronized (self) {
        NSUserDefaults *defaults = [self myInstance];
        [defaults removeObjectForKey:keyString];
        [defaults synchronize];
	}
}

/*
- (void)updateObjectFree:(id)object forKey:(NSString *)keyString {
    @synchronized (self) {
        NSUserDefaults *defaults = [self myInstance];
        [defaults removeObjectForKey:keyString];
        [defaults setObject:object forKey:keyString];
        [defaults synchronize];
	}
    
}
 */
- (void)updateObjectFree:(id)object forKey:(NSString *)keyString {
    @synchronized (self) {
        NSUserDefaults *defaults = [self myInstance];
        [defaults removeObjectForKey:keyString];
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:object] forKey:keyString];
        [defaults synchronize];
    }
}
/*
- (id)objectForKeyFree:(NSString *)keyString {
    
	@synchronized (self) {
        NSUserDefaults *defaults = [self myInstance];
        return [defaults objectForKey:keyString];
	}
	return nil;
}
*/
- (id)objectForKeyFree:(NSString *)keyString {
    
    @synchronized (self) {

        NSUserDefaults *defaults = [self myInstance];
        NSData *_data = [defaults objectForKey:keyString];
        
        NSObject *_dataArchive;
        if(_data!=NULL)
            _dataArchive = [NSKeyedUnarchiver unarchiveObjectWithData:_data];

        return _dataArchive;
    }
    return nil;
}

- (void)storeObject:(id)object forKey:(UDKey)key {
	@synchronized (self) {
		NSString *keyString = [self keyForKey:key];
		if (keyString != nil) {
            NSUserDefaults *defaults = [self myInstance];
			[defaults setObject:object forKey:keyString];
			[defaults synchronize];
		} else {
			[self logErrorForKey:key];
		}
	}
}

- (id)objectForKey:(UDKey)key {
	@synchronized (self) {
		NSString *keyString = [self keyForKey:key];
		if (keyString != nil) {
            NSUserDefaults *defaults = [self myInstance];
			return [defaults stringForKey:keyString];
		} else {
			[self logErrorForKey:key];
		}
	}
	return nil;
}

- (NSString*)stringForKey:(UDKey)key {
	@synchronized (self) {
		NSString *keyString = [self keyForKey:key];
		if (keyString != nil) {
            NSUserDefaults *defaults = [self myInstance];
			return [defaults objectForKey:keyString];
		} else {
			[self logErrorForKey:key];
		}
	}
	return nil;
}

- (void)storeInt:(int)object forKey:(UDKey)key {
	@synchronized (self) {
		NSString *keyString = [self keyForKey:key];
		if (keyString != nil) {
            NSUserDefaults *defaults = [self myInstance];
			[defaults setObject:[NSNumber numberWithInt:object] forKey:keyString];
			[defaults synchronize];
		} else {
			[self logErrorForKey:key];
		}
	}
}

- (int)intForKey:(UDKey)key {
	@synchronized (self) {
		NSString *keyString = [self keyForKey:key];
		if (keyString != nil) {
            NSUserDefaults *defaults = [self myInstance];
			return [defaults integerForKey:keyString];
		} else {
			[self logErrorForKey:key];
		}
	}
	return 0;
}

-(void)cleanAll{
    
    NSLog(@"XXX:CLEAN_ALL");
    NSString *userid=[self loadUserId];
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[self myInstance] removePersistentDomainForName:appDomain];
    
    //Mejor esto:
    NSUserDefaults *defaults = [self myInstance];
    NSArray *loskeys = [[defaults dictionaryRepresentation] allKeys];
    for(NSString* key in loskeys){
        if(![key isEqualToString:[NSString stringWithFormat:@"%@:LastMessageId",userid]])
            [defaults removeObjectForKey:key];
    }
    
}


- (NSString*)loadPassCode{
    return [self stringForKey:udKeyPassCode];
}

- (NSString*)loadSessionKey {
	return [self stringForKey:udKeySessionId];
}

- (NSString *)loadUserId{
    return [self stringForKey:udKeyUserId];
}

- (NSString *)loadUserName{
    return [self stringForKey:udKeyUserName];
}

- (NSString *)loadUserPassword{
    return [self objectForKeyFree:@"reference"];
}

- (NSString*)loadDeviceToken{
    return [self stringForKey:udKeyDeviceToken];
}

- (NSString *)loadLastMessageId{
    return [self stringForKey:udKeyLastMessageId] ;
}

- (void)storePassCode:(NSString*)passcode{
    [self storeObject:passcode forKey:udKeyPassCode];
}

- (void)storeSessionKey:(NSString*)sessionKey {
	[self storeObject:sessionKey forKey:udKeySessionId];
}

- (void)storeUserId:(NSString*)name{
    [self storeObject:name forKey:udKeyUserId];
}

- (void)storeUserName:(NSString*)name {
	[self storeObject:name forKey:udKeyUserName];
}

- (void)storeUserPassword:(NSString*)name{
    [self storeObjectFree:name forKey:@"reference"];
}

- (void)storeDeviceToken:(NSString*)name {
	[self storeObject:name forKey:udKeyDeviceToken];
}

- (void)storeLastMessageId:(NSString*)lastMessageId{

    
    [self storeObject:lastMessageId forKey:udKeyLastMessageId];
}

@end
