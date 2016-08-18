//
//  MOKConversation.h
//  Pods
//
//  Created by Gianni Carlo on 8/10/16.
//
//

#import <Foundation/Foundation.h>
@class MOKMessage;

@interface MOKConversation : NSObject

/**
 *	The identifier for a conversation, this can be a Monkey Id or a Group Id
 */
@property (nonatomic, copy) NSString * _Nonnull conversationId;

/**
 *	The metadata of the conversation (Group or user Info)
 */
@property (nonatomic, strong) NSMutableDictionary *info;

/**
 *	Array of Monkey Ids
 */
@property (nonatomic, strong) NSArray *members;

/**
 *	Last message of the conversation
 */
@property (nullable, nonatomic, strong) MOKMessage *lastMessage;

/**
 *	Last time I've seen this conversation
 */
@property (nonatomic) NSTimeInterval lastSeen;

/**
 *	Number of unread messages
 */
@property (nonatomic) uint unread;

/**
 *	Last time the conversation was altered
 */
@property (nonatomic) NSTimeInterval lastModified;

/**
 *  Initialize a conversation with an Id
 *
 *  @param conversationId Id of the conversation
 *
 *  @return Instance of MOKConversation
 */
-(nonnull instancetype)initWithId:(nonnull NSString *)conversationId;

/**
 *  Get avatar URL for the conversation
 */
-(nonnull NSURL *)getAvatarURL;

/**
 *	Boolean that determines if the conversation is a group or not
 */
-(BOOL)isGroup;

/**
 *  Not a valid initializer.
 */
- (nullable id)init NS_UNAVAILABLE;
@end
