//
//  untitled.m
//  Blip
//
//  Created by G V on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MOKutils.h"
#import "MOKUser.h"
#import "MOKMessage.h"

//#import "BLInvite.h"
#import "MOKConversation.h"

NSInteger timestampSort(id arg1, id arg2, void *arg3) {
	MOKMessage *m1 = arg1;
	MOKMessage *m2 = arg2;
	if (m1.timestamp == m2.timestamp) {
		return 0;
	}
	return m1.timestamp > m2.timestamp ? 1 : -1;
}

NSInteger timeSort(id arg1, id arg2, void *arg3) {
	MOKConversation *m1 = arg1;
	MOKConversation *m2 = arg2;
    
    //NSLog(@"sorting conver %@- %@",m1.lastMessage.messageText,m2.lastMessage.messageText);
    //NSLog(@"sorting conver %f - %f",m1.lastMessage.timestamp,m2.time);
    //NSLog(@"sresult %i",m1.time < m2.time ? 1 : -1);
    //antes m1.time en uno no cambi m1.lastMessage.timestamp
	if (m1.timestamp == m2.timestamp) {
		return 0;
	}

	return m1.timestamp < m2.timestamp ? 1 : -1;
}

/*
NSInteger sortAZInvites(id arg1, id arg2, void *arg3) {
	BLInvite *invite1 = arg1;
	BLInvite *invite2 = arg2;
	return [invite1.txt caseInsensitiveCompare:invite2.txt];
}
*/