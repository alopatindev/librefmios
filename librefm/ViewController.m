//
//  ViewController.m
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "ViewController.h"
#import "NSString+String.h"

@interface ViewController ()

@end

@implementation ViewController

- (BOOL)loginWithUsername:(NSString*)username password:(NSString*)password
{
    BOOL result = NO;

    NSString* passMD5 = [password md5];
    NSString* token;
    NSString* wsToken;
    NSString* timeStamp = [NSString currentTimeStamp];

    token = [passMD5 stringByAppendingString:timeStamp];
    token = [token md5];
    wsToken = [username stringByAppendingString:passMD5];
    wsToken = [wsToken md5];

    NSString* streamingLoginUrl = [NSString stringWithFormat:@"https://libre.fm/radio/handshake.php?username=%@&passwordmd5=%@", username, passMD5];
    NSString* scrobblingLoginUrl = [NSString stringWithFormat:@"https://turtle.libre.fm/?hs=true&p=1.2&u=%@&t=%@&a=%@&c=ldr", username, timeStamp, token];
    NSString* webServicesLoginUrl = [NSString stringWithFormat:@"https://libre.fm/2.0/?method=auth.getmobilesession&username=%@&authToken=%@", username, wsToken];

    NSLog(@"%@\n%@\n%@\n", streamingLoginUrl, scrobblingLoginUrl, webServicesLoginUrl);

    return result;
}

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

- (IBAction)LoginButtonClicked:(id)sender
{
    BOOL b = [self loginWithUsername:[self.usernameTextField text]
                            password:[self.passwordTextField text]];
}
@end
