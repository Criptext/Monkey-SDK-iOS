//
//  CPWatchdog.m
//  Criptext
//
//  Created by Gianni Carlo on 1/13/15.
//  Copyright (c) 2015 Nicolas VERINAUD. All rights reserved.
//

#import "MOKWatchdog.h"
#import "MOKMessage.h"
#import "MOKComServerConnection.h"
#import "MOKSGSConnection.h"
#import "MOKDBManager.h"

@interface MOKWatchdog ()
@property (nonatomic, strong) NSMutableArray *messagesInTransit;
@property (nonatomic, strong) NSMutableDictionary *mediasInTransit;
@property (nonatomic) BOOL isCheckingConnectivity;
@property (nonatomic) BOOL isUpdateFinished;
@property (nonatomic) BOOL isLogout;
@end

@implementation MOKWatchdog
#pragma mark initialization
+ (instancetype)sharedInstance
{
    static MOKWatchdog *sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] initPrivate];
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MOKWatchdog sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _messagesInTransit = [[NSMutableArray alloc] init];
        _mediasInTransit = [[NSMutableDictionary alloc] init];
        _isCheckingConnectivity = false;
        _isUpdateFinished = false;
        _isLogout = false;
    }
    return self;
}
#pragma mark - txt related methods
-(void)checkConnectivity{
    if(self.isCheckingConnectivity){
        return;
    }
    
    self.isCheckingConnectivity = true;
    NSLog(@"MONKEY - check connectivity in 15segs WOOF!");
    
    [self performSelector:@selector(resetConnectivity) withObject:nil afterDelay:15.0];
}

-(void)resetConnectivity{
    if (([MOKComServerConnection sharedInstance].connection.state != MOKSGSConnectionStateConnected || !self.isUpdateFinished) && !self.isLogout) {
        NSLog(@"MONKEY - reset conenctivity WOOF!");
        [[MOKComServerConnection sharedInstance] logOut];
        self.isCheckingConnectivity = false;
        self.isUpdateFinished = false;
        //reconnect
        UIViewController<MOKComServerConnectionDelegate> *delegate = [MOKComServerConnection sharedInstance].connectionDelegate;
        [[MOKComServerConnection sharedInstance]connectWithDelegate:delegate isFirst:NO];
        return;
    }
    
    self.isCheckingConnectivity = false;
    self.isUpdateFinished = false;
    NSLog(@"MONKEY - finish checking connectivity WOOF!");
}
-(void)messageInTransit:(MOKMessage *)message{
    @synchronized(self.messagesInTransit){
        [self.messagesInTransit addObject:message];
    }
//    [self.messagesInTransit addObject:message];
    [self performSelector:@selector(checkMessages) withObject:nil afterDelay:12.0];
}

-(void)checkMessages{
    @synchronized(self.messagesInTransit){
        if (self.messagesInTransit.count == 0) {
            return;
        }
        
        MOKMessage *msg = [[MOKDBManager sharedInstance]getMessageById:[(MOKMessage *)[self.messagesInTransit objectAtIndex:0] messageId]];
        
        if (msg == nil) {
            [self.messagesInTransit removeObjectAtIndex:0];
            //            NSLog(@"MONKEY - Todo tuenti en el watchdog!");
            return;
        }
        
        [self.messagesInTransit removeAllObjects];
        //        NSLog(@"MONKEY - Pum! removimos todos los objetos y forzamos reconección");
        [[MOKComServerConnection sharedInstance] logOut];
//        recconnect
        UIViewController<MOKComServerConnectionDelegate> *delegate = [MOKComServerConnection sharedInstance].connectionDelegate;
        [[MOKComServerConnection sharedInstance]connectWithDelegate:delegate isFirst:NO];
        
    }
}

#pragma mark - media related methods

-(void)mediaInTransit:(MOKMessage *)message{
    @synchronized(self.mediasInTransit){
        [self.mediasInTransit setObject:message forKey:[NSString stringWithFormat:@"%lld", message.messageId]];
    }
    
}

-(void)removeMediaInTransitWithId:(NSString *)id_message{
    @synchronized(self.mediasInTransit){
        [self.mediasInTransit removeObjectForKey:id_message];
    }
}

-(MOKMessage *)getMediaInTransitWithId:(NSString *)id_message{
    @synchronized(self.mediasInTransit){
        MOKMessage *msg = [self.mediasInTransit objectForKey:[NSString stringWithFormat:@"%@",id_message]];
        return msg;
    }
}
-(void)updateFinished{
    self.isUpdateFinished = true;
}
-(void)logout{
    self.isLogout = true;
}
-(void)login{
    self.isLogout = false;
}
@end
