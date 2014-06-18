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
        self.state = LibrefmConnectionStateNotLoggedIn;
    }
    return self;
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password
{
    self.username = username;
    self.password = password;
    [self tryLogin];
}

- (BOOL)isNeedInputLoginData {
    return (self.username == nil || self.password == nil) ? YES : NO;
}

- (void)tryLogin
{
    if ([self isNeedInputLoginData] == YES) {
        return;
    }

    NSString *passMD5 = [self.password md5];
    NSString *token;
    NSString *wsToken;
    NSString *timeStamp = [NSString currentTimeStamp];
    
    token = [passMD5 stringByAppendingString:timeStamp];
    token = [token md5];
    wsToken = [self.username stringByAppendingString:passMD5];
    wsToken = [wsToken md5];
    
    NSString *streamingLoginUrl = [NSString stringWithFormat:@"https://libre.fm/radio/handshake.php?username=%@&passwordmd5=%@", self.username, passMD5];
    NSString *scrobblingLoginUrl = [NSString stringWithFormat:@"https://turtle.libre.fm/?hs=true&p=1.2&u=%@&t=%@&a=%@&c=ldr", self.username, timeStamp, token];
    NSString *webServicesLoginUrl = [NSString stringWithFormat:@"%@%@&username=%@&authToken=%@", API2_URL, METHOD_AUTH_GETMOBILESESSION, self.username, wsToken];
    
    //NSLog(@"%@\n%@\n%@\n", streamingLoginUrl, scrobblingLoginUrl, webServicesLoginUrl);
    
    //[self sendRequest:streamingLoginUrl];
    //[self sendRequest:scrobblingLoginUrl]; // 213.138.110.197 or 213.138.110.193
    [self sendRequest:webServicesLoginUrl];
}

- (void)radioTune:(NSString*)tag
{
    NSString *url = [NSString stringWithFormat:@"%@%@", API2_URL, METHOD_RADIO_TUNE];
    [self sendRequest:url
             postData:[NSString stringWithFormat:@"sk=%@&station=librefm://globaltags/%@", self.mobileSessionKey, tag]];
}

- (void)radioGetPlaylist
{
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_RADIO_GETPLAYLIST, self.mobileSessionKey];
    [self sendRequest:url];
}

