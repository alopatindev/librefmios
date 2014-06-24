//
//  Utils.m
//  librefm
//
//  Created by sbar on 24/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (void)openBrowserWithURL:(NSURL*)url
{
    [[UIApplication sharedApplication] openURL:url];
}

+ (void)openBrowser:(NSString*)urlString
{
    [Utils openBrowserWithURL:[NSURL URLWithString:urlString]];
}

@end
