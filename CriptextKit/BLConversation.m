//
//  BLConversation.m
//  Blip
//
//  Created by G V on 20.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BLConversation.h"
#import "BLMessage.h"
#import "BLUserExtended.h"
#import "DBManager.h"
#import "UserDefaultsManager.h"


@implementation BLConversation

@synthesize userId,userIdLastAction,timestamp,mensajes,state,lastMessageSent,userConv,isLoadingPhoto,type,groupName,groupIds,mensajesSent;

- (id)initWithUserId:(NSString *)userId_  {
	if (self = [super init]) {
		userId = userId_;
        mensajes=[[NSMutableArray alloc]init];
        mensajesSent=[[NSMutableArray alloc]init];
		timestamp = [[NSDate date] timeIntervalSince1970];
        lastMessageSent=nil;
        userIdLastAction=nil;
        type=1;
        //estas llamando tb a user byd id, pasale todo el user mejor
        userConv=[[DBManager sharedInstance] userById:userId];
//        if(userConv==nil){
//            if (connector == nil) {
//                connector = [[WebConnector alloc] init];
//            }
//            [connector getUserInfo:userId delegate:self];
//        }
        groupName=@"";
        groupIds=@"";
        isLoadingPhoto=false;
	}
	return self;
}

- (id)initWithUserAnonymous:(NSString *)userId_{
	if (self = [super init]) {
		userId = userId_;
        mensajes=[[NSMutableArray alloc]init];
        mensajesSent=[[NSMutableArray alloc]init];
		timestamp = [[NSDate date] timeIntervalSince1970];
        lastMessageSent=nil;        
        userIdLastAction=nil;
        
        int number=[userId_ intValue]*-1*2;
        
        BLUserExtended *userAnonymous=[BLUserExtended defaultUser];
        [userAnonymous setFirstName:[NSString stringWithFormat:@"??? %d0",number]];
        [userAnonymous setUserName:@"-_-"];
        userConv=userAnonymous;
        groupName=@"";
        groupIds=@"";
        isLoadingPhoto=false;
	}
	return self;
}

- (id)initWithUser:(BLUserExtended *)userExt  {
	if (self = [super init]) {
		userId = userExt.userId;
        mensajes=[[NSMutableArray alloc]init];
        mensajesSent=[[NSMutableArray alloc]init];
		timestamp = [[NSDate date] timeIntervalSince1970];
        lastMessageSent=nil;
        userIdLastAction=nil;
        //estas llamando tb a user byd id, pasale todo el user mejor
        userConv=userExt;
        isLoadingPhoto=false;
        type=1;
        groupName=@"";
        groupIds=@"";
	}
	return self;
}

- (id)initWithMail:(NSString *)correo {
	if (self = [super init]) {
		userId = correo;
        mensajes=[[NSMutableArray alloc]init];
        mensajesSent=[[NSMutableArray alloc]init];
		timestamp = [[NSDate date] timeIntervalSince1970];
        lastMessageSent=nil;
        userIdLastAction=nil;
        BLUserExtended *user=[BLUserExtended defaultUser];
        [user setFirstName:correo];
        userConv=user;
        isLoadingPhoto=false;
        type=3;
        groupName=@"";
        groupIds=@"";
	}
	return self;
}

- (id)initWithId:(NSString *)convId andType:(int)paramType gname:(NSString *)gname{
    
    if (paramType==1) {
        self=[self initWithUserId:convId];
    }
    else if (self = [super init]) {
		userId = convId;
        self.type=paramType;
        
        mensajes=[[NSMutableArray alloc]init];
        mensajesSent=[[NSMutableArray alloc]init];
		timestamp = [[NSDate date] timeIntervalSince1970];
        lastMessageSent=nil;
        userIdLastAction=nil;
        isLoadingPhoto=false;
        
        if(gname.length==0){
//            if (connector == nil) {
//                connector = [[WebConnector alloc] init];
//            }
//            [connector getGroupInfo:[userId componentsSeparatedByString:@":"][1] delegate:self];
        }
        else
            groupName=gname;
	}
	return self;
}

