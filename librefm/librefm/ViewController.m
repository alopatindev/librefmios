//
//  ViewController.m
//  librefm
//
//  Created by sbar on 14/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "ViewController.h"
#import "LibrefmConnection.h"
#import "STKAudioPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

STKAudioPlayer *_audioPlayer;
LibrefmConnection *_librefmConnection;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:(STKAudioPlayerOptions){ .flushQueueOnSeek = YES, .enableVolumeMixer = NO, .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000} }];
    _audioPlayer.meteringEnabled = YES;
    _audioPlayer.volume = 1.0f;

    _librefmConnection = [LibrefmConnection new];
    _librefmConnection.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonClicked:(id)sender
{
    [_audioPlayer play:@"http://www.abstractpath.com/files/audiosamples/sample.mp3"];
    //[_audioPlayer play:@"http://gigue.rrbone.net/743638.ogg2"];
    return;
    [_librefmConnection loginWithUsername:[self.usernameTextField text]
                                 password:[self.passwordTextField text]];
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

@end
