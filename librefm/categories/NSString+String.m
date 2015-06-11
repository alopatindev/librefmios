//
//  NSString+String.m
//  librefm
//
//  Created by alopatindev on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "NSString+String.h"
#import <CommonCrypto/CommonDigest.h>
#import "../librefm/LibrefmConnection.h"

@implementation NSString (String)

+ (NSString *)currentTimeStamp
{
    long long t = (long long) time(NULL);
    return [NSString stringWithFormat:@"%lld", t];
}

- (NSString *)md5
{
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG) strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

- (BOOL)containsString:(NSString *)string
{
    return [self rangeOfString:string].location != NSNotFound ? YES : NO;
}

- (BOOL)isAPIMethod:(NSString *)method
{
    NSComparisonResult result =
        [self compare:method
              options:NSLiteralSearch
                range:NSMakeRange([API2_URL length], [method length])];
    return result == NSOrderedSame ? YES : NO;
}

- (BOOL)isValidEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

@end
