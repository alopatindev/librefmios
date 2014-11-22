//
//  LibrefmDelegate.h
//  librefm
//
//  Created by sbar on 17/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    LibrefmSignupErrorUnknown = 1,
    LibrefmSignupErrorAlreadyRegistered,
} LibrefmSignupError;

@protocol LibrefmDelegate <NSObject>

- (void)librefmDidChangeNetworkActivity:(BOOL)loading;

- (void)librefmDidLogin:(BOOL)ok
               username:(NSString*)username
               password:(NSString*)password
                  error:(NSError*)error;

- (void)librefmDidLoadPlaylist:(NSDictionary*)playlist
                            ok:(BOOL)ok
                         error:(NSError*)error;

- (void)librefmDidSignUp:(BOOL)ok
                   error:(NSError*)error
                username:(NSString*)username
                password:(NSString*)password
                   email:(NSString*)email;

- (void)librefmDidLoadTopTags:(BOOL)ok
                         tags:(NSDictionary*)tags;


@end
