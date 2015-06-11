//
//  ViewController.m
//  librefm
//
//  Created by alopatindev on 14/06/14.
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

@interface PlaylistItem : NSObject
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *artist;
@property (nonatomic) NSString *album;
@property (nonatomic) NSString *title;
@property (atomic) NSString *imageURL;
@property (atomic) NSData* imageData;
@end

@interface PlayerViewController ()
@property (atomic) NSMutableArray *playlist;
@property (atomic) int playlistIndex;
@property (atomic) PlaylistItem* currentPlaylistItem;
@end

@implementation PlaylistItem

- (BOOL)isEqual:(id)anObject
{
    PlaylistItem* item = (PlaylistItem*)anObject;
    if (item == nil) {
        return NO;
    } else {
        return self.url == item.url || [self.url isEqualToString:item.url];
    }
}

@end

@implementation PlayerViewController

id<IDZAudioPlayer> _audioPlayer;
__weak AppDelegate *_appDelegate;
__weak LibrefmConnection *_librefmConnection;
LoginViewController *_loginViewController;
SignupViewController *_signupViewController;
UIImage *_coverImagePlaceholder;
PlaylistItem *_lastScrobbledPlaylistItem;

const static size_t MIN_PLAYLIST_SIZE = 10;
const static size_t MAX_PLAYLIST_PREVIOUS_SIZE = 50;

NSString *_lastTag;
dispatch_queue_t _dispatchImageQueue;

NSTimer *_progressUpdateTimer;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    _dispatchImageQueue = dispatch_queue_create("imageQueue", NULL);
    _coverImagePlaceholder = [UIImage imageNamed:@"music59"];
    _appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.presentationViewHeightOffset = 0.0;

    _librefmConnection = _appDelegate.librefmConnection;

    [self setEnabled:NO];
    
    self.playlist = [NSMutableArray new];
    self.playlistIndex = -1;
    [self updateSongInfo];
    _lastTag = [NSString new];
    
    _audioPlayer = [IDZAQAudioPlayer new];
    _audioPlayer.delegate = self;
    
    [self addParallaxEffectWithDepth:12 foreground:NO];
}

- (void)setEnabled:(BOOL)enabled
{
    self.togglePlayPauseButton.enabled = enabled;
    self.previousButton.enabled = enabled;
    self.nextButton.enabled = enabled;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    _progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self
                                                          selector:@selector(updatePlayedProgress)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_progressUpdateTimer invalidate];
    _progressUpdateTimer = nil;

    [super viewWillDisappear:animated];
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
        NSString *notNowText = NSLocalizedString(@"Not Now", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:titleText
                                                        message:messageText
                                                       delegate:self
                                              cancelButtonTitle:loginText
                                              otherButtonTitles:notNowText, signupText, nil];
        [alert show];
        return YES;
    }
    return NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%d", (int)buttonIndex);
    switch (buttonIndex) {
        case 0:
            [self openLoginScreen];
            break;
        case 1:
            break;
        case 2:
            [self openSignupScreen];
            break;
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
    //[self updateSongInfo];
}

- (IBAction)togglePlayPauseButtonClicked:(id)sender
{
    [_audioPlayer togglePlayPause];
    [self updateTogglePlayPauseButton];
    //[self updateSongInfo];
}

- (IBAction)pauseButtonClicked:(id)sender
{
    [_audioPlayer pause];
    [self updatePlaylist];
}

- (IBAction)nextButtonClicked:(id)sender
{
    [self updatePlaylist];
    (void) [_audioPlayer next];
    self.playlistIndex++;
    [self maybeDecreasePlaylistToLimit];
    //[self updateSongInfo];
    
    NSLog(@"!!!! playlistIndex=%d, [playlist count]=%d", self.playlistIndex, (int)[self.playlist count]);
}

- (IBAction)previousButtonClicked:(id)sender
{
    // TODO
    if (self.playlistIndex-1 >= 0) {
        self.playlistIndex--;
        NSAssert(self.playlistIndex < [self.playlist count], @"playlistIndex should be < playlist count");
        [_audioPlayer clearPlaylist];
        [_audioPlayer stop];
        PlaylistItem *item = self.playlist[self.playlistIndex];
        [_audioPlayer queueURLString:item.url];
        [_audioPlayer next];
        [_audioPlayer play];
        item = self.playlist[self.playlistIndex + 1];
        [_audioPlayer queueURLString:item.url];
        //[self updateSongInfo];
    }
    NSLog(@"!!!! playlistIndex=%d, [playlist count]=%d", self.playlistIndex, (int)[self.playlist count]);
    //[_audioPlayer previous];
}

