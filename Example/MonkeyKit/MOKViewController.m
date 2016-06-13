//
//  MOKViewController.m
//  MonkeyKit
//
//  Created by Gianni Carlo on 06/07/2016.
//  Copyright (c) 2016 Gianni Carlo. All rights reserved.
//

#import "MOKViewController.h"


NSString * const MonkeyAppId = @"idkgwf6ghcmyfvvrxqiwwmi";
NSString * const MonkeyAppSecret = @"9da5bbc32210ed6501de82927056b8d2";
@interface MOKViewController ()
@property (strong, nonatomic) MOKUser *me;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSString *folderDestination;
@end

@implementation MOKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    self.folderDestination = [[NSString alloc] initWithFormat:@"%@/MonkeyFiles", documentDirectory];
    
    self.messages = [[NSMutableArray alloc] init];
    self.me = [MOKUser allObjects].firstObject;
    
    //listen to successful register event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monkeyDidRegister:) name:MonkeyRegistrationDidCompleteNotification object:nil];
    //listen to unsuccessful register event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monkeyDidFailRegister:) name:MonkeyRegistrationDidFailNotification object:nil];
    
    [[Monkey sharedInstance] addReceiver:self];
    
    
    [self initMonkey];
}

- (void)initMonkey {
    
    NSMutableDictionary *metadata = [@{@"name": @"Demo User!"} mutableCopy];
    
    if (self.me != nil) {
        metadata[@"monkeyId"] = self.me.monkeyId;
        metadata[@"name"] = self.me.name;
    }
    
    [[Monkey sharedInstance] initWithApp:MonkeyAppId
                                  secret:MonkeyAppSecret
                                    user:metadata
                           expireSession:true
                               debugging:true
                                autoSync:true
                           lastTimestamp:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    // Dismiss keyboard on screen touch
    [self.recipientTextField resignFirstResponder];
    [self.messageTextField resignFirstResponder];
}

#pragma mark - Event Listeners
-(void)monkeyDidRegister:(NSNotification *)notification {
    NSLog(@"did register: %@", notification.userInfo);
    MOKUser *user = [[MOKUser alloc] init];
    user.monkeyId = notification.userInfo[@"monkeyId"];
    user.name = notification.userInfo[@"name"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:user];
    [realm commitWriteTransaction];
}

-(void)monkeyDidFailRegister:(NSNotification *)notification {
    NSLog(@"did fail register: %@", notification.userInfo);
    
    // Do something about it, here we'll just try again after a second
    [self performSelector:@selector(initMonkey) withObject:nil afterDelay:1];
}

#pragma mark - IBActions
- (IBAction)compressDidChange:(UISwitch *)sender {
}
- (IBAction)encryptedDidChange:(UISwitch *)sender {
}
- (IBAction)sendTextPressed:(UIButton *)sender {
    NSString *recipientId = self.me.monkeyId;
    
    if (self.messageTextField.text.length == 0) {
        return;
    }
    if (self.recipientTextField.text.length > 0) {
        recipientId = self.recipientTextField.text;
    }
    
    MOKMessage *msg = [[Monkey sharedInstance] sendText:self.messageTextField.text encrypted:self.encryptedSwitch.on toUser:recipientId params:nil push:nil];
    
    self.messageTextField.text = @"";
    
    [self.messages addObject:msg];
    [self.tableView reloadData];
    
}
- (IBAction)sendImagePressed:(UIButton *)sender {
    UIAlertController *alertcontroller= [UIAlertController alertControllerWithTitle:nil
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* pickPhoto = [UIAlertAction
                                actionWithTitle:@"Pick Photo"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    
                                    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            switch (status) {
                                                case PHAuthorizationStatusAuthorized:{
                                                    [alertcontroller dismissViewControllerAnimated:YES completion:nil];
                                                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                                    picker.delegate = self;
                                                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                                    
                                                    [self presentViewController:picker animated:true completion:nil];
                                                    break;
                                                }
                                                case PHAuthorizationStatusRestricted:
                                                case PHAuthorizationStatusDenied:
                                                default:{
                                                    [alertcontroller dismissViewControllerAnimated:YES completion:nil];
                                                    NSLog(@"Enable access for the example to access your photos");
                                                    break;
                                                }
                                            }
                                        });
                                        
                                    }];
                                }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 [alertcontroller dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    [alertcontroller addAction:pickPhoto];
    [alertcontroller addAction:cancel];
    
    alertcontroller.popoverPresentationController.sourceView = self.view;
    alertcontroller.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height-45, 1.0, 1.0);
    [self presentViewController:alertcontroller animated:YES completion:nil];
}

