//
//  LibrefmConnection.h
//  librefm
//
//  Created by sbar on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibrefmConnection : NSObject<NSURLConnectionDelegate>
{
    NSMutableDictionary *_responseDict;
}

- (instancetype)init;
- (BOOL)loginWithUsername:(NSString*)username password:(NSString*)password;

@end
