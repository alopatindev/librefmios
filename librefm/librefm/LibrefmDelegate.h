//
//  LibrefmDelegate.h
//  librefm
//
//  Created by sbar on 17/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LibrefmDelegate <NSObject>

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error;

- (void)librefmDidLoadPlaylist:(NSDictionary*)playlist
                            ok:(BOOL)ok
                         error:(NSError*)error;

- (void)librefmDidSignUp:(BOOL)ok
                   error:(NSError*)error
                username:(NSString*)username
                password:(NSString*)password
                   email:(NSString*)email;

@end
