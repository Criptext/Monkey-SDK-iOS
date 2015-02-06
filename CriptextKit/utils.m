//
//  untitled.m
//  Blip
//
//  Created by G V on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "utils.h"
#import "BLUserExtended.h"
#import "BLMessage.h"

//#import "BLInvite.h"
//#import "BLConversation.h"

NSInteger sortAZF(id arg1, id arg2, void *arg3) {
	BLUserExtended *user1 = arg1;
	BLUserExtended *user2 = arg2;
	return [user1.lastName caseInsensitiveCompare:user2.lastName];	
}

NSInteger timestampSort(id arg1, id arg2, void *arg3) {
	BLMessage *m1 = arg1;
	BLMessage *m2 = arg2;
	if (m1.timestamp == m2.timestamp) {
		return 0;
	}
	return m1.timestamp > m2.timestamp ? 1 : -1;
}

//NSInteger timeSort(id arg1, id arg2, void *arg3) {
//	BLConversation *m1 = arg1;
//	BLConversation *m2 = arg2;
//    
//    //NSLog(@"sorting conver %@- %@",m1.lastMessage.messageText,m2.lastMessage.messageText);
//    //NSLog(@"sorting conver %f - %f",m1.lastMessage.timestamp,m2.time);
//    //NSLog(@"sresult %i",m1.time < m2.time ? 1 : -1);
//    //antes m1.time en uno no cambi m1.lastMessage.timestamp
//	if (m1.timestamp == m2.timestamp) {
//		return 0;
//	}
//
//	return m1.timestamp < m2.timestamp ? 1 : -1;
//}



NSInteger sortAZ(id arg1, id arg2, void *arg3) {
	BLUserExtended *user1 = arg1;
	BLUserExtended *user2 = arg2;
	if (arg3 == nil) {
		NSComparisonResult r = [user2.firstName caseInsensitiveCompare:user1.firstName];
		if (r == NSOrderedSame) {
			return [user2.lastName caseInsensitiveCompare:user1.lastName];
		} else {
			return r;
		}
	} else {
		NSComparisonResult r = [user1.firstName caseInsensitiveCompare:user2.firstName];
		if (r == NSOrderedSame) {
			return [user1.lastName caseInsensitiveCompare:user2.lastName];
		} else {
			return r;
		}
	}	
}
/*
NSInteger sortAZInvites(id arg1, id arg2, void *arg3) {
	BLInvite *invite1 = arg1;
	BLInvite *invite2 = arg2;
	return [invite1.txt caseInsensitiveCompare:invite2.txt];
}
*/