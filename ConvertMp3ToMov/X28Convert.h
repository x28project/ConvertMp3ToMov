#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface X28Convert : NSObject

+ (void)convertSongs:(NSArray *)songs
              toAiff:(BOOL)toAiff
             toVideo:(BOOL)toVideo
     toCombinedVideo:(BOOL)toCombinedVideo
           videoSize:(NSString *)videoSize
           videoName:(NSString *)videoName
               image:(NSURL *)urlImage
           directory:(NSURL *)directory
combinedVideoDetails:(NSTextView *)combinedVideoDetails
   progressIndicator:(NSProgressIndicator *)progressIndicator
         progressBar:(NSProgressIndicator *)progressBar
   progressTextField:(NSTextField *)progressTextField
    progressTextView:(NSTextView *)progressTextView
      progressButton:(NSButton *)progressButton
progressFinderButton:(NSButton *)progressFinderButton;

+ (void)close;

+ (void)cancel;

+ (NSArray *)getCombinedVideoDetails:(NSArray *)songs
                            textView:(NSTextView *)textView;
+ (void)cancelGetCombinedVideoDetails;

@end
