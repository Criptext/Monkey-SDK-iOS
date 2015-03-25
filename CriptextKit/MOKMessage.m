//
//  BLMessage.m
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKMessage.h"
#import "MOKUser.h"
#import "MOKDateUtils.h"
#import "MOKJSON.h"
#import "MOKSessionManager.h"
#include "MOKCriptext.h"

@implementation MOKMessage
@synthesize deliveredMessage,messageText, timestamp, userIdTo, messageId, oldMessageId, readByUser, type, isSending, userIdFrom, param, iv;

static NSDictionary *tagsDictionary = nil;

+ (MOKMessageType)typeForString:(NSString*)str {
	if (tagsDictionary == nil) {
		tagsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
						  [NSNumber numberWithInt:MOKMessageDefault], @"",
						  [NSNumber numberWithInt:MOKMessageFriendRequest], @"friend",
						  [NSNumber numberWithInt:MOKMessageTyping], @"typing",
						   [NSNumber numberWithInt:MOKMessageUntyping], @"untyping",
						  [NSNumber numberWithInt:MOKMessageStatus], @"status_message",
						  [NSNumber numberWithInt:MOKMessageAvatar], @"avatar",
						  [NSNumber numberWithInt:MOKMessageGroupAdd], @"group_add",
						  [NSNumber numberWithInt:MOKMessageGroupRemove], @"group_remove",
						  [NSNumber numberWithInt:MOKMessageGroupUpdate], @"group_update",
						  [NSNumber numberWithInt:MOKMessageGroupDelete], @"group_delete",
						  [NSNumber numberWithInt:MOKMessageGroupMessage], @"group_message",
						  [NSNumber numberWithInt:MOKMessageInviteAccepted], @"invite_accept",
						  [NSNumber numberWithInt:MOKMessageEmailOpen], @"email_open",
						  [NSNumber numberWithInt:MOKMessageInviteCanceled], @"invite_cancel",
						  [NSNumber numberWithInt:MOKMessageDeleteFriend], @"delete_friend",
						  //[NSNumber numberWithInt:MOKMessageShareAFriend], @"share_friend",
						  [NSNumber numberWithInt:MOKMessageConversationOpen], @"conversation_open",
						  [NSNumber numberWithInt:MOKMessageConversationClose], @"conversation_close",
						  [NSNumber numberWithInt:MOKMessageAudioAttachNew], @"file",
						  nil];
	}
	return [[tagsDictionary objectForKey:str] intValue];
}

//+(NSString *) getUniqueMessageId{
//	
//	NSTimeInterval timeStamp =   ([[NSDate date] timeIntervalSince1970]-[TimeSyncManager instance].delta)*10;
//	
//	double roundedValue = round(timeStamp);
//	
//	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//	
//	[formatter setMaximumFractionDigits:1];
//	
//	[formatter setRoundingMode: NSNumberFormatterRoundDown];
//	
//	
//	NSString *numberString = [formatter stringFromNumber:[NSNumber numberWithDouble:roundedValue]];
//		
//	return numberString;
//	
//}
- (id)initWithObjectStore:(NSDictionary*)dictionary{
    if (self = [super init]) {
		
		self.messageText = [self stringFromDictionary:dictionary key:@"message"];
    
		self.type  = [self integerFromDictionary:dictionary key:@"type"];
        
        if([dictionary objectForKey:@"iv"]!=nil)
            self.iv = [self stringIntFromDictionary:dictionary key:@"iv"];
		
		self.timestamp = [self doubleFromDictionary:dictionary key:@"datetime"];
        
		self.userIdFrom = [self stringFromDictionary:dictionary key:@"uid_sent"];
		
		self.userIdTo = [self stringFromDictionary:dictionary key:@"uid_to"];
		
		self.messageId = [self integerFromDictionary:dictionary key:@"message_id"];
        
		self.readByUser = [self booleanFromDictionary:dictionary key:@"readByUser"];
		
		self.isSending = [self booleanFromDictionary:dictionary key:@"isSending"];
        
        self.needsResend = [self booleanFromDictionary:dictionary key:@"needsResend"];
        
        if([dictionary objectForKey:@"p"]!=nil)
            self.param=[self stringFromDictionary:dictionary key:@"p"];
		      
	}
	
	return self;
}


