#import "X28MasterViewController.h"
#import "X28Song.h"
#import <AVFoundation/AVFoundation.h>
#import "X28Convert.h"

@interface X28MasterViewController ()

@property (weak) IBOutlet NSTableView *songsTableView;
@property (strong) NSURL *pictureURL;
@property (weak) IBOutlet NSImageView *pictureImageView;
@property (weak) IBOutlet NSTextField *pictureSizeTextField;
@property (weak) IBOutlet NSButton *moveSongUpButton;
@property (weak) IBOutlet NSButton *moveSongDownButton;
@property (weak) IBOutlet NSComboBox *pictureTypesComboBox;
@property (weak) IBOutlet NSButton *eachSongAiffButton;
@property (weak) IBOutlet NSButton *eachSongMovButton;
@property (weak) IBOutlet NSButton *allSongsMovButton;
@property (weak) IBOutlet NSTextField *allSongsNameTextField;
@property (strong) IBOutlet NSTextView *allSongsDetailsTextView;
@property (weak) IBOutlet NSProgressIndicator *allSongsDetailsIndicator;
@property (weak) IBOutlet NSButton *allSongsDetailsIncludeArtistButton;
@property (weak) IBOutlet NSButton *allSongsDetailsCopyButton;
@property (strong) IBOutlet NSPanel *loadingPanel;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSTextField *loadingTextField;
@property (strong) IBOutlet NSPanel *progressPanel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressTextField;
@property (strong) IBOutlet NSTextView *progressTextView;
@property (weak) IBOutlet NSButton *progressButton;
@property (weak) IBOutlet NSButton *progressFinderButton;

@end

