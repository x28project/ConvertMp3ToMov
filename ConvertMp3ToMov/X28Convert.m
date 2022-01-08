#import "X28Convert.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudio.h>
#import "X28Song.h"

@implementation X28Convert

static NSArray *_songs = nil;
static BOOL _toAiff = NO;
static BOOL _toVideo = NO;
static BOOL _toCombinedVideo = NO;
static NSString *_videoSize = nil;
static NSString *_videoName = nil;
static NSURL *_urlImage = nil;
static NSURL *_directory = nil;
static NSTextView *_combinedVideoDetails = nil;
static NSProgressIndicator *_progressIndicator = nil;
static NSProgressIndicator *_progressBar = nil;
static NSTextField *_progressTextField = nil;
static NSTextView *_progressTextView = nil;
static NSButton *_progressButton = nil;
static NSButton *_progressFinderButton = nil;
static int _count = 0;
static CVPixelBufferRef pixelBufferRef = nil;
static AVAssetExportSession* exportSession = nil;
static NSTimer *progressBarTimer = nil;

static BOOL _cancel = NO;
static BOOL _cancelGetCombinedVideoDetails = NO;

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
progressFinderButton:(NSButton *)progressFinderButton
{
    _songs = songs;
    _toAiff = toAiff;
    _toVideo = toVideo;
    _toCombinedVideo = toCombinedVideo;
    _videoSize = videoSize;
    _videoName = videoName;
    _urlImage = urlImage;
    _directory = directory;
    _combinedVideoDetails = combinedVideoDetails;
    _progressIndicator = progressIndicator;
    _progressBar = progressBar;
    _progressTextField = progressTextField;
    _progressTextView = progressTextView;
    _progressButton = progressButton;
    _progressFinderButton = progressFinderButton;
    
    if (_progressBar.usesThreadedAnimation == NO) {
        [_progressBar setUsesThreadedAnimation:YES];
    }
    [_progressBar setIndeterminate:YES];
    [_progressBar stopAnimation:nil];
    [_progressBar startAnimation:nil];
    [_progressBar setHidden:NO];
    
    _cancel = NO;
    
//    _combinedVideoDetails.string = @"";
    
    _videoName = [_videoName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
 
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Picture: %@\n", (_urlImage) ? [_urlImage path] : @""]];
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Each Song to AIFF file: %@\n", (_toAiff) ? @"Yes" : @"No"]];
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Each Song to MOV file: %@\n", (_toVideo) ? @"Yes" : @"No"]];
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"All Songs to Full Album MOV file: %@\n", (_toCombinedVideo) ? @"Yes" : @"No"]];
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Video Size: %@\n", (_videoSize) ? _videoSize : @""]];
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Video Name: %@\n", (_videoName) ? _videoName : @""]];
    
    _videoSize = [X28Convert getPictureTypeExportPreset:_videoSize];
    
    if (_toAiff == NO
    &&  _toVideo == NO
    &&  _toCombinedVideo == NO) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor redColor];
        _progressTextField.stringValue = @"Please check at least one of the Convert options.";
        _progressButton.title = @"OK";
        return;
    }
    
    if ((_toVideo == YES
    ||   _toCombinedVideo == YES)
    &&  _urlImage == nil) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor redColor];
        _progressTextField.stringValue = @"Please add a Picture for video conversion.";
        _progressButton.title = @"OK";
        return;
    }
    
    if ((_toVideo == YES
    ||   _toCombinedVideo == YES)
    &&  _videoSize == nil) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor redColor];
        _progressTextField.stringValue = @"Please select a Video Size for video conversion.";
        _progressButton.title = @"OK";
        return;
    }
    
    if (_toCombinedVideo == YES
    &&  (_videoName == nil
    ||   _videoName.length == 0)) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor redColor];
        _progressTextField.stringValue = @"Please eneter a Video Name for Full Album video conversion.";
        _progressButton.title = @"OK";
        return;
    }
    
    if (_toAiff) {
        [self convertToAiffAtIndex:0];
    }
    else if (_toVideo) {
        [self convertToVideoAtIndex:0];
    }
    else if (_toCombinedVideo) {
        [self convertToCombinedVideo];
    }
}

