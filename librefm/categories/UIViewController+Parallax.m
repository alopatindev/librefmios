//
//  UIViewController+Parallax.m
//  librefm
//
//  Created by sbar on 25/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "UIViewController+Parallax.h"

@implementation UIViewController (Parallax)

- (void)addParallaxEffectWithDepth:(int)depth foreground:(BOOL)foreground
{
    if (foreground == NO) {
        depth = -depth;
    }

    NSValue *minValue = @(-depth);
    NSValue *maxValue = @(depth);
    
    UIInterpolatingMotionEffect *verticalMotionEffect =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                        type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = minValue;
    verticalMotionEffect.maximumRelativeValue = maxValue;
    UIInterpolatingMotionEffect *horizontalMotionEffect =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                        type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = minValue;
    horizontalMotionEffect.maximumRelativeValue = maxValue;
    
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    [self.view addMotionEffect:group];
}

@end