- (id)initWithArgs:(NSDictionary*)dictionary{
	
	
	if (self = [super init]) {
		
//        NSLog(@"armando mensaje con text: %@", [self stringFromDictionary:dictionary key:@"message"]);
		self.messageText = [self stringFromDictionary:dictionary key:@"message"];
//        NSLog(@"confirmando: %@", self.messageText);
		self.type  = [self integerFromDictionary:dictionary key:@"type"];
		
		if([dictionary objectForKey:@"p"]!=nil)
            self.param = [self stringFromDictionary:dictionary key:@"p"];
        
        if([dictionary objectForKey:@"iv"]!=nil)
            self.iv = [self stringFromDictionary:dictionary key:@"iv"];
		
		self.timestamp = [self doubleFromDictionary:dictionary key:@"datetime"];
		
		self.userIdFrom = [self stringFromDictionary:dictionary key:@"uid_sent"];

        if([self.userIdFrom rangeOfString:@":"].location!=NSNotFound && [self.userIdFrom rangeOfString:@"G"].location==NSNotFound)
            self.userIdFrom=[[self.userIdFrom componentsSeparatedByString:@":"] objectAtIndex:1];

		if([dictionary objectForKey:@"uid_to"]!=nil){
            if([[self stringFromDictionary:dictionary key:@"uid_to"] rangeOfString:@":"].location!=NSNotFound && [[self stringFromDictionary:dictionary key:@"uid_to"] rangeOfString:@"G"].location==NSNotFound)
                self.userIdTo=[[[self stringFromDictionary:dictionary key:@"uid_to"] componentsSeparatedByString:@":"] objectAtIndex:1];
            else if([[self stringFromDictionary:dictionary key:@"uid_to"] rangeOfString:@"G"].location!=NSNotFound)
                self.userIdTo=[self stringFromDictionary:dictionary key:@"uid_to"];
        }
        else
            self.userIdTo = [MOKSessionManager sharedInstance].userId;
		
		self.messageId = [self integerFromDictionary:dictionary key:@"message_id"];
        if([dictionary objectForKey:@"idm"]!=nil)
            self.messageId = [self integerFromDictionary:dictionary key:@"idm"];
        
        self.oldMessageId = [self integerFromDictionary:dictionary key:@"old_id"];
		
		self.readByUser = NO;
		
		self.isSending = NO;
        
        self.needsResend = NO;
		
		stringsCount = -1;
		
		stringLength = -1.0;
				
		self.deliveredMessage=-1;

	}
	
	return self;
	
}

//add LUIS

-(BOOL)isErrorSending{
    return ([self getTimePassed]>15.0);
}
//change luis loaiza

-(void) messageOn{
	self.deliveredMessage=1;
	self.readByUser=YES;
}

- (id)initWithDictionary:(NSDictionary*)dictionary {
	if (self = [super init]) {
		NSString *typeString = [dictionary objectForKey:@"request"];
		self.messageText = [self stringFromDictionary:dictionary key:@"message"];
		self.type  = [MOKMessage typeForString:typeString];
		if (self.type == MOKMessageFile || self.type == MOKMessageAudioAttachNew) {
			NSString *filetype = [self stringFromDictionary:dictionary key:@"file_type"];
			if ([filetype isEqualToString:@"audio"]) {
				self.type = MOKMessageAudioAttachNew;
			} else {
				self.type = MOKMessagePhotoAttach;
			}
		}
//		[self checkForShareAFriend];
		if([dictionary objectForKey:@"iv"]!=nil)
            self.iv = [self stringFromDictionary:dictionary key:@"iv"];
		self.timestamp = [self doubleFromDictionary:dictionary key:@"datetime"];
		self.userIdFrom = [self stringFromDictionary:dictionary key:@"uid_sent"];
		self.userIdTo = [MOKSessionManager sharedInstance].userId;
		self.messageId = [self integerFromDictionary:dictionary key:@"message_id"];
        self.oldMessageId = [self integerFromDictionary:dictionary key:@"old_id"];
		self.readByUser = NO;
		self.isSending = NO;
		stringsCount = -1;
		stringLength = -1.0;
		//self.groupId = [self integerFromDictionary:dictionary key:@"group_id"];
		self.needsResend = NO;
		
		self.deliveredMessage=-1;
	}
	return self;
}

- (NSTimeInterval )getTimePassed {
	return [[NSDate date] timeIntervalSince1970]-self.timestamp;
}



- (id)init {
	if (self = [super init]) {
		self.messageText = nil;
        self.iv = nil;
		self.timestamp = 0;
		self.userIdTo = 0;
		self.userIdFrom = 0;
		self.messageId = 0;
		self.readByUser = NO;
		self.type = MOKMessageDefault;
		self.isSending = NO;
        self.needsResend = NO;
		stringsCount = -1;
		stringLength = -1.0;
		self.deliveredMessage=-1;
	}
	return self;
}

