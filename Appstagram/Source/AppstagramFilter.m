//
//  AppstagramFilter.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramFilter.h"

#import "AppstagramOverlayWindow.h"
#import "CGSPrivate.h"
#import "NSWindow+AppstagramFilter.h"

typedef void (^WindowBlock)(NSWindow* window);
typedef void (^Block)();

@interface AppstagramFilter ()

@property (copy, nonatomic) WindowBlock applyBlock;
@property (copy, nonatomic) Block cleanupBlock;
@property (copy, nonatomic) WindowBlock removeBlock;

+ (AppstagramFilter*)grayscaleFilter;
+ (AppstagramFilter*)sepiaFilter;
+ (AppstagramFilter*)roseFilter;
+ (AppstagramFilter*)blurFilter;
+ (AppstagramFilter*)paperFilter;
+ (AppstagramFilter*)glowFilter;
+ (AppstagramFilter*)blueRedFilter;
+ (AppstagramFilter*)sunFilter;
+ (AppstagramFilter*)colorblindFilter;
+ (AppstagramFilter*)vibranceFilter;
+ (AppstagramFilter*)peachFilter;

@end

@implementation AppstagramFilter

@synthesize applyBlock = mApplyBlock;
@synthesize cleanupBlock = mCleanupBlock;
@synthesize removeBlock = mRemoveBlock;

+ (NSDictionary*)filterMap {
    static NSDictionary* filters = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        filters = [[NSDictionary alloc] initWithObjectsAndKeys:
                   [AppstagramFilter plainFilter], @"Boring",
                   [AppstagramFilter grayscaleFilter], @"Ennui",
                   [AppstagramFilter sepiaFilter], @"Shootout",
                   [AppstagramFilter roseFilter], @"La Vie en Rose",
                   [AppstagramFilter blurFilter], @"Haze",
                   [AppstagramFilter paperFilter], @"Wastebasket",
                   [AppstagramFilter blueRedFilter], @"Roebling",
                   [AppstagramFilter glowFilter], @"Glow",
                   [AppstagramFilter sunFilter], @"Apollo",
                   [AppstagramFilter colorblindFilter], @"Colorblind",
                   [AppstagramFilter vibranceFilter], @"Spring",
                   [AppstagramFilter peachFilter], @"Cobb",
                   nil];
    });
    return filters;
}



+ (AppstagramFilter*)filterNamed:(NSString*)name {
    return [[self filterMap] objectForKey:name];
}

- (void)dealloc {
    self.cleanupBlock();
    self.cleanupBlock = nil;
    self.applyBlock = nil;
    self.removeBlock = nil;
    [super dealloc];
}

- (void)addOverlayImageNamed:(NSString*)imageName toWindow:(NSWindow*)window {
    AppstagramOverlayWindow* childWindow = window.appstagramOverlayWindow;
    if(childWindow == nil) {
        [[[AppstagramOverlayWindow alloc] initWithParentWindow:window] autorelease];
    }
    
    NSString* imagePath = [[NSBundle bundleForClass:[AppstagramFilter class]] pathForImageResource:imageName];
    NSImage* overlay = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
    [window.appstagramOverlayWindow useOverlayImage:overlay];
}

- (void)removeOverlayWindowFrom:(NSWindow*)window {
    [window.appstagramOverlayWindow removeFromParent];
}

+ (AppstagramFilter*)grayscaleFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIColorControls", &filter);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"inputSaturation"]);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:.8] forKey:@"inputContrast"]);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 1 << 2);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };
    
    return result;
}

+ (AppstagramFilter*)sepiaFilter {
    __block AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CISepiaTone", &filter);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"inputIntensity"]);
    
    result.applyBlock = ^(NSWindow* window) {
        [result addOverlayImageNamed:@"sepia-overlay" toWindow:window];
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 4);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
        [result removeOverlayWindowFrom:window];
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };
    
    return result;
}

+ (AppstagramFilter*)paperFilter {
    __block AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    result.applyBlock = ^(NSWindow* window) {
        [result addOverlayImageNamed:@"paper-overlay" toWindow:window];
    };
    result.removeBlock = ^(NSWindow* window) {
        [result removeOverlayWindowFrom:window];
    };
    result.cleanupBlock = ^ {
    };
    
    return result;
}

+ (AppstagramFilter*)blurFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIBoxBlur", &filter);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:4] forKey:@"inputRadius"]);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 4);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };
    
    return result;
}

+ (AppstagramFilter*)colorblindFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    
    CIVector* rVector = [CIVector vectorWithX:.45 Y:.55 Z:0 W:0];
    CIVector* gVector = [CIVector vectorWithX:.45 Y:.55 Z:0 W:0];
    CIVector* bVector = [CIVector vectorWithX:0 Y:0 Z:1 W:0];
    CIVector* aVector = [CIVector vectorWithX:0 Y:0 Z:0 W:1];
    CIVector* biasVector = [CIVector vectorWithX:0 Y:0 Z:0 W:0];
    
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                rVector.stringRepresentation, @"inputRVector",
                                gVector.stringRepresentation, @"inputGVector",
                                bVector.stringRepresentation, @"inputBVector",
                                aVector.stringRepresentation, @"inputAVector",
                                biasVector.stringRepresentation, @"inputBiasVector",
                                nil];
    
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIColorMatrix", &filter);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)parameters);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 4);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };
    
    return result;
}

+ (AppstagramFilter*)roseFilter {
    __block AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIHeightFieldFromMask", &filter);
    CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.7], @"inputRadius", nil]);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 4);
        [result addOverlayImageNamed:@"rose-overlay" toWindow:window];
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
        [result removeOverlayWindowFrom:window];
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };
    
    return result;
}

+ (AppstagramFilter*)glowFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIEdges", &filter);
    CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:2] forKey:@"inputIntensity"]);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 2);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };
    
    return result;
}

+ (AppstagramFilter*)blueRedFilter {
    __block AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    result.applyBlock = ^(NSWindow* window) {
        [result addOverlayImageNamed:@"bluered-overlay" toWindow:window];
    };
    result.removeBlock = ^(NSWindow* window) {
        [result removeOverlayWindowFrom:window];
    };
    result.cleanupBlock = ^ {
    };
    
    return result;
}

+ (AppstagramFilter*)sunFilter {
    __block AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    result.applyBlock = ^(NSWindow* window) {
        [result addOverlayImageNamed:@"sun-overlay" toWindow:window];
    };
    result.removeBlock = ^(NSWindow* window) {
        [result removeOverlayWindowFrom:window];
    };
    result.cleanupBlock = ^ {
    };
    
    return result;
}


+ (AppstagramFilter*)vibranceFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIVibrance", &filter);
    CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"inputAmount"]);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, filter, 2);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, filter);
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, filter);
    };

    
    return result;
}

+ (AppstagramFilter*)peachFilter {
    
    __block AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    result.applyBlock = ^(NSWindow* window) {
        [result addOverlayImageNamed:@"peach-overlay" toWindow:window];
    };
    result.removeBlock = ^(NSWindow* window) {
        [result removeOverlayWindowFrom:window];
    };
    result.cleanupBlock = ^ {
    };
    
    return result;
}

+ (AppstagramFilter*)plainFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    result.applyBlock = ^(NSWindow* window) {};
    result.removeBlock = ^(NSWindow* window) {};
    result.cleanupBlock = ^{};
    return result;
}

- (void)applyToWindow:(NSWindow*)window {
    self.applyBlock(window);
}

- (void)removeFromWindow:(NSWindow*)window {
    self.removeBlock(window);
}

@end
