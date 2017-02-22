//
//  MOKConversation.m
//  Pods
//
//  Created by Gianni Carlo on 8/10/16.
//
//

#import "MOKConversation.h"

@interface MOKConversation()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation MOKConversation

-(instancetype)initWithId:(NSString *)conversationId{
    
    if (self = [super init]) {
        _conversationId = conversationId;
        _info = [@{} mutableCopy];
        _members = [@[] mutableCopy];
    }
    
    return self;
}

-(NSURL *)getAvatarURL{
    NSString *path = self.info[@"avatar"] ?: [@"https://monkey.criptext.com/user/icon/default/" stringByAppendingString:self.conversationId];
    
    return [[NSURL alloc] initWithString:path];
}

-(BOOL)isGroup{
    return [self.conversationId rangeOfString:@"G:"].location != NSNotFound;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"MOKConversation:%@\ninfo:%@\nlast modified: %f", self.conversationId, self.info, self.lastModified];
}

- (NSString *)getLastSeenDate{
  if (self.dateFormatter == nil) {
    self.dateFormatter = [[NSDateFormatter alloc] init];
  }
  
  NSDate *currentDate = [NSDate date];
  NSDate *lastSeenDate = [NSDate dateWithTimeIntervalSince1970:self.lastSeen];
  
  unsigned flags = NSCalendarUnitDay;
  NSInteger difference = [[[NSCalendar currentCalendar] components:flags fromDate:lastSeenDate toDate:currentDate options:0] day];

  if(difference == 0) {
    [self.dateFormatter setDateFormat:@"HH:mm"];
  }else if(difference == 1) {
    return @"Yesterday";
  }else if (difference < 7) {
    [self.dateFormatter setDateFormat:@"EEEE"];
  }else {
    [self.dateFormatter setDateFormat:@"dd/MM/yyyy"];
  }

  return [self.dateFormatter stringFromDate:self.date];
}

-(NSDate *)date{
  return [NSDate dateWithTimeIntervalSince1970:self.lastSeen];
}

@end
