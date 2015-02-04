//
//  SGSConnection.m
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import "SGSConnection.h"
#import "SGSContext.h"
#import "SGSSession.h"
#import "SGSMessage.h"
#import "SGSProtocol.h"
#import "UserDefaultsManager.h"

#import <CFNetwork/CFNetwork.h>

#define SGS_CONNECTION_IMPL_IO_BUFSIZE	SGS_MSG_MAX_LENGTH

@interface CustomException : NSException
@end
@implementation CustomException
@end

@interface SGSConnection (PrivateMethods)

- (void)openStreams;
- (void)closeStreams;
- (void)connectionClosed;
- (void)resetBuffers;
- (BOOL)processOutgoingBytes;
- (BOOL)processIncomingBytes;

@end


@implementation SGSConnection

@synthesize socket;
@synthesize state;
@synthesize context;
@synthesize session;
@synthesize inBuf;
@synthesize outBuf;
@synthesize expectingDisconnect;
@synthesize inRedirect;

- (id)initWithContext:(SGSContext *)aContext {
	if(self = [super init]) {
		// Save reference to our context
		self.context = aContext;
		
		// Set some defaults
		expectingDisconnect = NO;
		inRedirect = NO;
		state = SGSConnectionStateDisconnected;
		session = [[SGSSession alloc] initWithConnection:self];
		
		// Create our io buffers
		inBuf = [[NSMutableData alloc] init];
		outBuf = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)disconnect {
    NSLog(@"???disconnect FUnction called por aca habian releases?");
	[self closeStreams];
	expectingDisconnect = NO;
	state = SGSConnectionStateDisconnected;
	
	if(inRedirect) {
		// Just reset the buffers if we are being redirected
		[self resetBuffers];
	} else {
		// Not redirecting so release the buffers and release
		// our references to the context and session
        
		//[inBuf release];
//		[outBuf release];
//		[session release];
		//[context release];
		/*
		inBuf = nil;
		outBuf = nil;
		session = nil;*/
		//context = nil;
	}
//    [[UserDefaultsManager instance]storeObjectFree:@"2" forKey:@"StreamDelayTime"];
//    [[UserDefaultsManager instance]storeObjectFree:@"15" forKey:@"StreamPortions"];
	
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
	
	if(self.state==SGSConnectionStateConnecting)
		return;
	

	self.state=SGSConnectionStateConnecting;
	
	// Create the host ref
    if (context.hostname == [NSNull null]) {
        context.hostname = @"central.criptext.com";
    }
	CFStringRef hostname = CFStringCreateWithCString(kCFAllocatorDefault, [context.hostname UTF8String], kCFStringEncodingASCII);
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, hostname);
	
	// Pre buffer the login request
	[session loginWithLogin:username password:password];
	
	// Try and connect to the socket
	CFReadStreamRef readStream = NULL;
	CFWriteStreamRef writeStream = NULL;
	
	CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, host, context.port, &readStream, &writeStream);
	if(readStream && writeStream) {
		CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		inputStream = (NSInputStream *)readStream;
		outputStream = (NSOutputStream *)writeStream;
		
		[self openStreams];
		//antes estaba connected en este estado, lo cambie porque realmente no esta conectado
		self.state = SGSConnectionStateConnecting;
        
	}
}

- (void)logout:(BOOL)force {
	if(force) {
		[self connectionClosed];
		return;
	}
	
	expectingDisconnect = YES;
	if(inRedirect) {
		return;
	}
	
	[session logout];
}

- (BOOL)sendMessage:(SGSMessage *)msg {
	
	[outBuf appendBytes:[msg bytes] length:[msg length]];
	return [self processOutgoingBytes];
	
	
}