@implementation X28MasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    [self loadPictureTypes];
    
    NSImage *imageLeft = [NSImage imageNamed:@"NSLeftFacingTriangleTemplate"];
    NSAffineTransform* transform = [NSAffineTransform transform] ;
    [transform translateXBy:+imageLeft.size.width / 2
                        yBy:+imageLeft.size.height / 2] ;
    [transform rotateByDegrees:-90] ;
    [transform translateXBy:-imageLeft.size.width / 2
                        yBy:-imageLeft.size.height / 2] ;
    [transform scaleBy:1.1];
    [imageLeft lockFocus] ;
    [transform concat] ;
    [imageLeft drawAtPoint:NSMakePoint(0, 0)
             fromRect:NSZeroRect
            operation:NSCompositeCopy
             fraction:1.0] ;
    [imageLeft unlockFocus];
    self.moveSongUpButton.image = imageLeft;
    
    NSImage *imageRight = [NSImage imageNamed:@"NSRightFacingTriangleTemplate"];
    transform = [NSAffineTransform transform] ;
    [transform translateXBy:+imageRight.size.width / 2
                        yBy:+imageRight.size.height / 2] ;
    [transform rotateByDegrees:-90] ;
    [transform translateXBy:-imageRight.size.width / 2
                        yBy:-imageRight.size.height / 2] ;
    [transform scaleBy:1.1];
    [imageRight lockFocus] ;
    [transform concat] ;
    [imageRight drawAtPoint:NSMakePoint(0, 0)
                  fromRect:NSZeroRect
                 operation:NSCompositeCopy
                  fraction:1.0] ;
    [imageRight unlockFocus];
    self.moveSongDownButton.image = imageRight;
    
    
    [[self.progressTextView enclosingScrollView] setHasHorizontalScroller:YES];
    [self.progressTextView setHorizontallyResizable:YES];
    [self.progressTextView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [[self.progressTextView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[self.progressTextView textContainer] setWidthTracksTextView:NO];
    
    [self.songsTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSMutableArray"]];
}

- (void)loadPictureTypes {
    if ([[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPreset640x480]) {
        [self.pictureTypesComboBox addItemWithObjectValue:@"480p (640 x 480)"];
    }
    if ([[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPreset960x540]) {
        [self.pictureTypesComboBox addItemWithObjectValue:@"540p (960 x 540)"];
    }
    if ([[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPreset1280x720]) {
        [self.pictureTypesComboBox addItemWithObjectValue:@"720p (1280 x 720)"];
    }
    if ([[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPreset1920x1080]) {
        [self.pictureTypesComboBox addItemWithObjectValue:@"1080p (1920 x 1080)"];
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
   
    if( [tableColumn.identifier isEqualToString:@"Artist"] )
    {
        X28Song *song = [self.songs objectAtIndex:row];
        cellView.textField.stringValue = song.artist;
        return cellView;
    }if( [tableColumn.identifier isEqualToString:@"Album"] )
    {
        X28Song *song = [self.songs objectAtIndex:row];
        cellView.textField.stringValue = song.album;
        return cellView;
    }if( [tableColumn.identifier isEqualToString:@"Song"] )
    {
        X28Song *song = [self.songs objectAtIndex:row];
        cellView.textField.stringValue = song.name;
        return cellView;
    }if( [tableColumn.identifier isEqualToString:@"Time"] )
    {
        X28Song *song = [self.songs objectAtIndex:row];
        cellView.textField.stringValue = song.time;
        return cellView;
    }
    if( [tableColumn.identifier isEqualToString:@"Path"] )
    {
        X28Song *song = [self.songs objectAtIndex:row];
        cellView.textField.stringValue = song.path;
        return cellView;
    }
    
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    return [self.songs count];
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:@"NSMutableArray"] owner:self];
    [pboard setData:data forType:@"NSMutableArray"];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (tableView == [info draggingSource]) // From self
    {
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSData *data = [[info draggingPasteboard] dataForType:@"NSMutableArray"];
    NSIndexSet *rowIndexSet = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (tableView == [info draggingSource])
    {
        NSArray *songsMoved = [self.songs objectsAtIndexes:rowIndexSet];
        [self.songs removeObjectsAtIndexes:rowIndexSet];
        if (row > self.songs.count)
        {
            for (int i = 0; i < rowIndexSet.count; i++) {
                [self.songs insertObject:[songsMoved objectAtIndex:i] atIndex:row + i - rowIndexSet.count];
            }
        }
        else
        {
            for (int i = 0; i < rowIndexSet.count; i++) {
                [self.songs insertObject:[songsMoved objectAtIndex:i] atIndex:row + i];
            }
        }
        [tableView reloadData];
        [tableView deselectAll:nil];
        
        [self performSelectorInBackground:@selector(loadAllSongsDetails) withObject:nil];
        
        return YES;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
    // configure the drag image
    // we are only dragging one item - changes will be required to handle multiple drag items
    NSTableCellView *cellView = [tableView viewAtColumn:2 row:rowIndexes.firstIndex makeIfNecessary:NO];
    NSTableCellView *cellViewLast = [tableView viewAtColumn:2 row:rowIndexes.lastIndex makeIfNecessary:NO];
    if (cellView
    &&  cellViewLast) {
        
        [session enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                           forView:tableView
                                           classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
                                     searchOptions:nil
                                        usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop)
         {
             // we can set the drag image directly
             //[draggingItem setDraggingFrame:NSMakeRect(0, 0, myWidth, myHeight) contents:myFunkyDragImage];
             
             NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:cellView.textField.font, NSFontAttributeName, nil];
             NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:cellView.textField.stringValue attributes:attributes];
             NSSize boxSize = [attributedString size];
             NSRect rect = NSMakeRect(0.0, 0.0, boxSize.width, boxSize.height);
             NSImage *image = [[NSImage alloc] initWithSize:boxSize];
             
             [image lockFocus];
             
             [attributedString drawInRect:rect];
             
             [image unlockFocus];
             
             [draggingItem setDraggingFrame:NSMakeRect(draggingItem.draggingFrame.origin.x,
                                                       draggingItem.draggingFrame.origin.y, image.size.width, image.size.height) contents:image];
             return;
             
             NSImage *firstImage = cellView.draggingImageComponents[0];
             NSImage *lastImage = cellViewLast.draggingImageComponents[0];
             NSImage* resultImage = [[NSImage alloc] initWithSize:firstImage.size];
             [resultImage lockFocus];
             
             [lastImage drawAtPoint:CGPointMake(0, firstImage.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
             
             [resultImage unlockFocus];
             
             NSMutableArray *images = [[NSMutableArray alloc] init];
             [images addObject:resultImage];
             
             // the tableview will grab the entire table cell view bounds as its image by default.
             // we can override NSTableCellView -draggingImageComponents
             // which defaults to only including the image and text fields
             draggingItem.imageComponentsProvider = ^NSArray*(void) { //return cellView.draggingImageComponents;};
                 return images;
             };
         }];
    }
}

- (IBAction)moveSongUp:(id)sender {
    
    if (self.songsTableView.selectedRow == -1) {
        return;
    }
    
    NSUInteger index = [self.songsTableView.selectedRowIndexes firstIndex];
    if (index == 0) {
        return;
    }
    [self.songsTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            *stop = YES;
            return;
        }
        [self.songs exchangeObjectAtIndex:idx withObjectAtIndex:(idx - 1)];
        [self.songsTableView moveRowAtIndex:idx toIndex:(idx - 1)];
    }];
    
    [self performSelectorInBackground:@selector(loadAllSongsDetails) withObject:nil];
}

- (IBAction)moveSongDown:(id)sender {
    
    if (self.songsTableView.selectedRow == -1) {
        return;
    }
    
    NSUInteger index = [self.songsTableView.selectedRowIndexes lastIndex];
    if (index == (self.songs.count - 1)) {
        return;
    }
    while (index != NSNotFound)
    {
        [self.songs exchangeObjectAtIndex:index withObjectAtIndex:(index + 1)];
        [self.songsTableView moveRowAtIndex:index toIndex:(index + 1)];
        index = [self.songsTableView.selectedRowIndexes indexLessThanIndex:index];
    }
    
    [self performSelectorInBackground:@selector(loadAllSongsDetails) withObject:nil];
}

- (IBAction)addSong:(id)sender {
    
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:[NSSound soundUnfilteredTypes]];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self performSelector:@selector(loadSongs:) withObject:[openPanel URLs] afterDelay:0];
        }
    }];
}

