//
//  MOKSecurityTests.m
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/8/16.
//  Copyright © 2016 Gianni Carlo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MonkeyKit/MonkeyKit.h>

@interface MOKSecurityTests : XCTestCase
@property (strong, nonatomic) NSString *providedAES;
@property (strong, nonatomic) NSString *providedPubKey;
@end

@implementation MOKSecurityTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStoreObject {
    NSString *plainText = @"Hello World!";
    NSString *identifier = @"TestIdentifier";
    BOOL isStored = [[MOKSecurityManager sharedInstance] storeObject:plainText withIdentifier:identifier];
    XCTAssertTrue(isStored);
    
    NSString *retreivedString = [[MOKSecurityManager sharedInstance] getObjectForIdentifier:identifier];
    XCTAssertTrue([plainText isEqualToString:retreivedString]);
}

- (void)testRSAencryption {
    NSString *plainText = @"Hello World!";
    NSString *encryptedText = [[MOKSecurityManager sharedInstance] rsaEncryptString:plainText];
    XCTAssertNotNil(encryptedText);
    
    NSString *decryptedText = [[MOKSecurityManager sharedInstance] rsaDecryptString:encryptedText];
    XCTAssertNotNil(decryptedText);
    
    XCTAssertTrue([plainText isEqualToString:decryptedText]);
}

- (void)testAESencryption {
    NSString *meIdentifier = @"MeId";
    NSString *aes = [[MOKSecurityManager sharedInstance] generateAESKeyAndIV];
    XCTAssertNotNil(aes);
    
    BOOL isStored = [[MOKSecurityManager sharedInstance] storeObject:aes withIdentifier:meIdentifier];
    XCTAssertTrue(isStored);
    
    NSString *plainText = @"Hello World!";
    NSString *encryptedText = [[MOKSecurityManager sharedInstance] aesEncryptText:plainText fromUser:meIdentifier];
    XCTAssertNotNil(encryptedText);
    
    NSString *decryptedText = [[MOKSecurityManager sharedInstance] aesDecryptText:encryptedText fromUser:meIdentifier];
    XCTAssertNotNil(decryptedText);
    
    XCTAssertTrue([plainText isEqualToString:decryptedText]);
}

- (void)testGetAES {
    NSString *meIdentifier = @"MeId";
    NSString *aesandiv = [[MOKSecurityManager sharedInstance] generateAESKeyAndIV];
    XCTAssertNotNil(aesandiv);
    
    BOOL isStored = [[MOKSecurityManager sharedInstance] storeObject:aesandiv withIdentifier:meIdentifier];
    XCTAssertTrue(isStored);
    
    NSArray *array = [aesandiv componentsSeparatedByString:@":"];
    XCTAssertTrue(array.count == 2);
    
    NSString *aes = array.firstObject;
    XCTAssertNotNil(aes);
    NSString *iv = array.lastObject;
    XCTAssertNotNil(iv);
    
    NSString *retreivedAES = [[MOKSecurityManager sharedInstance] getAESbase64forUser:meIdentifier];
    XCTAssertTrue([retreivedAES isEqualToString:aes]);
    
    NSString *retreivedIV = [[MOKSecurityManager sharedInstance] getIVbase64forUser:meIdentifier];
    XCTAssertTrue([retreivedIV isEqualToString:iv]);
}

@end