- (void)processJSON:(NSDictionary *)jsonDictionary forUrl:(NSString *)url
{
    if ([url isAPIMethod:METHOD_AUTH_GETMOBILESESSION]) {
        NSString *errorCode = jsonDictionary[@"error"];
        if (errorCode != nil) {
            NSString* errorMessage = jsonDictionary[@"message"];
            self.mobileSessionKey = nil;
            [self.delegate librefmDidLogin:NO
                                     error:[NSError errorWithDomain:errorMessage
                                                               code:[errorCode intValue]
                                                           userInfo:nil]];
        } else {
            NSDictionary *session = jsonDictionary[@"session"];
            self.mobileSessionKey = session[@"key"];
            self.name = session[@"name"];
            [self checkLogin];
            [self.delegate librefmDidLogin:(self.state == LibrefmConnectionStateLoggedIn
                                                       ? YES : NO)
                                     error:nil];
        }
    } else if ([url isAPIMethod:METHOD_RADIO_GETPLAYLIST]) {
        NSDictionary* playlist = jsonDictionary[@"playlist"];
        if (playlist != nil) {
            [self.delegate librefmDidLoadPlaylist:playlist ok:YES error:nil];
        } else {
            [self.delegate librefmDidLoadPlaylist:playlist
                                               ok:NO
                                            error:[NSError errorWithDomain:@"Failed to load playlist"
                                                                      code:-1
                                                                  userInfo:nil]];
        }
    } else if ([url isAPIMethod:METHOD_RADIO_TUNE]) {
        // TODO: check for error?
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
                self.state = LibrefmConnectionStateNotLoggedIn;
                self.mobileSessionKey = nil;
            } else if ([out containsString:@"FAILED"]) {
                // TODO
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

- (void)checkLogin
{
    if (self.mobileSessionKey != nil)
        self.state = LibrefmConnectionStateLoggedIn;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSString *url = [self currentURLStringFromConnection:connection];
    NSLog(@"didFailWithError url='%@' error: %@", url, error);
    
    if ([url hasPrefix:API2_URL] == YES) {
        if ([url isAPIMethod:METHOD_AUTH_GETMOBILESESSION]) {
            self.mobileSessionKey = nil;
            [self.delegate librefmDidLogin:NO
                                     error:error];
        } else if ([url isAPIMethod:METHOD_RADIO_GETPLAYLIST] ||
                   [url isAPIMethod:METHOD_RADIO_TUNE]) {
            [self.delegate librefmDidLoadPlaylist:nil
                                               ok:NO
                                            error:error];
        }
    }
    
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
    if ([self shouldTrustSelfSignedCertificateInAuthenticationChallenge:challenge]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
             forAuthenticationChallenge:challenge];
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

- (BOOL)shouldTrustSelfSignedCertificateInAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    BOOL result = NO;
    
    CFArrayRef localCertArrayRef = nil;
    SecCertificateRef localCert = nil;
    CFDataRef localCertDataRef = nil;
    CFDataRef serverCertDataRef = nil;
    //SecKeyRef serverPubKeyRef = nil;
    
    do {
        NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
        
        // load up the bundled certificate
        NSString *localCertPath = [[NSBundle mainBundle] pathForResource:protectionSpace.host ofType:@"der"];
        if (localCertPath == nil)
            break;
        
        OSStatus status;
        
        NSData *localServerCertData = [[NSData alloc] initWithContentsOfFile:localCertPath];
        localCertDataRef = (__bridge_retained CFDataRef)localServerCertData;
        if (localCertDataRef == nil)
            break;

        localCert = SecCertificateCreateWithData(NULL, localCertDataRef);
        if (localCert == nil)
            break;
        
        // establish a chain of trust anchored on our bundled certificate
        localCertArrayRef = CFArrayCreate(NULL, (void *)&localCert, 1, NULL);
        if (localCertArrayRef == nil)
            break;

        SecTrustRef serverTrust = protectionSpace.serverTrust;
        status = SecTrustSetAnchorCertificates(serverTrust, localCertArrayRef);
        if (status != errSecSuccess)
            break;
        
        // verify that trust
        SecTrustResultType trustResult;
        status = SecTrustEvaluate(serverTrust, &trustResult);
        if (status != errSecSuccess)
            break;
        
        if (trustResult == kSecTrustResultRecoverableTrustFailure) {
            // TODO: check the IP address

            // comparing server certificate with the local copy
            SecCertificateRef serverCertRef = SecTrustGetCertificateAtIndex(serverTrust, 0);
            if (serverCertRef == nil)
                break;
            
            serverCertDataRef = SecCertificateCopyData(serverCertRef);
            if (serverCertDataRef == nil)
                break;
            
            const UInt8* const data = CFDataGetBytePtr(serverCertDataRef);
            const CFIndex size = CFDataGetLength(serverCertDataRef);
            NSData* serverCertData = [NSData dataWithBytes:data length:(NSUInteger)size];
            if (serverCertData == nil)
                break;
            
            BOOL equal = [serverCertData isEqualToData:localServerCertData];
            result = equal;
            
            //serverPubKeyRef = SecTrustCopyPublicKey(serverTrust);
        } else {
            result = trustResult == kSecTrustResultUnspecified ||
                     trustResult == kSecTrustResultProceed;
        }
    } while (0);
    
    if (localCertArrayRef != nil)
        CFRelease(localCertArrayRef);
    
    if (localCert != nil)
        CFRelease(localCert);
    
    if (localCertDataRef != nil)
        CFRelease(localCertDataRef);
    
    if (serverCertDataRef != nil)
        CFRelease(serverCertDataRef);
    
    //if (serverPubKeyRef != nil)
    //    CFRelease(serverPubKeyRef);
    
    return result;
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSString *url = [self currentURLStringFromConnection:connection];
    _responseDict[url] = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
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
