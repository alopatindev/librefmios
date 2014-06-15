//
//  ViewController.m
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "ViewController.h"
#import "LibrefmConnection.h"

@interface ViewController ()

@end

@implementation ViewController

LibrefmConnection *_librefmConnection;

- (void)viewDidLoad
{
    [super viewDidLoad];
	_librefmConnection = [LibrefmConnection new];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)LoginButtonClicked:(id)sender
{
    BOOL b = [_librefmConnection loginWithUsername:[self.usernameTextField text]
                                          password:[self.passwordTextField text]];
}
@end
