//
//  KeychainManager.m
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import "MOKSecurityManager.h"
#import "MOKSessionManager.h"
#import "UICKeyChainStore.h"
#import "NSData+Base64.h"
#import "NSData+Conversion.h"
#import "MOKCriptext.h"
#import "BBAES.h"
#import "MOKMessage.h"

#import <CommonCrypto/CommonCrypto.h>

#define AUTHENTICATION_PUBKEY   @"authentication_pubKey"
#define MY_AESKEY      @"myAESKey"
#define MY_IV			@"myIV"

@interface MOKSecurityManager ()
@property (strong, nonatomic) UICKeyChainStore *keychainStore;
@property (strong, nonatomic) NSMutableDictionary *loadedKeys;
@end

@implementation MOKSecurityManager

#pragma mark initialization
+ (instancetype)sharedInstance
{
    static MOKSecurityManager *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initPrivate];
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[KeychainManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _keychainStore = [UICKeyChainStore keyChainStoreWithService:@"com.criptextkit.app"];
    }
    return self;
}

/*TODO
> Decrypt with RSA
> Encrypt with RSA
> Generate AES Key
> Store/Replace AES keys in keychain
> Load Keys in memory in hash table
*/
#pragma mark - Keychain Services
-(BOOL)storeObject:(NSString *)key withIdentifier:(NSString *)identifier{
    NSError *error;
    [self.keychainStore setString:key forKey:identifier error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSString *)getObjectForIdentifier:(NSString *)identifier{
    return self.keychainStore[identifier];
}

-(NSString *)getKeyAsBase64ForIdentifier:(NSString *)identifier{
    return self.keychainStore[identifier];
}
//
-(BOOL)storeAESKey:(NSData *)aesKey withIdentifier:(NSString *)identifier{
    NSError *error;
    [self.keychainStore setString:[aesKey mok_base64EncodedString] forKey:identifier error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSData *)getAESKeyForIdentifier:(NSString *)identifier{
    return [NSData mok_dataFromBase64String:self.keychainStore[identifier]];
}
//
-(BOOL)storeBase64AESKeyAndIV:(NSString *)base64string forUser:(NSString *)userId{
    NSError *error;
    [self.keychainStore setString:base64string forKey:userId error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSString *)getIVbase64forUser:(NSString *)userId{
    NSString *aesandiv = self.keychainStore[userId];
    NSArray *array = [aesandiv componentsSeparatedByString:@":"];
    return [array lastObject];
}

-(NSString *)getAESbase64forUser:(NSString *)userId{
    NSString *aesandiv = self.keychainStore[userId];
    NSLog(@"sacando el aes iv concatenado: %@", aesandiv);
    NSArray *array = [aesandiv componentsSeparatedByString:@":"];
    return [array firstObject];
}
//
-(BOOL)storeNSData:(NSData *)data withIdentifier:(NSString *)identifier{
    NSError *error;
    [self.keychainStore setString:[data mok_base64EncodedString] forKey:identifier error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSData *)getNSDataForIdentifier:(NSString *)identifier{
    return [NSData mok_dataFromBase64String:self.keychainStore[identifier]];
}


//
-(BOOL)storeIV:(NSData *)iv withIdentifier:(NSString *)identifier{
    NSError *error;
    [self.keychainStore setString:[iv mok_base64EncodedString] forKey:identifier error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSData *)getIV:(NSString *)identifier{
    return [NSData mok_dataFromBase64String:self.keychainStore[identifier]];
}


#pragma mark - RSA encryption
-(NSString *)rsaEncryptBase64String:(NSString *)string withPublicKeyIdentifier:(NSString *)identifier{
    NSString *pubKey = self.keychainStore[identifier];
    return [NSString stringWithFormat:@"%s", encriptarRSA([pubKey UTF8String], (unsigned char *) [string UTF8String]) ];
}

#pragma mark - AES encryption and decryption
-(MOKMessage *)aesEncryptIncomingMessage:(MOKMessage *)message{
    message.messageText = [self aesEncryptPlainText:message.messageText fromUser:message.userIdTo];
    return message;
}
-(MOKMessage *)aesEncryptOutgoingMessage:(MOKMessage *)message{
    message.messageText = [self aesEncryptPlainText:message.messageText fromUser:message.userIdFrom];
    return message;
}
-(MOKMessage *)aesDecryptIncomingMessage:(MOKMessage *)message{
    NSLog(@"decryptando mensaje de: %@", message.userIdFrom);
    NSLog(@"aes guardado de este user: %@", self.keychainStore[message.userIdFrom]);
    message.messageText = [self aesDecryptedStringFromStringBase64:message.messageText fromUser:message.userIdFrom];
    return message;
}
-(MOKMessage *)aesDecryptOutgoingMessage:(MOKMessage *)message{
    message.messageText = [self aesDecryptedStringFromStringBase64:message.messageText fromUser:message.userIdTo];
    return message;
}


-(MOKMessage *)aesEncryptFileData:(NSData *)dataToEncrypt forMessage:(MOKMessage *)message{
    message.messageText = [self aesEncryptNSData:dataToEncrypt fromUser:message.userIdFrom];
    return message;
}
-(NSData *)aesEncryptFileData:(NSData *)dataToEncrypt fromUser:(NSString *)userId{
    return [self aesEncryptData:dataToEncrypt withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]] ;
}
-(NSData *)aesDecryptFileData:(NSData *)dataToDecrypt fromUser:(NSString *)userId{
    return [self aesDecryptData:dataToDecrypt withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]];
}
-(NSString *)aesEncryptPlainText:(NSString *)stringToEncrypt fromUser:(NSString *)userId{
    return [[self aesEncryptData:[stringToEncrypt dataUsingEncoding:NSUTF8StringEncoding] withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]] mok_base64EncodedString];
}

-(NSString *)aesEncryptNSData:(NSData *)dataToEncrypt fromUser:(NSString *)userId{
    return [[self aesEncryptData:dataToEncrypt withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]] mok_base64EncodedString];
}
-(NSData *)aesDecryptedDataFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId{
    return [self aesDecryptData:[NSData mok_dataFromBase64String:encryptedString] withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]];
}
-(NSString *)aesDecryptedStringFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId{
    NSLog(@"userid: %@", userId);
    return [[NSString alloc]initWithData:[self aesDecryptData:[NSData mok_dataFromBase64String:encryptedString] withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]] encoding:NSUTF8StringEncoding];
}