- (IBAction)removeSong:(id)sender {
    
    if (self.songsTableView.selectedRow == -1) {
        return;
    }
    
    [self.songs removeObjectsAtIndexes:self.songsTableView.selectedRowIndexes];
    [self.songsTableView removeRowsAtIndexes:self.songsTableView.selectedRowIndexes withAnimation:NSTableViewAnimationSlideRight];
    
    [self resizeTableColumns];
    
    [self performSelectorInBackground:@selector(loadAllSongsDetails) withObject:nil];
}

- (void)loadSongs:(NSArray *)urls {
    
    [self.loadingIndicator startAnimation:nil];
    
    [[NSApplication sharedApplication] beginSheet:self.loadingPanel
                                   modalForWindow:[[self view] window]
                                    modalDelegate:self
                                   didEndSelector:nil
                                      contextInfo:nil];
    
    [self performSelectorInBackground:@selector(loadSongsData:) withObject:urls];
}

- (void)loadSongsData:(NSArray *)urls {
    
    NSError *error;
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime time = kCMTimeZero;
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    
    NSInteger trackIndex = 0;
    for (NSURL *urlAudio in urls) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingTextField.stringValue = urlAudio.path;
        });
        
        X28Song *song = [[X28Song alloc] initWithArtist:@""
                                                  album:@""
                                                   name:@""
                                                   time:@""
                                               duration:kCMTimeZero
                                                   year:@""
                                                   path:urlAudio.path];
    
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:urlAudio options:options];
        NSArray *tracks = [urlAsset tracksWithMediaType:AVMediaTypeAudio];
        if ([tracks count] == 0) {
            continue;
        }
        trackIndex++;
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, [urlAsset duration]);
        AVAssetTrack *assetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        if ([compositionTrack insertTimeRange:timeRange  ofTrack:assetTrack atTime:time error:&error]) {
            
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:CMTimeGetSeconds([urlAsset duration])];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"HH:mm:ss"];
            NSString* stringFromDate = [dateFormatter stringFromDate:date];
            if ([stringFromDate hasPrefix:@"00:0"]) {
                stringFromDate = [stringFromDate substringFromIndex:4];
            }
            else if ([stringFromDate hasPrefix:@"00:"]) {
                stringFromDate = [stringFromDate substringFromIndex:3];
            }
            else if ([stringFromDate hasPrefix:@"0"]) {
                stringFromDate = [stringFromDate substringFromIndex:1];
            }
            
            CMTime duration = CMTimeAdd(time, timeRange.duration);
            
            song.duration = duration;
            
            for (NSString *format in [urlAsset availableMetadataFormats]) {
                for (AVMetadataItem *item in [urlAsset metadataForFormat:format]) {
                    if ([[item commonKey] isEqualToString:AVMetadataCommonKeyArtist])
                    {
                        song.artist = item.stringValue;
                    }
                    else if ([[item commonKey] isEqualToString:AVMetadataCommonKeyAlbumName])
                    {
                        song.album =item.stringValue;
                    }
                    else if ([[item commonKey] isEqualToString:AVMetadataCommonKeyTitle])
                    {
                        song.name = item.stringValue;
                        song.time = stringFromDate;
                    }
                    else if (item.stringValue.length == 4
                    &&       [item.stringValue intValue] > 1900) {
                        song.year = item.stringValue;
                    }
                }
            }
        }
    
        [self performSelectorOnMainThread:@selector(addSongToTable:) withObject:song waitUntilDone:YES];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingPanel orderOut:self];
    });
    [NSApp endSheet:self.loadingPanel];
    
    [self.allSongsDetailsIndicator startAnimation:nil];
    [self performSelectorInBackground:@selector(loadAllSongsDetails) withObject:nil];
    
    [self performSelectorOnMainThread:@selector(resizeTableColumns) withObject:nil waitUntilDone:YES];
}

