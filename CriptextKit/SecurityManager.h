//
//  SecurityManager.h
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BLMessage;

@interface SecurityManager : NSObject

+(instancetype)sharedInstance;


//Keychain Services
-(BOOL)storeObject:(NSString *)object withIdentifier:(NSString *)identifier;
-(NSString *)getObjectForIdentifier:(NSString *)identifier;

-(BOOL)storeKey:(NSString *)key withIdentifier:(NSString *)identifier;

-(BOOL)storeAESKey:(NSData *)aesKey withIdentifier:(NSString *)identifier;
-(NSData *)getAESKeyForIdentifier:(NSString *)identifier;

//possibly split generate and encrypt
-(NSString *)generateAndEncryptAESKey;
//test descript
- (NSString *)decrypttest:(NSString *)stringtodecrypt;

//encryption and decryption
-(BLMessage *)aesEncryptIncomingMessage:(BLMessage *)message;
-(BLMessage *)aesEncryptOutgoingMessage:(BLMessage *)message;
-(BLMessage *)aesDecryptIncomingMessage:(BLMessage *)message;
-(BLMessage *)aesDecryptOutgoingMessage:(BLMessage *)message;
-(NSString *)aesEncryptPlainText:(NSString *)stringToEncrypt fromUser:(NSString *)userId;
-(NSString *)aesDecryptedStringFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId;
-(NSData *)aesEncryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *)aesDecryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv;
//for open
-(NSString *)aesDecryptAndStoreKeyFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId;


//other users aes
-(BOOL)storeBase64AESKeyAndIV:(NSString *)base64string forUser:(NSString *)userId;
-(NSString *)getAESbase64forUser:(NSString *)userId;
-(NSString *)getIVbase64forUser:(NSString *)userId;


@end
