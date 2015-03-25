//
//  AlertManager.h
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOKAlertsManager : NSObject

+ (void)alert:(NSString*)message;
+ (void)alert:(NSString*)title message:(NSString*)message;

@end
