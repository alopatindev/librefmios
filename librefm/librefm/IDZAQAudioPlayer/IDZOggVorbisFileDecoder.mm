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
#import <Vorbis/vorbisfile.h>

#import "IDZAudioDecoder.h"
#import "IDZOggVorbisFileDecoder.h"
#import "IDZTrace.h"

#include <string.h>

extern "C" {

#define IDZ_BITS_PER_BYTE 8
#define IDZ_BYTES_TO_BITS(bytes) ((bytes) * IDZ_BITS_PER_BYTE)
#define IDZ_OGG_VORBIS_WORDSIZE 2
    
static size_t network_stream_read(void* ptr, size_t size, size_t nitems, FILE* stream);
static int network_stream_close(FILE* stream);

static ov_callbacks MY_CALLBACKS_STREAMONLY = {
    (size_t (*)(void *, size_t, size_t, void *))  network_stream_read,
    (int (*)(void *, ogg_int64_t, int))           NULL,
    (int (*)(void *))                             network_stream_close,
    (long (*)(void *))                            NULL
};

static const size_t MAX_QUEUE_SIZE = (size_t) (1024U * 1024U); // 1 MiB
static const size_t MIN_QUEUE_SIZE = (size_t) (MAX_QUEUE_SIZE / 3U);
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

@property NSURL* url;
@property NSMutableDictionary* dataQueueDict;
@property NSMutableArray* urlList;

@property size_t downloadedBytes;
@property size_t expectedContentLength;
@property NSURLConnection* connection;

@end
    

static IDZOggVorbisFileDecoder* _self = nil;

    

@implementation IDZOggVorbisFileDecoder

@synthesize dataFormat = mDataFormat;
@synthesize bufferingState = _bufferingState;
@synthesize audioPlayerDelegate = _audioPlayerDelegate;

BOOL _headerIsRead;
NSTimer* _timerSendRequest;

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

- (void)prepareToPlayURL:(NSURL*)url
{
    [self reset];
    self.url = url;

    if ([url isFileURL] == NO)
    {
        self.dataQueueDict[url] = [NSMutableData new];
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
    self.url = nil;
    self.expectedContentLength = 0U;
    self.downloadedBytes = 0U;
    _headerIsRead = NO;
    self.bufferingState = BufferingStateNothing;
}

- (void)releaseResources
{
    if (_self != nil) {
        [_timerSendRequest invalidate];
        ov_clear(&mOggVorbisFile);
        network_stream_close(NULL);
        if (self.connection != nil) {
            [self.connection cancel];
        }
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
        _headerIsRead = NO;
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
    if (_headerIsRead == NO) {
        //NSAssert(mpFile, @"fopen succeeded.");
        int iReturn = ov_open_callbacks(mpFile ? mpFile : (FILE*)1, &mOggVorbisFile, NULL, 0, MY_CALLBACKS_STREAMONLY);
        //NSAssert(iReturn >= 0, @"ov_open_callbacks succeeded.");

        vorbis_info* pInfo = ov_info(&mOggVorbisFile, -1);
        int bytesPerChannel = IDZ_OGG_VORBIS_WORDSIZE;
        FillOutASBDForLPCM(mDataFormat,
                           (Float64)pInfo->rate, // sample rate (fps)
                           (UInt32)pInfo->channels, // channels per frame
                           (UInt32)IDZ_BYTES_TO_BITS(bytesPerChannel), // valid bits per channel
                           (UInt32)IDZ_BYTES_TO_BITS(bytesPerChannel), // total bits per channel
                           false, // isFloat
                           false); // isBigEndian
        
        _headerIsRead = YES;
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
    double duration = ov_time_total(&mOggVorbisFile, -1);
    return (NSTimeInterval)duration;
}

// networking

- (void)sendRequest:(NSURL *)url
{
    self.connection = nil;

    if (_self == nil || self.dataQueueDict[url] == nil) {
        return;
    }

    if ([self.dataQueueDict[url] length] >= MAX_QUEUE_SIZE) {
        [self sendRequest:url afterDelay:DELAY_BETWEEN_REQUESTS_SECONDS];
        return;
    }
    
    size_t downloadedBytes = self.downloadedBytes;
    if (downloadedBytes > self.expectedContentLength) {
        return;
    }

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
    
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    int statusCode = (int) httpResponse.statusCode;
    NSLog(@"! didReceiveResponse statusCode=%d", statusCode);
    
    switch (statusCode) {
        case 200: // OK
            self.expectedContentLength = (size_t) [response expectedContentLength];
            break;
        case 206: // partial content
            break;
        default:
            break;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.dataQueueDict[self.url] == nil) {
        [self.connection cancel];
        self.connection = nil;
        return;
    }

    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    size_t size = (size_t) [data length];
    self.bufferingState = BufferingStateReadyToRead;
    NSLog(@"GONNA WRITE self.downloadedBytes=%zu", self.downloadedBytes + size);
    [self.dataQueueDict[self.url] appendData:data];
    self.downloadedBytes += size;
    NSLog(@"WRITTEN self.downloadedBytes=%zu", self.downloadedBytes);
    
    size_t queueLength = (size_t) [self.dataQueueDict[self.url] length];
    if (queueLength >= MAX_QUEUE_SIZE) {
        NSLog(@"cancelling connection");
        [self.connection cancel];
        self.connection = nil;
        [self sendRequest:self.url afterDelay:DELAY_BETWEEN_REQUESTS_SECONDS];
    }
    if (queueLength >= MIN_QUEUE_SIZE) {
        [self.audioPlayerDelegate playIfQueuedPlayback];
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self readHeaderInfoIfNeeded];
    }];
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
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"! didFailWithError: %@", error);
    [self sendRequest:self.url];
}

static size_t network_stream_read(void* ptr, size_t size, size_t nitems, FILE* stream)
{
    // TODO: optimize CPU usage

    if (_self == nil || _self.dataQueueDict[_self.url] == nil) {
        return 0U;
    }
    
    size_t sizeNeedToRead = size * nitems;
    size_t dataQueueSize = (size_t) [_self.dataQueueDict[_self.url] length];
    size_t sizeWasRead = dataQueueSize > sizeNeedToRead ? sizeNeedToRead : dataQueueSize;

    const char* bytes = (const char*) [_self.dataQueueDict[_self.url] bytes];
    memcpy(ptr, bytes, sizeWasRead);
    
    NSMutableData *newData;
    if (size == sizeWasRead) {
        newData = [NSMutableData new];
    } else {
        newData = [[NSMutableData alloc] initWithBytes:&bytes[sizeWasRead]
                                                length:(dataQueueSize - sizeWasRead)];
    }
    _self.dataQueueDict[_self.url] = newData;
    
    return sizeWasRead;
}

static int network_stream_close(FILE* stream)
{
    if (_self == nil || _self.url == nil) {
        return -1;
    }
    
    /*if(_self->mpFile == stream && stream != NULL)
    {
        fclose(stream);
        _self->mpFile = NULL;
    }*/

    NSMutableData* data = _self.dataQueueDict[_self.url];
    if (data != nil) {
        data.length = 0;
        [_self.dataQueueDict removeObjectForKey:_self.url];
    }
    return 0;
}

@end

}
