//
//  KeychainManager.m
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import "SecurityManager.h"
#import "UICKeyChainStore.h"
#import "NSData+Base64.h"
#import "NSData+Conversion.h"
#import "Criptext.h"
#import "BBAES.h"

#import <CommonCrypto/CommonCrypto.h>

#define LOGIN_PUBKEY   @"authentication_pubKey"
#define MY_AESKEY      @"myAESKey"

@interface SecurityManager ()
@property (strong, nonatomic) UICKeyChainStore *keychainStore;
@property (strong, nonatomic) NSMutableDictionary *loadedKeys;
@end

@implementation SecurityManager

#pragma mark initialization
+ (instancetype)sharedInstance
{
    static SecurityManager *sharedInstance;
    
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
-(BOOL)storeKey:(NSString *)key withIdentifier:(NSString *)identifier{
    self.keychainStore[identifier] = key;
    return true;
}

-(BOOL)storeAESKey:(NSData *)aesKey withIdentifier:(NSString *)identifier{
    self.keychainStore[identifier] = [aesKey base64EncodedString];
    return true;
}

-(BOOL)storeObject:(NSString *)object withIdentifier:(NSString *)identifier{
    self.keychainStore[identifier] = object;
    return true;
}
-(NSString *)getObjectForIdentifier:(NSString *)identifier{
    return self.keychainStore[identifier];
}
-(NSData *)getAESKeyForIdentifier:(NSString *)identifier{
    return [NSData dataFromBase64String:self.keychainStore[identifier]];
}

-(NSString *)aesEncryptedKey{
    NSLog(@"test: %@",self.keychainStore[@"firstShake"]);
    return [NSString stringWithFormat:@"%s", encriptarRSA([self.keychainStore[@"firstShake"] UTF8String], (unsigned char *) [(NSString *)self.keychainStore[@"myAESKey"] UTF8String]) ];
}

#pragma mark - RSA encryption
-(NSString *)rsaEncryptBase64String:(NSString *)string withPublicKeyIdentifier:(NSString *)identifier{
    NSString *pubKey = self.keychainStore[identifier];
    NSLog(@"stringToEncrypt: %@", string);
    return [NSString stringWithFormat:@"%s", encriptarRSA([pubKey UTF8String], (unsigned char *) [string UTF8String]) ];
}

#pragma mark - AES Key
- (NSString *)generateAndEncryptAESKey{
    NSData *salt = [BBAES randomDataWithLength:BBAESSaltDefaultLength];
    NSData *aesKey = [BBAES keyBySaltingPassword:@"testingpassword" salt:salt keySize:BBAESKeySize256 numberOfIterations:BBAESPBKDF2DefaultIterationsCount];
    NSData *iv = [BBAES randomIV];
    
    NSData *encrypted = [BBAES encryptedDataFromData:[@"allyoop" dataUsingEncoding:NSUTF8StringEncoding] IV:iv key:aesKey options:0];
    NSString *base64_encrypted = [encrypted base64EncodedString];

    NSData *decrypted = [BBAES decryptedDataFromString:base64_encrypted IV:iv key:aesKey];
    NSString *decrypted_string =[[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    NSLog(@"test decrypted: %@", decrypted_string);
    
    [self storeAESKey:aesKey withIdentifier:MY_AESKEY];
    
    NSString *base64_aesKey = [aesKey base64EncodedString];
    NSString *base64_iv = [iv base64EncodedString];
    
    
    NSString *stringToEncrypt = [NSString stringWithFormat:@"%@:%@:%@",base64_aesKey,base64_iv,base64_encrypted];
    
    NSLog(@"stringToEncrypt: %@", stringToEncrypt);
    
    NSString *stringToSend = [self rsaEncryptBase64String:stringToEncrypt withPublicKeyIdentifier:LOGIN_PUBKEY];
    
    return stringToSend;
    
}

@end
