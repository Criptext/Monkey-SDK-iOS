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
#define SYNC_PUBKEY   @"mok_sync_pubKey"
#define SYNC_PRIVKEY   @"mok_sync_privKey"
#define MY_AESKEY      @"myAESKey"
#define MY_IV			@"myIV"

@interface MOKSecurityManager ()

@property (strong, nonatomic) NSMutableDictionary *loadedKeys;
@end

@implementation MOKSecurityManager

#pragma mark initialization
static MOKSecurityManager *securityManagerInstance = nil;
+ (instancetype)sharedInstance
{
    
    @synchronized(securityManagerInstance) {
        if (securityManagerInstance == nil) {
            securityManagerInstance = [[self alloc] initPrivate];
        }
        
        return securityManagerInstance;
    }
    
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use [MOKSecurityManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _keychainStore = [UICKeyChainStore keyChainStoreWithService:@"com.criptextkit.app"];
        RSA *rsaKeyPair = NULL;
        //        EVP_PKEY *PrivateKey = NULL;
        rsaKeyPair = RSA_new();
        
        BIGNUM *e = NULL;
        e = BN_new();
        BN_set_word(e, 5);
        
        //Generating KeyPair
        RSA_generate_key_ex(rsaKeyPair, 2048, e, NULL);
        
        //        PrivateKey = EVP_PKEY_new();
        
        BIO *pri = BIO_new(BIO_s_mem());
        BIO *pub = BIO_new(BIO_s_mem());
        
        
        PEM_write_bio_RSAPrivateKey(pri, rsaKeyPair, NULL, NULL, 0, NULL, NULL);
        PEM_write_bio_RSAPublicKey(pub, rsaKeyPair);
        
        size_t pri_len = BIO_pending(pri);
        size_t pub_len = BIO_pending(pub);
        
        char *pri_key = malloc(pri_len+1);
        char *pub_key = malloc(pub_len+1);
        
        BIO_read(pri, pri_key, pri_len);
        BIO_read(pub, pub_key, pub_len);
        
        pri_key[pri_len] = '\0';
        pub_key[pub_len] = '\0';
        
        NSString *PK = [[[NSString stringWithFormat:@"%s",pri_key] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
        PK = [NSString stringWithUTF8String:pri_key];
        
        NSString *PKK = [[[NSString stringWithFormat:@"%s",pub_key] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
        PKK = [NSString stringWithUTF8String:pub_key];
        PKK = [[PKK stringByReplacingOccurrencesOfString:@" RSA" withString:@""] stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        
        EVP_PKEY* pkey = EVP_PKEY_new();
        
        int rc = EVP_PKEY_set1_RSA(pkey, rsaKeyPair);
        //        EVP_PKEY_free(pkey);
        
        BIO *pub2 = BIO_new(BIO_s_mem());
        
        PEM_write_bio_PUBKEY(pub2, pkey);
        
        size_t pub_len2 = BIO_pending(pub2);
        char *pub_key2 = malloc(pub_len2+1);
        
        BIO_read(pub2, pub_key2, pub_len2);
        
        pub_key2[pub_len2] = '\0';
        
        [self storeObject:[NSString stringWithUTF8String:pub_key2] withIdentifier:SYNC_PUBKEY];
        [self storeObject:PK withIdentifier:SYNC_PRIVKEY];
    }
    return self;
}
-(void)logout{
    @synchronized(securityManagerInstance) {
        securityManagerInstance = nil;
    }
}
#pragma mark - Keychain Services
-(BOOL)storeObject:(NSString *)key withIdentifier:(NSString *)identifier{
    NSError *error;
    [self.keychainStore setString:key forKey:identifier error:&error];

    if (error) {
        NSLog(@"MONKEY - %@", error.localizedDescription);
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
    [aesKey base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [self.keychainStore setString:[aesKey mok_base64EncodedString] forKey:identifier error:&error];
    if (error) {
        NSLog(@"MONKEY - %@", error.localizedDescription);
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
    
    #ifdef DEBUG
    NSLog(@"MONKEY - final base 64 key and IV: %@test", base64string);
    #endif
    [self.keychainStore setString:base64string forKey:userId error:&error];
    if (error) {
        NSLog(@"MONKEY - %@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSString *)getIVbase64forUser:(NSString *)userId{
    NSString *aesAndiv = self.keychainStore[userId];
    NSArray *arrays = [aesAndiv componentsSeparatedByString:@":"];
    #ifdef DEBUG
    NSLog(@"MONKEY - el iv: %@test", [arrays lastObject]);
    #endif

    return [arrays lastObject];
}

-(NSString *)getAESbase64forUser:(NSString *)userId{
    NSString *aesandiv = self.keychainStore[userId];
    #ifdef DEBUG
    NSLog(@"MONKEY - sacando el aes iv concatenado: %@ for sessionid: %@", aesandiv, userId);
    #endif
    NSArray *array = [aesandiv componentsSeparatedByString:@":"];
    return [array firstObject];
}
//
-(BOOL)storeNSData:(NSData *)data withIdentifier:(NSString *)identifier{
    NSError *error;
    [self.keychainStore setString:[data mok_base64EncodedString] forKey:identifier error:&error];
    if (error) {
        NSLog(@"MONKEY - %@", error.localizedDescription);
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
        NSLog(@"MONKEY - %@", error.localizedDescription);
        return false;
    }
    return true;
}

-(NSData *)getIV:(NSString *)identifier{
    return [NSData mok_dataFromBase64String:self.keychainStore[identifier]];
}


#pragma mark - RSA encryption
-(NSString *)stripGarbage:(NSString *)s {
    
    //NSLog(@"antes:%@",s);
    NSString *sb=@"";
    for (int i = 0; i < [s length]; i++) {
        char ch = [s characterAtIndex:i];
        if ((ch >= 'A' && ch <= 'Z') ||
            (ch >= 'a' && ch <= 'z') ||
            (ch >= '0' && ch <= '9') ||
            ch == '%' || ch == '_' ||
            ch == '-' || ch == '!' ||
            ch == '.' || ch == '~' ||
            ch == '(' || ch == ')' ||
            ch == '*' || ch == '\'' ||
            ch == ';' || ch == '/' ||
            ch == '?' || ch == ':' ||
            ch == '@' || ch == '=' ||
            ch == '&' || ch == '$' ||
            ch == ',' || ch == '+') {
            sb=[NSString stringWithFormat:@"%@%c",sb,ch];
        }
        else
            break;
    }
    //NSLog(@"despues:%@",sb);
    
    return [sb stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

-(NSString *)rsaEncryptBase64String:(NSString *)string withPublicKeyIdentifier:(NSString *)identifier{
    NSString *pubKey = self.keychainStore[identifier];
    return [NSString stringWithFormat:@"%s", encriptarRSA([pubKey UTF8String], (unsigned char *) [string UTF8String]) ];
}
-(NSString *)rsaDecryptBase64String:(NSString *)string withPrivateKeyIdentifier:(NSString *)identifier{
    NSString *privKey = self.keychainStore[identifier];
    return [self stripGarbage:decriptarRSA([privKey UTF8String], (unsigned char *) [string UTF8String])];
}
#pragma mark - AES encryption and decryption
-(MOKMessage *)aesEncryptIncomingMessage:(MOKMessage *)message{
    message.encryptedText = [self aesEncryptPlainText:message.messageText fromUser:message.userIdTo];
    return message;
}
-(MOKMessage *)aesEncryptOutgoingMessage:(MOKMessage *)message{
    #ifdef DEBUG
    NSLog(@"MONKEY - encriptando mensaje de: %@", message.userIdFrom);
    NSLog(@"MONKEY - aes guardado de este user: %@", self.keychainStore[message.userIdFrom]);
    NSLog(@"MONKEY - mensaje a encriptar: %@", message.messageText);
    NSLog(@"MONKEY - iv en base64: %@", [self getIVbase64forUser:message.userIdFrom]);
	#endif
    NSString *ivtmp = [self getIVbase64forUser:message.userIdFrom];
    NSData *data = [[NSData alloc]initWithBase64EncodedString:ivtmp options:0];
    #ifdef DEBUG
    NSLog(@"MONKEY - iv en data: %@", data);
	#endif
    message.encryptedText = [self aesEncryptPlainText:message.messageText fromUser:message.userIdFrom];
    return message;
}
-(MOKMessage *)aesDecryptIncomingMessage:(MOKMessage *)message{
    #ifdef DEBUG
    NSLog(@"MONKEY - decryptando mensaje de: %@", message.userIdFrom);
    NSLog(@"MONKEY - aes guardado de este user: %@", self.keychainStore[message.userIdFrom]);
    NSLog(@"MONKEY - mensaje a decriptar: %@", message.encryptedText);
	#endif
    message.messageText = [self aesDecryptedStringFromStringBase64:message.encryptedText fromUser:message.userIdFrom];
    #ifdef DEBUG
    NSLog(@"MONKEY - mensaje decriptado: %@", message.messageText);
	#endif
    return message;
}
-(MOKMessage *)aesDecryptOutgoingMessage:(MOKMessage *)message{
    message.messageText = [self aesDecryptedStringFromStringBase64:message.encryptedText fromUser:message.userIdTo];
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
    NSString *aesbase64 = [self getAESbase64forUser:userId];
    NSData *aesdata = [NSData mok_dataFromBase64String:aesbase64];
    NSString *ivbase64 = [self getIVbase64forUser:userId];

    NSData *ivdata = [[NSData alloc]initWithBase64EncodedString:ivbase64 options:0];
//    NSData *ivdata = [NSData mok_dataFromBase64String:ivbase64];
    
    return [[self aesEncryptData:[stringToEncrypt dataUsingEncoding:NSUTF8StringEncoding] withKey:aesdata andIV:ivdata] mok_base64EncodedString];
}

-(NSString *)aesEncryptNSData:(NSData *)dataToEncrypt fromUser:(NSString *)userId{
    return [[self aesEncryptData:dataToEncrypt withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]] mok_base64EncodedString];
}
-(NSData *)aesDecryptedDataFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId{
    return [self aesDecryptData:[NSData mok_dataFromBase64String:encryptedString] withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]];
}
-(NSString *)aesDecryptedStringFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId{
    #ifdef DEBUG
    NSLog(@"MONKEY - userid: %@", userId);
	#endif
    
    return [[NSString alloc]initWithData:[self aesDecryptData:[NSData mok_dataFromBase64String:encryptedString] withKey:[NSData mok_dataFromBase64String:[self getAESbase64forUser:userId]] andIV:[NSData mok_dataFromBase64String:[self getIVbase64forUser:userId]]] encoding:NSUTF8StringEncoding];
}

-(NSString *)aesDecryptAndStoreKeyFromStringBase64:(NSString *)encryptedString fromUser:(NSString *)userId{
    NSString *aesandiv = [self aesDecryptedStringFromStringBase64:encryptedString fromUser:[MOKSessionManager sharedInstance].sessionId];
    NSRange range= [aesandiv rangeOfString:@"=" options:NSBackwardsSearch];
    
    //stripping the garbage at the end
    NSString *finalbase64aesandiv = [aesandiv substringToIndex:range.location+1];
    if (finalbase64aesandiv != nil) {
        finalbase64aesandiv = [NSString stringWithUTF8String:[finalbase64aesandiv UTF8String]];
        [self storeBase64AESKeyAndIV:finalbase64aesandiv forUser:userId];
    }
    
    return finalbase64aesandiv;
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
    NSString *base64_iv = [iv mok_base64EncodedString];
//    NSData *encrypted = [BBAES encryptedDataFromData:[@"allyoop" dataUsingEncoding:NSUTF8StringEncoding] IV:[NSData mok_dataFromBase64String:base64_iv] key:aesKey options:0];
//    NSString *base64_encrypted = [encrypted mok_base64EncodedString];

//    NSData *decrypted = [BBAES decryptedDataFromString:base64_encrypted IV:[NSData mok_dataFromBase64String:base64_iv] key:aesKey];
//    NSString *decrypted_string =[[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
//    NSLog(@"MONKEY - test decrypted: %@", decrypted_string);
    
    NSString *base64_aesKey = [aesKey mok_base64EncodedString];
//    NSString *base64_iv = [iv mok_base64EncodedString];
    
    NSString *aesandiv = [NSString stringWithFormat:@"%@:%@", base64_aesKey, base64_iv];
    
    [self storeBase64AESKeyAndIV:aesandiv forUser:[MOKSessionManager sharedInstance].sessionId];
    
    NSString *stringToEncrypt = [NSString stringWithFormat:@"%@:%@",base64_aesKey,base64_iv];
    
    #ifdef DEBUG
    NSLog(@"MONKEY - stringToEncrypt: %@", stringToEncrypt);
	#endif
//    NSLog(@"MONKEY - publickey: %@", self.keychainStore[AUTHENTICATION_PUBKEY]);
    NSString *stringToSend = [self rsaEncryptBase64String:stringToEncrypt withPublicKeyIdentifier:AUTHENTICATION_PUBKEY];
    
    return stringToSend;
    
}



- (NSString *)decrypttest:(NSString *)stringtodecrypt{
    
    NSData *iv = [NSData mok_dataFromBase64String:@"aeBrjLZ89kadnOT0Wr8fEw=="];
    
    NSData *key = [NSData mok_dataFromBase64String:@"TjyBz8lG1p7bDsITh4Ro8S2S/HYjy6dkhpVQNM3DuZc="];
    
//    NSLog(@"MONKEY - key quemado: %@", key);
//    NSLog(@"MONKEY - aes quemado: %@",[[self getAESKeyForIdentifier:@"myAESKey"] base64EncodedString]);
//    NSLog(@"MONKEY - key decodedbase64: %@", key);
//    
//    NSLog(@"MONKEY - key decodedbase64 and data initwithbase64encodeddata: %@", [[NSData alloc]initWithBase64EncodedData:key options:NSDataBase64DecodingIgnoreUnknownCharacters]);
    
//   unsigned char *bytePtr = (unsigned char *)[key bytes];
//    NSLog(@"MONKEY - char: %s", bytePtr);
//    NSLog(@"MONKEY - mi key: %@", [self getAESKeyForIdentifier:[[SessionManager sharedInstance] idUser]]);
    
    
    NSData *string = [NSData mok_dataFromBase64String:stringtodecrypt];
    return [[NSString alloc] initWithData:[self aesDecryptData:string withKey:key andIV:iv] encoding:NSUTF8StringEncoding];
//    return nil;
    
}
@end
