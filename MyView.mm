#import "MyView.h"
#import "MyGLLayer.h"

@implementation MyView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (! self)
		return nil;

    return self;
}

/// The xib requests that MyView be layer backed, and AppKit calls this to create our layer.
- (CALayer *)makeBackingLayer
{
	MyGLLayer *layer = [[MyGLLayer alloc] init];
	
	return layer;
}

@end
