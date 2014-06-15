//
//  LibrefmConnection.h
//  librefm
//
//  Created by sbar on 15/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const API2_URL = @"https://libre.fm/2.0/?format=json&method=";

static NSString *const METHOD_ALBUM_ADDTAGS          = @"album.addTags";
static NSString *const METHOD_ALBUM_GETTAGS          = @"album.getTags";
static NSString *const METHOD_ALBUM_GETTOPTAGS       = @"album.getTopTags";
static NSString *const METHOD_ARTIST_ADDTAGS         = @"artist.addTags";
static NSString *const METHOD_ARTIST_GETINFO         = @"artist.getInfo";
static NSString *const METHOD_ARTIST_GETTAGS         = @"artist.getTags";
static NSString *const METHOD_ARTIST_GETTOPTRACKS    = @"artist.getTopTracks";
static NSString *const METHOD_ARTIST_GETTOPTAGS      = @"artist.getTopTags";
static NSString *const METHOD_ARTIST_GETTOPFANS      = @"artist.getTopFans";
static NSString *const METHOD_TRACK_ADDTAGS          = @"track.addTags";
static NSString *const METHOD_TRACK_REMOVETAG        = @"track.removeTag";
static NSString *const METHOD_TRACK_BAN              = @"track.ban";
static NSString *const METHOD_TRACK_LOVE             = @"track.love";
static NSString *const METHOD_TRACK_UNBAN            = @"track.unban";
static NSString *const METHOD_TRACK_UNLOVE           = @"track.unlove";
static NSString *const METHOD_TRACK_GETTAGS          = @"track.getTags";
static NSString *const METHOD_TRACK_GETTOPTAGS       = @"track.getTopTags";
static NSString *const METHOD_TRACK_GETTOPFANS       = @"track.getTopFans";
static NSString *const METHOD_USER_GETBANNEDTRACKS   = @"user.getBannedTracks";
static NSString *const METHOD_USER_GETINFO           = @"user.getInfo";
static NSString *const METHOD_USER_GETLOVEDTRACKS    = @"user.getLovedTracks";
static NSString *const METHOD_USER_GETNEIGHBOURS     = @"user.getNeighbours";
static NSString *const METHOD_USER_GETPERSONALTAGS   = @"user.getPersonalTags";
static NSString *const METHOD_USER_GETRECENTTRACKS   = @"user.getRecentTracks";
static NSString *const METHOD_USER_GETTOPARTISTS     = @"user.getTopArtists";
static NSString *const METHOD_USER_GETTOPTAGS        = @"user.getTopTags";
static NSString *const METHOD_USER_GETTOPTRACKS      = @"user.getTopTracks";
static NSString *const METHOD_TAG_GETTOPTAGS         = @"tag.getTopTags";
static NSString *const METHOD_TAG_GETTOPARTISTS      = @"tag.getTopArtists";
static NSString *const METHOD_TAG_GETTOPALBUMS       = @"tag.getTopAlbums";
static NSString *const METHOD_TAG_GETTOPTRACKS       = @"tag.getTopTracks";
static NSString *const METHOD_TAG_GETINFO            = @"tag.getInfo";
static NSString *const METHOD_AUTH_GETTOKEN          = @"auth.getToken";
static NSString *const METHOD_AUTH_GETSESSION        = @"auth.getSession";
static NSString *const METHOD_AUTH_GETMOBILESESSION  = @"auth.getMobileSession";
static NSString *const METHOD_RADIO_TUNE             = @"radio.tune";
static NSString *const METHOD_RADIO_GETPLAYLIST      = @"radio.getPlaylist";
static NSString *const METHOD_LIBRARY_REMOVESCROBBLE = @"library.removescrobble";

@interface LibrefmConnection : NSObject<NSURLConnectionDelegate>
{
    NSMutableDictionary *_responseDict;
}

- (instancetype)init;
- (BOOL)loginWithUsername:(NSString*)username password:(NSString*)password;

@end
