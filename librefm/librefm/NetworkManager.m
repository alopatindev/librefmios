//
//  NetworkManager.m
//  librefm
//
//  Created by sbar on 23/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "NetworkManager.h"
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

static NetworkManager *networkManager = nil;

@implementation NetworkManager

@synthesize connectionAvailable = _connectionAvailable;
NSMutableArray* _observers;
NSTimer* _timer;

+ (instancetype) instance
{
    if (networkManager == nil) {
        networkManager = [NetworkManager new];
    }
    return networkManager;
}

+ (void)releaseResources
{
    networkManager = nil;
    [_timer invalidate];
    _timer = nil;
}

- (instancetype)init
{
    if (self = [super init]) {
        _observers = [NSMutableArray new];
        _connectionAvailable = NO;
        [self onUpdate:nil];
        _timer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                  target:self
                                                selector:@selector(onUpdate:)
                                                userInfo:nil
                                                 repeats:YES];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"NetworkManager dealloc");
}

- (void)addObserver:(__weak id<NetworkManagerObserver>) observer
{
    [_observers addObject:observer];
}

- (BOOL)isConnectionAvailable
{
    return _connectionAvailable;
}

- (void)setConnectionAvailable:(BOOL)available
{
    if (_connectionAvailable == available) {
        return;
    }

    _connectionAvailable = available;
    NSLog(@"connectionAvailable: %d", available);

    for (id<NetworkManagerObserver> ob in _observers) {
        [ob networkAvailabilityChanged:available];
    }
}

- (void)onUpdate:(NSTimer*)timer
{
    BOOL available = [self checkConnectivity];
    [self setConnectionAvailable:available];
}

// http://stackoverflow.com/questions/1083701/how-to-check-for-an-active-internet-connection-on-iphone-sdk/7934636#7934636
- (BOOL)checkConnectivity
{
    struct sockaddr_in zeroAddress;
    memset(&zeroAddress, 0, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                return YES;
            }
            
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
            {
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs
                
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                {
                    // ... and no [user] intervention is needed
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
            {
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                return YES;
            }
        }
    }
    
    return NO;
}

@end
