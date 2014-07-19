//
//  SignupViewController.m
//  librefm
//
//  Created by sbar on 19/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "SignupViewController.h"
#import "UIColor+CustomColors.h"

@interface SignupViewController ()

@end

@implementation SignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.errorLabel.textColor = [UIColor customRedColor];
    [self.signupButton setColorText:[UIColor blackColor]
                         background:[UIColor customYellowColor]];
}

- (IBAction)signupButtonClicked:(id)sender
{
    [self.librefmConnection signUpWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                         email:self.emailTextField.text];
}

- (void)animateError:(NSString*)errorText
{
    self.errorLabel.text = errorText;
    [self popupLabel:self.errorLabel from:self.signupButton];
    [self shakeButton:self.signupButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
