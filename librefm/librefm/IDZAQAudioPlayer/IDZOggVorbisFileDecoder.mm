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

/**
 * @brief IDZOggVorbisFileDecoder private internals.
 */
@interface IDZOggVorbisFileDecoder ()
{
@private
    FILE* mpFile;
    OggVorbis_File mOggVorbisFile;
}

@property NSPipe* pipe;
@property NSOperationQueue* networkQueue;
@property size_t downloadedBytes;

@end

@implementation IDZOggVorbisFileDecoder
@synthesize dataFormat = mDataFormat;
@synthesize bufferingState = _bufferingState;

FILE* _mpWFile;
BOOL _headerIsRead;

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

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError *__autoreleasing *)error
{
    if(self = [super init])
    {
        mpFile = NULL;
        _mpWFile = NULL;
        _downloadedBytes = 0;
        _headerIsRead = NO;
        self.bufferingState = BufferingStateNothing;

        if ([url isFileURL] == NO)
        {
            _pipe = [NSPipe pipe];
            mpFile = fdopen([[_pipe fileHandleForReading] fileDescriptor], "r");
            _mpWFile = fdopen([[_pipe fileHandleForWriting] fileDescriptor], "w");
            _networkQueue = [[NSOperationQueue alloc] init];
            [self sendRequest:url];
        } else {
            NSString* path = [url path];
            self.bufferingState = BufferingStateDone;
            mpFile = fopen([path UTF8String], "r");
            [self readHeaderInfoIfNeeded];
        }
    }
    return self;
}

- (void)readHeaderInfoIfNeeded
{
    if (_headerIsRead == NO) {
        NSAssert(mpFile, @"fopen succeeded.");
        int iReturn = ov_open_callbacks(mpFile, &mOggVorbisFile, NULL, 0, OV_CALLBACKS_STREAMONLY);
        NSAssert(iReturn >= 0, @"ov_open_callbacks succeeded.");

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

- (void)dealloc
{
    ov_clear(&mOggVorbisFile);
    if(mpFile)
    {
        fclose(mpFile);
        mpFile = NULL;
        if (self.pipe != nil) {
            [[self.pipe fileHandleForReading] closeFile];
        }
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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:40.0];

    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    
    size_t downloadedBytes = self.downloadedBytes;
    if (downloadedBytes > 0U) {
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%zu-", downloadedBytes];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }

    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:NO];
    [connection setDelegateQueue:self.networkQueue];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    int statusCode = (int) httpResponse.statusCode;
    NSLog(@"! didReceiveResponse statusCode=%d", statusCode);
    
    switch (statusCode) {
        case 200: // OK
            break;
        case 206: // partial content
            break;
        default:
            break;
    }

    assert(_mpWFile);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    size_t size = (size_t) [data length];
    self.bufferingState = BufferingStateReadyToRead;
    NSLog(@"GONNA WRITE _downloadedBytes=%zu", _downloadedBytes + size);
    fwrite([data bytes], size, 1, _mpWFile);
    _downloadedBytes += size;
    NSLog(@"WRITTEN _downloadedBytes=%zu", _downloadedBytes);
    
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
    if (_mpWFile != NULL) {
        fclose(_mpWFile);
        _mpWFile = NULL;
        [[self.pipe fileHandleForWriting] closeFile];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"! didFailWithError: %@", error);
    NSURL *url = [[connection currentRequest] URL];
    [self sendRequest:url];
}

@end

}
