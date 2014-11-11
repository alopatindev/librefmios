//
//  IDZAQAudioPlayer.m
//  IDZAQAudioPlayer
//
// Copyright (c) 2013 iOSDeveloperZone.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import <AudioToolbox/AudioToolbox.h>

#import "IDZAQAudioPlayer.h"
#import "IDZAudioDecoder.h"
#import "IDZTrace.h"
#import "IDZOggVorbisFileDecoder.h"

/*
 * Apple uses 3 buffers in the AQPlayer example. We'll do the same.
 * See: http://developer.apple.com/library/ios/#samplecode/SpeakHere/Listings/Classes_AQPlayer_mm.html
 */
#define IDZ_BUFFER_COUNT 3

/**
 * @brief IDZAudioPlayer private internals.
 */
@interface IDZAQAudioPlayer ()
{
@private
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[IDZ_BUFFER_COUNT];
    BOOL mStopping;
    NSTimeInterval mQueueStartTime;
}
/**
 * @brief Queries the value of the Audio Queue's kAudioQueueProperty_IsRunning property.
 */
- (UInt32)queryIsRunning;
/**
 * @brief Reads data from the audio source and enqueues it on the audio queue.
 */
- (void)readBuffer:(AudioQueueBufferRef)buffer;
/**
 * @brief Stops playback
 * @param immediate if YES playback stops immediately, otherwise playback stops after all enqueued buffers 
 * have finished playing.
 */
//- (BOOL)stop:(BOOL)immediate;
- (BOOL)stop;
/**
 * @brief YES if the player is playing, NO otherwise.
 */
@property (readwrite, getter=isPlaying) BOOL playing;
/**
 * @brief The decoder associated with this player.
 */
@property (readonly, strong) id<IDZAudioDecoder> decoder;

@end


@implementation IDZAQAudioPlayer
@dynamic currentTime;
@dynamic numberOfChannels;
@dynamic duration;
@dynamic durationRatio;
@synthesize playing = mPlaying;
@synthesize decoder = mDecoder;
@synthesize state = mState;
@synthesize queuedPlayback = _queuedPlayback;

BOOL _initializedAudio;
BOOL _continueWithNextSong;

// MARK: - Static Callbacks
static void IDZOutputCallback(void *                  inUserData,
                              AudioQueueRef           inAQ,
                              AudioQueueBufferRef     inCompleteAQBuffer)
{
    IDZAQAudioPlayer* pPlayer = (__bridge IDZAQAudioPlayer*)inUserData;
    [pPlayer readBuffer:inCompleteAQBuffer];
}

static void IDZPropertyListener(void* inUserData,
                                AudioQueueRef inAQ,
                                AudioQueuePropertyID inID)
{
    IDZAQAudioPlayer* pPlayer = (__bridge IDZAQAudioPlayer*)inUserData;
    if(inID == kAudioQueueProperty_IsRunning)
    {
        UInt32 isRunning = [pPlayer queryIsRunning];
        NSLog(@"isRunning = %u", (unsigned int)isRunning);
        BOOL bDidFinish = (pPlayer.playing && !isRunning);
        pPlayer.playing = isRunning ? YES : NO;
        if(bDidFinish)
        {
            [pPlayer.delegate audioPlayerDidFinishPlaying:pPlayer
                                              successfully:YES];
            /*
             * To match AVPlayer's behavior we need to reset the file.
             */
            pPlayer.currentTime = 0;
        }
        if(!isRunning) {
            _continueWithNextSong = YES;
            pPlayer.state = IDZAudioPlayerStateStopped;
        }
    }
    
}

- (id)init
{
    id<IDZAudioDecoder> decoder = [IDZOggVorbisFileDecoder new];

    if (self = [self initWithDecoder:decoder
                               error:nil])
    {
        decoder.audioPlayerDelegate = self;
    }
    return self;
}

- (id)initWithDecoder:(id<IDZAudioDecoder>)decoder error:(NSError *__autoreleasing *)error  
{
    NSParameterAssert(decoder);
    if(self = [super init])
    {
        mDecoder = decoder;
        mState = IDZAudioPlayerStateStopped;
        mQueueStartTime = 0.0;
        _queuedPlayback = NO;
        _initializedAudio = NO;
        _continueWithNextSong = NO;
    }
    return self;
}

