//
//  BaseTabViewController.h
//  librefm
//
//  Created by sbar on 26/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseTabViewController : UIViewController <UITabBarControllerDelegate>

- (void)switchToTab:(UIViewController *)controller;
- (void)switchToTabIndex:(NSUInteger)controllerIndex;

@end
