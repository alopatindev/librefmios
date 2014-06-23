//
//  ViewController.m
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "ViewController.h"
#import "LibrefmConnection.h"

#import "IDZAudioPlayer.h"
#import "IDZAQAudioPlayer.h"
#import "IDZOggVorbisFileDecoder.h"

@interface ViewController ()

@end

@implementation ViewController

id<IDZAudioPlayer> _audioPlayer;
LibrefmConnection *_librefmConnection;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self loadingAnimation] startAnimating];

    /*_librefmConnection = [LibrefmConnection new];
    _librefmConnection.delegate = self;
    
    [self loginButtonClicked:nil];*/

    NSURL *oggUrl = [NSURL URLWithString:@"http://gigue.rrbone.net/725290.ogg2"];
    IDZOggVorbisFileDecoder *decoder = [IDZOggVorbisFileDecoder new];
    //[decoder queueURLString:@"http://gfile.ru/d/tf/f785881deb7e223cbfcbd7eaa02a41b7/14034792/aaX3V/storage5-7-4-455147/little.ogg"];
    [decoder queueURL:oggUrl];
    [decoder queueURLString:@"http://gfile.ru/d/tf/acc4cac1bccd85ebd6bc38430f38485b/14034878/aaX3V/storage5-7-4-455147/little.ogg"];
    
    [decoder queueURLString:@"http://gigue.rrbone.net/743638.ogg2"];
    [decoder queueURLString:@"http://gigue.rrbone.net/24765.ogg2"];
    //NSLog(@"Ogg Vorbis file duration is %g", decoder.duration);
    
    _audioPlayer = [[IDZAQAudioPlayer alloc] initWithDecoder:decoder error:nil];
    _audioPlayer.delegate = self;
    decoder.audioPlayerDelegate = _audioPlayer;
    [_audioPlayer play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonClicked:(id)sender
{
    //[_librefmConnection loginWithUsername:[self.usernameTextField text]
    //                             password:[self.passwordTextField text]];
}

- (IBAction)playButtonClicked:(id)sender
{
    [_audioPlayer play];
}

- (IBAction)pauseButtonClicked:(id)sender
{
    //[_audioPlayer releaseResources];
    //_audioPlayer = nil;
    [_audioPlayer pause];
}

- (IBAction)nextButtonClicked:(id)sender
{
    [_audioPlayer next];
}

- (void)librefmDidLogin:(BOOL)ok error:(NSError*)error
{
    if (ok) {
        [_librefmConnection radioTune:@"rock"];  // TODO DEBUG
    } else {

    }
}

- (void)librefmDidLoadPlaylist:(NSDictionary*)playlist ok:(BOOL)ok error:(NSError*)error
{
    if (ok) {
         NSString *title = playlist[@"title"];
         NSString *creator = playlist[@"creator"];
         //@"link", @"date"
         NSArray *track = playlist[@"track"];
         for (NSDictionary *t in track) {
             NSString *creator = t[@"creator"];
             NSString *album = t[@"album"];
             NSString *title = t[@"title"];
             //NSDictionary* extension = t[@"extension"]; //artist info
             //@"identifier" : @"0000"
             NSString *location = t[@"location"];
             NSString *image = t[@"image"];
             //NSNumber *duration = t[@"duration"]; // always 180000?
             NSLog(@"track '%@' '%@' '%@'", creator, title, location);
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

@end
