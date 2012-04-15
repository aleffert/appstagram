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

@interface AppstagramSIMBL ()
+ (void)useFilterNamed:(NSString*)filterName;
@end

@implementation AppstagramSIMBL

static AppstagramFilter* gCurrentFilter = nil;

+ (void)load
{
    NSLog(@"Loaded appstagram into %@", [[NSRunningApplication currentApplication] bundleIdentifier]);
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFilter:) name:AppstagramChangedNotification object:[[NSRunningApplication currentApplication] bundleIdentifier]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowUpdated:) name:NSWindowDidMoveNotification object:nil];
    
    NSString* filterName = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
    [self useFilterNamed:filterName];
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

+ (void)useFilterNamed:(NSString*)filterName forWindows:(NSArray*)windows {
    [[NSUserDefaults standardUserDefaults] setObject:filterName forKey:AppstagramFilterNameKey];
    AppstagramFilter* filter = [AppstagramFilter filterNamed:filterName];
    if(filter == nil) {
        filter = [AppstagramFilter plainFilter];
    }
    if(![filter isEqual:gCurrentFilter]) {
        [gCurrentFilter release];
        gCurrentFilter = [filter retain];
        for(NSWindow* window in windows) {
            [self setFilters:[NSArray arrayWithObject:filter] forWindow:window];
        }
    }
    
}


+ (void)useFilterNamed:(NSString*)filterName {
    [self useFilterNamed:filterName forWindows:[NSApplication sharedApplication].windows];
}

+ (void)windowUpdated:(NSNotification*)notification {
    NSWindow* window = notification.object;
    NSString* filterName = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
    if(window.appstagramFilters == nil && filterName != nil) {
        [self useFilterNamed:filterName forWindows:[NSArray arrayWithObject:window]];
    }
}

+ (void)changeFilter:(NSNotification*)notification {
    NSString* filterName = [[notification userInfo] objectForKey:AppstagramFilterNameKey];
    [self useFilterNamed:filterName];
}

@end
