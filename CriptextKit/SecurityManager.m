//
//  KeychainManager.m
//  Criptext
//
//  Created by Gianni Carlo on 1/28/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import "SecurityManager.h"
#import "UICKeyChainStore.h"
#import "RNCryptor.h"
#import "NSData+Base64.h"
#import "Criptext.h"

#include <openssl/bn.h>
#include <openssl/dsa.h>
#include <openssl/rsa.h>
#include <openssl/opensslv.h>
#include <openssl/engine.h>
#include <openssl/pem.h>

@interface SecurityManager ()
@property (strong, nonatomic) UICKeyChainStore *keychainStore;
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
//    NSString *pemkey = [NSString stringWithFormat:@"%@%@%@", @"-----BEGIN PUBLIC KEY-----\n", key, @"-----END PUBLIC KEY-----\n"];
//    NSLog(@"pemkey: %@", pemkey);
//    const char *charkey = [pemkey UTF8String];
//    NSLog(@"charkey: %s",charkey);
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
    return [NSString stringWithFormat:@"%s", encriptarRSA([self.keychainStore[@"firstShake"] UTF8String], (unsigned char *) [(NSString *)self.keychainStore[@"myAESKey"] UTF8String]) ];
}

#pragma mark - RSA encryption
-(NSData *)rsaEncryptData:(NSData *)data withPublicKey:(NSString *)publicKey{
    
    return nil;
}
#pragma mark - AES Key
- (NSData*)generateSalt256 {
    unsigned char salt[32];
    for (int i=0; i<32; i++) {
        salt[i] = (unsigned char)arc4random();
    }
    return [NSData dataWithBytes:salt length:32];
}

static const RNCryptorKeyDerivationSettings mySettings = {
    .keySize = kCCKeySizeAES256,
    .saltSize = 32,
    .PBKDFAlgorithm = kCCPBKDF2,
    .PRF = kCCPRFHmacAlgSHA1,
    .rounds = 10000
};

- (NSData *)generateAESKey{
    NSData *aesKey =[RNCryptor keyForPassword:@"testingpassword" salt:[self generateSalt256] settings:mySettings];
    [self storeAESKey:aesKey withIdentifier:@"myAESKey"];
    return aesKey;
}

@end
