//
//  BaseModalViewController.m
//  librefm
//
//  Created by sbar on 25/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "BaseModalViewController.h"
#import <POP/POP.h>

@interface BaseModalViewController ()

@end

@implementation BaseModalViewController

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

    //self.view.backgroundColor = [UIColor yellowColor];
    self.view.layer.cornerRadius = 10.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)shakeButton:(UIButton*)button
{
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimation.velocity = @2000;
    positionAnimation.springBounciness = 20;
    [positionAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        button.userInteractionEnabled = YES;
    }];
    [button.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
}

- (void)popupLabel:(UILabel*)label from:(UIView*)fromView
{
    CGPoint pos = label.layer.position;
    pos.y = fromView.layer.position.y - fromView.intrinsicContentSize.height * 0.5;
    label.layer.position = pos;
    
    //label.layer.opacity = 1.0;
    label.hidden = NO;
    POPSpringAnimation *layerScaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    layerScaleAnimation.springBounciness = 18;
    layerScaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.f, 1.f)];
    [label.layer pop_addAnimation:layerScaleAnimation forKey:@"labelScaleAnimation"];
    
    POPSpringAnimation *layerPositionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    layerPositionAnimation.toValue = @(fromView.layer.position.y - fromView.intrinsicContentSize.height);
    layerPositionAnimation.springBounciness = 12;
    [label.layer pop_addAnimation:layerPositionAnimation forKey:@"layerPositionAnimation"];
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
