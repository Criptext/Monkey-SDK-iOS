//
//  Criptext.h
//  CriptextKit
//
//  Created by Gianni Carlo on 2/3/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <openssl/bn.h>
#include <openssl/dsa.h>
#include <openssl/rsa.h>
#include <openssl/aes.h>
#include <openssl/opensslv.h>
#include <openssl/engine.h>
#include <openssl/pem.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

//char *encriptar(unsigned char* mensaje);
char *encriptarRSA(const char *b64_pKey,unsigned char* mensaje);
NSString *decriptarRSA(const char *b64priv_key,unsigned char* base64_mensaje);
char *encriptarAES(NSString *aesKey,unsigned char* mensaje);
