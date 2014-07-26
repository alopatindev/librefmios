//
//  ViewController.m
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "PlayerViewController.h"
#import "UIViewController+Parallax.h"

#import "AppDelegate.h"
#import "LibrefmConnection.h"

#import "IDZAudioPlayer.h"
#import "IDZAQAudioPlayer.h"
#import "Utils.h"

#import "LoginViewController.h"
#import "SignupViewController.h"

#import "DismissingAnimator.h"
#import "PresentingAnimator.h"

@interface PlayerViewController ()

@end

@implementation PlayerViewController

id<IDZAudioPlayer> _audioPlayer;
__weak LibrefmConnection *_librefmConnection;
LoginViewController *_loginViewController;
SignupViewController *_signupViewController;
CGFloat _presentationViewHeightOffset;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _presentationViewHeightOffset = 0.0;

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _librefmConnection = appDelegate.librefmConnection;
    //[self loginButtonClicked:nil];
    
//    [_librefmConnection getTopTags];

    _audioPlayer = [IDZAQAudioPlayer new];
    _audioPlayer.delegate = self;
    
    NSURL *oggUrl = [NSURL URLWithString:@"http://gigue.rrbone.net/725290.ogg2"];
    //[_audioPlayer queueURL:oggUrl];
//    [_audioPlayer queueURLString:@"http://zalil.ru/d/tf/00a61d009813661117c43caa5996e1eb/14035400/aceaH/storage5-7-4-455147/little.ogg"];
    [_audioPlayer queueURLString:@"http://gigue.rrbone.net/743638.ogg2"];
    //[_audioPlayer queueURLString:@"http://gigue.rrbone.net/24765.ogg2"];

    //[_audioPlayer play];
    
    
    [self addParallaxEffectWithDepth:12 foreground:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)maybeStartLogin
{
    if ([_librefmConnection isNeedInputLoginData] == YES) {
        NSString *titleText = NSLocalizedString(@"", nil);
        NSString *messageText = NSLocalizedString(@"To continue please login with your Libre.fm account", nil);
        NSString *loginText = NSLocalizedString(@"Login", nil);
        NSString *signupText = NSLocalizedString(@"Sign Up", nil);
        //NSString *notNowText = NSLocalizedString(@"Not Now", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:titleText
                                                        message:messageText
                                                       delegate:self
                                              cancelButtonTitle:loginText
                                              otherButtonTitles:/*notNowText, */signupText, nil];
        [alert show];
        return YES;
    }
    return NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%d", buttonIndex);
    switch (buttonIndex) {
        case 0:
            [self openLoginScreen];
            break;
        case 1:
            [self openSignupScreen];
            break;
        //case 2:
        default:
            break;
    }
}

/*- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    return YES;
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
}*/

- (void)openLoginScreen
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    _loginViewController.transitioningDelegate = self;
    _loginViewController.modalPresentationStyle = UIModalPresentationCustom;
    _loginViewController.librefmConnection = _librefmConnection;
    _presentationViewHeightOffset = 280.0;
    [self presentViewController:_loginViewController animated:YES completion:nil];
}

- (void)openSignupScreen
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _signupViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignupViewController"];
    _signupViewController.transitioningDelegate = self;
    _signupViewController.modalPresentationStyle = UIModalPresentationCustom;
    _signupViewController.librefmConnection = _librefmConnection;
    _presentationViewHeightOffset = 220.0;
    [self presentViewController:_signupViewController animated:YES completion:nil];
}

- (IBAction)playButtonClicked:(id)sender
{
    [_audioPlayer play];
}

- (IBAction)pauseButtonClicked:(id)sender
{
    //[_librefmConnection updateNowPlayingArtist:@"Metallica" track:@"Master of Puppets" album:@""];
    //[_audioPlayer releaseResources];
    //_audioPlayer = nil;
//    [_audioPlayer pause];
//    [_audioPlayer clearPlaylist];
//    [_audioPlayer queueURLString:@"http://gigue.rrbone.net/743638.ogg2"];
    //[_librefmConnection signUpWithUsername:@"1" password:@"2" email:@"a@b.c"];

    [self maybeStartLogin];
    //[_librefmConnection getTopTags];
}

- (IBAction)nextButtonClicked:(id)sender
{
    [_audioPlayer next];
}

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error
{
    if (ok) {
        if (_loginViewController != nil) {
            [_loginViewController dismissViewControllerAnimated:YES completion:nil];
            _loginViewController = nil;
        }
        [_librefmConnection radioTune:@"rock"];  // TODO DEBUG
    } else {
        [_loginViewController animateError:[error domain]];
    }
}

- (void)librefmDidSignUp:(BOOL)ok
                   error:(NSError*)error
                username:(NSString*)username
                password:(NSString*)password
                   email:(NSString*)email
{
    if (ok) {
        [_signupViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        switch ([error code]) {
            case LibrefmSignupErrorAlreadyRegistered:
                [_signupViewController animateError:NSLocalizedString(@"Username is already registered", nil)];
                break;
            case LibrefmSignupErrorUnknown:
            default:
                [_signupViewController animateError:NSLocalizedString(@"Oops, something went wrong", nil)];
                [_signupViewController replaceSignupButtonWithOpenBrowser];
                break;
        }
    }
}

- (void)audioPlayerDidFinishPlaying:(id<IDZAudioPlayer>)player
                       successfully:(BOOL)flag
{
}

- (void)audioPlayerDecodeErrorDidOccur:(id<IDZAudioPlayer>)player
                                 error:(NSError *)error
{
}

- (void)audioPlayerChangedState:(IDZAudioPlayerState)state
                            url:(NSURL *)url
{
    NSLog(@"! changed state=%d url='%@'", state, [url absoluteString]);
    
    NSString* str;
    switch(state)
    {
        case IDZAudioPlayerStatePaused:
            str = @"IDZAudioPlayerStatePaused";
            break;
        case IDZAudioPlayerStatePlaying:
            str = @"IDZAudioPlayerStatePlaying";
            break;
        case IDZAudioPlayerStatePrepared:
            str = @"IDZAudioPlayerStatePrepared";
            break;
        case IDZAudioPlayerStateStopped:
            str = @"IDZAudioPlayerStateStopped";
            break;
        case IDZAudioPlayerStateStopping:
            str = @"IDZAudioPlayerStateStopping";
            break;
        default:
            str = @"uknown";
            break;
    }
    
    self.statusLabel.text = [NSString stringWithFormat:@"Status: %@", str];
    self.urlLabel.text = [url absoluteString];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    return [[PresentingAnimator alloc] initWithHeightOffset:_presentationViewHeightOffset];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [DismissingAnimator new];
}

@end
