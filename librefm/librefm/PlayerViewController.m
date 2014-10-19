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

@interface PlayerViewController ()

@end

@interface PlaylistItem : NSObject
    @property (nonatomic) NSString *url;
    @property (nonatomic) NSString *artist;
    @property (nonatomic) NSString *album;
    @property (nonatomic) NSString *title;
    @property (nonatomic) NSString *imageURL;
@end

@implementation PlaylistItem
@end

@implementation PlayerViewController

id<IDZAudioPlayer> _audioPlayer;
__weak LibrefmConnection *_librefmConnection;
LoginViewController *_loginViewController;
SignupViewController *_signupViewController;

const static size_t MIN_PLAYLIST_SIZE = 10;
const static size_t MAX_PLAYLIST_PREVIOUS_SIZE = 50;

NSMutableArray *_playlist;
int _playlistIndex;
NSString *_lastTag;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.presentationViewHeightOffset = 0.0;

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _librefmConnection = appDelegate.librefmConnection;

    _playlist = [NSMutableArray new];
    _playlistIndex = -1;
    [self updateSongInfo];
    _lastTag = [NSString new];
    
    _audioPlayer = [IDZAQAudioPlayer new];
    _audioPlayer.delegate = self;
    
    [self addParallaxEffectWithDepth:12 foreground:NO];
    [self maybeStartLogin];
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
    self.presentationViewHeightOffset = 280.0;
    [self presentViewController:_loginViewController animated:YES completion:nil];
}

- (void)openSignupScreen
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _signupViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignupViewController"];
    _signupViewController.transitioningDelegate = self;
    _signupViewController.modalPresentationStyle = UIModalPresentationCustom;
    _signupViewController.librefmConnection = _librefmConnection;
    self.presentationViewHeightOffset = 220.0;
    [self presentViewController:_signupViewController animated:YES completion:nil];
}

- (IBAction)playButtonClicked:(id)sender
{
    [_audioPlayer play];
    [self updateSongInfo];
}

- (IBAction)togglePlayPauseButtonClicked:(id)sender
{
    [_audioPlayer togglePlayPause];
    [self updateTogglePlayPauseButton];
    [self updateSongInfo];
}

- (IBAction)pauseButtonClicked:(id)sender
{
    [_audioPlayer pause];
    [self updatePlaylist];
}

- (IBAction)nextButtonClicked:(id)sender
{
    [self updatePlaylist];
    if ([_audioPlayer next] == YES)
    {
        _playlistIndex++;
        [self maybeDecreasePlaylistToLimit];
        [self updateSongInfo];
    }
    
    NSLog(@"!!!! playlistIndex=%d, [playlist count]=%d", _playlistIndex, (int)[_playlist count]);
}

- (IBAction)previousButtonClicked:(id)sender
{
    // TODO
    if (_playlistIndex-1 >= 0)
    {
        _playlistIndex--;
        assert(_playlistIndex < [_playlist count]);
        [_audioPlayer clearPlaylist];
        [_audioPlayer stop];
        PlaylistItem *item = _playlist[_playlistIndex];
        [_audioPlayer queueURLString:item.url];
        [_audioPlayer next];
        [_audioPlayer play];
        item = _playlist[_playlistIndex + 1];
        [_audioPlayer queueURLString:item.url];
        [self updateSongInfo];
    }
    NSLog(@"!!!! playlistIndex=%d, [playlist count]=%d", _playlistIndex, (int)[_playlist count]);
    //[_audioPlayer previous];
}

