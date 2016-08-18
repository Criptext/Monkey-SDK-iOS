//
//  MOKUser.h
//  Pods
//
//  Created by Gianni Carlo on 8/17/16.
//
//

#import <Foundation/Foundation.h>

@interface MOKUser : NSObject

/**
 *	The identifier or the user
 */
@property (nonatomic, copy) NSString * _Nonnull monkeyId;

/**
 *	The metadata of the user
 */
@property (nonatomic, strong) NSMutableDictionary *info;

/**
 *  Initialize a user with an Id
 *
 *  @param monkeyId Id of the user
 *
 *  @return Instance of MOKUser
 */
-(nonnull instancetype)initWithId:(nonnull NSString *)monkeyId;

/**
 *  Not a valid initializer.
 */
- (nullable id)init NS_UNAVAILABLE;
@end