- (void)addSongToTable:(X28Song *)song {
    
    [self.songs addObject:song];
    NSInteger newRowIndex = self.songs.count - 1;
     
    [self.songsTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newRowIndex] withAnimation:NSTableViewAnimationEffectGap];

    [self.songsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRowIndex] byExtendingSelection:NO];
    [self.songsTableView scrollRowToVisible:newRowIndex];
}

- (void)resizeTableColumns {
    
    [self.songsTableView.tableColumns enumerateObjectsUsingBlock:
     ^(id obj, NSUInteger idx, BOOL *stop) {
         NSTableColumn* column = (NSTableColumn*) obj;
         if ([column.identifier isEqualToString:@"Path"]) {
             return;
         }
         CGFloat width = 0;
         for (int row = 0; row < self.songsTableView.numberOfRows; row++) {
             NSTableCellView* view = [self.songsTableView viewAtColumn: idx
                                                                   row: row
                                                       makeIfNecessary: YES];
             [[view textField] sizeToFit];
             NSSize size = [view textField].bounds.size;
             width = MAX(width, MIN(column.maxWidth, size.width));
         }
         column.width = width;
     }];
    [self.songsTableView reloadData];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    
    [self.allSongsDetailsIndicator startAnimation:nil];
    [self performSelectorInBackground:@selector(loadAllSongsDetails) withObject:nil];
}

