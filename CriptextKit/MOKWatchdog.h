//
//  CPWatchdog.h
//  Criptext
//
//  Created by Gianni Carlo on 1/13/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MOKMessage;
@interface MOKWatchdog : NSObject

+(instancetype)sharedInstance;

-(void)messageInTransit:(MOKMessage *)message;
-(void)mediaInTransit:(MOKMessage *)message;
-(void)removeMediaInTransitWithId:(NSString *)id_message;
-(MOKMessage *)getMediaInTransitWithId:(NSString *)id_message;
-(void)updateFinished;
@end