- (void)initializeAudio
{
    if (mDecoder.headerIsRead == NO) {
        NSLog(@"initializeAudio: headerIsRead == NO");
        return;
    }

    AudioStreamBasicDescription dataFormat = mDecoder.dataFormat;
    OSStatus status = AudioQueueNewOutput(&dataFormat, IDZOutputCallback,
                                          (__bridge void*)self,
                                          CFRunLoopGetCurrent(),
                                          kCFRunLoopCommonModes,
                                          0,
                                          &mQueue);
    //NSAssert(status == noErr, @"Audio queue creation was successful.");
    if (status != noErr) {
        NSLog(@"Audio queue creation was not successful");
        return;
    }
    AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
    status = AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning,
                                           IDZPropertyListener, (__bridge void*)self);
    if (status != noErr) {
        NSLog(@"AudioQueueAddPropertyListener failed");
        return;
    }
    
    for(int i = 0; i < IDZ_BUFFER_COUNT; ++i)
    {
        UInt32 bufferSize = 128 * 1024;
        status = AudioQueueAllocateBuffer(mQueue, bufferSize, &mBuffers[i]);
        if(status != noErr)
        {
            /*if(*error)
            {
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            }*/
            AudioQueueDispose(mQueue, true);
            mQueue = 0;
            //return nil;
            return;
        }
    }
    
    _initializedAudio = YES;
}

- (BOOL)prepareToPlay
{
    NSLog(@"prepareToPlay");
    for(int i = 0; i < IDZ_BUFFER_COUNT; ++i)
    {
        [self readBuffer:mBuffers[i]];
    }
    self.state = IDZAudioPlayerStatePrepared;
    return YES;
}

- (BOOL)playIfQueuedPlayback
{
    NSLog(@"playIfQueuedPlayback");
    if (_queuedPlayback == YES && self.playing == YES) {
        return [self play];
    }
    return NO;
}

- (BOOL)play
{
    self.playing = YES;
    _queuedPlayback = YES;
    if (mDecoder.bufferingState == BufferingStateReadyToRead) {
        if (_initializedAudio == NO) {
            [self initializeAudio];
        }
        return [self play_];
    }
    return YES;
}

- (BOOL)play_
{
    switch(self.state)
    {
        case IDZAudioPlayerStatePlaying:
            return NO;
        case IDZAudioPlayerStatePaused:
        case IDZAudioPlayerStatePrepared:
        case IDZAudioPlayerStateStopping:
            break;
        default:
            [self prepareToPlay];
    }
    if (self.playing == NO)
    {
        [self stop];
        return NO;
    }
    OSStatus osStatus = AudioQueueStart(mQueue, NULL);
    //NSAssert(osStatus == noErr, @"AudioQueueStart failed");
    if (osStatus != noErr) {
        NSLog(@"AudioQueueStart failed");
        return NO;
    }
    self.state = IDZAudioPlayerStatePlaying;
    //self.playing = YES;
    _queuedPlayback = NO;
    return (osStatus == noErr);
    
}

- (BOOL)togglePlayPause
{
    switch(self.state)
    {
        case IDZAudioPlayerStatePlaying:
        case IDZAudioPlayerStatePrepared:
            return [self pause];
        case IDZAudioPlayerStatePaused:
        case IDZAudioPlayerStateStopped:
            return [self play];
        default:
            return NO;
    }
}

- (BOOL)pause
{
    NSLog(@"pause");
    self.playing = NO;
    //_shouldPause = YES;
    _queuedPlayback = NO;
    if(self.state != IDZAudioPlayerStatePlaying) return NO;
    OSStatus osStatus = AudioQueuePause(mQueue);
    //NSAssert(osStatus == noErr, @"AudioQueuePause failed");
    if (osStatus != noErr) {
        NSLog(@"AudioQueuePause failed");
        return NO;
    }
    self.state = IDZAudioPlayerStatePaused;
    return (osStatus == noErr);
}

- (BOOL)stop
{
    NSLog(@"stop");
    _queuedPlayback = NO;

    if (_initializedAudio == NO) {
        return NO;
    }
    return [self stop_:YES];
}

- (BOOL)stop_:(BOOL)immediate
{
    NSLog(@"stop_");
    //self.playing = NO;
    self.state = IDZAudioPlayerStateStopping;
    OSStatus osStatus = AudioQueueStop(mQueue, immediate);
    if (osStatus != noErr) {
        NSLog(@"AudioQueueStop failed");
        return NO;
    }
    _initializedAudio = NO;

    //NSAssert(osStatus == noErr, @"AudioQueueStop failed");
    return (osStatus == noErr);    
}

- (BOOL)next
{
    if (self.playing == NO)
        return NO;

    if ([mDecoder isNextURLAvailable] == YES) {
        NSLog(@"next");
        [self stop];
        _queuedPlayback = YES;
        if ([mDecoder prepareToPlayNextURL] == YES) {
            [self play];
            return YES;
        }
    }
    return NO;
}

- (void)releaseResources
{
    [self stop];
    [mDecoder releaseResources];
    mDecoder = nil;
}