- (id)initWithMessage:(NSString*)_messageText messageId:(MOKMessageId)_messageId  messageIV:(NSString *)_iv timestamp:(NSTimeInterval)_timestamp userId:(NSString *)_userId {
	if (self = [super init]) {
		//NSLog(@"modo1");
		self.messageText = _messageText;
		self.timestamp = _timestamp;
		self.userIdFrom = _userId;
        self.iv = _iv;
		self.userIdTo = [MOKSessionManager sharedInstance].userId;
		self.messageId = _messageId;
		self.readByUser = NO;
		self.type = MOKMessageDefault;
		self.isSending = NO;
        self.needsResend = NO;
		stringsCount = -1;
		stringLength = -1.0;
		self.deliveredMessage=-1;
	}
	return self;
}


- (id)initWithMyMessage:(NSString*)_messageText userTo:(NSString *)_userId {
	if (self = [super init]) {
		//NSLog(@"modo2");

		self.messageText = _messageText;
        self.messageId = [[NSDate date] timeIntervalSince1970]* -1;
		self.timestamp = [[NSDate date] timeIntervalSince1970];
		self.userIdTo = _userId;
		self.userIdFrom = [MOKSessionManager sharedInstance].userId;
		//self.messageId = 0;
		self.readByUser = NO;
		self.type = MOKMessageDefault;
		self.isSending = NO;
        self.needsResend = NO;
		stringsCount = -1;
		stringLength = -1.0;
		
		self.deliveredMessage=-1;
	}
	return self;	
}

- (id)initWithMyMessageAnonymous:(NSString*)_messageText userTo:(NSString *)_userId {
	if (self = [super init]) {
		//NSLog(@"modo2");
        
		self.messageText = _messageText;
		self.timestamp = [[NSDate date] timeIntervalSince1970];
		self.userIdTo = _userId;
		self.userIdFrom = [NSString stringWithFormat:@"-%@",[MOKSessionManager sharedInstance].userId];
		self.messageId = 0;
		self.readByUser = NO;
		self.type = MOKMessageDefault;
		self.isSending = NO;
        self.needsResend = NO;
		stringsCount = -1;
		stringLength = -1.0;
		
		self.deliveredMessage=-1;
	}
	return self;
}

- (NSString*)messageTextToShow {
	switch (self.type) {
            
		case MOKMessageAudioAttachNew: case MOKMessageAudioAttach: case MOKMessageFile:
			return @"Audio File";
			break;
		case MOKMessagePhotoAttach: case MOKMessagePhotoAttachNew:
			return @"Photo";
			break;
		default: {
			if (stringLength < 0) {
//				[self myLoadData];
			}
			return messageTextToShow;
			break;
		}
	}
	
}
							 
- (float)stringLength {
	if (stringLength < 0) {
//		[self myLoadData];
	}
	return stringLength;
}

- (int)stringsCount {
	if (stringsCount < 0) {
//		[self myLoadData];
	}
	return stringsCount;
}

- (BOOL)isMessageFromMe {
	return self.userIdFrom == [MOKSessionManager sharedInstance].userId;
}


- (NSString*)dateTimeAsString {
	if (dateTimeAsString == nil) {
		dateTimeAsString = [[MOKDateUtils instance] stringFromTimestamp:self.timestamp];
	}
	return dateTimeAsString;
}

- (NSString*)conversationTime {
    
    return [MOKMessage conversationTime:self.timestamp];
}

+ (NSString*)conversationTime:(NSTimeInterval)time {
    
    NSString *fechaFinal;
    
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDate *now = [NSDate date];
    
    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit ;
    
    NSDateComponents *fecha = [sysCalendar components:unitFlags fromDate:date];
      
    // format: YYYY-MM-DD HH:MM:SS ±HHMM
    NSString *dateStr = [date description];
    NSString *dateNowStr = [now description];
    NSRange range;
    
    //month
    range.location = 5;
    range.length = 2;
    NSString *monthStr = [dateStr substringWithRange:range];
    NSString *monthNowStr = [dateNowStr substringWithRange:range];
    int month = [monthStr intValue];
    int month0 = [monthNowStr intValue];
    
    NSString *fechaservidor;
    fechaservidor=[[MOKDateUtils instance] stringFromTimestampConv4:time];
    // This just sets up the two dates you want to compare
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy"];
    NSDate *startDate = [formatter dateFromString:fechaservidor];
    NSDate *endDate = [NSDate date];
    
    // This performs the difference calculation
    unsigned flags = NSDayCalendarUnit;
    NSDateComponents *difference = [[NSCalendar currentCalendar] components:flags fromDate:startDate toDate:endDate options:0];

    
    if((month-month0)==0){
        NSString *minuto=[NSString stringWithFormat:@"%d", [fecha minute]];
        if([fecha minute]<10){
            minuto=[NSString stringWithFormat:@"0%d", [fecha minute]];
        }
        if([difference day]==0){
            fechaFinal=[[MOKDateUtils instance] stringFromTimestampConv3:time];
        }
        else if ([difference day]==1 || [difference day]==-1)
            fechaFinal=NSLocalizedString(@"ayerKey", @"");
        else if ([difference day]<7 && [difference day]>0)
            fechaFinal=[[MOKDateUtils instance] stringFromTimestampConv2:time];
        else
            fechaFinal=[[MOKDateUtils instance] stringFromTimestampConv1:time];
    }
    else
        fechaFinal=[[MOKDateUtils instance] stringFromTimestampConv1:time];
        
    //NSLog(@"correcta: %@",[[DateUtils instance] stringFromTimestampConv3:time]);
    //NSLog(@"fecha: %d",day);
    //NSLog(@"actual: %d",day0);
    
    // This just logs your output
    //NSLog(@"Start Date, %@", startDate);
    //NSLog(@"End Date, %@", endDate);
    //NSLog(@"Diferencia: %d dias", [difference day]);
    
    /*
	if ([[DateTimeManager instance] isTimeIntervalOfThisWeek:time]) {
		return [[DateUtils instance] stringFromTimestampConv1:time];
	} else {
		return [[DateUtils instance] stringFromTimestampConv2:time];
	}
    */
    
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a.m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p.m." withString:@"PM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"2014" withString:@"14"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"1969" withString:@"14"];

    return fechaFinal;
}

