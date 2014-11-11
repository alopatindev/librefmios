//
//  IDZOggVorbisFileDecoder.m
//  IDZAudioDecoder
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

extern "C" {

#import <Vorbis/vorbisfile.h>
#import "IDZAudioDecoder.h"
#import "IDZOggVorbisFileDecoder.h"
#import "IDZTrace.h"
#import "IDZAQAudioPlayer.h"
#import "NetworkManager.h"
#include <string.h>

#define IDZ_BITS_PER_BYTE 8
#define IDZ_BYTES_TO_BITS(bytes) ((bytes) * IDZ_BITS_PER_BYTE)
#define IDZ_OGG_VORBIS_WORDSIZE 2
    
static size_t network_stream_read(void* ptr, size_t size, size_t nitems, FILE* stream);
static int network_stream_close(FILE* stream);
//static int network_stream_seek(FILE* stream, ogg_int64_t off, int whence);

static ov_callbacks MY_CALLBACKS_STREAMONLY = {
    (size_t (*)(void *, size_t, size_t, void *))  network_stream_read,
    (int (*)(void *, ogg_int64_t, int))           NULL /*network_stream_seek*/,
    (int (*)(void *))                             network_stream_close,
    (long (*)(void *))                            NULL
};

static const size_t MAX_DATA_QUEUE_SIZE = (size_t) (1024U * 1024U / 3U);
static const size_t MIN_DATA_QUEUE_SIZE = (size_t) (MAX_DATA_QUEUE_SIZE / 2U);
static const int DELAY_BETWEEN_REQUESTS_SECONDS = 20; // seconds
    
/**
 * @brief IDZOggVorbisFileDecoder private internals.
 */
@interface IDZOggVorbisFileDecoder ()
{
@private
    FILE* mpFile;
    OggVorbis_File mOggVorbisFile;
}

@property NSMutableDictionary* dataQueueDict;
@property NSMutableArray* urlList;

@property size_t downloadedBytes;
@property size_t readBytes;
@property size_t expectedContentLength;
@property NSURLConnection* connection;

@end
    

static IDZOggVorbisFileDecoder* _self = nil;

    

@implementation IDZOggVorbisFileDecoder

@synthesize dataFormat = mDataFormat;
@synthesize bufferingState = _bufferingState;
@synthesize audioPlayerDelegate = _audioPlayerDelegate;
@synthesize headerIsRead = _headerIsRead;
@synthesize url = _url;

NSTimer* _timerSendRequest;
BOOL _downloadComplete;

//BufferingState _bufferingState;
/*- (void)setBufferingState:(BufferingState)state
{
    NSLog(@"!!! setBufferingState %d", state);
    _bufferingState = state;
}

- (BufferingState)bufferingState
{
    NSLog(@"!!! bufferingState %d", _bufferingState);
    return _bufferingState;
}*/

- (void)queueURL:(NSURL*)url
{
    [self.urlList addObject:url];
    
    if ([self.urlList count] == 1U) {
        [self prepareToPlayURL:url];
    }
}

- (void)queueURLString:(NSString*)urlString
{
    NSURL* url = [NSURL URLWithString:urlString];
    [self queueURL:url];
}

- (void)clearPlaylist
{
    [self reset];
    [self.urlList removeAllObjects];
}

- (BOOL)isNextURLAvailable
{
    BOOL result = [self.urlList count] > 1 /*&&
                  self.headerIsRead == YES &&
                  self.bufferingState != BufferingStateNothing*/ /*&&
                  ((IDZAQAudioPlayer*)self.audioPlayerDelegate).state != IDZAudioPlayerStateStopping*/;
    return result;
}

- (BOOL)prepareToPlayNextURL
{
    if ([self isNextURLAvailable] == YES) {
        NSURL* nextURL = self.urlList[1];
        [self.urlList removeObjectAtIndex:0];

        [self prepareToPlayURL:nextURL];
        return YES;
    }
    return NO;
}

- (void)prepareToPlayURL:(NSURL*)url
{
    [self reset];
    self.url = url;

    if ([url isFileURL] == NO) {
        //self.dataQueueDict[url] = [NSMutableData new];
        [self sendRequest:url];
    } else {
        NSString* path = [url path];
        self.bufferingState = BufferingStateDone;
        mpFile = fopen([path UTF8String], "r");
        [self readHeaderInfoIfNeeded];
    }
}

- (void)reset
{
    [self releaseResources];
    _self = self;
    mpFile = NULL;
    _downloadComplete = NO;
    self.url = nil;
    self.expectedContentLength = 0U;
    self.downloadedBytes = 0U;
    self.readBytes = 0U;
    self.headerIsRead = NO;
    self.bufferingState = BufferingStateNothing;
}

- (void)releaseResources
{
    if (_self != nil) {
        if (self.connection != nil) {
            [self.connection cancel];
        }
        self.connection = nil;
        [_timerSendRequest invalidate];
        ov_clear(&mOggVorbisFile);
        network_stream_close(NULL);
        //self.dataQueueDict = nil;
        _self = nil;
    }
}

- (void)dealloc
{
    NSLog(@"IDZOggVorbisFileDecoder dealloc");
    //self.audioPlayerDelegate = nil;
    [self releaseResources];
}

- (id)init
{
    if (self = [super init]) {
        self.urlList = [NSMutableArray new];
        self.dataQueueDict = [NSMutableDictionary new];
        [self reset];
        [[NetworkManager instance] addObserver:self];
    }
    return self;
}

/*- (id)initWithContentsOfURL:(NSURL*)url error:(NSError *__autoreleasing *)error
{
    if(self = [super init])
    {
        _self = self;
        mpFile = NULL;
        self.url = url;
        self.expectedContentLength = 0U;
        self.downloadedBytes = 0U;
        self.headerIsRead = NO;
        self.bufferingState = BufferingStateNothing;

        if ([url isFileURL] == NO)
        {
            self.dataQueueDict[self.url] = [NSMutableData new];
            [self sendRequest:url];
        } else {
            NSString* path = [url path];
            self.bufferingState = BufferingStateDone;
            mpFile = fopen([path UTF8String], "r");
            [self readHeaderInfoIfNeeded];
        }
    }
    return self;
}*/

- (void)readHeaderInfoIfNeeded
{
    if (self.headerIsRead == NO /*&& self.downloadedBytes > 0*/) {
        //NSAssert(mpFile, @"fopen succeeded.");
        int iReturn = ov_open_callbacks(mpFile ? mpFile : (FILE*)1, &mOggVorbisFile, NULL, 0, MY_CALLBACKS_STREAMONLY);
        //NSAssert(iReturn >= 0, @"ov_open_callbacks succeeded.");
        
        if (iReturn < 0)
        {
            NSLog(@"ov_open_callbacks returned %d", iReturn);
            return;
        }

        vorbis_info* pInfo = ov_info(&mOggVorbisFile, -1);
        
        if (pInfo == nil) {
            NSLog(@"readHeaderInfoIfNeeded: cannot read header");
            return;
        }
        
        int bytesPerChannel = IDZ_OGG_VORBIS_WORDSIZE;
        FillOutASBDForLPCM(mDataFormat,
                           (Float64)pInfo->rate, // sample rate (fps)
                           (UInt32)pInfo->channels, // channels per frame
                           (UInt32)IDZ_BYTES_TO_BITS(bytesPerChannel), // valid bits per channel
                           (UInt32)IDZ_BYTES_TO_BITS(bytesPerChannel), // total bits per channel
                           false, // isFloat
                           false); // isBigEndian
        
        self.headerIsRead = YES;
    }
}

- (BOOL)readBuffer:(AudioQueueBufferRef)pBuffer
{
    //self.bufferingState = BufferingStateReadyToRead;

    //IDZTrace();
    int bigEndian = 0;
    int wordSize = IDZ_OGG_VORBIS_WORDSIZE;
    int signedSamples = 1;
    int currentSection = -1;
    
    /* See: http://xiph.org/vorbis/doc/vorbisfile/ov_read.html */
    UInt32 nTotalBytesRead = 0;
    long nBytesRead = 0;
    do
    {
        nBytesRead = ov_read(&mOggVorbisFile,
                             (char*)pBuffer->mAudioData + nTotalBytesRead,
                             (int)(pBuffer->mAudioDataBytesCapacity - nTotalBytesRead),
                             bigEndian, wordSize,
                             signedSamples, &currentSection);
        if(nBytesRead  <= 0)
            break;
        nTotalBytesRead += nBytesRead;
    } while(nTotalBytesRead < pBuffer->mAudioDataBytesCapacity);
    if(nTotalBytesRead == 0)
        return NO;
    if(nBytesRead < 0)
    {
        return NO;
    }
    pBuffer->mAudioDataByteSize = nTotalBytesRead;
    pBuffer->mPacketDescriptionCount = 0;
    return YES;
}

- (BOOL)seekToTime:(NSTimeInterval)time error:(NSError**)error
{
    /* 
     * Possible errors are OV_ENOSEEK, OV_EINVAL, OV_EREAD, OV_EFAULT, OV_EBADLINK
     * See: http://xiph.org/vorbis/doc/vorbisfile/ov_time_seek.html
     */
    int iResult = ov_time_seek(&mOggVorbisFile, time);
    NSLog(@"ov_time_seek(%g) = %d", time, iResult);
    return (iResult == 0);
}

// MARK: - Dynamic Properties
- (NSTimeInterval)duration
{
    NSLog(@"playedRatio=%d", [self playedRatio]);
    double duration = ov_time_total(&mOggVorbisFile, -1);
    return (NSTimeInterval)duration;
}

- (int)playedRatio
{
    //size_t fileSize = _downloadComplete ? self.downloadedBytes : self.expectedContentLength;
    size_t fileSize = self.expectedContentLength;
    if (fileSize == 0LLU)
        return 0;
    return (self.readBytes * 100LLU) / fileSize;
}

// networking

- (void)networkAvailabilityChanged:(BOOL)available
{
    if (_downloadComplete == NO && self.url != nil) {
        [self sendRequest:self.url];
    }
}

- (void)sendRequest:(NSURL *)url
{
    self.connection = nil;
    
    if ([[NetworkManager instance] isConnectionAvailable] == NO) {
        return;
    }
    
    BOOL isCurrentURL = [url isEqual:self.url];
    BOOL isActualURL = isCurrentURL || [self.urlList containsObject:url];
    if (isActualURL == NO) {
        return;
    }

    //if (_self == nil /*|| self.dataQueueDict[url] == nil*/) {
    //    return;
    //}

    if ([self.dataQueueDict[url] length] >= MAX_DATA_QUEUE_SIZE) {
        [self sendRequest:url afterDelay:DELAY_BETWEEN_REQUESTS_SECONDS];
        if (isCurrentURL == YES) {
            [self readHeaderInfoIfNeeded];
            [self.audioPlayerDelegate playIfQueuedPlayback];
        }
        return;
    }
    
    size_t downloadedBytes = self.downloadedBytes;
    /*if (downloadedBytes > self.expectedContentLength) {
        return;
    }*/

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:40.0];

    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];

    if (downloadedBytes > 0U) {
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%zu-", downloadedBytes];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }

    self.connection = [[NSURLConnection alloc] initWithRequest:request
                                                      delegate:self];
}