+ (void)convertToAiffAtIndex:(NSInteger)index
{
    NSError *error;
    
    if (_cancel) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor orangeColor];
        _progressTextField.stringValue = @"Conversion cancelled.";
        _progressButton.title = @"Close";
        [_progressButton setEnabled:YES];
        return;
    }
    
    if (index >= _songs.count) {
        if (_toVideo) {
            [self convertToVideoAtIndex:0];
        }
        else if (_toCombinedVideo) {
            [self convertToCombinedVideo];
        }
        else {
            [_progressIndicator stopAnimation:nil];
            [_progressBar setIndeterminate:NO];
            [_progressBar stopAnimation:nil];
            [_progressBar setHidden:YES];
            _progressTextField.textColor = [NSColor greenColor];
            _progressTextField.stringValue = @"Conversion complete.";
            _progressButton.title = @"Done";
            [_progressFinderButton setHidden:NO];
        }
        return;
    }
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    AVURLAsset *urlAsset = [[AVURLAsset alloc]
                            initWithURL:[NSURL fileURLWithPath:((X28Song *)_songs[index]).path]
                                options:options];
    
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Converting to AIFF: %@\n", [urlAsset.URL path]]];
    
    NSString *path = [urlAsset.URL lastPathComponent];
    path = [NSString stringWithFormat:@"%@%@", [path stringByDeletingPathExtension], @".aiff"];
    NSURL *urlOut = [_directory URLByAppendingPathComponent:path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[urlOut path]]) {
        [[NSFileManager defaultManager] removeItemAtURL: urlOut error: &error];
    }
    
    AVAssetReader *assetReaderAudio = [AVAssetReader assetReaderWithAsset:urlAsset error:&error];
    if (!assetReaderAudio) {
        return;
    }
    
    AVAssetTrack *assetTrackAudio = [[assetReaderAudio.asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    NSDictionary *readerOutputSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
     nil];
    AVAssetReaderOutput *assetReaderOutputAudio = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetTrackAudio
                                                                                        outputSettings:readerOutputSettings];
    if (![assetReaderAudio canAddOutput:assetReaderOutputAudio]) {
        return;
    }
    [assetReaderAudio addOutput:assetReaderOutputAudio];
    
    AVAssetWriter *assetWriterAudio = [[AVAssetWriter alloc] initWithURL:urlOut
                                                           fileType:AVFileTypeAIFF
                                                              error:&error];
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *writerOutputSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [ NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
     [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
     [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
     [ NSData dataWithBytes: &channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
     //[ NSNumber numberWithInt: 192000 ], AVEncoderBitRateKey,
     [ NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
     [ NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
     [ NSNumber numberWithBool:YES], AVLinearPCMIsBigEndianKey,
     [ NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
     nil];
    
    AVAssetWriterInput *assetWriterInputAudio = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                              outputSettings:writerOutputSettings];
    if (![assetWriterAudio canAddInput:assetWriterInputAudio]) {
        return;
    }
    [assetWriterAudio addInput:assetWriterInputAudio];
    assetWriterInputAudio.expectsMediaDataInRealTime = NO;
    
    [assetWriterAudio startWriting];
    [assetReaderAudio startReading];
    [assetWriterAudio startSessionAtSourceTime:CMTimeMake(0, assetTrackAudio.naturalTimeScale)];
    
    _count = 0;
    dispatch_queue_t writerQueue = dispatch_queue_create("writerQueue", NULL);
    [assetWriterInputAudio requestMediaDataWhenReadyOnQueue:writerQueue usingBlock:^{
        while (assetWriterInputAudio.readyForMoreMediaData) {
            CMSampleBufferRef sampleBufferRef = [assetReaderOutputAudio copyNextSampleBuffer];
            if (sampleBufferRef)
            {
                [assetWriterInputAudio appendSampleBuffer: sampleBufferRef];
                
                CFRelease(sampleBufferRef);
                sampleBufferRef = nil;
            }
            else {
                [assetWriterInputAudio markAsFinished];
                [assetWriterAudio finishWritingWithCompletionHandler:^(){}];
                [assetReaderAudio cancelReading];
                
                [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"New AIFF: %@\n", [urlOut path]]];
                
                [self convertToAiffAtIndex:(index + 1)];
            }
        }
    }];
}

+ (void)convertToVideoAtIndex:(NSInteger)index
{
    NSError *error;
    
    if (_cancel) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor orangeColor];
        _progressTextField.stringValue = @"Conversion cancelled.";
        _progressButton.title = @"Close";
        [_progressButton setEnabled:YES];
        return;
    }
    
    if (index >= _songs.count) {
        if (_toCombinedVideo) {
            [self convertToCombinedVideo];
        }
        else {
            [_progressIndicator stopAnimation:nil];
            [_progressBar setIndeterminate:NO];
            [_progressBar stopAnimation:nil];
            [_progressBar setHidden:YES];
            _progressTextField.textColor = [NSColor greenColor];
            _progressTextField.stringValue = @"Conversion complete.";
            _progressButton.title = @"Done";
            [_progressFinderButton setHidden:NO];
        }
        return;
    }
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    AVURLAsset *urlAsset = [[AVURLAsset alloc]
                            initWithURL:[NSURL fileURLWithPath:((X28Song *)_songs[index]).path]
                                options:options];
    
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Converting to MOV: %@\n", [urlAsset.URL path]]];
    
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, [urlAsset duration]);
    CMTime time = CMTimeAdd(kCMTimeZero, timeRange.duration);
    
    NSURL *urlVideo = [_directory URLByAppendingPathComponent:@"combined.mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[urlVideo path]]) {
        [[NSFileManager defaultManager] removeItemAtURL: urlVideo error: &error];
        if (error) {
            //_progressTextView.stringValue = @"File exists and could not be deleted.";
            return;
        }
    }
    
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:urlVideo
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:_urlImage];
    if (image.representations && image.representations.count > 0) {
        long lastSquare = 0, curSquare;
        NSImageRep *imageRep;
        for (imageRep in image.representations) {
            curSquare = imageRep.pixelsWide * imageRep.pixelsHigh;
            if (curSquare > lastSquare) {
                image.size = NSMakeSize(imageRep.pixelsWide, imageRep.pixelsHigh);
                lastSquare = curSquare;
            }
        }
    }
    image = [X28Convert resizeImage:image toSize:[X28Convert getPictureTypeSize:_videoSize]];
    NSRect rect = NSMakeRect(0, 0, image.size.width, image.size.height);
    CGImageRef imageRef = [image CGImageForProposedRect:&rect context:NULL hints:nil];
    
    /*NSMutableDictionary *compressionSettings = NULL;
     compressionSettings = [NSMutableDictionary dictionary];
     [compressionSettings setObject:AVVideoColorPrimaries_ITU_R_709_2
     forKey:AVVideoColorPrimariesKey];
     [compressionSettings setObject:AVVideoTransferFunction_ITU_R_709_2
     forKey:AVVideoTransferFunctionKey];
     [compressionSettings setObject:AVVideoYCbCrMatrix_ITU_R_709_2
     forKey:AVVideoYCbCrMatrixKey];*/
    
    
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:rect.size.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:rect.size.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:1960000], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:24],AVVideoMaxKeyFrameIntervalKey,
                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   nil];
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    AVVideoCodecH264, AVVideoCodecKey,
                                    //AVVideoScalingModeResize, AVVideoScalingModeKey,
                                    codecSettings,AVVideoCompressionPropertiesKey,
                                    [NSNumber numberWithInt:rect.size.width], AVVideoWidthKey,
                                    [NSNumber numberWithInt:rect.size.height], AVVideoHeightKey,
                                    //compressionSettings, AVVideoColorPropertiesKey,
                                    nil];
    AVAssetWriterInput* assetWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:outputSettings];
    if (![assetWriter canAddInput:assetWriterInput]) {
        return;
    }
    
    NSMutableDictionary *sourcePixelBufferAttributes = [[NSMutableDictionary alloc] init];
    [sourcePixelBufferAttributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [sourcePixelBufferAttributes setObject:[NSNumber numberWithUnsignedInt:rect.size.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [sourcePixelBufferAttributes setObject:[NSNumber numberWithUnsignedInt:rect.size.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    AVAssetWriterInputPixelBufferAdaptor *inputPixelBufferAdaptor =
    [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterInput
                                                                     sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    [assetWriter addInput:assetWriterInput];
    assetWriterInput.expectsMediaDataInRealTime = YES;
    
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    float audioDurationSeconds = CMTimeGetSeconds(urlAsset.duration);
    
    pixelBufferRef = NULL;
    pixelBufferRef = [self pixelBufferFromCGImage:imageRef];
    
    _count = 0;
    [_progressBar setIndeterminate:NO];
    [_progressBar stopAnimation:nil];
    [_progressBar setDoubleValue:0];
    _progressBar.minValue = 0;
    _progressBar.maxValue = audioDurationSeconds * 15;
    dispatch_queue_t writerQueue = dispatch_queue_create("writerQueue", NULL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:writerQueue usingBlock:^{
        while (assetWriterInput.readyForMoreMediaData) {
            if (_count < urlAsset.duration.value
            &&  _count < (audioDurationSeconds * 15))
            {
                [_progressBar setDoubleValue:_count];
                [inputPixelBufferAdaptor appendPixelBuffer:pixelBufferRef withPresentationTime:CMTimeMake(_count, 15)];
                _count++;
            }
            else {
                [assetWriterInput markAsFinished];
                [assetWriter endSessionAtSourceTime:time];
                [assetWriter finishWritingWithCompletionHandler:^(){}];
                
                [_progressBar setIndeterminate:YES];
                [_progressBar startAnimation:nil];
                
                NSCharacterSet *charactersToRemove = [NSCharacterSet characterSetWithCharactersInString:@":."];
                NSCharacterSet *characterSlashToReplace = [NSCharacterSet characterSetWithCharactersInString:@"/"];
                NSString *artist = nil;
                NSString *title = nil;
                for (AVMetadataItem *item in [urlAsset commonMetadata]) {
                    if ([[item commonKey] isEqualToString:AVMetadataCommonKeyArtist])
                    {
                        artist = item.stringValue;
                        if (artist != nil) {
                            artist = [[artist componentsSeparatedByCharactersInSet: charactersToRemove] componentsJoinedByString: @""];
                            artist = [[artist componentsSeparatedByCharactersInSet: characterSlashToReplace] componentsJoinedByString: @":"];
                        }
                    }
                    else if ([[item commonKey] isEqualToString:AVMetadataCommonKeyTitle])
                    {
                        title = item.stringValue;
                        if (title != nil) {
                            title = [[title componentsSeparatedByCharactersInSet: charactersToRemove] componentsJoinedByString: @""];
                            title = [[title componentsSeparatedByCharactersInSet: characterSlashToReplace] componentsJoinedByString: @":"];
                        }
                    }
                    else if (artist != nil
                    &&       title != nil) {
                        break;
                    }
                }
                
                NSString *videoName = [NSString stringWithFormat:@"%@%@%@%@",
                                       artist,
                                       (artist != nil && title != nil) ? @" - " : @"",
                                       title,
                                       @".mov"];
                
                [self combineAudio:(NSURL *)urlAsset.URL
                         withVideo:(NSURL *)urlVideo
                         videoName:videoName
                        completion:^{
                            [self convertToVideoAtIndex:(index + 1)];
                        }];

            }
        }
    }];
}

+ (void)convertToCombinedVideo
{
    NSError *error;
    
    if (_cancel) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor orangeColor];
        _progressTextField.stringValue = @"Conversion cancelled.";
        _progressButton.title = @"Close";
        [_progressButton setEnabled:YES];
        return;
    }
    
    [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Combining Tracks...\n"]];
    
    NSArray *compositionAndTime = [X28Convert getCombinedVideoDetails:_songs
                                                             textView:_combinedVideoDetails];
    AVMutableComposition *composition = compositionAndTime[0];
    NSValue *timeValue = compositionAndTime[1];
    CMTime time;
    [timeValue getValue:&time];
    
    NSURL *urlAudio = [_directory URLByAppendingPathComponent:@"combined.m4a"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[urlAudio path]]) {
        [[NSFileManager defaultManager] removeItemAtURL: urlAudio error: &error];
    }
    
    exportSession = [AVAssetExportSession
                     exportSessionWithAsset:composition
                     presetName:AVAssetExportPresetAppleM4A];
    exportSession.outputURL = urlAudio;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
        }
        else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Failed to create Combined M4A: %@\n", [urlAudio path]]];
            return;
        }
        
        NSError *error;
        
        NSURL *urlVideo = [_directory URLByAppendingPathComponent:@"combined.mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[urlVideo path]]) {
            [[NSFileManager defaultManager] removeItemAtURL: urlVideo error: &error];
        }
        
        AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:urlVideo
                                                               fileType:AVFileTypeQuickTimeMovie
                                                                  error:&error];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:_urlImage];
        if (image.representations && image.representations.count > 0) {
            long lastSquare = 0, curSquare;
            NSImageRep *imageRep;
            for (imageRep in image.representations) {
                curSquare = imageRep.pixelsWide * imageRep.pixelsHigh;
                if (curSquare > lastSquare) {
                    image.size = NSMakeSize(imageRep.pixelsWide, imageRep.pixelsHigh);
                    lastSquare = curSquare;
                }
            }
        }
        
        NSRect rect = NSMakeRect(0, 0, image.size.width, image.size.height);
        CGImageRef imageRef = [image CGImageForProposedRect:&rect context:NULL hints:nil];
        
        NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        AVVideoCodecH264, AVVideoCodecKey,
                                        //AVVideoScalingModeResize, AVVideoScalingModeKey,
                                        [NSNumber numberWithInt:rect.size.width], AVVideoWidthKey,
                                        [NSNumber numberWithInt:rect.size.height], AVVideoHeightKey,
                                        //compressionSettings, AVVideoColorPropertiesKey,
                                        nil];
        AVAssetWriterInput* assetWriterInput = [AVAssetWriterInput
                                                assetWriterInputWithMediaType:AVMediaTypeVideo
                                                outputSettings:outputSettings];
        if (![assetWriter canAddInput:assetWriterInput]) {
            return;
        }
        
        NSMutableDictionary *sourcePixelBufferAttributes = [[NSMutableDictionary alloc] init];
        [sourcePixelBufferAttributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [sourcePixelBufferAttributes setObject:[NSNumber numberWithUnsignedInt:rect.size.width] forKey:(NSString*)kCVPixelBufferWidthKey];
        [sourcePixelBufferAttributes setObject:[NSNumber numberWithUnsignedInt:rect.size.height] forKey:(NSString*)kCVPixelBufferHeightKey];
        
        AVAssetWriterInputPixelBufferAdaptor *inputPixelBufferAdaptor =
        [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterInput
                                                                         sourcePixelBufferAttributes:sourcePixelBufferAttributes];
        
        [assetWriter addInput:assetWriterInput];
        assetWriterInput.expectsMediaDataInRealTime = NO;
        
        [assetWriter startWriting];
        [assetWriter startSessionAtSourceTime:kCMTimeZero];
        
        CVPixelBufferRef pixelBufferRef = NULL;
        pixelBufferRef = [self pixelBufferFromCGImage:imageRef];
        
        _count = 0;
        float audioDurationSeconds = CMTimeGetSeconds(composition.duration);
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        [_progressBar setDoubleValue:0];
        _progressBar.minValue = 0;
        _progressBar.maxValue = audioDurationSeconds * 15;
        dispatch_queue_t writerQueue = dispatch_queue_create("writerQueue", NULL);
        [assetWriterInput requestMediaDataWhenReadyOnQueue:writerQueue usingBlock:^{
            while (assetWriterInput.readyForMoreMediaData) {
                if (_count < composition.duration.value
                &&  _count < (audioDurationSeconds * 15))
                {
                    [_progressBar setDoubleValue:_count];
                    [inputPixelBufferAdaptor appendPixelBuffer:pixelBufferRef withPresentationTime:CMTimeMake(_count, 15)];
                    _count++;
                }
                else {
                    [assetWriterInput markAsFinished];
                    [assetWriter endSessionAtSourceTime:time];
                    [assetWriter finishWritingWithCompletionHandler:^(){}];
                    
                    NSCharacterSet *charactersToRemove = [NSCharacterSet characterSetWithCharactersInString:@":."];
                    NSCharacterSet *characterSlashToReplace = [NSCharacterSet characterSetWithCharactersInString:@"/"];
                    if (_videoName != nil) {
                        _videoName = [[_videoName componentsSeparatedByCharactersInSet: charactersToRemove] componentsJoinedByString: @""];
                        _videoName = [[_videoName componentsSeparatedByCharactersInSet: characterSlashToReplace] componentsJoinedByString: @":"];
                    }
                    
                    [self combineAudio:urlAudio
                             withVideo:urlVideo
                             videoName:[NSString stringWithFormat:@"%@.mov", _videoName]
                            completion:^{
                                NSError *error;
                                
                                if ([[NSFileManager defaultManager] fileExistsAtPath:[urlAudio path]]) {
                                    [[NSFileManager defaultManager] removeItemAtURL: urlAudio error: &error];
                                }
                                
                                if ([[NSFileManager defaultManager] fileExistsAtPath:[urlVideo path]]) {
                                    [[NSFileManager defaultManager] removeItemAtURL: urlVideo error: &error];
                                }
                                
                                [_progressIndicator stopAnimation:nil];
                                [_progressBar setIndeterminate:YES];
                                [_progressBar stopAnimation:nil];
                                [_progressBar setHidden:YES];
                                _progressTextField.textColor = [NSColor greenColor];
                                _progressTextField.stringValue = @"Conversion complete.";
                                _progressButton.title = @"Done";
                                [_progressFinderButton setHidden:NO];
                            }];
                    
                }
            }
        }];
    }];
}