- (BOOL)haveAttach {
	return self.type == MOKMessageAudioAttach || self.type == MOKMessageAudioAttachNew || self.type == MOKMessageFile || self.type == MOKMessagePhotoAttach || self.type == MOKMessagePhotoAttachNew;
}

-(BOOL)haveContent{
    
    return [self.messageText rangeOfString:@"photo.png"].location!=NSNotFound || [self.messageText rangeOfString:@"loop.mp4"].location!=NSNotFound;

}

- (NSString*)videoPath {
	
		return [NSString stringWithFormat:@"http://api.jigl.com/files/%lli.wav", self.messageId];
}

- (NSString*)filePath {
    
    if(self.type==MOKMessageFile || self.type == MOKMessageAudioAttach){
        return [self audioPath];
    }
    if (self.type == MOKMessageAudioAttachNew) {
        return [self audioPathFree];
    }
    if (self.type == MOKMessagePhotoAttachNew) {
        return [self photoPathFree];
    } else
        return [self photoPath];
}

//- (NSString*)audioPath {
//    
//    if(filePathDesencriptado.length==0)
////        filePathDesencriptado=[NSString stringWithFormat:@"https://api.criptext.com/audio/%@.3gp",[MessageViewerViewController stripGarbage:desencriptar((char *) [self.messageText UTF8String])]];
//
//    return filePathDesencriptado;
//}

- (NSString*)audioPathFree {
    return [NSString stringWithFormat:@"https://api.criptext.com/audio/%@.3gp", self.messageText];
}

//- (NSString*)photoPath {
//    //NSLog(@"antes:%@",[NSString stringWithFormat:@"http://api.criptext.com/files/%@.png",[NSString stringWithFormat:@"%s",desencriptar((char *) [self.messageText UTF8String])]]);
//    //NSLog(@"Descargando:%@",[NSString stringWithFormat:@"http://api.criptext.com/files/%@.png", [MessageViewerViewController stripGarbage:[NSString stringWithFormat:@"%s",desencriptar((char *) [self.messageText UTF8String])]]]);
//    
//    if(filePathDesencriptado.length==0)
////        filePathDesencriptado=[NSString stringWithFormat:@"https://api.criptext.com/files/%@.png", [MessageViewerViewController stripGarbage:desencriptar((char *) [self.messageText UTF8String])]];
//    
//    return filePathDesencriptado;
//}

- (NSString*)photoPathFree {
    return [NSString stringWithFormat:@"https://api.criptext.com/files/%@.png", self.messageText];
}

-(id) mutableCopyWithZone: (NSZone *) zone
{
    MOKMessage *messCopy = [[MOKMessage allocWithZone: zone] init];
    
    messCopy.userIdTo=userIdTo;
    messCopy.userIdFrom=userIdFrom;
    messCopy.messageId=messageId;
    messCopy.messageText=messageText;
    
    messCopy.timestamp=timestamp;
    messCopy.type=type;
    messCopy.readByUser=readByUser;
    messCopy.oldMessageId=oldMessageId;
    
    return messCopy;
}

- (BOOL)isBroadcastMessage {
    return [self.userIdTo rangeOfString:@","].location!=NSNotFound;
}

- (BOOL)isGroupMessage {
    return [self.userIdTo rangeOfString:@"G"].location!=NSNotFound;
}

- (NSString *)getIdForConversation {
    if([self isGroupMessage])
        return self.userIdTo;
    else
        return self.userIdFrom;
}

@end