- (void)sendRequest:(NSURL*)url afterDelay:(int)delayInSeconds
{
    NSLog(@"scheduling request after %d seconds", delayInSeconds);
    [_timerSendRequest invalidate];
    _timerSendRequest = [NSTimer scheduledTimerWithTimeInterval:delayInSeconds
                                                         target:self
                                                       selector:@selector(onTickSendRequest:)
                                                       userInfo:nil
                                                        repeats:NO];
}

-(void)onTickSendRequest:(NSTimer*)timer
{
    NSLog(@"sending request!");
    [self sendRequest:self.url];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];

    NSURL* url = [[connection currentRequest] URL];
    BOOL isCurrentURL = [url isEqual:self.url];

    static NSArray* const kValidMimeTypes = @[@"audio/ogg", @"application/octet-stream"];
    BOOL correctMimeType = [kValidMimeTypes indexOfObject:[response MIMEType]] != NSNotFound;

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    int statusCode = (int) httpResponse.statusCode;
    NSLog(@"! didReceiveResponse statusCode=%d MIMEType='%@'", statusCode, [response MIMEType]);
    
    BOOL wrongResponse = NO;
    switch (statusCode) {
        case 200: // OK
            self.expectedContentLength = (size_t) [response expectedContentLength];
            break;
        case 206: // partial content
            break;
        default:
            // 404 and so on
            wrongResponse = YES;
            break;
    }

    wrongResponse = wrongResponse || !correctMimeType;
    
    if (isCurrentURL == YES && wrongResponse == YES) {
        NSLog(@"! wrong response; skipping it");
        /*BOOL queuedPlayback = self.audioPlayerDelegate.queuedPlayback;
        [self.audioPlayerDelegate stop];
        [self prepareToPlayNextURL];
        self.audioPlayerDelegate.queuedPlayback = queuedPlayback;*/
        [self.audioPlayerDelegate skipBrokenPlaylistItem];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];

    NSURL* url = [[connection currentRequest] URL];
    
    BOOL isCurrentURL = [url isEqual:self.url];
    BOOL isActualURL = isCurrentURL || [self.urlList containsObject:url];

    if (isActualURL == NO /*|| self.dataQueueDict[url] == nil*/) {
        NSLog(@"cancelling connection (case 2)");
        [self.connection cancel];
        self.connection = nil;
        if (self.dataQueueDict[url] != nil) {
            [self.dataQueueDict removeObjectForKey:url];
        }
        return;
    }
    
    if (self.dataQueueDict[url] == nil) {
        self.dataQueueDict[url] = [NSMutableData new];
    }

    size_t size = (size_t) [data length];
    //NSLog(@"GONNA WRITE self.downloadedBytes=%zu", self.downloadedBytes + size);
    [self.dataQueueDict[url] appendData:data];
    self.downloadedBytes += size;
    //NSLog(@"WRITTEN self.downloadedBytes=%zu", self.downloadedBytes);
    
    if (isCurrentURL) {
        self.bufferingState = BufferingStateReadyToRead;
    }
    
    size_t queueLength = (size_t) [self.dataQueueDict[url] length];
    if (queueLength >= MAX_DATA_QUEUE_SIZE) {
        NSLog(@"cancelling connection");
        [self.connection cancel];
        self.connection = nil;

        [self sendRequest:url afterDelay:DELAY_BETWEEN_REQUESTS_SECONDS];
        
        if (isCurrentURL) {
            [self.audioPlayerDelegate playIfQueuedPlayback];
        }
    }

    if (queueLength >= MIN_DATA_QUEUE_SIZE && isCurrentURL) {
        [self readHeaderInfoIfNeeded];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"song downloading complete!");
    self.connection = nil;
    _downloadComplete = YES;
    
    // for very small songs
    NSURL* url = [[connection currentRequest] URL];
    BOOL isCurrentURL = [url isEqual:self.url];
    if (isCurrentURL) {
        [self readHeaderInfoIfNeeded];
        [self.audioPlayerDelegate playIfQueuedPlayback];
    }

    if ([self isNextURLAvailable] == YES) {
        //NSLog(@"downloading the NEXT song");
        //NSURL* nextURL = self.urlList[1];
        //[self sendRequest:nextURL];
    } else {
        NSLog(@"all songs has been downloaded?");
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"! didFailWithError: %@", error);
    if ([error code] == NSURLErrorNotConnectedToInternet) {
        [NetworkManager instance].connectionAvailable = NO;
        return;
    }

    [self sendRequest:self.url];
}

