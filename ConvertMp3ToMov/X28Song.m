#import "X28Song.h"

@implementation X28Song

- (id)initWithArtist:(NSString *)artist
               album:(NSString *)album
                name:(NSString *)name
                time:(NSString *)time
            duration:(CMTime)duration
                year:(NSString *)year
                path:(NSString *)path {
    if ((self = [super init])) {
        self.artist = artist;
        self.album = album;
        self.name = name;
        self.time = time;
        self.duration = duration;
        self.year = year;
        self.path = path;
    }
    return self;
}

@end
