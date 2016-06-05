//
//  SecurityManager.h
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MOKMessage;
@class UICKeyChainStore;

@interface MOKSecurityManager : NSObject
@property (strong, nonatomic) UICKeyChainStore *keychainStore;

+(instancetype)sharedInstance;

-(void)logout;

//Keychain Services

-(BOOL)storeObject:(NSString *)key withIdentifier:(NSString *)identifier;
-(NSString *)getObjectForIdentifier:(NSString *)identifier;

-(BOOL)storeAESKey:(NSData *)aesKey withIdentifier:(NSString *)identifier;
-(NSData *)getAESKeyForIdentifier:(NSString *)identifier;

//possibly split generate and encrypt
-(NSString *)generateAESKeyAndIV;

//possibly split generate and encrypt
-(NSString *)generateAESKey;

//encryption and decryption
-(NSString *)exportPublicKeyRSA;
//encrypt with a given pubkey
- (NSString *)rsaEncryptString:(NSString *)str publicKey:(NSString *)pubKey;
- (NSString *)rsaEncryptString:(NSString *)plainString;
- (NSString *)rsaDecryptString:(NSString *)encryptedString;

-(MOKMessage *)aesEncryptIncomingMessage:(MOKMessage *)message;
-(MOKMessage *)aesEncryptOutgoingMessage:(MOKMessage *)message;
-(MOKMessage *)aesDecryptIncomingMessage:(MOKMessage *)message;
-(MOKMessage *)aesDecryptOutgoingMessage:(MOKMessage *)message;
-(MOKMessage *)aesEncryptFileData:(NSData *)dataToEncrypt forMessage:(MOKMessage *)message;
-(NSData *)aesEncryptFileData:(NSData *)dataToEncrypt fromUser:(NSString *)userId;
-(NSData *)aesDecryptFileData:(NSData *)dataToDecrypt fromUser:(NSString *)userId;
-(NSString *)aesEncryptPlainText:(NSString *)stringToEncrypt fromUser:(NSString *)userId;
-(NSString *)aesDecryptedStringFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId;
-(NSData *)aesEncryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *)aesDecryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *)aesDecryptedDataFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId;
//for open
-(NSString *)aesDecryptAndStoreKeyFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId;


//other users aes
-(BOOL)storeBase64AESKeyAndIV:(NSString *)base64string forUser:(NSString *)userId;
-(NSString *)getAESbase64forUser:(NSString *)userId;
-(NSString *)getIVbase64forUser:(NSString *)userId;


@end
