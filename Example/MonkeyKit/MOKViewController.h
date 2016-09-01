//
//  MOKViewController.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 06/07/2016.
//  Copyright (c) 2016 Gianni Carlo. All rights reserved.
//

#import "MOKMessageViewCell.h"
#import "UserDB.h"
#import <MonkeyKit/MonkeyKit.h>

#import <AssetsLibrary/AssetsLibrary.h>
@import Photos;
@import UIKit;

@interface MOKViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITextField *recipientTextField;
@property (weak, nonatomic) IBOutlet UISwitch *encryptedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *compressedSwitch;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