- (IBAction)loadAllSongsDetails:(id)sender {
    [self loadAllSongsDetails];
}
- (void)loadAllSongsDetails {
    
    @synchronized(self) {
    
        NSMutableArray *artists = [[NSMutableArray alloc] init];
        NSMutableArray *albumNames = [[NSMutableArray alloc] init];
        NSMutableArray *trackArtists = [[NSMutableArray alloc] init];
        NSMutableArray *trackAlbums = [[NSMutableArray alloc] init];
        NSMutableArray *trackNumbers = [[NSMutableArray alloc] init];
        NSMutableArray *trackTitles = [[NSMutableArray alloc] init];
        NSMutableArray *trackTimes = [[NSMutableArray alloc] init];
        NSMutableArray *years = [[NSMutableArray alloc] init];
        NSMutableArray *trackYears = [[NSMutableArray alloc] init];
        
        CMTime time = kCMTimeZero;
        
        NSString *paddingTrackNumber = [NSString stringWithFormat:@"%%0%ldd",
                                        (long)((NSString *)[NSString stringWithFormat:@"%ld",
                                                            (long)self.songs.count]).length];
        
        int trackIndex = 1;
        for (X28Song *song in self.songs) {
            if ([artists indexOfObject:song.artist] == NSNotFound) {
                [artists addObject:song.artist];
            }
            [trackArtists addObject:song.artist];
            if ([albumNames indexOfObject:song.album] == NSNotFound) {
                [albumNames addObject:song.album];
            }
            [trackAlbums addObject:song.album];
            [trackNumbers addObject:[NSString stringWithFormat:paddingTrackNumber, (long)trackIndex]];
            [trackTitles addObject:song.name];
            if ([years indexOfObject:song.year] == NSNotFound) {
                [years addObject:song.year];
            }
            [trackYears addObject:song.year];
            
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, song.duration);
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:CMTimeGetSeconds(time)];
            if (CMTimeCompare(time, kCMTimeZero) != 0) {
                date = [NSDate dateWithTimeInterval:1.0 sinceDate:date];
            }
            [trackTimes addObject:date];
            
            time = CMTimeAdd(time, timeRange.duration);
            
            trackIndex++;
        }
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCompare:)];
        years = (NSMutableArray *)[years sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:CMTimeGetSeconds(time)];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        NSString* stringFromDate = [dateFormatter stringFromDate:date];
        if ([stringFromDate hasPrefix:@"00:0"]) {
            [dateFormatter setDateFormat:@"m:ss"];
        }
        else if ([stringFromDate hasPrefix:@"00:"]) {
            [dateFormatter setDateFormat:@"mm:ss"];
        }
        else if ([stringFromDate hasPrefix:@"0"]) {
            [dateFormatter setDateFormat:@"H:mm:ss"];
        }
        
        [self appendToTextView:self.allSongsDetailsTextView
                          text:@""
                   scrollToEnd:NO
                         clear:YES];
        [self.allSongsDetailsIncludeArtistButton setHidden:YES];
        [self.allSongsDetailsCopyButton setHidden:YES];
        
        for (int j = 0; j < (trackTitles.count + 1); j++) {
            if (trackTitles.count == 0) {
                return;
            }
            int iOverride = j;
            if (! self.eachSongMovButton.state) {
                j = (int)trackTitles.count;
            }
            if (j == trackTitles.count) {
                if (! self.allSongsMovButton.state) {
                    break;
                }
                iOverride = -1;
            }
            [self appendToTextView:self.allSongsDetailsTextView
                              text:[NSString stringWithFormat:@"--------------------%@--------------------\n",
                                    (j == trackTitles.count) ?
                                        @" (Full Album) " :
                                        [NSString stringWithFormat:@" (%@) ", trackTitles[j]]]
                       scrollToEnd:NO];
            
            for (int i = 0; i < artists.count; i++) {
                NSString *artist = artists[i];
                if (iOverride > -1) {
                    i = iOverride;
                    artist = trackArtists[i];
                }
                if (artists.count == 1
                ||  iOverride > -1) {
                    [self appendToTextView:self.allSongsDetailsTextView
                                      text:[NSString stringWithFormat:@"Artist: %@\n", artist]
                               scrollToEnd:NO];
                }
                else {
                    if ([self.allSongsDetailsIncludeArtistButton isHidden]) {
                        [self.allSongsDetailsIncludeArtistButton setHidden:NO];
                    }
                    if (i == 0) {
                        [self appendToTextView:self.allSongsDetailsTextView
                                          text:[NSString stringWithFormat:@"Artists: %@",
                                                artist]
                                   scrollToEnd:NO];
                    }
                    else {
                        [self appendToTextView:self.allSongsDetailsTextView
                                          text:[NSString stringWithFormat:@", %@",
                                                artist]
                                   scrollToEnd:NO];
                        
                        if (i == (artists.count - 1)) {
                            [self appendToTextView:self.allSongsDetailsTextView
                                              text:[NSString stringWithFormat:@"\n"]
                                       scrollToEnd:NO];
                        }
                    }
                }
                if (iOverride > -1) {
                    break;
                }
            }
            NSString *allSongsNameTextFieldStringValue = self.allSongsNameTextField.stringValue;
            if (allSongsNameTextFieldStringValue.length > 0
            &&  iOverride == -1) {
                [self appendToTextView:self.allSongsDetailsTextView
                                  text:[NSString stringWithFormat:@"Album: %@\n",
                                        allSongsNameTextFieldStringValue]
                           scrollToEnd:NO];
            }
            else {
                for (int i = 0; i < albumNames.count; i++) {
                    NSString *albumName = albumNames[i];
                    if (iOverride > -1) {
                        i = iOverride;
                        albumName = trackAlbums[i];
                    }
                    if (albumNames.count == 1
                    ||  iOverride > -1) {
                        [self appendToTextView:self.allSongsDetailsTextView
                                          text:[NSString stringWithFormat:@"Album: %@\n",
                                                albumName]
                                   scrollToEnd:NO];
                    }
                    else {
                        if (i == 0) {
                            [self appendToTextView:self.allSongsDetailsTextView
                                              text:[NSString stringWithFormat:@"Albums: %@",
                                                    albumName]
                                       scrollToEnd:NO];
                        }
                        else {
                            [self appendToTextView:self.allSongsDetailsTextView
                                              text:[NSString stringWithFormat:@", %@",
                                                    albumName]
                                       scrollToEnd:NO];
                            
                            if (i == (albumNames.count - 1)) {
                                [self appendToTextView:self.allSongsDetailsTextView
                                                  text:[NSString stringWithFormat:@"\n"]
                                           scrollToEnd:NO];
                            }
                        }
                    }
                    if (iOverride > -1) {
                        break;
                    }
                }
            }
            [self appendToTextView:self.allSongsDetailsTextView
                              text:[NSString stringWithFormat:@"\n"]
                       scrollToEnd:NO];
            for (int i = 0; i < trackTitles.count; i++) {
                if (iOverride > -1) {
                    i = iOverride;
                }
                if (trackTitles.count == 1
                ||  iOverride > -1) {
                    [self appendToTextView:self.allSongsDetailsTextView
                                      text:[NSString stringWithFormat:@"%@\n",
                                            trackTitles[i]]
                               scrollToEnd:NO];
                }
                else if (artists.count == 1
                ||       self.allSongsDetailsIncludeArtistButton.state == 0) {
                    [self appendToTextView:self.allSongsDetailsTextView
                                      text:[NSString stringWithFormat:@"%@   %@. %@\n",
                                            [dateFormatter stringFromDate:trackTimes[i]],
                                            trackNumbers[i],
                                            trackTitles[i]]
                               scrollToEnd:NO];
                }
                else {
                    [self appendToTextView:self.allSongsDetailsTextView
                                      text:[NSString stringWithFormat:@"%@   %@. %@ - %@\n",
                                            [dateFormatter stringFromDate:trackTimes[i]],
                                            trackNumbers[i],
                                            trackArtists[i],
                                            trackTitles[i]]
                               scrollToEnd:NO];
                }
                if (iOverride > -1) {
                    break;
                }
            }
            [self appendToTextView:self.allSongsDetailsTextView
                              text:[NSString stringWithFormat:@"\n©"]
                       scrollToEnd:NO];
            for (int i = 0; i < years.count; i++) {
                NSString *year = years[i];
                if (iOverride > -1) {
                    i = iOverride;
                    year = trackYears[i];
                }
                if ((i + 1) == years.count
                ||  iOverride > -1) {
                    [self appendToTextView:self.allSongsDetailsTextView
                                      text:[NSString stringWithFormat:@" %@\n",
                                            year]
                               scrollToEnd:NO];
                }
                else {
                    [self appendToTextView:self.allSongsDetailsTextView
                                      text:[NSString stringWithFormat:@" %@,",
                                            year]
                               scrollToEnd:NO];
                }
                if (iOverride > -1) {
                    break;
                }
            }
            [self appendToTextView:self.allSongsDetailsTextView
                              text:[NSString stringWithFormat:@""]
                       scrollToEnd:YES];
        }
        [self.allSongsDetailsCopyButton setHidden:NO];
        
        [self.allSongsDetailsIndicator stopAnimation:nil];
    }
}

