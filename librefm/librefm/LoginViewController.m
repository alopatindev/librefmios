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

    self.errorLabel.textColor = [UIColor customRedColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
//    [self popupLabel:self.errorLabel from:sender];
//    [self shakeButton:sender];
    //[self shakeButton:sender];
    //[self jumpLabel:self.errorLabel from:sender];
    //[_librefmConnection loginWithUsername:[self.usernameTextField text]
    //                             password:[self.passwordTextField text]];
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
