//
//  SignupViewController.m
//  librefm
//
//  Created by alopatindev on 19/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "SignupViewController.h"
#import "UIColor+CustomColors.h"
#import "NSString+String.h"

@interface SignupViewController ()

@end

@implementation SignupViewController

BOOL _useWebBrowser;

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
    _useWebBrowser = NO;
    
    self.usernameTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    [self updateButtons];
}

- (IBAction)signupButtonClicked:(id)sender
{
    self.signupButton.enabled = NO;

    if (_useWebBrowser == YES) {
        [self.librefmConnection openSignupBrowser];
    } else {
        [self.librefmConnection signUpWithUsername:self.usernameTextField.text
                                          password:self.passwordTextField.text
                                             email:self.emailTextField.text];
    }
}

- (IBAction)updateButtons
{
    BOOL needInput = [self.usernameTextField.text length] == 0 ||
                     [self.passwordTextField.text length] == 0 ||
                     [self.emailTextField.text isValidEmail] == NO;
    self.signupButton.enabled = needInput ? NO : YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UIControl *nextControl = nil;

    if (textField == self.usernameTextField) {
        nextControl = self.emailTextField;
    } else if (textField == self.emailTextField) {
        nextControl = self.passwordTextField;
    } else if (textField == self.passwordTextField) {
        [self.signupButton click];
    }
    
    if (nextControl != nil) {
        [textField resignFirstResponder];
        [nextControl becomeFirstResponder];
    }
    
    return YES;
}

- (void)animateError:(NSString *)errorText
{
    self.errorLabel.text = errorText;
    [self popupLabel:self.errorLabel from:self.signupButton];
    [self shakeButton:self.signupButton];
    self.signupButton.enabled = YES;
}

- (void)replaceSignupButtonWithOpenBrowser
{
    _useWebBrowser = YES;
    [self.signupButton setTitle:NSLocalizedString(@"Open Browser", nil)
                       forState:UIControlStateNormal];
    // TODO: fix button size
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