- (id)initWithObjectStore:(NSDictionary*)dictionary{
    if (self = [super init]) {
		
        self.groupName = [self stringFromDictionary:dictionary key:@"groupName"];
        self.groupIds = [self stringFromDictionary:dictionary key:@"groupIds"];
        
        self=[self initWithId:[self stringFromDictionary:dictionary key:@"userId"] andType:[self integerFromDictionary:dictionary key:@"type"] gname:self.groupName];
        
        self.timestamp = [self doubleFromDictionary:dictionary key:@"datetime"];
	}
	
	return self;
}
//- (id)initWithRealm:(Conversation *)conversation{
//  if (self = [super init]) {
//    self.groupName = conversation.groupName;
//    self.groupIds = conversation.groupIds;
//    self = [self initWithId:conversation andType:conversation.type gname:self.groupName];
//  }
//}
-(BLMessage *)getLastMessage{
    if([self.mensajes count]>0)
        return [self.mensajes objectAtIndex:0];
    
    return NULL;
}
//primer elemento
-(void)removeLastMessage{

    [self.mensajes removeObjectAtIndex:0];
    
}

-(int)getTotalMessagesWithoutRead{
    int total=0;
    for (int i=0; i<[mensajes count]; i++) {
        BLMessage * msj = [mensajes objectAtIndex:i];
        if(!msj.readByUser)
            total++;
    }
    return total;
}

-(NSMutableArray *)getMessagesWithoutRead{
    NSMutableArray *elarray=[[NSMutableArray alloc] init];
    BOOL efimero=false;
    for (int i=0; i<[mensajes count]; i++) {
        BLMessage * msj = [mensajes objectAtIndex:i];
        if(msj.param!=nil){
            if([msj.param isEqualToString:@"1"])
                efimero=true;
            else
                efimero=false;
        }
        else
            efimero=false;
        if(!msj.readByUser && !efimero)
            [elarray addObject:msj];
    }
    return elarray;
}

-(BLMessage *)lastMessageWithoutRead{
    for(int i=[mensajes count]-1;i>=0;i--){
        BLMessage *message=[mensajes objectAtIndex:i];
        if(!message.readByUser){
            return message;
        }
    }
    return nil;
}

-(bool)hasUser{
    return (userConv!=nil);
    
}

- (BOOL)isBroadcastConv{
    return [self.userId rangeOfString:@","].location!=NSNotFound;
}

- (BOOL)isGroupConv{
    return [self.userId rangeOfString:@"G"].location!=NSNotFound;
}

- (NSString*)avatarGroupImageWebPath {
    return [NSString stringWithFormat:@"http://criptext.com:4080/groupvatar?ids=%@",self.groupIds];
}

//#pragma getUserInfo
//
//- (void)onGetUserInfo:(BLUserExtended*)user{
//    
//    userConv=user;
//    MenuViewController *menuVC=[MenuViewController instance];
//    ConversationsViewController *conversationsVC=menuVC.conversationsVC;
//    [conversationsVC reloadTable];
//}
//
//- (void)onGetUserInfoFail:(NSString *)descriptionError{
//    
//}
//
//#pragma get group info
//
//- (void)onGetGroupInfoOK:(NSString *)name members:(NSMutableArray *)members{
//    
//    MenuViewController *menuVC=[MenuViewController instance];
//    ConversationsViewController *conversationsVC=menuVC.conversationsVC;
//    
//    self.groupName=name;
//    self.groupIds=[members componentsJoinedByString:@","];
//    
//    if([[UserDefaultsManager instance] objectForKeyFree:[NSString stringWithFormat:@"Conversation:%@",self.userId]]!=nil){
//        [[DBManager instance] updateConversationGroupNameMembs:self.userId members:self.groupIds name:self.groupName];
//        [conversationsVC reloadTable];
//    }
//    else{
//        [[DBManager instance] createConversation:self];
//        [conversationsVC addConversationFirst:self];
//    }
//    
//    
//}
//
//- (void)onGetGroupInfoFail:(NSString *)descriptionError{
//    
//}

@end
