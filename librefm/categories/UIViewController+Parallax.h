//
//  UIViewController+Parallax.h
//  librefm
//
//  Created by alopatindev on 25/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Parallax)

- (void)addParallaxEffectWithDepth:(int)depth foreground:(BOOL)foreground;

@end
