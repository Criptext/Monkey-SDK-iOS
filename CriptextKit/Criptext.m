//
//  Criptext.m
//  CriptextKit
//
//  Created by Gianni Carlo on 2/3/15.
//  Copyright (c) 2015 Criptext. All rights reserved.
//

#import "Criptext.h"

#define PADDING RSA_PKCS1_PADDING

const static char* b64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" ;

// maps A=>0,B=>1..
const static unsigned char unb64[]={
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //10
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //20
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //30
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //40
    0,   0,   0,  62,   0,   0,   0,  63,  52,  53, //50
    54,  55,  56,  57,  58,  59,  60,  61,   0,   0, //60
    0,   0,   0,   0,   0,   0,   1,   2,   3,   4, //70
    5,   6,   7,   8,   9,  10,  11,  12,  13,  14, //80
    15,  16,  17,  18,  19,  20,  21,  22,  23,  24, //90
    25,   0,   0,   0,   0,   0,   0,  26,  27,  28, //100
    29,  30,  31,  32,  33,  34,  35,  36,  37,  38, //110
    39,  40,  41,  42,  43,  44,  45,  46,  47,  48, //120
    49,  50,  51,   0,   0,   0,   0,   0,   0,   0, //130
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //140
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //150
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //160
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //170
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //180
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //190
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //200
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //210
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //220
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //230
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //240
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0, //250
    0,   0,   0,   0,   0,   0,
}; // This array has 255 elements

char* hash_base64( const void* binaryData, int len, int *flen )
{
    const unsigned char* bin = (const unsigned char*) binaryData ;
    char* res ;
    
    int rc = 0 ; // result counter
    int byteNo ; // I need this after the loop
    
    int modulusLen = len % 3 ;
    int pad = ((modulusLen&1)<<1) + ((modulusLen&2)>>1) ; // 2 gives 1 and 1 gives 2, but 0 gives 0.
    
    *flen = 4*(len + pad)/3 ;
    res = (char*) malloc( *flen + 1 ) ; // and one for the null
    if( !res )
    {
        puts( "ERROR: base64 could not allocate enough memory." ) ;
        puts( "I must stop because I could not get enough" ) ;
        return 0;
    }
    
    for( byteNo = 0 ; byteNo <= len-3 ; byteNo+=3 )
    {
        unsigned char BYTE0=bin[byteNo];
        unsigned char BYTE1=bin[byteNo+1];
        unsigned char BYTE2=bin[byteNo+2];
        res[rc++]  = b64[ BYTE0 >> 2 ] ;
        res[rc++]  = b64[ ((0x3&BYTE0)<<4) + (BYTE1 >> 4) ] ;
        res[rc++]  = b64[ ((0x0f&BYTE1)<<2) + (BYTE2>>6) ] ;
        res[rc++]  = b64[ 0x3f&BYTE2 ] ;
    }
    
    if( pad==2 )
    {
        res[rc++] = b64[ bin[byteNo] >> 2 ] ;
        res[rc++] = b64[ (0x3&bin[byteNo])<<4 ] ;
        res[rc++] = '=';
        res[rc++] = '=';
    }
    else if( pad==1 )
    {
        res[rc++]  = b64[ bin[byteNo] >> 2 ] ;
        res[rc++]  = b64[ ((0x3&bin[byteNo])<<4)   +   (bin[byteNo+1] >> 4) ] ;
        res[rc++]  = b64[ (0x0f&bin[byteNo+1])<<2 ] ;
        res[rc++] = '=';
    }
    
    res[rc]=0; // NULL TERMINATOR! ;)
    return res ;
}

unsigned char* hash_unbase64( const char* ascii, int len, int *flen )
{
    const unsigned char *safeAsciiPtr = (const unsigned char*)ascii ;
    unsigned char *bin ;
    int cb=0;
    int charNo;
    int pad = 0 ;
    
    if( len < 2 ) { // 2 accesses below would be OOB.
        // catch empty string, return NULL as result.
        puts( "ERROR: You passed an invalid base64 string (too short). You get NULL back." ) ;
        *flen=0;
        return 0 ;
    }
    if( safeAsciiPtr[ len-1 ]=='=' )  ++pad ;
    if( safeAsciiPtr[ len-2 ]=='=' )  ++pad ;
    
    *flen = 3*len/4 - pad ;
    bin = (unsigned char*)malloc( *flen ) ;
    if( !bin )
    {
        puts( "ERROR: unbase64 could not allocate enough memory." ) ;
        puts( "I must stop because I could not get enough" ) ;
        return 0;
    }
    
    for( charNo=0; charNo <= len - 4 - pad ; charNo+=4 )
    {
        int A=unb64[safeAsciiPtr[charNo]];
        int B=unb64[safeAsciiPtr[charNo+1]];
        int C=unb64[safeAsciiPtr[charNo+2]];
        int D=unb64[safeAsciiPtr[charNo+3]];
        
        bin[cb++] = (A<<2) | (B>>4) ;
        bin[cb++] = (B<<4) | (C>>2) ;
        bin[cb++] = (C<<6) | (D) ;
    }
    
    if( pad==1 )
    {
        int A=unb64[safeAsciiPtr[charNo]];
        int B=unb64[safeAsciiPtr[charNo+1]];
        int C=unb64[safeAsciiPtr[charNo+2]];
        
        bin[cb++] = (A<<2) | (B>>4) ;
        bin[cb++] = (B<<4) | (C>>2) ;
    }
    else if( pad==2 )
    {
        int A=unb64[safeAsciiPtr[charNo]];
        int B=unb64[safeAsciiPtr[charNo+1]];
        
        bin[cb++] = (A<<2) | (B>>4) ;
    }
    
    return bin ;
}

