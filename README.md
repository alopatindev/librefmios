Libre.fm for iOS
================

This is the [Libre.fm](https://libre.fm) iOS [client](https://www.facebook.com/librefmios) source code.

### Sad story
I used to develop this app during learning some iOS/Objective-C programming.
Then there was a time period while Libre.fm was experiencing [some server side issues](https://lists.gnu.org/archive/html/librefm-discuss/2014-12/msg00001.html),
so I didn't publish the app until the issues were resolved.
Since everything got fixed I've published the app but my iOS Developer Program account was about to expire.
So I'm no longer interested in developing this app.
Sorry for inconvenience. Use this code whatever way you like.

![Player](screenshots/player.png)
![Tags](screenshots/tags.png)

### Used stuff
https://github.com/iosdevzone/IDZAQAudioPlayer
https://github.com/schneiderandre/popping
http://www.flaticon.com/packs/ios7-set-lined-1

### Release CFLAGS
-I../../librefm/LibreFM/librefm/popping -DNS_BLOCK_ASSERTIONS=1 -DNSLog(...)=

### License
This software is licensed under the terms of BSD-2 (read COPYING.txt for details).