- (IBAction)copyAllSongsDetails:(id)sender {
    [self.allSongsDetailsTextView selectAll:self];
    [self.allSongsDetailsTextView copy:self];
    [self.allSongsDetailsTextView setSelectedRange:NSMakeRange(0, 0)];
}

- (void)appendToTextView:(NSTextView *)textView
                    text:(NSString*)text
             scrollToEnd:(BOOL)scrollToEnd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self appendToTextView:textView text:text scrollToEnd:scrollToEnd clear:NO];
    });
}
- (void)appendToTextView:(NSTextView *)textView
                    text:(NSString*)text
             scrollToEnd:(BOOL)scrollToEnd
                   clear:(BOOL)clear
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @synchronized(self) {
        
            if (clear) {
                textView.string = @"";
            }
            else {
                NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
                [[textView textStorage] appendAttributedString:attr];
            }
            
            if (scrollToEnd) {
                [textView scrollRangeToVisible:NSMakeRange([[textView string] length], 0)];
            }
            else {
                [textView scrollRangeToVisible:NSMakeRange(0, 0)];
            }
        }
    });
}

- (IBAction)addPicture:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:[NSImage imageFileTypes]];
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            for (NSURL *url in [openPanel URLs]) {
                self.pictureURL = url;
                NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
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
                    self.pictureSizeTextField.stringValue = [NSString stringWithFormat:@"%.00f x %.00f", image.size.width, image.size.height];
                }
                self.pictureImageView.image = image;
                if (image.size.width >= image.size.height) {
                    if (image.size.width >= 1920) {
                        [self.pictureTypesComboBox selectItemAtIndex:3];
                    }
                    else if (image.size.width >= 1280) {
                        [self.pictureTypesComboBox selectItemAtIndex:2];
                    }
                    else if (image.size.width >= 960) {
                        [self.pictureTypesComboBox selectItemAtIndex:1];
                    }
                    else {
                        [self.pictureTypesComboBox selectItemAtIndex:0];
                    }
                }
                else {
                    if (image.size.height >= 1080) {
                        [self.pictureTypesComboBox selectItemAtIndex:3];
                    }
                    else if (image.size.height >= 720) {
                        [self.pictureTypesComboBox selectItemAtIndex:2];
                    }
                    else if (image.size.height >= 540) {
                        [self.pictureTypesComboBox selectItemAtIndex:1];
                    }
                    else {
                        [self.pictureTypesComboBox selectItemAtIndex:0];
                    }
                }
            }
        }
    }];
}