- (void)updateTogglePlayPauseButton
{
    NSString *filename = [_audioPlayer isPlaying] == NO ? @"play33.png" : @"pause11.png";
    UIImage *image = [UIImage imageNamed:filename];
    [self.togglePlayPauseButton setImage:image forState:UIControlStateNormal];
}

- (void)librefmDidLogin:(BOOL)ok
               username:(NSString*)username
               password:(NSString*)password
                  error:(NSError*)error
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
    NSLog(@"updateSongInfo");
    if (self.playlistIndex >= 0 && self.playlistIndex < [self.playlist count]) {
        PlaylistItem* item = self.playlist[self.playlistIndex];
        if (self.currentPlaylistItem != nil && (item == self.currentPlaylistItem || [item isEqual:self.currentPlaylistItem] == YES)) {
            NSLog(@"!! updateSongInfo the same item");
            return;
        }
        NSLog(@"updateSongInfo => updating");
        self.currentPlaylistItem = item;
        self.titleLabel.text = item.title;
        //self.artistLabel.text = [NSString stringWithFormat:@"by %@", item.artist];
        self.artistLabel.text = item.artist;
        self.coverImageView.hidden = YES;
        
        [self setEnabled:YES];
        
        dispatch_async(_dispatchImageQueue, ^{
            PlaylistItem* item = self.currentPlaylistItem;
            if (item == nil) {
                return;
            }
            NSString* imageURL = item.imageURL;
            if (imageURL != nil && [imageURL length] > 0) {
                NSString* largeImageURL = [imageURL stringByReplacingOccurrencesOfString:@"imagesize=200" withString:@"imagesize=600"];
                NSLog(@"image url: '%@'", largeImageURL);
                NSURL* url = [[NSURL alloc] initWithString:largeImageURL];
                if (url != nil) {
                    item.imageData = [NSData dataWithContentsOfURL:url];
                }

                if (item.imageData == nil) {
                    NSLog(@"no large picture");
                    url = [[NSURL alloc] initWithString:imageURL];
                    if (url != nil) {
                        item.imageData = [NSData dataWithContentsOfURL:url];
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                PlaylistItem* item = self.currentPlaylistItem;
                if (item == nil || item.imageData == nil)
                {
                    self.coverImageView.image = _coverImagePlaceholder;
                }
                else
                {
                    self.coverImageView.image = [UIImage imageWithData:self.currentPlaylistItem.imageData];
                }
                self.coverImageView.hidden = NO;
            });
        });
    }
    else
    {
        NSLog(@"updateSongInfo => setting to empty");
        [self setEnabled:NO];
        self.titleLabel.text = [NSString new];
        self.artistLabel.text = [NSString new];
        self.coverImageView.hidden = YES;
        self.playedProgressView.progress = 0.0f;
        self.currentPlaylistItem = nil;
    }
}

- (void)updatePlayedProgress
{
    //NSLog(@"updatePlayedProgress");
    float progress = (float)[_audioPlayer playedRatio] / 100.0f;
    self.playedProgressView.progress = progress;

    if (progress >= 0.5f && _lastScrobbledPlaylistItem != self.currentPlaylistItem) {
        PlaylistItem* item = self.currentPlaylistItem;
        [_librefmConnection scrobbleArtist:item.artist
                                     track:item.title
                                     album:item.album];
        _lastScrobbledPlaylistItem = self.currentPlaylistItem;
    }
}

- (void)maybeDecreasePlaylistToLimit
{
    if (self.playlistIndex >= MAX_PLAYLIST_PREVIOUS_SIZE) {
        PlaylistItem* item = self.playlist[self.playlistIndex];
        NSLog(@"!!! decreasePlaylistToLimit(1) %d >= %d; self.playlist[self.playlistIndex].url='%@'", self.playlistIndex, (int)MAX_PLAYLIST_PREVIOUS_SIZE, item.url);
        int offset = self.playlistIndex - (int)MAX_PLAYLIST_PREVIOUS_SIZE;
        NSLog(@"!!! offset=%d", offset);
        self.playlistIndex -= offset;
        [self.playlist removeObjectsInRange:NSMakeRange(0, offset)];
        item = self.playlist[self.playlistIndex];
        //NSLog(@"!!! decreasePlaylistToLimit(2) %d-1 >= %d; self.playlist[self.playlistIndex].url='%@'", self.playlistIndex, (int)MAX_PLAYLIST_PREVIOUS_SIZE, item.url);
    }
}