#pragma mark NSStreamDelegate Impl

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {
    //NSLog(@"STREAM handleEvent has bytes comming");
    
	switch (eventCode) {
		case NSStreamEventOpenCompleted:
		{
			if(stream == outputStream) {
				// Output stream is connected
				// Update our state on this
				state = SGSConnectionStateConnected;
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{//0x8b

			dispatch_async(dispatch_get_main_queue(), ^{
                [self readInputProcess];
            });
			break;
		}
		case NSStreamEventHasSpaceAvailable:
		{
			[self processOutgoingBytes];
			break;
		}
		case NSStreamEventEndEncountered:
		{
			[self connectionClosed];
			[self notifyConnectionClosed];
			break;
		}
		case NSStreamEventErrorOccurred:
			[self connectionClosed];
			[self notifyConnectionClosed];
			break;
		default:
			break;
	}
}

-(void) readInputProcess{
    

//    uint8_t buffer[1024];
//    int len;
//    
//    while ([inputStream hasBytesAvailable]) {
//        len = [inputStream read:buffer maxLength:sizeof(buffer)];
//        if (len > 0) {
//            
//            NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
//            
//            if (nil != output) {
//                NSLog(@"server said: %@", output);
//            }
//        }
//    }


    @try {
        // read data from the buffer
        uint8_t buf[1024];
        uint8_t *buffer;
        NSUInteger ilen = 0;
        @synchronized(inBuf){
        if(![inputStream getBuffer:&buffer length:&ilen]) {
            NSInteger amount;
            
            while([inputStream hasBytesAvailable]) {
                
                amount = [inputStream read:buf maxLength:sizeof(buf)];
                if(amount>0)
                    [inBuf appendBytes:buf length:amount];
                
                //NSLog(@"new *** Opcode : 0x%x", buf[2]);
            }//end while
            
            
           
            
        } else {
            NSLog(@"ELSE inputStream not available APPEND -- bbuffer");
            // We have a reference to the buffer
            // copy the buffer over to our input buffer and begin processing
            [inBuf appendBytes:buffer length:ilen];
        }
        
        
        //NSString *outputString = [[NSString alloc] initWithBytes:buf length:amount encoding:NSASCIIStringEncoding];
//        NSLog(@"BUffer size %i String collected %@",amount,outputString);
        }
        do {} while([self processIncomingBytes]);
        
        
    }@catch (CustomException *ce){
        if ([[[UserDefaultsManager instance] objectForKeyFree:@"StreamDidChangeValue"] isEqualToString:@"0"]) {
            [[UserDefaultsManager instance]storeObjectFree:@"1" forKey:@"StreamDidChangeValue"];
        
            int streamDelayTime = [[[UserDefaultsManager instance] objectForKeyFree:@"StreamDelayTime"] intValue];
            int streamPortions = [[[UserDefaultsManager instance] objectForKeyFree:@"StreamPortions"] intValue];
            
            
            streamDelayTime = streamDelayTime + 1;
            streamPortions = streamPortions - 1;
            if (streamPortions < 10 ) {
                streamPortions = 10;
            }
            if (streamDelayTime <2 ) {
                streamDelayTime = 2;
            }
            if (streamDelayTime >5) {
                streamDelayTime = 5;
            }
            [[UserDefaultsManager instance]storeObjectFree:[NSString stringWithFormat:@"%d",streamDelayTime] forKey:@"StreamDelayTime"];
            [[UserDefaultsManager instance]storeObjectFree:[NSString stringWithFormat:@"%d",streamPortions] forKey:@"StreamPortions"];
            NSLog(@"incrementado delay a:%d y decrementado porciones a:%d", streamDelayTime, streamPortions);
            
            // Delay execution of my block for 10 seconds.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [[UserDefaultsManager instance]storeObjectFree:[NSString stringWithFormat:@"%d",2] forKey:@"StreamDelayTime"];
                [[UserDefaultsManager instance]storeObjectFree:[NSString stringWithFormat:@"%d",15] forKey:@"StreamPortions"];
            });
        }
    }
    @catch (NSException *e) {
        NSLog(@"gettin disconnect %@",e);
        [self disconnect];
        [self notifyConnectionClosed];
        
    }
    
    
}
#pragma mark Private Methods