-(NSString *)aesDecryptAndStoreKeyFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId{
    NSString *aesandiv = [self aesDecryptedStringFromStringBase64:encryptedString fromUser:[MOKSessionManager sharedInstance].userId];
    [self storeBase64AESKeyAndIV:aesandiv forUser:userId];
    return aesandiv;
    
}

-(NSData *)aesEncryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv{
    return [BBAES encryptedDataFromData:data IV:iv key:key options:0];
}
-(NSData *)aesDecryptData:(NSData *)data withKey:(NSData *)key andIV:(NSData *)iv{
    return [BBAES decryptedDataFromData:data IV:iv key:key];
}



#pragma mark - AES Key
- (NSString *)generateAndEncryptAESKey{
    NSData *salt = [BBAES randomDataWithLength:BBAESSaltDefaultLength];
    NSData *aesKey = [BBAES keyBySaltingPassword:@"testingpassword" salt:salt keySize:BBAESKeySize256 numberOfIterations:BBAESPBKDF2DefaultIterationsCount];
    NSData *iv = [BBAES randomIV];
    
    NSData *encrypted = [BBAES encryptedDataFromData:[@"allyoop" dataUsingEncoding:NSUTF8StringEncoding] IV:iv key:aesKey options:0];
    NSString *base64_encrypted = [encrypted mok_base64EncodedString];
//
//    NSData *decrypted = [BBAES decryptedDataFromString:base64_encrypted IV:iv key:aesKey];
//    NSString *decrypted_string =[[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
//    
//    NSLog(@"test decrypted: %@", decrypted_string);
    
    NSString *base64_aesKey = [aesKey mok_base64EncodedString];
    NSString *base64_iv = [iv mok_base64EncodedString];
    
    NSString *aesandiv = [NSString stringWithFormat:@"%@:%@", base64_aesKey, base64_iv];
    
    [self storeBase64AESKeyAndIV:aesandiv forUser:[MOKSessionManager sharedInstance].userId];
    
    NSString *stringToEncrypt = [NSString stringWithFormat:@"%@:%@:%@",base64_aesKey,base64_iv,base64_encrypted];
    
    NSLog(@"stringToEncrypt: %@", stringToEncrypt);
//    NSLog(@"publickey: %@", self.keychainStore[AUTHENTICATION_PUBKEY]);
    NSString *stringToSend = [self rsaEncryptBase64String:stringToEncrypt withPublicKeyIdentifier:AUTHENTICATION_PUBKEY];
    
    return stringToSend;
    
}

- (NSString *)decrypttest:(NSString *)stringtodecrypt{
    
    NSData *iv = [NSData mok_dataFromBase64String:@"aeBrjLZ89kadnOT0Wr8fEw=="];
    
    NSData *key = [NSData mok_dataFromBase64String:@"TjyBz8lG1p7bDsITh4Ro8S2S/HYjy6dkhpVQNM3DuZc="];
    
//    NSLog(@"key quemado: %@", key);
//    NSLog(@"aes quemado: %@",[[self getAESKeyForIdentifier:@"myAESKey"] base64EncodedString]);
//    NSLog(@"key decodedbase64: %@", key);
//    
//    NSLog(@"key decodedbase64 and data initwithbase64encodeddata: %@", [[NSData alloc]initWithBase64EncodedData:key options:NSDataBase64DecodingIgnoreUnknownCharacters]);
    
//   unsigned char *bytePtr = (unsigned char *)[key bytes];
//    NSLog(@"char: %s", bytePtr);
//    NSLog(@"mi key: %@", [self getAESKeyForIdentifier:[[SessionManager sharedInstance] idUser]]);
    
    
    NSData *string = [NSData mok_dataFromBase64String:stringtodecrypt];
    return [[NSString alloc] initWithData:[self aesDecryptData:string withKey:key andIV:iv] encoding:NSUTF8StringEncoding];
//    return nil;
    
}
@end
