//
//  TabBarViewController.h
//  librefm
//
//  Created by alopatindev on 26/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>

enum Tab {
    TabTags = 0,
    TabPlayer
};

@interface TabBarViewController : UITabBarController<UITabBarControllerDelegate>

@end
