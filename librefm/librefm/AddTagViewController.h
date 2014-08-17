//
//  AddTagViewController.h
//  librefm
//
//  Created by sbar on 16/08/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseModalViewController.h"
#import "FlatButton.h"
#import "TagsViewController.h"

@interface AddTagViewController : BaseModalViewController

@property (weak, nonatomic) IBOutlet FlatButton *addButton;
@property (weak, nonatomic) IBOutlet UITextField *tagTextField;
@property (weak, nonatomic) TagsViewController *delegate;

- (IBAction)updateButtons;
- (IBAction)onAddClicked;

@end
