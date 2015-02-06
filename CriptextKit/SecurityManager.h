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

-(BOOL)storeObject:(NSString *)object withIdentifier:(NSString *)identifier;
-(NSString *)getObjectForIdentifier:(NSString *)identifier;

-(BOOL)storeKey:(NSString *)key withIdentifier:(NSString *)identifier;
-(BOOL)storeAESKey:(NSData *)aesKey withIdentifier:(NSString *)identifier;
-(NSData *)getAESKeyForIdentifier:(NSString *)identifier;

//possibly split generate and encrypt
-(NSString *)generateAndEncryptAESKey;

-(NSData *)rsaEncryptData:(NSData *)data withPublicKey:(NSString *)publicKey;




-(NSString *)aesEncryptedKey;
@end