- (void)readBuffer:(AudioQueueBufferRef)buffer
{
    if(self.state == IDZAudioPlayerStateStopping)
        return;

    NSAssert(self.decoder, @"self.decoder is valid.");
    if(/*self.decoder.bufferingState == BufferingStateReadyToRead &&*/buffer != NULL && [self.decoder readBuffer:buffer] == YES)
    {
        OSStatus status = AudioQueueEnqueueBuffer(mQueue, buffer, 0, 0);
        if(status != noErr)
        {
            NSLog(@"Error: %s status=%d", __PRETTY_FUNCTION__, (int)status);
        }
    } else {
        /*
         * Signal to the audio queue that we have run out of data,
         * but set the immediate flag to false so that playback of
         * currently enqueued buffers completes.
         */
        self.state = IDZAudioPlayerStateStopping;
        Boolean immediate = false;
        AudioQueueStop(mQueue, immediate);
        //_continueWithNextSong = YES;
        _initializedAudio = NO;
    }
}

- (void)dealloc
{
    NSLog(@"IDZAQAudioPlayer dealloc");
    [self stop];
    
    [mDecoder releaseResources];
    mDecoder = nil;
}

// MARK: - Properties

- (UInt32)queryIsRunning
{
    UInt32 oRunning = 0;
    UInt32 ioSize = sizeof(oRunning);
    OSStatus result = AudioQueueGetProperty(mQueue, kAudioQueueProperty_IsRunning, &oRunning, &ioSize);
    if (result != noErr) {
        NSLog(@"queryIsRunning failed");
        return 0;
    }
    return result == noErr && oRunning;
}
- (NSTimeInterval)duration
{
    NSTimeInterval duration = mDecoder.duration;
    return duration;
}

- (int)durationRatio
{
    return mDecoder.durationRatio;
}

- (NSTimeInterval)currentTime
{
    
    AudioTimeStamp outTimeStamp;
    Boolean outTimelineDiscontinuity;
    /*
     * can fail with -66678
     */
    OSStatus status = AudioQueueGetCurrentTime(mQueue, NULL, &outTimeStamp, &outTimelineDiscontinuity);
    NSTimeInterval currentTime;
    switch(status)
    {
        case noErr:
            currentTime = (NSTimeInterval)outTimeStamp.mSampleTime/self.decoder.dataFormat.mSampleRate + mQueueStartTime;
            break;
        case kAudioQueueErr_InvalidRunState:
            currentTime = 0.0;
            break;
        default:
            currentTime = -1.0;
            
    }
    return mQueueStartTime + currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    IDZAudioPlayerState previousState = self.state;
    switch(self.state)
    {
        case IDZAudioPlayerStatePlaying:
            [self stop];
            break;
        default:
            break;
    }
//    [self.decoder seekToTime:currentTime error:nil]; //FIXME: should be used with file?
    mQueueStartTime = currentTime;
    switch(previousState)
    {
        case IDZAudioPlayerStatePrepared:
            [self prepareToPlay];
            break;
        case IDZAudioPlayerStatePlaying:
            [self play];
            break;
        default:
            break;
    }
}

- (NSUInteger)numberOfChannels
{
    return self.decoder.dataFormat.mChannelsPerFrame;
}


- (void)setState:(IDZAudioPlayerState)state
{
    if (mDecoder != nil) {
        [self.delegate audioPlayerChangedState:state url:mDecoder.url];
    }

    switch(state)
    {
        case IDZAudioPlayerStatePaused:
            NSLog(@"IDZAudioPlayerStatePaused");
            break;
        case IDZAudioPlayerStatePlaying:
            NSLog(@"IDZAudioPlayerStatePlaying");
            break;
        case IDZAudioPlayerStatePrepared:
            NSLog(@"IDZAudioPlayerStatePrepared");
            break;
        case IDZAudioPlayerStateStopped:
            NSLog(@"IDZAudioPlayerStateStopped");
            if (_continueWithNextSong == YES) {
                _continueWithNextSong = NO;
                [self next];
            }
            break;
        case IDZAudioPlayerStateStopping:
            NSLog(@"IDZAudioPlayerStateStopping");
            break;
    }
    mState = state;
}

- (void)queueURL:(NSURL*)url
{
    [mDecoder queueURL:url];
}

- (void)queueURLString:(NSString*)urlString
{
    [mDecoder queueURLString:urlString];
}

- (void)clearPlaylist
{
    //[self stop];
    [mDecoder clearPlaylist];
    _queuedPlayback = NO;
}

- (BOOL)isNextURLAvailable
{
    return [mDecoder isNextURLAvailable];
}

- (void)skipBrokenPlaylistItem
{
    [self.delegate audioPlayerDecodeErrorDidOccur:self error:nil];
}

@end
