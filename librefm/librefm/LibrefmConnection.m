//
//  LibrefmConnection.m
//  librefm
//
//  Created by sbar on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "LibrefmConnection.h"
#import "NSString+String.h"
#import "NetworkManager.h"
#import "Utils.h"

@implementation LibrefmConnection

NSMutableDictionary *_responseDict;
NSMutableSet* _requestsQueue;
NSMutableSet* _requestsNoAuthQueue;
NSString* _signupUsername;
NSString* _signupPassword;
NSString* _signupEmail;

NSString* _anonymousSessionKey;
time_t _anonymousSessionTimestamp;
BOOL _anonymousSessionParsingFailed;

- (instancetype)init
{
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password
{
    self.username = username;
    self.password = password;
    [self tryLogin];
}

- (void)logout
{
    [self reset];
    [self.delegate librefmDidLogout];
}

- (void)reset
{
    self.username = nil;
    self.password = nil;
    self.state = LibrefmConnectionStateNotLoggedIn;
    self.name = nil;
    self.mobileSessionKey = nil;
    _responseDict = [NSMutableDictionary new];
    _requestsQueue = [NSMutableSet new];
    _requestsNoAuthQueue = [NSMutableSet new];
    _anonymousSessionKey = nil;
    _anonymousSessionTimestamp = 0;
    _anonymousSessionParsingFailed = NO;
}

- (NSString*)getAppropriateSessionKey
{
    if (self.state == LibrefmConnectionStateNotLoggedIn) {
        return _anonymousSessionKey;
    } else {
        return self.mobileSessionKey;
    }
}

- (BOOL)isNeedInputLoginData
{
    return (self.username == nil || self.password == nil ||
            [self.username length] == 0 || [self.password length] == 0) ? YES : NO;
}

- (void)tryLogin
{
    if ([self isNeedInputLoginData] == YES) {
        return;
    }
    
    if ([[NetworkManager instance] isConnectionAvailable] == NO) {
        return;
    }
    
    self.state = LibrefmConnectionStateLoginStarted;

    NSString *passMD5 = [self.password md5];
    //NSString *token;
    NSString *wsToken;
    //NSString *timeStamp = [NSString currentTimeStamp];
    
    //token = [passMD5 stringByAppendingString:timeStamp];
    //token = [token md5];
    wsToken = [self.username stringByAppendingString:passMD5];
    wsToken = [wsToken md5];
    
    //NSString *streamingLoginUrl = [NSString stringWithFormat:@LIBREFM_URL_PREFIX "radio/handshake.php?username=%@&passwordmd5=%@", self.username, passMD5];
    //NSString *scrobblingLoginUrl = [NSString stringWithFormat:@"https://turtle." LIBREFM_HOSTNAME "/?hs=true&p=1.2&u=%@&t=%@&a=%@&c=ldr", self.username, timeStamp, token];
    NSString *webServicesLoginUrl = [NSString stringWithFormat:@"%@%@&username=%@&authToken=%@", API2_URL, METHOD_AUTH_GETMOBILESESSION, self.username, wsToken];
    
    //NSLog(@"%@\n%@\n%@\n", streamingLoginUrl, scrobblingLoginUrl, webServicesLoginUrl);
    
    //[self sendRequest:streamingLoginUrl];
    //[self sendRequest:scrobblingLoginUrl]; // 213.138.110.197 or 213.138.110.193
    [self sendRequest:webServicesLoginUrl];
    
    [self updateNetworkActivity];
}

- (void)signUpWithUsername:(NSString*)username password:(NSString*)password email:(NSString*)email
{
    NSString *url = SIGNUP_URL;
    
    username = [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    password = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    _signupUsername = username;
    _signupPassword = password;
    _signupEmail = email;
    
    NSString *postData = [NSString stringWithFormat:@"username=%@&email=%@&password=%@&password-repeat=%@&foo-check=remember-me&register=Sign%%20up", username, email, password, password];
    [self sendRequest:url postData:postData];
}

- (void)openSignupBrowser
{
    [Utils openBrowser:SIGNUP_URL];
}

- (void)radioTune_:(NSString*)tag
{
    NSString *url = [NSString stringWithFormat:@"%@%@", API2_URL, METHOD_RADIO_TUNE];
    tag = [tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self sendRequest:url
             postData:[NSString stringWithFormat:@"sk=%@&station=librefm://globaltags/%@", [self getAppropriateSessionKey], tag]];
}

- (void)radioGetPlaylist_
{
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_RADIO_GETPLAYLIST, [self getAppropriateSessionKey]];
    [self sendRequest:url];
}

- (void)radioTune:(NSString*)tag
{
    NSArray *req = @[NSStringFromSelector(@selector(radioTune_:)), tag];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)radioGetNextPlaylistPage
{
    NSArray *req = @[NSStringFromSelector(@selector(radioGetPlaylist_))];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)updateNowPlayingArtist_:(NSArray*)args
{
    if (self.state != LibrefmConnectionStateLoggedIn) {
        return;
    }

    NSString* artist = args[0];
    NSString* track = args[1];
    NSString* album = args[2];
    artist = [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    track = [track stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    album = [album stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_TRACK_UPDATENOWPLAYING, [self getAppropriateSessionKey]];
    
    NSString *postData;
    if ([album length] > 0) {
        postData = [NSString stringWithFormat:@"artist=%@&track=%@&album=%@", artist, track, album];
    } else {
        postData = [NSString stringWithFormat:@"artist=%@&track=%@", artist, track];
    }
    
    [self sendRequest:url postData:postData];
}

- (void)updateNowPlayingArtist:(NSString*)artist track:(NSString*)track album:(NSString*)album
{
    NSArray *req = @[NSStringFromSelector(@selector(updateNowPlayingArtist_:)), @[artist, track, album]];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)scrobbleArtist_:(NSArray*)args
{
    if (self.state != LibrefmConnectionStateLoggedIn) {
        return;
    }

    NSString* artist = args[0];
    NSString* track = args[1];
    NSString* album = args[2];
    NSString* timestamp = [NSString currentTimeStamp];
    
    artist = [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    track = [track stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    album = [album stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_TRACK_SCROBBLE, [self getAppropriateSessionKey]];
    
    NSString *postData;
    if ([album length] > 0) {
        postData = [NSString stringWithFormat:@"artist=%@&track=%@&album=%@&timestamp=%@", artist, track, album, timestamp];
    } else {
        postData = [NSString stringWithFormat:@"artist=%@&track=%@&timestamp=%@", artist, track, timestamp];
    }
    
    [self sendRequest:url postData:postData];
}

- (void)scrobbleArtist:(NSString*)artist track:(NSString*)track album:(NSString*)album
{
    NSArray *req = @[NSStringFromSelector(@selector(scrobbleArtist_:)), @[artist, track, album]];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)love_:(NSArray*)args
{
    if (self.state != LibrefmConnectionStateLoggedIn) {
        return;
    }

    NSString* artist = args[0];
    NSString* track = args[1];
    
    artist = [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    track = [track stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_TRACK_LOVE, [self getAppropriateSessionKey]];
    NSString *postData = [NSString stringWithFormat:@"artist=%@&track=%@", artist, track];
    [self sendRequest:url postData:postData];
}

- (void)loveArtist:(NSString*)artist track:(NSString*)track
{
    NSArray *req = @[NSStringFromSelector(@selector(love_:)), @[artist, track]];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)unlove_:(NSArray*)args
{
    if (self.state != LibrefmConnectionStateLoggedIn) {
        return;
    }

    NSString* artist = args[0];
    NSString* track = args[1];
    
    artist = [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    track = [track stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_TRACK_UNLOVE, [self getAppropriateSessionKey]];
    NSString *postData = [NSString stringWithFormat:@"artist=%@&track=%@", artist, track];
    [self sendRequest:url postData:postData];
}

- (void)unloveArtist:(NSString*)artist track:(NSString*)track
{
    NSArray *req = @[NSStringFromSelector(@selector(unlove_:)), @[artist, track]];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)ban_:(NSArray*)args
{
    if (self.state != LibrefmConnectionStateLoggedIn) {
        return;
    }

    NSString* artist = args[0];
    NSString* track = args[1];
    
    artist = [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    track = [track stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_TRACK_BAN, [self getAppropriateSessionKey]];
    NSString *postData = [NSString stringWithFormat:@"artist=%@&track=%@", artist, track];
    [self sendRequest:url postData:postData];
}

- (void)banArtist:(NSString*)artist track:(NSString*)track
{
    NSArray *req = @[NSStringFromSelector(@selector(ban_:)), @[artist, track]];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)unban_:(NSArray*)args
{
    if (self.state != LibrefmConnectionStateLoggedIn) {
        return;
    }

    NSString* artist = args[0];
    NSString* track = args[1];
    
    artist = [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    track = [track stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@%@&sk=%@", API2_URL, METHOD_TRACK_UNBAN, [self getAppropriateSessionKey]];
    NSString *postData = [NSString stringWithFormat:@"artist=%@&track=%@", artist, track];
    [self sendRequest:url postData:postData];
}

- (void)unbanArtist:(NSString*)artist track:(NSString*)track
{
    NSArray *req = @[NSStringFromSelector(@selector(unban_:)), @[artist, track]];
    [_requestsQueue addObject:req];
    [self processRequestsQueue];
}

- (void)getTopTags_
{
    NSString *url = [NSString stringWithFormat:@"%@%@", API2_URL, METHOD_TAG_GETTOPTAGS];
    [self sendRequest:url];
}

- (void)getTopTags
{
    NSArray *req = @[NSStringFromSelector(@selector(getTopTags_))];
    [_requestsNoAuthQueue addObject:req];
    [self processRequestsQueue];
}

- (void)getAnonymousSession_
{
    NSString *url = ANONYMOUS_SESSION_URL;
    [self sendRequest:url];
}

- (void)getAnonymousSession
{
    NSArray *req = @[NSStringFromSelector(@selector(getAnonymousSession_))];
    [_requestsNoAuthQueue addObject:req];
    [self processRequestsQueue];
}

- (BOOL)isAnonymousSessionOld
{
    time_t dt = time(NULL) - _anonymousSessionTimestamp;
    return dt > MAX_ANONYMOUS_SESSION_TIME;
}

- (void)maybeGetAnonymousSession
{
    if (_anonymousSessionParsingFailed == NO && [self isAnonymousSessionOld] == YES) {
        [self getAnonymousSession];
        _anonymousSessionTimestamp = time(NULL);
    }
}

- (void)processRequestsQueue
{
    if ([[NetworkManager instance] isConnectionAvailable] == NO) {
        return;
    }
    
    [self updateNetworkActivity];
    
    while ([_requestsNoAuthQueue count] > 0) {
        NSArray* a = [_requestsNoAuthQueue anyObject];
        [self processRequest:a fromAuthQueue:NO];
    }

    while ([_requestsQueue count] > 0) {
        NSArray* a = [_requestsQueue anyObject];

        if (self.state == LibrefmConnectionStateNotLoggedIn) {
            [self tryLogin];
            if (self.state == LibrefmConnectionStateNotLoggedIn && _anonymousSessionKey != nil) {
                [self processRequest:a fromAuthQueue:YES];
            }
            break;
        } else if (self.state == LibrefmConnectionStateLoggedIn) {
            [self processRequest:a fromAuthQueue:YES];
        } else {
            break;
        }
    }
}

- (void)processRequest:(NSArray*)a fromAuthQueue:(BOOL)auth
{
    if (auth) {
        [_requestsQueue removeObject:a];
    } else {
        [_requestsNoAuthQueue removeObject:a];
    }

    SEL sel = NSSelectorFromString(a[0]);
    switch([a count]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        case 1UL:
            [self performSelector:sel];
            break;
        case 2UL:
            [self performSelector:sel withObject:a[1]];
            break;
        case 3UL:
            [self performSelector:sel withObject:a[1] withObject:a[2]];
            break;
        default:
            break;
#pragma clang diagnostic pop
    }
}

- (void)processJSONResonse:(NSDictionary *)jsonDictionary forUrl:(NSString *)url
{
    if ([url isAPIMethod:METHOD_AUTH_GETMOBILESESSION]) {
        NSString *errorCode = jsonDictionary[@"error"];
        if (errorCode != nil || jsonDictionary == nil) {
            int errorCodeInt = [errorCode intValue];
            NSString* errorMessage;
            if (errorCodeInt == 4) {
                errorMessage = NSLocalizedString(@"Invalid username or password", nil);
                self.username = nil;
                self.password = nil;
            } else {
                errorMessage = jsonDictionary[@"message"];
            }

            self.mobileSessionKey = nil;
            [self.delegate librefmDidLogin:NO
                                  username:self.username
                                  password:self.password
                                     error:[NSError errorWithDomain:errorMessage
                                                               code:errorCodeInt
                                                           userInfo:nil]];
            self.state = LibrefmConnectionStateNotLoggedIn;
        } else {
            NSDictionary *session = jsonDictionary[@"session"];
            self.mobileSessionKey = session[@"key"];
            self.name = session[@"name"];
            [self checkLogin];
            BOOL loggedIn = self.state == LibrefmConnectionStateLoggedIn
                            ? YES : NO;
            [self.delegate librefmDidLogin:loggedIn
                                  username:self.username
                                  password:self.password
                                     error:nil];
            if (loggedIn == NO) {
                self.state = LibrefmConnectionStateNotLoggedIn;
            }
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
        if (jsonDictionary == nil) {
            [self.delegate librefmDidLoadPlaylist:nil
                                               ok:NO
                                            error:[NSError errorWithDomain:@"Failed to tune to the radio"
                                                                      code:-1
                                                                  userInfo:nil]];
        }
        [self radioGetNextPlaylistPage];
    } else if ([url isAPIMethod:METHOD_TAG_GETTOPTAGS]) {
        NSDictionary* tag = jsonDictionary[@"toptags"][@"tag"];
        if (tag != nil) {
            NSMutableDictionary *tags = [NSMutableDictionary new];
            for (NSDictionary *t in tag) {
                tags[t[@"name"]] = @([t[@"count"] integerValue]);
            }
            [self.delegate librefmDidLoadTopTags:YES tags:tags];
        } else {
            [self.delegate librefmDidLoadTopTags:NO tags:nil];
        }
    } else {
        NSLog(@"unknown response; url=%@", url);
        NSAssert(jsonDictionary != nil, @"failed to parse json");
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    NSString *url = [self currentURLStringFromConnection:connection];
    NSLog(@"connectionDidFinishLoading url='%@'", url);
    NSMutableData *data = _responseDict[url];

    if ([url hasPrefix:API2_URL] == YES) {
        NSDictionary *jsonDictionary = nil;
        if (data != nil) {
            NSError *error;
            jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
            if (jsonDictionary == nil) {
                NSString *out = [[NSString alloc] initWithData:data
                                                      encoding:NSUTF8StringEncoding];
                if ([out containsString:@"BADSESSION"]) {
                    NSLog(@"BADSESSION");
                    self.state = LibrefmConnectionStateNotLoggedIn;
                    self.mobileSessionKey = nil;
                    [self maybeGetAnonymousSession];
                    [self tryLogin];
                } else if ([out containsString:@"FAILED"]) {
                    // TODO
                }
            } else {
                [self processJSONResonse:jsonDictionary forUrl:url];
            }
        }
    } else if ([url hasPrefix:SIGNUP_URL]) {
        BOOL alreadyRegistered = _signupUsername == nil ||
                                 _signupPassword == nil ||
                                 _signupEmail == nil;
        if (alreadyRegistered == NO) {
            NSString *out = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
            if ([out containsString:@"Go! Go! Go! Check your email now"]) {
                [self.delegate librefmDidSignUp:YES
                                          error:nil
                                       username:_signupUsername
                                       password:_signupPassword
                                          email:_signupEmail];
                _signupUsername = nil;
                _signupPassword = nil;
                _signupEmail = nil;
            } else if ([out containsString:@"Sorry, that username is already registered."]) {
                [self.delegate librefmDidSignUp:NO
                                          error:[NSError errorWithDomain:@"" code:LibrefmSignupErrorAlreadyRegistered userInfo:nil]
                                       username:_signupUsername
                                       password:_signupPassword
                                          email:_signupEmail];
            } else {
                NSLog(@"%@", out);
                [self.delegate librefmDidSignUp:NO
                                          error:[NSError errorWithDomain:@"" code:LibrefmSignupErrorUnknown userInfo:nil]
                                       username:_signupUsername
                                       password:_signupPassword
                                          email:_signupEmail];
            }
        }
    } else if ([url hasPrefix:ANONYMOUS_SESSION_URL]) {
        @try {
            NSString *out = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
            _anonymousSessionKey =
                [[[[out componentsSeparatedByString:@"var radio_session = \""] objectAtIndex:1]
                        componentsSeparatedByString:@"\";"] objectAtIndex:0];
        } @catch (NSException* e) {
            NSLog(@"anonymous session parsing fail: %@", e);
            _anonymousSessionParsingFailed = YES;
        }
    } else {
        NSString *out = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
        NSLog(@"\n\ndata='''%@'''\n\n", out);
    }

    data.length = 0;
    [_responseDict removeObjectForKey:url];
    
    [self processRequestsQueue];
}

- (void)checkLogin
{
    if (self.mobileSessionKey != nil) {
        self.state = LibrefmConnectionStateLoggedIn;
        [self processRequestsQueue];
    }
}

- (void)updateNetworkActivity
{
    BOOL loading =
        [_requestsQueue count] > 0 ||
        [_responseDict count] > 0 ||
        self.state == LibrefmConnectionStateLoginStarted;

    [self.delegate librefmDidChangeNetworkActivity:loading];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    NSString *url = [self currentURLStringFromConnection:connection];
    NSLog(@"didFailWithError url='%@' error: %@", url, error);
    
    if ([url hasPrefix:API2_URL] == YES) {
        if ([url isAPIMethod:METHOD_AUTH_GETMOBILESESSION]) {
            self.mobileSessionKey = nil;
            [self.delegate librefmDidLogin:NO
                                  username:self.username
                                  password:self.password
                                     error:error];
            self.state = LibrefmConnectionStateNotLoggedIn;
        } else if ([url isAPIMethod:METHOD_RADIO_GETPLAYLIST] ||
                   [url isAPIMethod:METHOD_RADIO_TUNE]) {
            [self.delegate librefmDidLoadPlaylist:nil
                                               ok:NO
                                            error:error];
        } else if ([url isAPIMethod:METHOD_TAG_GETTOPTAGS]) {
            // TODO
        }
    }
    
    if (self.state == LibrefmConnectionStateLoginStarted) {
        self.state = LibrefmConnectionStateNotLoggedIn;
    }
    
    NSMutableData *data = _responseDict[url];
    if (data != nil) {
        data.length = 0;
        [_responseDict removeObjectForKey:url];
    }
    
    [self updateNetworkActivity];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
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
            
            const UInt8 *const data = CFDataGetBytePtr(serverCertDataRef);
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
    (void)conn;
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
}

- (void)sendRequest:(NSString *)url postData:(NSString*)data
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    //[request addValue:@"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_2 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8H7 Safari/6533.18.5" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:self];
    (void)conn;
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
}

- (NSString *)currentURLStringFromConnection:(NSURLConnection *)connection
{
    return [[[connection currentRequest] URL] absoluteString];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    NSString *url = [self currentURLStringFromConnection:connection];
    _responseDict[url] = [NSMutableData new];
    [self updateNetworkActivity];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[connection currentRequest]];
    NSString *url = [self currentURLStringFromConnection:connection];
    [_responseDict[url] appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

@end
