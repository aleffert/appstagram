//
//  AppstagramFilter.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramFilter.h"

#import "CGSPrivate.h"

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
+ (AppstagramFilter*)glowFilter;

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
                   [AppstagramFilter sepiaFilter], @"Wistful",
                   [AppstagramFilter roseFilter], @"La Vie en Rose",
                   [AppstagramFilter blurFilter], @"Haze",
                   [AppstagramFilter glowFilter], @"Glow",
                   nil];
    });
    return filters;
}

+ (NSArray*)filterNames {
    return [NSArray arrayWithObjects:@"Boring", @"Ennui", @"Wistful", @"La Vie en Rose", @"Haze", @"Glow", nil];
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
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CISepiaTone", &filter);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"inputIntensity"]);
    
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

+ (AppstagramFilter*)blurFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIBoxBlur", &filter);
	CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:4] forKey:@"inputRadius"]);
    
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

+ (AppstagramFilter*)roseFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef filter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIFalseColor", &filter);
    CIColor* color1 = [CIColor colorWithRed:255./255. green:217./255. blue:210./255];
    CIColor* color0 = [CIColor colorWithRed:76./255. green:0./255. blue:0./255];
    CGSSetCIFilterValuesFromDictionary(connection, filter, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:color0, @"inputColor0", color1, @"inputColor0", nil]);
    
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