+ (void)combineAudio:(NSURL *)urlAudio
           withVideo:(NSURL *)urlVideo
           videoName:(NSString *)videoName
          completion:(void (^)(void))completion
{
    NSError *error;
    
    if (_cancel) {
        [_progressIndicator stopAnimation:nil];
        [_progressBar setIndeterminate:NO];
        [_progressBar stopAnimation:nil];
        _progressTextField.textColor = [NSColor orangeColor];
        _progressTextField.stringValue = @"Conversion cancelled.";
        _progressButton.title = @"Close";
        [_progressButton setEnabled:YES];
        return;
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    NSURL *urlOut = [_directory URLByAppendingPathComponent:videoName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[urlOut path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[urlOut path] error:&error];
    }
    
    CMTime time = kCMTimeZero;
    
    AVURLAsset *videoURLAsset = [[AVURLAsset alloc]initWithURL:urlVideo options:nil];
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,videoURLAsset.duration);
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:videoTimeRange ofTrack:[[videoURLAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:time error:nil];
    
    AVURLAsset *audioURLAsset = [[AVURLAsset alloc]initWithURL:urlAudio options:nil];
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioURLAsset.duration);
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:audioTimeRange ofTrack:[[audioURLAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:time error:nil];
    
    exportSession = [[AVAssetExportSession alloc]
                     initWithAsset:composition
                     presetName:_videoSize];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.outputURL = urlOut;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.timeRange = audioTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
            [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"New MOV: %@\n", [urlOut path]]];
            if (completion) {
                completion();
            }
            return;
        }
        else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Failed to create MOV: %@, %@\n",
                                                                 [exportSession.error localizedFailureReason],
                                                                 [urlOut path]]];
        }
    }];
    
    [_progressBar setIndeterminate:NO];
    [_progressBar stopAnimation:nil];
    [_progressBar setDoubleValue:0];
    _progressBar.minValue = 0;
    _progressBar.maxValue = 1;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        progressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateProgressBar) userInfo:nil repeats:YES];
    });
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image),
                                  CGImageGetHeight(image));
    NSDictionary *options =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithBool:YES],
     kCVPixelBufferCGImageCompatibilityKey,
     [NSNumber numberWithBool:YES],
     kCVPixelBufferCGBitmapContextCompatibilityKey,
     nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status =
    CVPixelBufferCreate(
                        kCFAllocatorDefault, frameSize.width, frameSize.height,
                        kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options,
                        &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);//CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 pxdata, frameSize.width, frameSize.height,
                                                 8, CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 //(CGBitmapInfo)kCGBitmapByteOrder32Little |
                                                 kCGImageAlphaNoneSkipFirst);//kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (NSImage *)resizeImage:(NSImage*)image toSize:(NSSize)size
{
    float ratioWidth = size.width / image.size.width;
    float ratioHeight = size.height/ image.size.height;
    
    if (ratioWidth >= ratioHeight) {
        size.width = floor(image.size.width * ratioHeight);
    }
    else {
        size.height = floor(image.size.height * ratioWidth);
    }
    
    NSImage *newImage = [[NSImage alloc] initWithSize: size];
    [newImage lockFocus];
    [image setSize: size];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeCopy fraction:1.0];
    [newImage unlockFocus];
    
    return newImage;
}

