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
#import "AppstagramOverlayWindow.h"
#import "CGSPrivate.h"
#import "NSWindow+AppstagramFilter.h"

@interface AppstagramSIMBL ()
- (void)useFilterNamed:(NSString*)filterName;
@end

@implementation AppstagramSIMBL

+ (void)load
{
    static dispatch_once_t onceToken;
    static AppstagramSIMBL* controller = nil;
    dispatch_once(&onceToken, ^{
        NSLog(@"Loaded appstagram into %@", [[NSRunningApplication currentApplication] bundleIdentifier]);
        controller = [[AppstagramSIMBL alloc] init];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:controller selector:@selector(changeFilter:) name:AppstagramChangedNotification object:[[NSRunningApplication currentApplication] bundleIdentifier]];
        
        [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(windowUpdated:) name:NSWindowDidUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(windowUpdated:) name:NSWindowDidBecomeMainNotification object:nil];
        
        NSString* filterName = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
        [controller useFilterNamed:filterName];

    });
}

- (void)setFilter:(AppstagramFilter*)filter forWindow:(NSWindow*)window {
    if(![window isKindOfClass:[AppstagramOverlayWindow class]]) {
        AppstagramFilter* currentFilter = window.appstagramFilter;
        if(![currentFilter isEqual:filter]) {
            @synchronized(self) {
                [currentFilter removeFromWindow:window];
                [filter applyToWindow:window];
                window.appstagramFilter = filter;
            }
        }
    }
}

- (void)useFilterNamed:(NSString*)filterName forWindows:(NSArray*)windows {
    [[NSUserDefaults standardUserDefaults] setObject:filterName forKey:AppstagramFilterNameKey];
    AppstagramFilter* filter = [AppstagramFilter filterNamed:filterName];
    if(filter == nil) {
        filter = [AppstagramFilter plainFilter];
    }
    for(NSWindow* window in windows) {
        [self setFilter:filter forWindow:window];
    }
    
}


- (void)useFilterNamed:(NSString*)filterName {
    [self useFilterNamed:filterName forWindows:[NSApplication sharedApplication].windows];
}

- (void)windowUpdated:(NSNotification*)notification {
    NSWindow* window = notification.object;
    NSString* filterName = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
    if(filterName != nil) {
        [self useFilterNamed:filterName forWindows:[NSArray arrayWithObject:window]];
    }
}

- (void)changeFilter:(NSNotification*)notification {
    NSString* filterName = [[notification userInfo] objectForKey:AppstagramFilterNameKey];
    [self useFilterNamed:filterName];
}

@end
