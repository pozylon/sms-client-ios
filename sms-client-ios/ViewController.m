//
//  ViewController.m
//  sms-client-ios
//
//  Created by Kaufmann Pascal, ENT-SAP-PSR-MBL-MII on 16.05.14.
//  Copyright (c) 2014 Swisscom Enterprise Solutions. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIAlertViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - API specific Events

- (IBAction)btnSend_clicked:(id)sender {
    [self.actSend startAnimating];
    [self.btnSend setEnabled:NO];
    
    NSString *receiverPhone = [NSString stringWithFormat:@"tel:%@",self.tfMobileNr.text];
    NSString *senderPhone   = [NSString stringWithFormat:@"tel:%@",self.tfMobileNr.text];
    
    NSDictionary *dict = @{
                           @"outboundSMSMessageRequest": @{
                                   @"address": @[ receiverPhone ],
                                   @"senderAddress": senderPhone,
                                   @"outboundSMSTextMessage": @{
                                           @"message":@"Hello from the Swisscom objective-c example"
                                           }
                                   }
                           };
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                    NULL,
                                                                                                    (CFStringRef)senderPhone,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.swisscom.com/v1/messaging/sms/outbound/%@/requests", encodedString]] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    
    [self sendAPIRequest:request withDictionary:dict andAPIKey:self.tfAPIKey.text completion:^(BOOL success) {
        [self.actSend stopAnimating];
        [self.btnSend setEnabled:YES];
        
        if (success) {
            [[[UIAlertView alloc] initWithTitle:@"API: SendSMS" message:@"SMS Sent" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"API: SendSMS" message:@"Errors occured (see log)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

- (IBAction)btnSendToken_clicked:(id)sender {
    [self.actSend startAnimating];
    [self.btnSendToken setEnabled:NO];
    
    NSDictionary *dict = @{
                           @"to": self.tfMobileNr.text,
                           @"text": @"API: SendToken: %TOKEN%",
                           @"tokenType": @"SHORT_NUMERIC",
                           @"expireTime": @(5000),
                           @"tokenLength": @(5),
                           @"traceId": @"exTrace"
                           };
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.swisscom.com/v1/tokenvalidation"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    
    [self sendAPIRequest:request withDictionary:dict andAPIKey:self.tfAPIKey.text completion:^(BOOL success) {
        [self.actSend stopAnimating];
        [self.btnSendToken setEnabled:YES];
        
        if (!success) {
            [[[UIAlertView alloc] initWithTitle:@"API: SendToken" message:@"Errors occured (see log)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            UIAlertView *specialAlert = [[UIAlertView alloc] initWithTitle:@"API: SendToken" message:@"Token sent, please confirm" delegate:self cancelButtonTitle:@"Validate" otherButtonTitles:nil];
            [specialAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [specialAlert show];
        }
        
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.actSend startAnimating];
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                    NULL,
                                                                                                    (CFStringRef)self.tfMobileNr.text,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
    NSString *token = ((UITextField *)[alertView textFieldAtIndex:0]).text;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.swisscom.com/v1/tokenvalidation/%@/%@", encodedString, token]] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    
    [self sendAPIRequest:request withDictionary:nil andAPIKey:self.tfAPIKey.text completion:^(BOOL success) {
        [self.actSend stopAnimating];
        
        if (success) {
            [[[UIAlertView alloc] initWithTitle:@"API: ValidateToken" message:@"Token correct" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"API: ValidateToken" message:@"Errors occured (see log)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

#pragma mark - Generic Swisscom API Request

- (void)sendAPIRequest:(NSMutableURLRequest *)request withDictionary:(NSDictionary *)dict andAPIKey:(NSString *)apiKEY completion:(void (^)(BOOL))completionBlockRequest {
    
    NSData *jsonData = nil;
    if (dict) {
        NSError *error;
        jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if (error) {
            // handle accordingly
            NSLog(@"serialization error: %@",error);
            completionBlockRequest(NO);
        } else if (!jsonData) {
            NSLog(@"serialization error: nil");
            completionBlockRequest(NO);
        }
        
        NSString *jsonRequestBody = [[NSString alloc] initWithData:jsonData encoding:NSASCIIStringEncoding];
        NSData *postData = [jsonRequestBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        
        [request setValue:[NSString stringWithFormat:@"%d", [postData length]]  forHTTPHeaderField:@"Content-Length"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:postData];
    } else {
        [request setHTTPMethod:@"GET"];
    }
    
    [request setValue:apiKEY                                                forHTTPHeaderField:@"client_id"];
    [request setValue:@"application/json; charset=utf-8"                    forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Content-Type:application/json; charset=utf-8"       forHTTPHeaderField:@"Accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSString *responseRaw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSLog(@"data: %@",responseRaw);
        NSLog(@"connectionError: %@",connectionError);
        NSLog(@"response: %@",response);
        
        if (!connectionError) {
            completionBlockRequest(YES);
        } else {
            completionBlockRequest(NO);
        }
    }];

}

@end
