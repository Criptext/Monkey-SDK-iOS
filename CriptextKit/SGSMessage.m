//
//  SGSMessage.m
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import "SGSMessage.h"
#import "SGSProtocol.h"
#import "SGSId.h"
#import "SGSChannel.h"

@interface SGSMessage (PrivateMethods)

- (void)updatePayloadLength;

@end

@implementation SGSMessage

@synthesize payloadLength;
@synthesize position;

+ (id)message {
	return [[[SGSMessage alloc] init] autorelease];
}

+ (id)messageWithData:(NSData *)theData {
	return [[[SGSMessage alloc] initWithData:theData] autorelease];
}

+ (id)sessionMessage {
	SGSMessage *msg = [[[SGSMessage alloc] init] autorelease];
	uint8_t opcode = SGSOpcodeSessionMessage;
	[msg appendArbitraryBytes:&opcode length:sizeof(uint8_t)];
	return msg;
}

+ (id)channelMessage:(SGSChannel *)channel {
	SGSMessage *msg = [[[SGSMessage alloc] init] autorelease];
	
	// Append the opcode
	uint8_t opcode = SGSOpcodeChannelMessage;
	[msg appendArbitraryBytes:&opcode length:sizeof(uint8_t)];
	
	// Append the channel id
	NSData *channelId = channel.sgsId.data;
	[msg appendFixedBytes:[channelId bytes] length:[channelId length]];
	
	return msg;
}

- (id)init {
	if(self = [super init]) {
		uint32_t len = 0;
		data = [[NSMutableData alloc] initWithBytes:&len length:SGS_MSG_LENGTH_OFFSET];
		payloadLength = len;
		position = SGS_MSG_LENGTH_OFFSET;
	}
	return self;
}

- (id)initWithData:(NSData *)theData {
	if(self = [super init]) {
		data = [theData mutableCopy];
		
		// Get the payload length from the message
		if([theData length] < SGS_MSG_LENGTH_OFFSET) {
			payloadLength = 0;
		} else {
			uint32_t len;
			[theData getBytes:&len length:SGS_MSG_LENGTH_OFFSET];
			payloadLength = ntohs(len);
		}
		
		position = SGS_MSG_LENGTH_OFFSET;
	}
	return self;
}

- (void)dealloc {
	[data release];
	[super dealloc];
}

- (const void *)bytes {
	return [data bytes];
}

- (NSUInteger)length {
	return [data length];
}

- (SGSOpcode)getOpcode {
	SGSOpcode opcode;
	[data getBytes:&opcode length:1];
	return opcode;
}

- (void)appendFixedBytes:(const void *)bytes length:(NSUInteger)length {
	uint16_t _uint16_tmp = htons(length);
	[data appendBytes:&_uint16_tmp length:2];
	[data appendBytes:bytes length:length];
	payloadLength += length + 2; // 2 bytes for the length of the appended bytes
	[self updatePayloadLength];
}

- (void)appendArbitraryBytes:(const void *)bytes length:(NSUInteger)length {
	[data appendBytes:bytes length:length];
	payloadLength += length;
	[self updatePayloadLength];
}

- (void)appendString:(NSString *)string {
	NSData *strData = [string dataUsingEncoding:NSUTF8StringEncoding];
	uint16_t _uint16_tmp = htons([strData length]);
	[data appendBytes:&_uint16_tmp length:2];
	[data appendBytes:[strData bytes] length:[strData length]];
	payloadLength += [strData length] + 2;
	[self updatePayloadLength];
}

- (void)appendUInt16:(uint16_t)val {
	uint16_t converted = htons(val);
	[data appendBytes:&converted length:sizeof(short)];
	payloadLength += sizeof(short);
	[self updatePayloadLength];
}

- (void)appendUInt32:(uint32_t)val {
	uint32_t converted = htonl(val);
	[data appendBytes:&converted length:sizeof(int)];
	payloadLength += sizeof(int);
	[self updatePayloadLength];
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes {
	[data replaceBytesInRange:range withBytes:bytes];
}

- (void)rewind {
	position = SGS_MSG_LENGTH_OFFSET;
}

- (void)readBytes:(void *)bytes length:(NSUInteger)length {
	
	[data getBytes:bytes range:NSMakeRange(position, length)];
	
	position += length;
}

- (NSData *)readBytes {
	// Get the length of this field
	uint16_t length;
	[self readBytes:&length length:sizeof(uint16_t)];
	length = ntohs(length);
	

	
	uint8_t buffer[length];
	[self readBytes:&buffer length:length];
	return [NSData dataWithBytes:buffer length:length];
}

- (NSData *)readBytesWithLength:(NSUInteger)length {
	if(length <= 0) {
		return [self readBytes];
	}
	
	uint8_t buffer[length];
	[self readBytes:&buffer length:length];
	return [NSData dataWithBytes:buffer length:length];
}

- (NSData *)readRemainingBytes {
	NSUInteger length = payloadLength - position + SGS_MSG_INIT_LEN;
	return [self readBytesWithLength:length];
}

- (NSString *)readString {
	
	
	
	// Get the length of this field
	NSMutableString* resultado=[[NSMutableString alloc] init];
	//THE CHARS inside bytes dont show at nSLOG they have to be process in another way	
	char *bytes = (char *)[data bytes];
	int i;
	
	for (i =3; i < [data length]; i++){
		//NSLog(@"Character %d is '%c'\n", i, bytes[i]);
		[resultado appendFormat:@"%c",bytes[i]];
	}
	
	
	
	
	NSString *decodedString = [NSString stringWithUTF8String:[resultado cStringUsingEncoding:[NSString defaultCStringEncoding]]];
	
	//NSLog(@"Modified string is UTF8 '%@' \n", decodedString);
	

	return decodedString;
	
	
	/*
	 
	 // Get the length of this field
	 uint16_t length;
	 [self readBytes:&length length:sizeof(uint16_t)];
	 length = ntohs(length);
	 
	 uint8_t buffer[length];
	 [self readBytes:&buffer length:length];
	 NSString *result = [[[NSString alloc] initWithBytes:buffer length:length encoding:NSUTF8StringEncoding] autorelease];
	 return result;
	 */
	
}

- (uint16_t)readUInt16 {
	uint16_t val;
	[self readBytes:&val length:sizeof(uint16_t)];
	return ntohs(val);
}

- (uint32_t)readUInt32 {
	uint32_t val;
	[self readBytes:&val length:sizeof(uint32_t)];
	return ntohl(val);
}

- (SGSOpcode)readOpcode {
	uint8_t opcode;
	[self readBytes:&opcode length:1];
	return opcode;
}

#pragma mark Private Methods

- (void)updatePayloadLength {
	uint16_t len = htons(payloadLength);
	[data replaceBytesInRange:NSMakeRange(0, SGS_MSG_LENGTH_OFFSET) withBytes:&len];
}

@end
