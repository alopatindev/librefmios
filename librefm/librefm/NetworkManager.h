//
//  NetworkManager.h
//  librefm
//
//  Created by alopatindev on 23/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkManagerObserver

- (void) networkAvailabilityChanged:(BOOL)available;

@end


@interface NetworkManager : NSObject

@property (getter=isConnectionAvailable) BOOL connectionAvailable;

+ (instancetype) instance;
+ (void)releaseResources;

- (void)addObserver:(__weak id<NetworkManagerObserver>) observer;

@end
