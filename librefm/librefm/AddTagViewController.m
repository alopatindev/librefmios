//
//  AddTagViewController.m
//  librefm
//
//  Created by sbar on 16/08/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "AddTagViewController.h"
#import "UIColor+CustomColors.h"

@interface AddTagViewController ()

@end

@implementation AddTagViewController

- (IBAction)updateButtons
{
    BOOL needInput = [self.tagTextField.text length] == 0;
    self.addButton.enabled = needInput ? NO : YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.addButton setColorText:[UIColor whiteColor]
                      background:[UIColor customGreenColor]];
    [self updateButtons];
}

- (IBAction)onAddClicked
{
    [self.delegate addTag:self.tagTextField.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
