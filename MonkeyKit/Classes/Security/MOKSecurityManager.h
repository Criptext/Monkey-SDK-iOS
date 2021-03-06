//
//  SecurityManager.h
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MOKMessage;

@interface MOKSecurityManager : NSObject
+(instancetype)sharedInstance;

-(void)logout;

//Keychain Services
-(BOOL)storeObject:(NSString *)key withIdentifier:(NSString *)identifier;
-(NSString *)getObjectForIdentifier:(NSString *)identifier;


//RSA
//generate rsa keypair
- (void)generateKeyPairRSA;
//encrypt with keypair generated
- (NSString *)exportPublicKeyRSA;
- (NSString *)rsaEncryptString:(NSString *)plainString;
//decrypt with keypair generated
- (NSString *)rsaDecryptString:(NSString *)encryptedString;
//encrypt with a given pubkey
- (NSString *)rsaEncryptString:(NSString *)str publicKey:(NSString *)pubKey;


//AES
-(NSString *)generateAESKeyAndIV;
-(NSString *)aesEncryptText:(NSString *)text fromUser:(NSString *)userId;
-(NSString *)aesDecryptText:(NSString *)text fromUser:(NSString *)userId;

-(NSData *)aesEncryptData:(NSData *)data fromUser:(NSString *)userId;
-(NSData *)aesDecryptData:(NSData *)data fromUser:(NSString *)userId;

-(NSString *)aesEncryptText:(NSString *)text withKey:(NSString *)aes andIV:(NSString *)iv;
-(NSString *)aesDecryptText:(NSString *)text withKey:(NSString *)aes andIV:(NSString *)iv;

-(NSData *)aesEncryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *)aesDecryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv;


//for open
-(NSString *)aesDecryptKeyAndClean:(NSString *)encryptedString fromUser:(NSString *)userId;


//get users aes
-(NSString *)getAESbase64forUser:(NSString *)userId;
-(NSString *)getIVbase64forUser:(NSString *)userId;

//base64
-(NSString *)decodeBase64:(NSString *)encodedString;
-(NSString *)encodeBase64:(NSString *)plainString;

@end
