//
//  Utils.h
//  librefm
//
//  Created by alopatindev on 24/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (CGFloat)aspectRatio;
+ (void)openBrowserWithURL:(NSURL*) url;
+ (void)openBrowser:(NSString*) url;

@end
