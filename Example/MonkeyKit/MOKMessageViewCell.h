//
//  MOKMessageViewCell.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 6/7/16.
//  Copyright © 2016 Gianni Carlo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MOKMessageViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *senderMonkeyId;
@property (weak, nonatomic) IBOutlet UILabel *recipientMonkeyId;
@property (weak, nonatomic) IBOutlet UIImageView *contentImageView;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end
