//
//  NSString+String.m
//  librefm
//
//  Created by sbar on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "NSString+String.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (String)

+ (NSString*) currentTimeStamp
{
    long long t = (long long) time(NULL);
    return [NSString stringWithFormat:@"%lld", t];
}

- (NSString*) md5
{
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

@end
