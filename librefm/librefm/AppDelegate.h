//
//  AppDelegate.h
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibrefmDelegate.h"
#import "LibrefmConnection.h"
#import "TagsViewController.h"
#import "PlayerViewController.h"

@interface AppDelegate : UIResponder <LibrefmDelegate,
                                      UIApplicationDelegate,
                                      UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LibrefmConnection *librefmConnection;

@property (strong, nonatomic) TagsViewController *tagsViewController;
@property (strong, nonatomic) PlayerViewController *playerViewController;

@end
