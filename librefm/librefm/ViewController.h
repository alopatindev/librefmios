//
//  ViewController.h
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibrefmDelegate.h"
#import "IDZAudioPlayer.h"

@interface ViewController : UIViewController <LibrefmDelegate, IDZAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAnimation;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

- (IBAction)loginButtonClicked:(id)sender;
- (IBAction)playButtonClicked:(id)sender;
- (IBAction)pauseButtonClicked:(id)sender;
- (IBAction)nextButtonClicked:(id)sender;

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error;
- (void)librefmDidLoadPlaylist:(NSDictionary*)playlist
                            ok:(BOOL)ok
                         error:(NSError*)error;

@end
