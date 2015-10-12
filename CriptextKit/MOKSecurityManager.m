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
const char *sync_publicKey = "-----BEGIN PUBLIC KEY-----\n"
"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvF6h6ev2VHSzfd8QR4ek\n"
"O7qbBGdxaKgT5hylD9te9sggXIyVv8aiNHmecaJocyRXYP6DkoimkKq0K84OImpU\n"
"VcfmX73I3mNJFLmWuDxFvuzOIdHx1y70ltrj63ETscMC+Zp2Comr3cz1LqAcnJzX\n"
"LEOf9YFp8AsQD8dc9YH2igc4U3JrJWXKOxkDgjaiDNLw1v6FRXbJirNbU3GrJiXj\n"
"nKmPE7l8UbpPYSAibsijM8ZsUHe9Wms34BZsj2a3I8tB5lubIXmIh0AgBlrMt+1l\n"
"Tc43LSLtilzX2xsz3iJOjVnib2DaeqQ8OVDTmJqesgV/lhx6ZnqC/n5Ixi9i8CW0\n"
"fQIDAQAB\n"
"-----END PUBLIC KEY-----\n";

// private key
const char *sync_privkey = "-----BEGIN RSA PRIVATE KEY-----\n"
"MIIEpgIBAAKCAQEAvF6h6ev2VHSzfd8QR4ekO7qbBGdxaKgT5hylD9te9sggXIyV\n"
"v8aiNHmecaJocyRXYP6DkoimkKq0K84OImpUVcfmX73I3mNJFLmWuDxFvuzOIdHx\n"
"1y70ltrj63ETscMC+Zp2Comr3cz1LqAcnJzXLEOf9YFp8AsQD8dc9YH2igc4U3Jr\n"
"JWXKOxkDgjaiDNLw1v6FRXbJirNbU3GrJiXjnKmPE7l8UbpPYSAibsijM8ZsUHe9\n"
"Wms34BZsj2a3I8tB5lubIXmIh0AgBlrMt+1lTc43LSLtilzX2xsz3iJOjVnib2Da\n"
"eqQ8OVDTmJqesgV/lhx6ZnqC/n5Ixi9i8CW0fQIDAQABAoIBAQCObXs9lSXHDApf\n"
"hRcZDq2WX+0wMkrk2Blbp5MC31r5e65EbCQaQkWJKeAsiaEyVmsfMrInTN2sivX6\n"
"HS5AxWcJCUHeaHCF/kpWulEE8sXFq+XcWpLiomVb3xvwfKpogUwxkKHqK9hgt8U3\n"
"QOcBX/GuTV+YUQbZ8nNtis917pOMHscjArKNdqdNEDuS2jUqCvYCAvHumVFK2eN/\n"
"HgY02A0sZn3AmB7NkjeG8+fJ7Qjo2IESSVlmhTqnz4c2BA4Y8hEuLFusLVBA3De3\n"
"RvBMiiGC6DH3W+fCAOh/AAHSS3uyy7rHPZNdjOxfC9NTvU3GTbtiT8VY/giM4GaG\n"
"HcWSy0J9AoGBAOOjtzaL5xu2stG5RIA6gnxNTMQQFgZvMx4SQduTQ5SEJ/HIE/mX\n"
"MQnR7TyTZRyPGSbMVX/EHcb0r5AGdei2EjxSpMony67So7rXHoizBWlEbLRJ4DVf\n"
"v9R5HfTec5pBFdWwmtOsxH5FNGK9DI/B79qAJx+Z+dUl2Bz8HyFU6f5PAoGBANPW\n"
"c+N2vFYQLt8lbUXyh6vQ8lZmZLmkYMp46BOg7KQo6SI4lCu/R1cg8eyRmIwgDbWL\n"
"xGdR+0rsCp0rOYPBrXWO2Zc4Qda383U/sQYQVOHdUz+DPMXDqyE7xGdJzNVhdzPP\n"
"4yUuQ2ChuZQrtyHNNc5VFqHAoPhZKybaWdhTsVlzAoGBAJfT9vvzneY3GdeVqSGZ\n"
"ZLSBXiUa0YXjHwX8iV5pP1bMOlQh7Wi4NaXmFUQkzviYXN8qxA/efznWs03tcTEQ\n"
"VuNS/8QxfMGSjk+s8RmdxYsrbxFkgJ04ypptWdSbliEZLfYDv5BVGA1cHQ+KJdmw\n"
"MUjb1rxWF3LZteXHJwA1QYgzAoGBAJ0Eazfh7a2ZJzTtp/Zd06ROJyJVmTllFv1c\n"
"6yCJen4feNaNu35FtJpnaAqizMCojaDQbY7r3GjnVuKyhFod9/WYIb6Ny3ddOA7j\n"
"W9KTzmbwR2FfZG9uHm1uwKCSuko7iUCVSddoWDbLCSRD1uUuF0DOHw1cG7SZW3vc\n"
"AxZuypjzAoGBAN0/7w/C1xxMWG6z6MciUbjpDyBWgcqQcqTl+td9FxlRHI4sspAp\n"
"FEsZP+bbER+pKFcHSwevRHGOwzoxSFLQ3bLe0AKbSaNhHe+b2BXXgqo+jGITrrWM\n"
"dAAFMAWf/JsKdnI/9gRh9JM6mw9GZio0HDu209EjNAcvc2lnWJaIZbwC\n"
"-----END RSA PRIVATE KEY-----\n";


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
        [self storeObject:[NSString stringWithUTF8String:sync_publicKey] withIdentifier:SYNC_PUBKEY];
        [self storeObject:[NSString stringWithUTF8String:sync_privkey] withIdentifier:SYNC_PRIVKEY];
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
    NSRange range= [base64string rangeOfString:@"=" options:NSBackwardsSearch];
    
    //stripping the garbage at the end
    NSString *finalbase64string = [base64string substringToIndex:range.location+1];
    finalbase64string = [NSString stringWithUTF8String:[finalbase64string UTF8String]];
    base64string = finalbase64string;
    #ifdef DEBUG
    NSLog(@"MONKEY - final base 64 key and IV: %@test", finalbase64string);
    #endif
    [self.keychainStore setString:finalbase64string forKey:userId error:&error];
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
