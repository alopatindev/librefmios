//
//  LoginViewController.h
//  librefm
//
//  Created by sbar on 24/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseModalViewController.h"
#import "LibrefmConnection.h"
#import "FlatButton.h"

@interface LoginViewController : BaseModalViewController

@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet FlatButton *loginButton;

@property (weak, nonatomic) LibrefmConnection *librefmConnection;

- (IBAction)loginButtonClicked:(id)sender;
- (void)animateError:(NSString*)errorText;

@end