static size_t network_stream_read(void* ptr, size_t size, size_t nitems, FILE* stream)
{
    // TODO: optimize CPU usage

    if (_self == nil) {
        return 0U;
    }
    
    NSURL* url = _self.url;

    if (_self.dataQueueDict[url] == nil) {
        return 0U;
    }
    
    size_t sizeNeedToRead = size * nitems;
    size_t dataQueueSize = (size_t) [_self.dataQueueDict[url] length];
    size_t sizeWasRead = dataQueueSize > sizeNeedToRead ? sizeNeedToRead : dataQueueSize;

    const char* bytes = (const char*) [_self.dataQueueDict[url] bytes];
    memcpy(ptr, bytes, sizeWasRead);
    
    NSMutableData *newData;
    if (size == sizeWasRead) {
        newData = [NSMutableData new];
    } else {
        newData = [[NSMutableData alloc] initWithBytes:&bytes[sizeWasRead]
                                                length:(dataQueueSize - sizeWasRead)];
    }
    _self.dataQueueDict[url] = newData;
    _self.readBytes += sizeWasRead;
    
    return sizeWasRead;
}

static int network_stream_close(FILE* stream)
{
    if (_self == nil) {
        return -1;
    }
    
    NSURL* url = _self.url;
    if (url == nil) {
        return -1;
    }
    
    /*if(_self->mpFile == stream && stream != NULL)
    {
        fclose(stream);
        _self->mpFile = NULL;
    }*/

    NSMutableData* data = _self.dataQueueDict[url];
    if (data != nil) {
        data.length = 0;
        [_self.dataQueueDict removeObjectForKey:url];
    }
    return 0;
}

/*static int network_stream_seek(FILE* stream, ogg_int64_t off, int whence)
{
    NSLog(@"network_stream_seek %ld %d", (long)off, whence);
    return 0;
}*/

@end

}
