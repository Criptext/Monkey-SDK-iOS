/*
 *  SGSProtocol.h
 *  LuckyOnline
 *
 *  Created by Timothy Braun on 3/11/09.
 *  Copyright 2009 Fellowship Village. All rights reserved.
 *
 */

#define SGS_MSG_MAX_LENGTH		65535

#define SGS_MAX_PAYLOAD_LENGTH	65533

#define SGS_MSG_INIT_LEN		(SGS_MSG_MAX_LENGTH - SGS_MAX_PAYLOAD_LENGTH)

#define SGS_MSG_VERSION			'\005'

#define SGS_OPCODE_OFFSET		2

#define SGS_MSG_LENGTH_OFFSET	2

typedef enum {
	SGSOpcodeLoginRequest = 0x10,
	SGSOpcodeLoginSuccess = 0x11,
	SGSOpcodeLoginFailure = 0x12,
	SGSOpcodeLoginRedirect = 0x13,
	SGSOpcodeReconnectRequest = 0x20,
	SGSOpcodeReconnectSuccess = 0x21,
	SGSOpcodeReconnectFailure = 0x22,
	SGSOpcodeSessionMessage = 0x30,
	SGSOpcodeLogoutRequest = 0x40,
	SGSOpcodeLogoutSuccess = 0x41,
	SGSOpcodeChannelJoin = 0x50,
	SGSOpcodeChannelLeave = 0x51,
	SGSOpcodeChannelMessage = 0x52,
} SGSOpcode;