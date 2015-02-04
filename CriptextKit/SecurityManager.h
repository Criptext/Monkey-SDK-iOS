//
//  SecurityManager.h
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SecurityManager : NSObject

+(instancetype)sharedInstance;

-(BOOL)storeKey:(NSString *)key withIdentifier:(NSString *)identifier;
-(BOOL)storeAESKey:(NSData *)aesKey withIdentifier:(NSString *)identifier;
-(BOOL)storeObject:(NSString *)object withIdentifier:(NSString *)identifier;
-(NSData *)rsaEncryptData:(NSData *)data withPublicKey:(NSString *)publicKey;
-(NSString *)getObjectForIdentifier:(NSString *)identifier;
-(NSData *)getAESKeyForIdentifier:(NSString *)identifier;
-(NSString *)generateAndEncryptAESKey;

-(NSString *)aesEncryptedKey;
@end
