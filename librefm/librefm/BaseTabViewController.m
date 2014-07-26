//
//  BaseTabViewController.m
//  librefm
//
//  Created by sbar on 26/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "BaseTabViewController.h"

@interface BaseTabViewController ()

@end

@implementation BaseTabViewController

- (void)switchToTab:(UIViewController *)controller
{
    UIView *fromView = self.tabBarController.selectedViewController.view;
    UIView *toView = controller.view;
    
    if (fromView == toView) {
        return;
    }
    
    NSUInteger controllerIndex = [self.tabBarController.viewControllers indexOfObject:controller];
    
    [UIView transitionFromView:fromView
                        toView:toView
                      duration:0.2
                       options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished) {
                        if (finished) {
                            self.tabBarController.selectedIndex = controllerIndex;
                        }
                    }];
}

- (void)switchToTabIndex:(NSUInteger)controllerIndex
{
    UIViewController *controller = (UIViewController *)(self.tabBarController.viewControllers[controllerIndex]);
    [self switchToTab:controller];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
