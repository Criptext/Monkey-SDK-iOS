//
//  SGSSession.m
//  LuckyOnline
//
//  Created by Timothy Braun on 3/11/09.
//  Copyright 2009 Fellowship Village. All rights reserved.
//

#import "SGSSession.h"
#import "SGSConnection.h"
#import "SGSMessage.h"
#import "SGSProtocol.h"
#import "SGSContext.h"
#import "SGSChannel.h"
#import "SGSId.h"

@implementation SGSSession

@synthesize connection;
@synthesize reconnectKey;
@synthesize channels;
@synthesize login;
@synthesize password;

- (id)initWithConnection:(SGSConnection *)aConnection {
	if(self = [super init]) {
		self.connection = aConnection;
		self.channels = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc {
    NSLog(@"SESSIon TAMBIEEEEEN? te desaolcaste we");
	[reconnectKey release];
	[channels release];
	[login release];
	[password release];
	
	[super dealloc];
}

- (void)receiveMessage:(SGSMessage *)message {
	// Get the opcode from the message
	
	SGSOpcode opcode = [message readOpcode];

	switch (opcode) {
		case SGSOpcodeLoginSuccess:
		{
			// Login success only contains the key which is a byte
			// array.  We use this should we ever need to reconnect
			self.reconnectKey = [message readRemainingBytes];
			if([connection.context.delegate respondsToSelector:@selector(sgsContext:loggedIn:forConnection:)]) {
				[connection.context.delegate sgsContext:connection.context loggedIn:self forConnection:connection];
			}
			
			break;
		}
		case SGSOpcodeLoginFailure:
		{
			// We need to get the error string then disconnect
			NSString *err = [message readString];
			
			// Disconnect from the servier
			[self.connection disconnect];
			
			if([connection.context.delegate respondsToSelector:@selector(sgsContext:loginFailed:forConnection:withMessage:)]) {
				[connection.context.delegate sgsContext:connection.context loginFailed:self forConnection:connection withMessage:err];
			}
			
			break;
		}
		case SGSOpcodeLoginRedirect:
		{
			// Get our new host and port
			NSString *newHost = [message readString];
			uint32_t newPort;
			[message readBytes:&newPort length:sizeof(uint32_t)];
			
			// Reset the context and prepare for the redirect
			connection.context.hostname = newHost;
			connection.context.port = newPort;
			connection.inRedirect = YES;
			[connection disconnect];
			
			// Try to login again
			[connection loginWithUsername:login password:password];
			break;
		}
		case SGSOpcodeSessionMessage:
		{
			// Pass the message onto the handler
			if([connection.context.delegate respondsToSelector:@selector(sgsContext:messageReceived:forConnection:)]) {
				[connection.context.delegate sgsContext:connection.context messageReceived:message forConnection:connection];
			}
			break;
		}
		case SGSOpcodeReconnectSuccess:
		{
			if([connection.context.delegate respondsToSelector:@selector(sgsContext:reconnected:)]) {
				[connection.context.delegate sgsContext:connection.context reconnected:connection];
			}
			break;
		}
		case SGSOpcodeReconnectFailure:
		{
			[connection disconnect];
			break;
		}
		case SGSOpcodeLogoutSuccess:
		{
			connection.expectingDisconnect = YES;
			[connection disconnect];
			break;
		}
		case SGSOpcodeChannelJoin:
		{
			NSString *name = [message readString];
			NSData *sgsData = [message readRemainingBytes];
			SGSId *sgsId = [SGSId idWithData:sgsData];
			
			
			if([channels objectForKey:name]) {

				return;
			}
			
			SGSChannel *channel = [[SGSChannel alloc] initWithSession:self channelId:sgsId name:name];
			

			
			[channels setObject:channel forKey:channel.name];
			
			if([connection.context.delegate respondsToSelector:@selector(sgsContext:channelJoined:forConnection:)]) {
				[connection.context.delegate sgsContext:connection.context channelJoined:channel forConnection:connection];
			}
			
			[channel release];
			
			break;
		}
		case SGSOpcodeChannelLeave:
		{
			return;
			/*
			NSData *sgsData = [message readRemainingBytes];
			//SGSId *sgsId = [SGSId idWithData:sgsData];
			
			
			SGSChannel *channel = [channels objectForKey:sgsId];
			if(!channel) {
				NSLog(@"Channel Leave Request Failed. Not member of channel.");
				return;
			}
			
			
			if([channel.delegate respondsToSelector:@selector(channelLeft:)]) {
				[channel.delegate channelLeft:channel];
			}
			
			//[channels removeObjectForKey:sgsId];
			break;
			 */
		}
		case SGSOpcodeChannelMessage:
		{
			//NSData *sgsData = [message readBytes];
			//SGSId *sgsId = [SGSId idWithData:sgsData];
			
//			NSLog(@"Channel comming message ");
			
	//			NSString *name = [message readString];
			
	
			
			//SGSChannel *channel = [channels objectForKey:name];
			
	/*
			
			if(!channel) {
				NSLog(@"Channel message dropped.  Channel not found. %@",channel.name);
				
								
				return;
			}
			
	
	
	
			if([channel.delegate respondsToSelector:@selector(channel:messageReceived:)]) {
				[channel.delegate channel:channel messageReceived:message];
			}
			*/
			
			
			if([connection.context.delegate respondsToSelector:@selector(channelMessageReceived:)]) {
				[connection.context.delegate channelMessageReceived:message];
				
				//[connection.context.delegate sgsContext:connection.context messageReceived:message forConnection:connection];
			}
			
			//[channel release];
			
			break;
		}
		default:
			NSLog(@"Unknown opcode received.");
			break;
	}
}

- (void)loginWithLogin:(NSString *)aLogin password:(NSString *)aPassword {
	// Build the message
	SGSMessage *msg = [[SGSMessage alloc] init];
	
	uint8_t opcode = SGSOpcodeLoginRequest;
	[msg appendArbitraryBytes:&opcode length:1];
	
	// Add the protocol version field
	uint8_t protocolVersion = SGS_MSG_VERSION;
	[msg appendArbitraryBytes:&protocolVersion length:1];
	
	// Add the login string field
	[msg appendString:aLogin];
	
	// Add the password field
	[msg appendString:aPassword];
	
	// Save reference to used username and password
	self.login = aLogin;
	self.password = aPassword;

	// Add message to connection
	[connection sendMessage:msg];
    

	//[msg release];
    
    
}

- (void)logout {
	SGSMessage *message = [SGSMessage message];
	uint8_t opcode = SGSOpcodeLogoutRequest;
	[message appendArbitraryBytes:&opcode length:1];
	[connection sendMessage:message];
}

@end
