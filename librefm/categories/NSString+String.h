//
//  NSString+String.h
//  librefm
//
//  Created by alopatindev on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (String)

+ (NSString *)currentTimeStamp;
- (NSString *)md5;
- (BOOL)containsString:(NSString *)string;
- (BOOL)isAPIMethod:(NSString *)method;
- (BOOL)isValidEmail;

@end
