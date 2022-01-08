#import "X28ScrollerTransparent.h"

@implementation X28ScrollerTransparent

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawKnob];
}

@end
