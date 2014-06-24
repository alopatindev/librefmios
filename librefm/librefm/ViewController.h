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

@interface ViewController : UIViewController <LibrefmDelegate,
                                              IDZAudioPlayerDelegate,
                                              UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAnimation;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

- (IBAction)playButtonClicked:(id)sender;
- (IBAction)pauseButtonClicked:(id)sender;
- (IBAction)nextButtonClicked:(id)sender;

@end
