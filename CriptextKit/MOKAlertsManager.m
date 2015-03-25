//
//  AlertManager.m
//  Blip
//
//  Created by G V on 12.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKAlertsManager.h"
#import <UIKit/UIAlertView.h>


@implementation MOKAlertsManager

+ (void)alert:(NSString*)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

+ (void)alert:(NSString*)title message:(NSString*)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

@end
