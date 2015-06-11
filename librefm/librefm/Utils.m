//
//  Utils.m
//  librefm
//
//  Created by alopatindev on 24/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (CGFloat)aspectRatio
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    return screenHeight / screenWidth;
}

+ (void)openBrowserWithURL:(NSURL*)url
{
    [[UIApplication sharedApplication] openURL:url];
}

+ (void)openBrowser:(NSString*)urlString
{
    [Utils openBrowserWithURL:[NSURL URLWithString:urlString]];
}

@end
