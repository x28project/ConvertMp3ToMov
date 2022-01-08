#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface X28Song : NSObject

@property (strong) NSString *artist;
@property (strong) NSString *album;
@property (strong) NSString *name;
@property (strong) NSString *time;
@property CMTime duration;
@property (strong) NSString *year;
@property (strong) NSString *path;

- (id)initWithArtist:(NSString *)artist
               album:(NSString *)album
                name:(NSString *)name
                time:(NSString *)time
            duration:(CMTime)duration
                year:(NSString *)year
                path:(NSString *)path;

@end
