//
//  ViewController.h
//  sms-client-ios
//
//  Created by Kaufmann Pascal, ENT-SAP-PSR-MBL-MII on 16.05.14.
//  Copyright (c) 2014 Swisscom Enterprise Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actSend;

@property (weak, nonatomic) IBOutlet UITextField *tfAPIKey;
@property (weak, nonatomic) IBOutlet UITextField *tfMobileNr;

@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UIButton *btnSendToken;

- (IBAction)btnSend_clicked:(id)sender;
- (IBAction)btnSendToken_clicked:(id)sender;

@end
