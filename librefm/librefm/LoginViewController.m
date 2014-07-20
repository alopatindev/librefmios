//
//  LoginViewController.m
//  librefm
//
//  Created by sbar on 24/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "LoginViewController.h"
#import "UIColor+CustomColors.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self updateButtons];
    self.errorLabel.textColor = [UIColor customRedColor];
    [self.loginButton setColorText:[UIColor whiteColor]
                        background:[UIColor customGreenColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonClicked:(id)sender
{
    [self.librefmConnection loginWithUsername:self.usernameTextField.text
                                     password:self.passwordTextField.text];
}

- (IBAction)updateButtons
{
    BOOL needInput = [self.usernameTextField.text length] == 0 ||
                     [self.passwordTextField.text length] == 0;
    self.loginButton.enabled = needInput ? NO : YES;
}

- (void)animateError:(NSString*)errorText
{
    self.errorLabel.text = errorText;
    [self popupLabel:self.errorLabel from:self.loginButton];
    [self shakeButton:self.loginButton];
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
