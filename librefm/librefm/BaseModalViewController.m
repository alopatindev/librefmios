//
//  BaseModalViewController.m
//  librefm
//
//  Created by sbar on 25/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "BaseModalViewController.h"
#import "UIViewController+Parallax.h"
#import <POP/POP.h>

@interface BaseModalViewController ()
@end

@implementation BaseModalViewController

UITapGestureRecognizer *_tapOutsideRecognizer;

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
    
    [self addParallaxEffectWithDepth:7 foreground:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self enableDismissingPressingByOutside];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_tapOutsideRecognizer != nil) {
        [self.view.window removeGestureRecognizer:_tapOutsideRecognizer];
        _tapOutsideRecognizer = nil;
    }
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

// http://stackoverflow.com/questions/2623417/iphone-sdk-dismissing-modal-viewcontrollers-on-ipad-by-clicking-outside-of-it
- (void)enableDismissingPressingByOutside
{
    if (_tapOutsideRecognizer == nil) {
        _tapOutsideRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handleTapBehind:)];
        
        if ([_tapOutsideRecognizer respondsToSelector:@selector(locationInView:)] == NO) {
            _tapOutsideRecognizer = nil;
            return;
        }
        
        [_tapOutsideRecognizer setNumberOfTapsRequired:1];
        _tapOutsideRecognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
        [self.view.window addGestureRecognizer:_tapOutsideRecognizer];
    }
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    sender.delegate = nil;
    sender.enabled = NO;

    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window
        
        //Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
        if ([self.view pointInside:[self.view convertPoint:location
                                                   fromView:self.view.window]
                          withEvent:nil] == NO)
        {
            // Remove the recognizer first so it's view.window is valid.
            [self.view.window removeGestureRecognizer:sender];
            _tapOutsideRecognizer = nil;
            sender = nil;
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)dealloc
{
    _tapOutsideRecognizer = nil;
    [self.view.window removeGestureRecognizer:_tapOutsideRecognizer];
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