- (void)clearPlaylist
{
    [_audioPlayer stop];
    [_audioPlayer clearPlaylist];
    [self.playlist removeAllObjects];
    self.playlistIndex = -1;
    [self updateSongInfo];
}

- (void)updatePlaylist
{
    if ([self.playlist count] - self.playlistIndex < MIN_PLAYLIST_SIZE) {
        [self radioTune:_lastTag];
    }
    
    if ([_audioPlayer isNextURLAvailable] == NO) {
        if (self.playlistIndex > 0 && self.playlistIndex + 1 < [self.playlist count])
        {
            PlaylistItem* item = self.playlist[self.playlistIndex + 1];
            [_audioPlayer queueURLString:item.url];
        }
    }
}

- (void)radioTune:tag
{
    //[self maybeStartLogin];
    [_librefmConnection maybeGetAnonymousSession];
    _appDelegate.loadingUntilPlayingStarted = YES;
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
    
    if ([self.playlist containsObject:item] == NO || [self.playlist count] - self.playlistIndex < MIN_PLAYLIST_SIZE)
    {
        [self.playlist addObject:item];
        if (self.playlistIndex == -1) {
            self.playlistIndex = 0;
        }
        
        if ([_audioPlayer isNextURLAvailable] == NO) {
            [_audioPlayer queueURLString:url];
        }
    }
    else
    {
        NSLog(@"this item already exists");
    }
    
    if ([self.playlist count] == 1) {
        [self playButtonClicked:nil];
    }
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
        [self.playlist removeObjectAtIndex:self.playlistIndex];
        NSLog(@"!!!!!!! audioPlayerDecodeErrorDidOccur removed previous song");
    }
    else
    {
        NSLog(@"!!!! audioPlayerDecodeErrorDidOccur: fail of fails");
    }
}

- (BOOL)tryFixPlaylistItemIndex:(NSURL*)correctURL
{
    int newPlaylistIndex = self.playlistIndex;

    while (newPlaylistIndex >= 0 && newPlaylistIndex < [self.playlist count])
    {
        PlaylistItem* item = self.playlist[newPlaylistIndex];
        if (item == nil || [item.url isEqualToString:[correctURL absoluteString]] == NO) {
            NSLog(@"fixing playlist index");
            newPlaylistIndex++;
        } else {
            self.playlistIndex = newPlaylistIndex;
            return YES;
        }
    }

    NSLog(@"tryFixPlaylistItemIndex failed");

    return NO;
}

- (void)audioPlayerChangedState:(IDZAudioPlayerState)state
                            url:(NSURL *)url
{
    NSString* str;
    switch(state)
    {
        case IDZAudioPlayerStatePaused:
            str = @"IDZAudioPlayerStatePaused";
            break;
        case IDZAudioPlayerStatePlaying:
        {
            str = @"IDZAudioPlayerStatePlaying";
            _appDelegate.loadingUntilPlayingStarted = NO;
            [_appDelegate librefmDidChangeNetworkActivity:NO];
            
            if ([self tryFixPlaylistItemIndex:url] == YES) {
                [self updateSongInfo];
                PlaylistItem* item = self.currentPlaylistItem;
                [_librefmConnection updateNowPlayingArtist:item.artist
                                                     track:item.title
                                                     album:item.album];
            } else {
                NSLog(@"! playlistIndex not in playlist");
                [self updateSongInfo];
            }
            break;
        }
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
    NSLog(@"! changed state=%d %@ url='%@' audioPlayer.isPlaying=%d", state, str, [url absoluteString], [_audioPlayer isPlaying]);
    
    //self.statusLabel.text = [NSString stringWithFormat:@"Status: %@", str];
    //self.urlLabel.text = [url absoluteString];
    [self updateTogglePlayPauseButton];
}

@end