#pragma mark - UIImageViewController Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(chosenImage);
    
    if (imageData == nil) {
        NSLog(@"Image null");
        return;
    }
    
    NSURL *refURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    NSLog(@"ref url: %@", refURL);
    
    // get the asset library and fetch the asset based on the ref url (pass in block above)
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    
    [assetslibrary assetForURL:refURL resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *imageRep = [asset defaultRepresentation];
        
        
        [[NSFileManager defaultManager] createDirectoryAtPath:self.folderDestination withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *selectedPhotoPath = [self.folderDestination stringByAppendingPathComponent:[imageRep filename]];
        [imageData writeToFile:selectedPhotoPath atomically:YES];
        
        NSString *recipientId = self.me.monkeyId;
        if (self.recipientTextField.text.length > 0) {
            recipientId = self.recipientTextField.text;
        }
        
        MOKMessage *message = [[Monkey sharedInstance] sendFilePath:selectedPhotoPath type:MOKPhoto filename:@"myphoto.png" encrypted:true compressed:true toUser:recipientId params:nil push:nil success:^(MOKMessage * _Nonnull message) {
            NSLog(@"success uploading");
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"fail to upload");
        }];
        
        [self.messages addObject:message];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } failureBlock:nil];
    
    
    
    
}

#pragma mark - Monkey Listener Delegate
-(void)messageReceived:(MOKMessage *)message{
    if ([message isMedia]) {
        
        [[Monkey sharedInstance] downloadFileMessage:message fileDestination:self.folderDestination success:^(NSData * _Nonnull data) {
            [self.tableView reloadData];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Fail: %@", error);
        }];
    }
    [self.messages addObject:message];
    [self.tableView reloadData];
}

-(void)acknowledgeReceived:(MOKMessage *)ackMessage{
    MOKMessage *msg = [self.messages objectAtIndex:[self.messages indexOfObject:ackMessage]];
    
    msg.messageId = ackMessage.messageId;
    
    [self.tableView reloadData];
    
}

-(void)notificationReceived:(MOKMessage *)notificationMessage{
    
}

-(BOOL)isMessageMine:(MOKMessage *)message {
    if ([[Monkey sharedInstance].session[@"monkeyId"] isEqualToString:message.userIdFrom]) {
        return true;
    }
    
    return false;
}
#pragma mark - Tableview Datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MOKMessageViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MOKMessageViewCell" forIndexPath:indexPath];
    MOKMessage *msg = [self.messages objectAtIndex:indexPath.row];
    cell.senderMonkeyId.text = msg.userIdFrom;
    cell.recipientMonkeyId.text = msg.userIdTo;
    cell.contentTextView.text = msg.text;
    
    if ([msg isInTransit]) {
        cell.statusLabel.text = @"(Sending)";
    }else{
        cell.statusLabel.text = @"(Sent)";
    }
    
    if (![self isMessageMine:msg]) {
        cell.statusLabel.text = @"(Received)";
    }
    
    if ([msg isMedia]) {
        cell.contentImageView.hidden = false;
        cell.contentImageView.image = [UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:[self.folderDestination stringByAppendingPathComponent:msg.messageText]]];
    }else{
        cell.contentTextView.hidden = false;
    }
    
    return cell;
}
#pragma mark - Tableview Delegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 183.0f;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[Monkey sharedInstance] removeReceiver:self];
}

@end