- (void)openStreams {
	inputStream.delegate = self;
	[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inputStream open];
	outputStream.delegate = self;
	[outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[outputStream open];

}

- (void)closeStreams {
	
	if(inputStream) {
		[inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//		[inputStream release];
//		inputStream = nil;
	}
	
	if(outputStream) {
		[outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//	[outputStream release];
	//	outputStream = nil;
	}
}

- (void)connectionClosed {
	if(inRedirect)
		return;
	
	[self disconnect];
	
	
	
}

-(void)notifyConnectionClosed{
	//antes fuera de disconnect
	if([context.delegate respondsToSelector:@selector(sgsContext:disconnected:)]) {
		[context.delegate sgsContext:context disconnected:self];
	}
}


- (void)resetBuffers {
	[inBuf release];
	[outBuf release];
	inBuf = [[NSMutableData alloc] init];
	outBuf = [[NSMutableData alloc] init];
	
	NSLog(@"________reseting buffers___");
}

- (BOOL)isConnectionAvailable {
	
	if((![outputStream hasSpaceAvailable] || state==SGSConnectionStateDisconnected || !inputStream) && state!=SGSConnectionStateConnecting) {
		return NO;
	}

	return YES;
}

- (BOOL)processOutgoingBytes {
	
	if(![outputStream hasSpaceAvailable]) {
        NSLog(@"NO SPACE AVAILABLE TO GO");
		return NO;
	}
	
	unsigned olen = [outBuf length];
	if(0 < olen) {
		int writ = [outputStream write:[outBuf bytes] maxLength:olen];
		if(writ < olen) {
			memmove([outBuf mutableBytes], [outBuf mutableBytes] + writ, olen - writ);
			[outBuf setLength:olen - writ];
			return YES;
		}
	
		[outBuf setLength:0];
	}

	return YES;
}

- (BOOL)processIncomingBytes {
    // See if we have enough bytes to read the message length
    NSUInteger ilen = [inBuf length];
    
    if(ilen < SGS_MSG_LENGTH_OFFSET) {
        return NO;
    }
    @synchronized(inBuf){
        
        
        NSString *output = [[NSString alloc] initWithBytes:inBuf length:ilen encoding:NSUTF8StringEncoding];
        
        NSLog(@"server said: %@", output);
        

        
        
        /*
         SGSMessage *msg = [SGSMessage messageWithData:inBuf];
         [session receiveMessage:msg];
         [inBuf release];
         inBuf = [[NSMutableData alloc] init];
         return YES;
         */
        
        
        // We have enough bytes, get the message length -  the first 2 bytes is the length of the message
        uint32_t mlen;
        [inBuf getBytes:&mlen length:SGS_MSG_LENGTH_OFFSET];
        mlen = ntohs(mlen);//network to host short /  computed valid short
        //ntohs 2 byte short
        
        // Copy the bytes to the message buffer and clear them from the input buffer
        size_t len = mlen + SGS_MSG_LENGTH_OFFSET;// message len + the 2 bytes telling the leng is the total of the message
        
        NSMutableData *messageBuffer;
        
        if(len>[inBuf length])//el LEN calculado es mayor al que tiene el buffer realmente
        {
            //NSLog(@"COMPARA LEN %lu con ILEN %i Y MLEN %i ", len,ilen,mlen);
            
//            messageBuffer = [NSMutableData dataWithLength:ilen];
            
            // copia al messageBuffer lo de inBuf
//            memcpy([messageBuffer mutableBytes], [inBuf bytes], ilen);
            
//            NSLog(@"ESTAMOS MAL MOVE LEN %lu  [inBuf length] - len= %lu; el ilen es %lu =? %lu", len,([inBuf length] - len),ilen,[inBuf length]);
            
            //move the pointer to the next message in the inbuf buffer, has several messages in the buffer
//            memmove([inBuf mutableBytes], [inBuf bytes] + ilen, [inBuf length] - ilen);
            
            @throw [[CustomException alloc] initWithName:@"Bytes Error Exception" reason:@"Exceding Bytes" userInfo:nil];
            return YES;

//            [inBuf setLength:ilen - ilen];// 0
        }
        else{

            messageBuffer = [NSMutableData dataWithLength:len];
            
            // copia al messageBuffer lo de inBuf
            memcpy([messageBuffer mutableBytes], [inBuf bytes], len);
            NSLog(@"ESTAMOS BIEN MOVE LEN %lu  COUNT %lu , MLEN es %i", len,[inBuf length] - len,mlen);
            //estoy copiando moviendo los bytesINBUF a mutable en la posicion +len
            memmove([inBuf mutableBytes], [inBuf bytes] + len, [inBuf length] - len);
            
            [inBuf setLength:ilen - len];
        }
        

        
        // Build the message with the message buffer
        SGSMessage *mess = [SGSMessage messageWithData:messageBuffer];
        [session receiveMessage:mess];
    }
    return YES;
}

@end
