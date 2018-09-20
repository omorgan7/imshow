#import <Cocoa/Cocoa.h>
#import <string.h>

// objective C files are C files
// which is important to remember

@interface LightWeightWindow : NSWindow
    - (BOOL) canBecomeKeyWindow;
    - (BOOL) showsResizeIndicator;
    @property BOOL windowIsOpen;
    @property const char* windowNameAsCString;

@end

@implementation LightWeightWindow

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

- (BOOL) showsResizeIndicator
{
    return YES;
}

@end

static NSMutableArray* windowList = nil;

@interface WindowDelegate : NSObject<NSWindowDelegate>

// needed to make the window clean up if the user closes it.
- (void) windowWillClose: (NSNotification*) notification;
@end

@implementation WindowDelegate
- (void) windowWillClose: (NSNotification *) notification
{
    LightWeightWindow* theWindow = [notification object];

    if (theWindow) {
        theWindow.windowIsOpen = NO;
        // find the window in the list of windows

        // 1 past the end, which can't be removed
        int windowIndex = [windowList count];
        for (int i = 0; i < [windowList count]; ++i) {
            if (strcmp([windowList[i] windowNameAsCString], [theWindow windowNameAsCString]) == 0) {
                windowIndex = i;
                break;
            }
        }
        if (windowIndex != [windowList count]) {
            [windowList removeObjectAtIndex: windowIndex];
        }
    }
}
@end

// the <> syntax refers to *protocol* conformance
@interface ApplicationWindowDelegate : NSObject<NSApplicationDelegate>
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication;
@end

@implementation ApplicationWindowDelegate
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

static void init()
{
    windowList = [[NSMutableArray alloc] init];
    NSApplication *app = [NSApplication sharedApplication];

    ApplicationWindowDelegate* delegate = [ApplicationWindowDelegate alloc];
    [app setDelegate: delegate];
    [app activateIgnoringOtherApps: YES];
}

static LightWeightWindow* createWindow(const char* windowName)
{
    LightWeightWindow* window;
    window = [[LightWeightWindow alloc] 
        initWithContentRect: NSMakeRect(0, 0, 0, 0)
        styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView
        backing: NSBackingStoreBuffered
        defer: YES];
    

    if (window == nil) {
        return nil;
    }
    window.contentView = nil;
    window.windowIsOpen = YES;
    window.windowNameAsCString = windowName;

    NSString* nsWindowName = [[NSString alloc] initWithCString: windowName
                                        encoding: NSASCIIStringEncoding];

    if (nsWindowName == nil) {
        return nil;
    }
    [window setTitle: nsWindowName];

    [window center];
    [window makeKeyAndOrderFront: nil];
    [window setFrame: [window frame] display: YES];
    [window setHasShadow: YES];
    [window setAcceptsMouseMovedEvents: YES];
    
    WindowDelegate* delegate = [[WindowDelegate alloc] init];
    [window setDelegate: delegate];

    [windowList addObject: window];

    return window;
}

static LightWeightWindow* findWindow(const char* windowName)
{
    if (windowList == nil) {
        init();
    }
    for (LightWeightWindow* window in windowList) {
        if (strcmp(windowName, window.windowNameAsCString) == 0) {
            return window;
        }
    }
    return nil;
}

// C style function
int imshow_u8_c1(const char* windowName,
                uint8_t* imageData,
                int imageWidth,
                int imageHeight)
{
    // this is sort of how objective C does memory management
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

    const int bufSize = imageWidth * imageHeight;
    
    LightWeightWindow* window = findWindow(windowName);
@autoreleasepool {
    if (window == nil) {
        window = createWindow(windowName);
        if (window == nil) {
            return 1;
        }
    }

    NSPoint origin = [window frame].origin;
    NSRect newWindowFrame = NSMakeRect(0, 0, imageWidth, imageHeight + 24);

    if (!NSEqualRects(newWindowFrame, [window frame])) {
        [window setFrame: newWindowFrame
            display: YES];
    }
    
    NSImageView* imageView = [window contentView];

    if (imageView == nil) {
        printf("Image view was nil\n");
        NSRect imageRect = NSMakeRect(0, 0, imageWidth, imageHeight);
        imageView = [[NSImageView alloc] initWithFrame: imageRect];
        imageView.image = nil;
    }


    if ([imageView image] == nil) {
        printf("Image in image view was nil\n");
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
            [imageView setImage: image];
        }
        [window setContentView: imageView];
    }
    else {
        NSImage* image = [imageView image];
        if ([[image representations] count] >= 1) {
            NSBitmapImageRep* oldImageRep = (NSBitmapImageRep*) [image representations][0];
            memcpy(oldImageRep.bitmapData, imageData, imageWidth * imageHeight);
        }
    }
    
    [imageView setNeedsDisplay];
    [window display];

    NSApplication* app = [NSApplication sharedApplication];

    NSEvent* event =
            [app nextEventMatchingMask: NSEventMaskAny
            untilDate: [NSDate distantPast]
            inMode: NSDefaultRunLoopMode
            dequeue: YES];

    [app sendEvent: event];
    [app updateWindows];
    
    // free everything? I think
    // really not sure if this has thousands of leaks
}
    return window.windowIsOpen == NO;   
}