+ (NSString *)getPictureTypeExportPreset:(NSString *)pictureType
{
    if ([pictureType isEqual:@"480p (640 x 480)"]) {
        return AVAssetExportPreset640x480;
    }
    else if ([pictureType isEqual:@"540p (960 x 540)"]) {
        return AVAssetExportPreset960x540;
    }
    else if ([pictureType isEqual:@"720p (1280 x 720)"]) {
        return AVAssetExportPreset1280x720;
    }
    else if ([pictureType isEqual:@"1080p (1920 x 1080)"]) {
        return AVAssetExportPreset1920x1080;
    }
    return nil;
}

+ (NSSize)getPictureTypeSize:(NSString *)pictureType
{
    if ([pictureType isEqual:AVAssetExportPreset640x480]) {
        return CGSizeMake(640, 480);
    }
    else if ([pictureType isEqual:AVAssetExportPreset960x540]) {
        return CGSizeMake(960, 540);
    }
    else if ([pictureType isEqual:AVAssetExportPreset1280x720]) {
        return CGSizeMake(1280, 720);
    }
    else if ([pictureType isEqual:AVAssetExportPreset1920x1080]) {
        return CGSizeMake(1920, 1080);
    }
    return CGSizeMake(320, 240);
}
     
+ (void)appendToTextView:(NSTextView *)textView text:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [X28Convert appendToTextView:(NSTextView *)textView text:(NSString*)text scrollToEnd:YES];
    });
}
+ (void)appendToTextView:(NSTextView *)textView text:(NSString*)text scrollToEnd:(BOOL)scrollToEnd
{
    if (_cancelGetCombinedVideoDetails) {
        return;
    }
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
        
        [[textView textStorage] appendAttributedString:attr];
        
        //textView.string = [NSString stringWithFormat:@"%@%@", textView.string, text];
        
        /*@try {
            textView.string = [NSString stringWithFormat:@"%@%@", textView.string, text];
        }
        @catch (NSException *exception) {
            
        }*/
        
        if (scrollToEnd) {
            [textView scrollRangeToVisible:NSMakeRange([[textView string] length], 0)];
        }
        else {
            [textView scrollRangeToVisible:NSMakeRange(0, 0)];
        }
    //});
}

