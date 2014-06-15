//
//  LibrefmConnection.m
//  librefm
//
//  Created by sbar on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "LibrefmConnection.h"
#import "NSString+String.h"

@implementation LibrefmConnection

- (instancetype)init
{
    if (self = [super init]) {
        _responseDict = [NSMutableDictionary new];
    }
    return self;
}

- (BOOL)loginWithUsername:(NSString*)username password:(NSString*)password
{
    BOOL result = NO;
    
    NSString* passMD5 = [password md5];
    NSString* token;
    NSString* wsToken;
    NSString* timeStamp = [NSString currentTimeStamp];
    
    token = [passMD5 stringByAppendingString:timeStamp];
    token = [token md5];
    wsToken = [username stringByAppendingString:passMD5];
    wsToken = [wsToken md5];
    
    NSString* streamingLoginUrl = [NSString stringWithFormat:@"https://libre.fm/radio/handshake.php?username=%@&passwordmd5=%@", username, passMD5];
    NSString* scrobblingLoginUrl = [NSString stringWithFormat:@"https://turtle.libre.fm/?hs=true&p=1.2&u=%@&t=%@&a=%@&c=ldr", username, timeStamp, token];
    NSString* webServicesLoginUrl = [NSString stringWithFormat:@"https://libre.fm/2.0/?method=auth.getmobilesession&username=%@&authToken=%@", username, wsToken];
    
    NSLog(@"%@\n%@\n%@\n", streamingLoginUrl, scrobblingLoginUrl, webServicesLoginUrl);
    
    [self sendRequest:streamingLoginUrl];
    //[self sendRequest:scrobblingLoginUrl];
    [self sendRequest:webServicesLoginUrl];
    
    return result;
}

- (void)sendRequest:(NSString*)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:self];
}

- (NSString*)currentURLStringFromConnection:(NSURLConnection*)connection
{
    return [[[connection currentRequest] URL] absoluteString];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSString* url = [self currentURLStringFromConnection:connection];
    _responseDict[url] = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    NSString* url = [self currentURLStringFromConnection:connection];
    [_responseDict[url] appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString* url = [self currentURLStringFromConnection:connection];
    NSLog(@"connectionDidFinishLoading url='%@'", url);
    NSMutableData* data = _responseDict[url];
    
    if (data != nil) {
        NSString* out = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
        
        NSLog(@"\n\ndata='''%@'''\n\n", out);
    
        data.length = 0;
        [_responseDict removeObjectForKey:url];
    }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    NSString* url = [self currentURLStringFromConnection:connection];
    NSLog(@"didFailWithError url='%@' error: %@", url, error);
    NSMutableData* data = _responseDict[url];
    if (data != nil) {
        data.length = 0;
        [_responseDict removeObjectForKey:url];
    }
}

@end
