//
//  SignupViewController.h
//  librefm
//
//  Created by sbar on 19/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseModalViewController.h"
#import "LibrefmConnection.h"
#import "FlatButton.h"

@interface SignupViewController : BaseModalViewController

@property (weak, nonatomic) LibrefmConnection *librefmConnection;
@property (weak, nonatomic) IBOutlet FlatButton *signupButton;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end
