#import <Cocoa/Cocoa.h>

// objective C files are C files
// which is important to remember

@interface LightWeightWindow : NSWindow
    - (BOOL) canBecomeKeyWindow;
@end

@implementation LightWeightWindow

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

@end

// the <> syntax refers to *protocol* conformance
@interface WindowDelegate : NSObject<NSApplicationDelegate>
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication;
@end

@implementation WindowDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{

    // in this function, we don't the app to terminate (call exit)
    // but we do want control to return to the caller of imshow
    [theApplication stop: self];

    [theApplication postEvent: 
        [NSEvent otherEventWithType: NSEventTypeApplicationDefined
        location: NSMakePoint(0, 0)
        modifierFlags: 0
        timestamp: 0
        windowNumber: 0
        context: nil
        subtype: 0
        data1: 0
        data2: 0
    ] atStart: YES];

    return NO;
}

@end

// C style function
int imshow_u8_c1(const char* windowName,
                uint8_t* imageData,
                int imageWidth,
                int imageHeight)
{
    // this is sort of how objective C doe memory management
    // todo: actually understand this

    if (imageData == NULL) {
        return 1;
    }

    if (windowName == NULL) {
        return 1;
    }

    if (imageWidth < 0 || imageHeight < 0) {
        return 1;
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    const int bufSize = imageWidth * imageHeight;
    
    NSApplication *app = [NSApplication sharedApplication];
    if (app == nil) {
        return 1;
    }

    WindowDelegate* delegate = [WindowDelegate alloc];
    if (delegate == nil) {
        return 1;
    }

    [app setDelegate: delegate];
    
    LightWeightWindow* window = [[LightWeightWindow alloc] 
        initWithContentRect: NSMakeRect(0, 0, 1000, 1000)
        styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView
        backing: NSBackingStoreBuffered
        defer: YES];
    
    if (window == nil) {
        return 1;
    }

    NSString* nsWindowName = [[NSString alloc] initWithCString: windowName
                                        encoding: NSASCIIStringEncoding];

    if (nsWindowName == nil) {
        return 1;
    }

    [window setTitle: nsWindowName];

    [window center];
    [window makeKeyAndOrderFront:nil];

    NSView* view = [window contentView];
    NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: &imageData 
                              pixelsWide: imageWidth 
                              pixelsHigh: imageHeight 
                           bitsPerSample: 8 
                         samplesPerPixel: 1 
                                hasAlpha: NO
                                isPlanar: NO
                          colorSpaceName: NSCalibratedWhiteColorSpace
                             bytesPerRow: imageWidth 
                            bitsPerPixel: 8];
    if (imageRep == nil) {
        return 1;
    }

    NSSize imageSize = NSMakeSize(CGImageGetWidth([imageRep CGImage]), CGImageGetHeight([imageRep CGImage]));
    NSImage* image = [[NSImage alloc] initWithSize: imageSize];
    
    if (image) {  
        [image addRepresentation: imageRep];

        NSImageView* imageView = [[NSImageView alloc] initWithFrame: [window frame]];
        [imageView setImage: image];
        [window setContentView: imageView];
    }  

    [window setFrame: [window frame] display: YES];
    [window setHasShadow: YES];
    [window setAcceptsMouseMovedEvents: YES];
    [window makeKeyWindow];
    [app run];
    
    // free everything? I think
    // really not sure if this has thousands of leaks
    [pool release];
    return 0;   
}
