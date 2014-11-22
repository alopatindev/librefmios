//
//  AppDelegate.m
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "NetworkManager.h"
#import "TabBarViewController.h"
#import "BaseTabViewController.h"
#import "KeychainItemWrapper.h"

@implementation AppDelegate

KeychainItemWrapper *_keychainWrapper;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    srand(time(NULL));
    
    self.needSaveCredentials = NO;
    self.loadingUntilPlayingStarted = NO;
    
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];

    //Float32 bufferLength = 0.1;
    //AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(bufferLength), &bufferLength);

    (void) [NetworkManager instance];
    
    _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"UserAuth" accessGroup:nil];
    
    TabBarViewController *tabBarController = (TabBarViewController *)self.window.rootViewController;
    tabBarController.delegate = self;
    _tagsViewController = tabBarController.viewControllers[TabTags];
    _playerViewController = tabBarController.viewControllers[TabPlayer];
    
    _librefmConnection = [LibrefmConnection new];
    _librefmConnection.delegate = self;
    [_librefmConnection getTopTags];
    
    [application beginReceivingRemoteControlEvents];
    
    [self loadCredentials];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [NetworkManager releaseResources];
    [application endReceivingRemoteControlEvents];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl)
    {
        switch (event.subtype)
        {
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"next track");
                [_playerViewController nextButtonClicked:nil];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"previous track");
                [_playerViewController previousButtonClicked:nil];
                break;
            case UIEventSubtypeRemoteControlPlay:
                NSLog(@"play");
                [_playerViewController playButtonClicked:nil];
                break;
            case UIEventSubtypeRemoteControlPause:
                NSLog(@"pause");
                [_playerViewController pauseButtonClicked:nil];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                NSLog(@"toggle play pause");
                [_playerViewController togglePlayPauseButtonClicked:nil];
                break;
            default:
                NSLog(@"remoteControlReceivedWithEvent %d", event.subtype);
                break;
        }
    }
}

- (void)loadCredentials
{
    NSString* username = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    NSString* password = [_keychainWrapper objectForKey:(__bridge id)(kSecValueData)];
    if (username != nil && [username length] != 0) {
        NSLog(@"username and password loaded");
        [_librefmConnection loginWithUsername:username password:password];
    } else {
        NSLog(@"no username/password");
    }
}

- (void)maybeSaveCredentialsUsername:(NSString*)username password:(NSString*)password
{
    if (self.needSaveCredentials) {
        NSLog(@"saving credentials");
        [_keychainWrapper setObject:username forKey:(__bridge id)(kSecAttrAccount)];
        [_keychainWrapper setObject:password forKey:(__bridge id)(kSecValueData)];
    } else {
        NSLog(@"not gonna save credentials");
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    BaseTabViewController *controller = (BaseTabViewController *)viewController;
    [controller switchToTab:controller];
    return YES;
}

- (void)librefmDidChangeNetworkActivity:(BOOL)loading
{
    if (self.loadingUntilPlayingStarted == YES)
        loading = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = loading;
}

- (void)librefmDidLogin:(BOOL)ok
               username:(NSString*)username
               password:(NSString*)password
                  error:(NSError*)error
{
    if (ok) {
        [self maybeSaveCredentialsUsername:username password:password];
    }
    [_playerViewController librefmDidLogin:ok username:username password:password error:error];
}

- (void)librefmDidLoadPlaylist:(NSDictionary*)playlist ok:(BOOL)ok error:(NSError*)error
{
    if (ok) {
        //NSString *title = playlist[@"title"];
        //NSString *creator = playlist[@"creator"];
        //@"link", @"date"
        //[_playerViewController clearPlaylist];

        NSArray *track = playlist[@"track"];
        for (NSDictionary *t in track) {
            NSString *artist = t[@"creator"];
            NSString *album = t[@"album"];
            NSString *title = t[@"title"];
            //NSDictionary* extension = t[@"extension"]; //artist info
            //@"identifier" : @"0000"
            NSString *url = t[@"location"];
            NSString *image = t[@"image"];
            if ([image isKindOfClass:[NSString class]] == NO) // FIXME: wtf
                image = @"";
            //NSNumber *duration = t[@"duration"]; // always 180000?
            [_playerViewController addToPlaylistURL:url
                                             artist:artist
                                              album:album
                                              title:title
                                           imageURL:image];
        }
    }
}

- (void)librefmDidSignUp:(BOOL)ok
                   error:(NSError*)error
                username:(NSString*)username
                password:(NSString*)password
                   email:(NSString*)email
{
    if (ok) {
        self.needSaveCredentials = YES;
        [self maybeSaveCredentialsUsername:username password:password];
        [_librefmConnection loginWithUsername:username password:password];
    }

    [_playerViewController librefmDidSignUp:ok
                                      error:error
                                   username:username
                                   password:password
                                      email:email];
}

- (void)librefmDidLoadTopTags:(BOOL)ok
                         tags:(NSDictionary*)tags
{
    [_tagsViewController librefmDidLoadTopTags:ok tags:tags];
}

@end