RSA* loadPUBLICKeyFromString( const char* publicKeyStr )
{
    // A BIO is an I/O abstraction (Byte I/O?)
    
    // BIO_new_mem_buf: Create a read-only bio buf with data
    // in string passed. -1 means string is null terminated,
    // so BIO_new_mem_buf can find the dataLen itself.
    // Since BIO_new_mem_buf will be READ ONLY, it's fine that publicKeyStr is const.
    BIO* bio = BIO_new_mem_buf( (void*)publicKeyStr, -1 ) ; // -1: assume string is null terminated
    
    BIO_set_flags( bio, BIO_FLAGS_BASE64_NO_NL ) ; // NO NL
    
    // Load the RSA key from the BIO
    RSA* rsaPubKey = PEM_read_bio_RSA_PUBKEY( bio, NULL, NULL, NULL ) ;
    if( !rsaPubKey )
        printf( "ERROR: Could not load PUBLIC KEY!  PEM_read_bio_RSA_PUBKEY FAILED: %s\n", ERR_error_string( ERR_get_error(), NULL ) ) ;
    
    BIO_free( bio ) ;
    return rsaPubKey ;
}

unsigned char* rsaEncrypt( RSA *pubKey, const unsigned char* str, int dataSize, int *resultLen )
{
    int rsaLen = RSA_size( pubKey ) ;
    unsigned char* ed = (unsigned char*)malloc( rsaLen ) ;
    
    // RSA_public_encrypt() returns the size of the encrypted data
    // (i.e., RSA_size(rsa)). RSA_private_decrypt()
    // returns the size of the recovered plaintext.
    *resultLen = RSA_public_encrypt( dataSize, (const unsigned char*)str, ed, pubKey, PADDING ) ;
    if( *resultLen == -1 )
        printf("ERROR: RSA_public_encrypt: %s\n", ERR_error_string(ERR_get_error(), NULL));
    
    return ed ;
}

// You may need to encrypt several blocks of binary data (each has a maximum size
// limited by pubKey).  You shoudn't try to encrypt more than
// RSA_LEN( pubKey ) bytes into some packet.
// returns base64( rsa encrypt( <<binary data>> ) )
// base64OfRsaEncrypted()
// base64StringOfRSAEncrypted
// rsaEncryptThenBase64
char* rsaEncryptThenBase64( RSA *pubKey, unsigned char* binaryData, int binaryDataLen, int *outLen )
{
    int encryptedDataLen ;
    
    // RSA encryption with public key
    unsigned char* encrypted = rsaEncrypt( pubKey, binaryData, binaryDataLen, &encryptedDataLen ) ;
    
    // To base 64
    int asciiBase64EncLen;
    char* asciiBase64Enc = hash_base64( encrypted, encryptedDataLen, &asciiBase64EncLen ) ;
    
    // Destroy the encrypted data (we are using the base64 version of it)
    free( encrypted ) ;
    
    // Return the base64 version of the encrypted data
    return asciiBase64Enc ;
}

char *encriptarRSA(const char *b64_pKey,unsigned char* mensaje){
    
    ERR_load_crypto_strings();
    
    // String to encrypt, INCLUDING NULL TERMINATOR:
    int dataSize=240 ; // 128 for NO PADDING, __ANY SIZE UNDER 128 B__ for RSA_PKCS1_PADDING
    
    // LOAD PUBLIC KEY
    RSA *pubKey = loadPUBLICKeyFromString( b64_pKey ) ;
    
    int asciiB64ELen ;
    char* asciiB64E = rsaEncryptThenBase64( pubKey, mensaje, dataSize, &asciiB64ELen ) ;
    
    RSA_free( pubKey ) ; // free the public key when you are done all your encryption
    //free( asciiB64E ) ; // rxOverHTTP
    ERR_free_strings();
    
    return asciiB64E;
    
}