- (IBAction)convertSongs:(id)sender {
    
    [self.progressIndicator startAnimation:nil];
    
    [[NSApplication sharedApplication] beginSheet:self.progressPanel
                                   modalForWindow:[[self view] window]
                                    modalDelegate:self
                                   didEndSelector:nil
                                      contextInfo:nil];
    
    [self performSelectorInBackground:@selector(convertSongs) withObject:nil];
}
- (void)convertSongs {
    
    NSError *error = nil;
    
    /*NSMutableArray *urls = [[NSMutableArray alloc] init];
    for (X28Song *song in self.songs) {
        [urls addObject:[[NSURL alloc] initFileURLWithPath:[song path]]];
    }*/
    
    
    BOOL toAiff = self.eachSongAiffButton.state;
    BOOL toVideo = self.eachSongMovButton.state;
    BOOL toCombinedVideo = self.allSongsMovButton.state;
    
    NSString *videoSize = self.pictureTypesComboBox.objectValueOfSelectedItem;
    
    NSString *allSongsName = nil;
    if (self.allSongsMovButton.state) {
        allSongsName = self.allSongsNameTextField.stringValue;
    }
    
    NSURL *urlImage = self.pictureURL;
    
    NSURL *documents = [[NSFileManager defaultManager] URLForDirectory: NSDocumentDirectory
                                                              inDomain: NSUserDomainMask
                                                     appropriateForURL: nil
                                                                create: YES
                                                                 error: &error];

    [X28Convert convertSongs:self.songs
                      toAiff:toAiff
                     toVideo:toVideo
             toCombinedVideo:toCombinedVideo
                   videoSize:videoSize
                   videoName:allSongsName
                       image:urlImage
                   directory:documents
        combinedVideoDetails:self.allSongsDetailsTextView
           progressIndicator:self.progressIndicator
                 progressBar:self.progressBar
           progressTextField:self.progressTextField
            progressTextView:self.progressTextView
              progressButton:self.progressButton
        progressFinderButton:self.progressFinderButton];
}

- (IBAction)closeProgress:(id)sender {
    
    if ([self.progressButton.title isEqualToString:@"Done"]
    ||  [self.progressButton.title isEqualToString:@"OK"]
    ||  [self.progressButton.title isEqualToString:@"Close"]) {
        [self.progressPanel orderOut:self];
        [NSApp endSheet:self.progressPanel];
        [X28Convert close];
    }
    else {
        [X28Convert cancel];
    }
}
- (IBAction)showInFinder:(id)sender {

    NSError *error;
    
    NSURL *documents = [[NSFileManager defaultManager] URLForDirectory: NSDocumentDirectory
                                                              inDomain: NSUserDomainMask
                                                     appropriateForURL: nil
                                                                create: YES
                                                                 error: &error];
    
    [[NSWorkspace sharedWorkspace] openURL: documents];
}

@end
