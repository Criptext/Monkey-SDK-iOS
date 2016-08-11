//
//  MOKConversation.h
//  Pods
//
//  Created by Gianni Carlo on 8/10/16.
//
//

#import <Foundation/Foundation.h>

@interface MOKConversation : NSObject

/**
 *	The identifier for a conversation, this can be a Monkey Id or a Group Id
 */
@property (nonatomic, copy) NSString *conversationId;

/**
 *	The metadata 
 */
@property (nonatomic, copy) NSDictionary *info;

@end
