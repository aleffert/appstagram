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
+ (AppstagramFilter*)plainFilter;

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
                   [AppstagramFilter plainFilter], @"Plain",
                   [AppstagramFilter grayscaleFilter], @"Gray",
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

+ (AppstagramFilter*)grayscaleFilter {
    AppstagramFilter* result = [[[AppstagramFilter alloc] init] autorelease];
    CGSWindowFilterRef grayscaleFilter = NULL;
    CGSConnection connection = _CGSDefaultConnection();
    CGSNewCIFilterByName(connection, (CFStringRef)@"CIColorControls", &grayscaleFilter);
	CGSSetCIFilterValuesFromDictionary(connection, grayscaleFilter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"inputSaturation"]);
    
    result.applyBlock = ^(NSWindow* window) {
        CGSAddWindowFilter(connection, (int)window.windowNumber, grayscaleFilter, 1 << 2);
    };
    result.removeBlock = ^(NSWindow* window) {
        CGSRemoveWindowFilter(connection, (int)window.windowNumber, grayscaleFilter);
    };
    result.cleanupBlock = ^ {
        CGSReleaseCIFilter(connection, grayscaleFilter);
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
