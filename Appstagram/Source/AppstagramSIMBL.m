//
//  AppstagramSIMBL.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramSIMBL.h"

#import "AppstagramCommon.h"
#import "AppstagramFilter.h"
#import "CGSPrivate.h"
#import "NSWindow+AppstagramFilter.h"

@implementation AppstagramSIMBL

static AppstagramFilter* gCurrentFilter = nil;

+ (void)load
{
    
    NSLog(@"Loaded appstagram into %@", [[NSRunningApplication currentApplication] bundleIdentifier]);
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFilter:) name:AppstagramChangedNotification object:[[NSRunningApplication currentApplication] bundleIdentifier]];
}

+ (void)setFilters:(NSArray*)filters forWindow:(NSWindow*)window {
    NSMutableArray* filtersToApply = [NSMutableArray arrayWithArray:filters];
    for(AppstagramFilter* filter in window.appstagramFilters) {
        if([filters containsObject:filter]) {
            [filtersToApply removeObject:filter];
        }
        else {
            [filter removeFromWindow:window];
        }
    }
    for(AppstagramFilter* filter in filtersToApply) {
        [filter applyToWindow:window];
    }
    window.appstagramFilters = filters;
}

+ (void)changeFilter:(NSNotification*)notification {
    NSString* filterName = [[notification userInfo] objectForKey:AppstagramFilterNameKey];
    NSLog(@"setting filter named : %@,", filterName);
    [gCurrentFilter release];
    AppstagramFilter* filter = [AppstagramFilter filterNamed:filterName];
    gCurrentFilter = [filter retain];
    for(NSWindow* window in [NSApplication sharedApplication].windows) {
        NSLog(@"filtering window %@ with %@", window, filter);
        [self setFilters:[NSArray arrayWithObject:filter] forWindow:window];
    }
}

@end