- (void)updateTogglePlayPauseButton
{
    NSString *filename = [_audioPlayer isPlaying] == NO ? @"play33.png" : @"pause11.png";
    UIImage *image = [UIImage imageNamed:filename];
    [self.togglePlayPauseButton setImage:image forState:UIControlStateNormal];
}

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error
{
    if (ok) {
        if (_loginViewController != nil) {
            [_loginViewController dismissViewControllerAnimated:YES completion:nil];
            _loginViewController = nil;
        }
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

- (void)updateSongInfo
{
    if (_playlistIndex >= 0 && _playlistIndex < [_playlist count])
    {
        PlaylistItem* item = _playlist[_playlistIndex];
        self.titleLabel.text = item.title;
        self.artistLabel.text = [NSString stringWithFormat:@"by %@", item.artist];
    }
    else
    {
        self.titleLabel.text = [NSString new];
        self.artistLabel.text = [NSString new];
    }
}

- (void)maybeDecreasePlaylistToLimit
{
    if (_playlistIndex - 1 >= MAX_PLAYLIST_PREVIOUS_SIZE)
    {
        PlaylistItem* item = _playlist[_playlistIndex];
        NSLog(@"!!! decreasePlaylistToLimit(1) %d-1 >= %d; _playlist[_playlistIndex].url='%@'", _playlistIndex, (int)MAX_PLAYLIST_PREVIOUS_SIZE, item.url);
        int offset = _playlistIndex - (int)MAX_PLAYLIST_PREVIOUS_SIZE;
        NSLog(@"!!! offset=%d", offset);
        _playlistIndex -= offset;
        [_playlist removeObjectsInRange:NSMakeRange(0, offset)];
        item = _playlist[_playlistIndex];
        NSLog(@"!!! decreasePlaylistToLimit(2) %d-1 >= %d; _playlist[_playlistIndex].url='%@'", _playlistIndex, (int)MAX_PLAYLIST_PREVIOUS_SIZE, item.url);
    }
}

- (void)clearPlaylist
{
    [_audioPlayer stop];
    [_audioPlayer clearPlaylist];
    [_playlist removeAllObjects];
    _playlistIndex = -1;
    [self updateSongInfo];
}

- (void)updatePlaylist
{
    if ([_playlist count] - _playlistIndex < MIN_PLAYLIST_SIZE)
        [self radioTune:_lastTag];
    
    if ([_audioPlayer isNextURLAvailable] == NO)
    {
        if (_playlistIndex > 0 && _playlistIndex + 1 < [_playlist count])
        {
            PlaylistItem* item = _playlist[_playlistIndex + 1];
            [_audioPlayer queueURLString:item.url];
        }
    }
}

- (void)radioTune:tag
{
    [_librefmConnection radioTune:tag];
    _lastTag = tag;
}

- (void)addToPlaylistURL:(NSString *)url
                  artist:(NSString *)artist
                   album:(NSString *)album
                   title:(NSString *)title
                imageURL:(NSString *)imageURL
{
    //[_audioPlayer queueURLString:url];
    // TODO
    PlaylistItem* item = [PlaylistItem alloc];
    item.url = url;
    item.artist = artist;
    item.album = album;
    item.title = title;
    item.imageURL = imageURL;
    [_playlist addObject:item];
    if (_playlistIndex == -1)
        _playlistIndex = 0;
    
    if ([_audioPlayer isNextURLAvailable] == NO)
        [_audioPlayer queueURLString:url];
}

- (void)audioPlayerDidFinishPlaying:(id<IDZAudioPlayer>)player
                       successfully:(BOOL)flag
{
}

- (void)audioPlayerDecodeErrorDidOccur:(id<IDZAudioPlayer>)player
                                 error:(NSError *)error
{
    NSLog(@"!!!!!!! audioPlayerDecodeErrorDidOccur");
    [self updatePlaylist];
    if ([_audioPlayer next] == YES)
    {
        [_playlist removeObjectAtIndex:_playlistIndex];
        NSLog(@"!!!!!!! audioPlayerDecodeErrorDidOccur removed previous song");
    }
    else
    {
        NSLog(@"!!!! audioPlayerDecodeErrorDidOccur: fail of fails");
    }
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
            [self updateTogglePlayPauseButton];
            break;
        case IDZAudioPlayerStatePlaying:
            str = @"IDZAudioPlayerStatePlaying";
            [self updateTogglePlayPauseButton];
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
    
    //self.statusLabel.text = [NSString stringWithFormat:@"Status: %@", str];
    //self.urlLabel.text = [url absoluteString];
}

@end