+ (void)close
{
    _progressTextField.textColor = [NSColor blackColor];
    _progressTextField.stringValue = @"Converting...";
    [_progressTextView setString:@""];
    _progressButton.title = @"Cancel";
    [_progressFinderButton setHidden:YES];
}

+ (void)cancel
{
    _cancel = YES;
    _progressTextField.textColor = [NSColor orangeColor];
    _progressTextField.stringValue = @"Cancelling Conversion...";
    [_progressButton setEnabled:NO];
}

+ (NSArray *)getCombinedVideoDetails:(NSArray *)songs
                            textView:(NSTextView *)textView
{
    NSError *error;
    
    _cancelGetCombinedVideoDetails = NO;
    
    //textView.string = @"";
    
    NSMutableArray *artists = [[NSMutableArray alloc] init];
    NSMutableArray *albumNames = [[NSMutableArray alloc] init];
    NSMutableArray *trackArtists = [[NSMutableArray alloc] init];
    NSMutableArray *trackNumbers = [[NSMutableArray alloc] init];
    NSMutableArray *trackTitles = [[NSMutableArray alloc] init];
    NSMutableArray *trackTimes = [[NSMutableArray alloc] init];
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime time = kCMTimeZero;
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    
    NSInteger trackIndex = 0;
    for (X28Song *song in songs) {
        
        if (_cancelGetCombinedVideoDetails) {
            return nil;
        }
        
        [X28Convert appendToTextView:_progressTextView text:[NSString stringWithFormat:@"Combining track: %@\n", song.path]];
        
        NSURL *urlAudio = [NSURL fileURLWithPath:song.path];
        
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:urlAudio options:options];
        NSArray *tracks = [urlAsset tracksWithMediaType:AVMediaTypeAudio];
        if ([tracks count] == 0) {
            continue;
        }
        trackIndex++;
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, [urlAsset duration]);
        AVAssetTrack *assetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        if ([compositionTrack insertTimeRange:timeRange  ofTrack:assetTrack atTime:time error:&error]) {
            
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:CMTimeGetSeconds(time)];
            if (CMTimeCompare(time, kCMTimeZero) != 0) {
                date = [NSDate dateWithTimeInterval:1.0 sinceDate:date];
            }
            
            time = CMTimeAdd(time, timeRange.duration);
            
            for (AVMetadataItem *item in [urlAsset commonMetadata]) {
                
                if (_cancelGetCombinedVideoDetails) {
                    return nil;
                }
                
                if ([[item commonKey] isEqualToString:AVMetadataCommonKeyArtist])
                {
                    if ([artists indexOfObject:item.stringValue] == NSNotFound) {
                        [artists addObject:item.stringValue];
                    }
                    [trackArtists addObject:item.stringValue];
                }
                if ([[item commonKey] isEqualToString:AVMetadataCommonKeyAlbumName])
                {
                    if ([albumNames indexOfObject:item.stringValue] == NSNotFound) {
                        [albumNames addObject:item.stringValue];
                    }
                }
                if ([[item commonKey] isEqualToString:AVMetadataCommonKeyTitle])
                {
                    [trackNumbers addObject:[NSString stringWithFormat: @"%ld", (long)trackIndex]];
                    [trackTitles addObject:item.stringValue];
                    [trackTimes addObject:date];
                }
            }
        }
    }
    
