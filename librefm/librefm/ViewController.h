//
//  ViewController.h
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibrefmDelegate.h"

@interface ViewController : UIViewController <LibrefmDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)loginButtonClicked:(id)sender;

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error;
- (void)librefmDidLoadPlaylist:(NSDictionary*)playlist
                            ok:(BOOL)ok
                         error:(NSError*)error;

@end
