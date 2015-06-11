//
//  BaseModalViewController.h
//  librefm
//
//  Created by alopatindev on 25/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseModalViewController : UIViewController

- (void)shakeButton:(UIButton*)button;
- (void)popupLabel:(UILabel*)label from:(UIView*)fromView;
- (IBAction)didShowKeyboard:(id)sender;
//- (IBAction)removeKeyboard:(id)sender;

@end