//    NSDate* date = [NSDate dateWithTimeIntervalSince1970:CMTimeGetSeconds(time)];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
//    [dateFormatter setDateFormat:@"HH:mm:ss"];
//    NSString* stringFromDate = [dateFormatter stringFromDate:date];
//    if ([stringFromDate hasPrefix:@"00:0"]) {
//        [dateFormatter setDateFormat:@"m:ss"];
//    }
//    else if ([stringFromDate hasPrefix:@"00:"]) {
//        [dateFormatter setDateFormat:@"mm:ss"];
//    }
//    else if ([stringFromDate hasPrefix:@"0"]) {
//        [dateFormatter setDateFormat:@"H:mm:ss"];
//    }
//    
//    textView.string = @"";
//    for (int i = 0; i < artists.count; i++) {
//        
//        if (_cancelGetCombinedVideoDetails) {
//            return nil;
//        }
//        
//        NSString *artist = artists[i];
//        if (artists.count == 1) {
//            [X28Convert appendToTextView:textView
//                                    text:[NSString stringWithFormat:@"Artist: %@\n",
//                                          artist]
//                             scrollToEnd:NO];
//        }
//        else {
//            if (i == 0) {
//                [X28Convert appendToTextView:textView
//                                        text:[NSString stringWithFormat:@"Artists: %@",
//                                              artist]
//                                 scrollToEnd:NO];
//            }
//            else {
//                [X28Convert appendToTextView:textView
//                                        text:[NSString stringWithFormat:@", %@",
//                                              artist]
//                                 scrollToEnd:NO];
//                
//                if (i == (artists.count - 1)) {
//                    [X28Convert appendToTextView:textView
//                                            text:[NSString stringWithFormat:@"\n"]
//                                     scrollToEnd:NO];
//                }
//            }
//        }
//    }
//    for (int i = 0; i < albumNames.count; i++) {
//        
//        if (_cancelGetCombinedVideoDetails) {
//            return nil;
//        }
//        
//        NSString *albumName = albumNames[i];
//        if (albumNames.count == 1) {
//            [X28Convert appendToTextView:textView
//                                    text:[NSString stringWithFormat:@"Album: %@\n",
//                                          albumName]
//                             scrollToEnd:NO];
//        }
//        else {
//            if (i == 0) {
//                [X28Convert appendToTextView:textView
//                                        text:[NSString stringWithFormat:@"Albums: %@",
//                                              albumName]
//                                 scrollToEnd:NO];
//            }
//            else {
//                [X28Convert appendToTextView:textView
//                                        text:[NSString stringWithFormat:@", %@",
//                                              albumName]
//                                 scrollToEnd:NO];
//                
//                if (i == (albumNames.count - 1)) {
//                    [X28Convert appendToTextView:textView
//                                            text:[NSString stringWithFormat:@"\n"]
//                                     scrollToEnd:NO];
//                }
//            }
//        }
//    }
//    
//    if (_cancelGetCombinedVideoDetails) {
//        return nil;
//    }
//    
//    [X28Convert appendToTextView:textView
//                            text:[NSString stringWithFormat:@"\n"]
//                     scrollToEnd:NO];
//    for (int i = 0; i < trackTitles.count; i++) {
//        
//        if (_cancelGetCombinedVideoDetails) {
//            return nil;
//        }
//        
//        if (artists.count == 1) {
//            [X28Convert appendToTextView:textView
//                                    text:[NSString stringWithFormat:@"%@   %@. %@\n",
//                                          [dateFormatter stringFromDate:trackTimes[i]],
//                                          trackNumbers[i],
//                                          trackTitles[i]]
//                             scrollToEnd:NO];
//        }
//        else {
//            [X28Convert appendToTextView:textView
//                                    text:[NSString stringWithFormat:@"%@   %@. %@ - %@\n",
//                                          [dateFormatter stringFromDate:trackTimes[i]],
//                                          trackNumbers[i],
//                                          trackArtists[i],
//                                          trackTitles[i]]
//                             scrollToEnd:NO];
//        }
//    }
    
    NSArray *compositionAndTime = [[NSArray alloc] initWithObjects:
                                   composition,
                                   [NSValue valueWithBytes:&time objCType:@encode(CMTime)],
                                   nil];
    
    return compositionAndTime;
}
+ (void)cancelGetCombinedVideoDetails
{
    _cancelGetCombinedVideoDetails = YES;
}

+ (void)updateProgressBar {
    [_progressBar setDoubleValue:exportSession.progress];
    if (_progressBar.doubleValue > .99) {
        [progressBarTimer invalidate];
    }
}

@end
