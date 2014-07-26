//
//  ViewController.h
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDZAudioPlayer.h"
#import "BaseTabViewController.h"

@interface PlayerViewController : BaseTabViewController <IDZAudioPlayerDelegate,
                                                         UIViewControllerTransitioningDelegate,
                                                         UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

- (IBAction)playButtonClicked:(id)sender;
- (IBAction)pauseButtonClicked:(id)sender;
- (IBAction)nextButtonClicked:(id)sender;

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error;
- (void)librefmDidSignUp:(BOOL)ok
                   error:(NSError*)error
                username:(NSString*)username
                password:(NSString*)password
                   email:(NSString*)email;

@end
