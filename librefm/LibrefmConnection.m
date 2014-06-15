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
        _loggedIn = NO;
    }
    return self;
}

- (BOOL)loginWithUsername:(NSString *)username password:(NSString *)password
{
    BOOL result = NO;
    
    NSString *passMD5 = [password md5];
    NSString *token;
    NSString *wsToken;
    NSString *timeStamp = [NSString currentTimeStamp];
    
    token = [passMD5 stringByAppendingString:timeStamp];
    token = [token md5];
    wsToken = [username stringByAppendingString:passMD5];
    wsToken = [wsToken md5];
    
    NSString *streamingLoginUrl = [NSString stringWithFormat:@"https://libre.fm/radio/handshake.php?username=%@&passwordmd5=%@", username, passMD5];
    NSString *scrobblingLoginUrl = [NSString stringWithFormat:@"https://turtle.libre.fm/?hs=true&p=1.2&u=%@&t=%@&a=%@&c=ldr", username, timeStamp, token];
    NSString *webServicesLoginUrl = [NSString stringWithFormat:@"%@%@&username=%@&authToken=%@", API2_URL, METHOD_AUTH_GETMOBILESESSION, username, wsToken];
    
    //NSLog(@"%@\n%@\n%@\n", streamingLoginUrl, scrobblingLoginUrl, webServicesLoginUrl);
    
    //[self sendRequest:streamingLoginUrl];
    //[self sendRequest:scrobblingLoginUrl];
    [self sendRequest:webServicesLoginUrl];
    
    return result;
}

- (void)radioTune:(NSString*)tag
{
    NSString *url = [NSString stringWithFormat:@"%@%@", API2_URL, METHOD_RADIO_TUNE];
    [self sendRequest:url postData:[NSString stringWithFormat:@"sk=%@&station=librefm://globaltags/%@", self.mobileSessionKey, tag]];
}

- (void)radioGetPlaylist
{
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_RADIO_GETPLAYLIST, self.mobileSessionKey];
    [self sendRequest:url];
}

- (void)processJSON:(NSDictionary *)jsonDictionary forUrl:(NSString *)url
{
    if (_loggedIn == NO && [url isAPIMethod:METHOD_AUTH_GETMOBILESESSION]) {
        if (jsonDictionary[@"error"] != nil) {
            NSLog(@"error: %@", jsonDictionary[@"message"]);
        } else {
            NSDictionary *session = jsonDictionary[@"session"];
            self.mobileSessionKey = session[@"key"];
            self.username = session[@"name"];
        }
        [self checkLogin];
        [self radioTune:@"rock"];
    } else if (_loggedIn == YES && [url isAPIMethod:METHOD_RADIO_GETPLAYLIST]) {
        NSDictionary *playlist = jsonDictionary[@"playlist"];
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
        
    } else if (_loggedIn == YES && [url isAPIMethod:METHOD_RADIO_TUNE]) {
        [self radioGetPlaylist];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *url = [self currentURLStringFromConnection:connection];
    NSLog(@"connectionDidFinishLoading url='%@'", url);
    NSMutableData *data = _responseDict[url];
    assert(data != nil);

    if ([url hasPrefix:API2_URL] == YES) {
        NSError *error;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&error];
        if (jsonDictionary == nil) {
            NSString *out = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
            if ([out containsString:@"BADSESSION"]) {
                NSLog(@"BADSESSION");
                _loggedIn = NO;
            }
        } else {
            assert(jsonDictionary != nil);
        }
        [self processJSON:jsonDictionary forUrl:url];
    } else {
        NSString *out = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
        NSLog(@"\n\ndata='''%@'''\n\n", out);
    }

    data.length = 0;
    [_responseDict removeObjectForKey:url];
}

- (void) checkLogin
{
    _loggedIn = self.mobileSessionKey != nil
              ? YES : NO;  // TODO
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    NSString *url = [self currentURLStringFromConnection:connection];
    NSLog(@"didFailWithError url='%@' error: %@", url, error);
    NSMutableData* data = _responseDict[url];
    if (data != nil) {
        data.length = 0;
        [_responseDict removeObjectForKey:url];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([self shouldTrustProtectionSpace:challenge.protectionSpace]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
             forAuthenticationChallenge:challenge];
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

- (BOOL)shouldTrustProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    // load up the bundled certificate
    NSString *certPath = [[NSBundle mainBundle] pathForResource:protectionSpace.host ofType:@"der"];
    
    if (certPath == nil)
        return NO;

    OSStatus status;
    NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
    CFDataRef certDataRef = (__bridge_retained CFDataRef)certData;
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, certDataRef);

    // establish a chain of trust anchored on our bundled certificate
    CFArrayRef certArrayRef = CFArrayCreate(NULL, (void *)&cert, 1, NULL);
    SecTrustRef serverTrust = protectionSpace.serverTrust;
    status = SecTrustSetAnchorCertificates(serverTrust, certArrayRef);

    // verify that trust
    SecTrustResultType trustResult;
    status = SecTrustEvaluate(serverTrust, &trustResult);

    CFRelease(certArrayRef);
    CFRelease(cert);
    CFRelease(certDataRef);
    
    return trustResult == kSecTrustResultConfirm ||
           trustResult == kSecTrustResultUnspecified ||
           trustResult == kSecTrustResultProceed/* ||
           trustResult == kSecTrustResultRecoverableTrustFailure*/;  // FIXME
}

- (void)sendRequest:(NSString *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:self];
}

- (void)sendRequest:(NSString *)url postData:(NSString*)data
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:self];
}

- (NSString *)currentURLStringFromConnection:(NSURLConnection *)connection
{
    return [[[connection currentRequest] URL] absoluteString];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSString *url = [self currentURLStringFromConnection:connection];
    _responseDict[url] = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    NSString *url = [self currentURLStringFromConnection:connection];
    [_responseDict[url] appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

@end
