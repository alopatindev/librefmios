//
//  LoginViewController.h
//  librefm
//
//  Created by sbar on 24/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController /*<LibrefmDelegate>*/

@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
- (IBAction)loginButtonClicked:(id)sender;

@end
