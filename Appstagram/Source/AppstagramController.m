//
//  AppstagramController.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramController.h"

#import "AppstagramCommon.h"
#import "AppstagramFilter.h"
#import "AppstagramOverlayWindow.h"
#import "CGSPrivate.h"
#import "NSWindow+AppstagramFilter.h"

@interface AppstagramController ()
@property (assign) BOOL appstagramRunning;
- (void)useFilterNamed:(NSString*)filterName;
- (void)sendFilterAnnouncement;
@end

OSErr InjectAppstagram(const AppleEvent *ev, AppleEvent *reply, long refcon);

OSErr InjectAppstagram(const AppleEvent *ev, AppleEvent *reply, long refcon)
{
    OSErr resultCode = noErr;
    [AppstagramController load];
	return resultCode;
}

@implementation AppstagramController

@synthesize appstagramRunning = _appstagramRunning;

+ (void)load
{
    static dispatch_once_t onceToken;
    static AppstagramController* controller = nil;
    dispatch_once(&onceToken, ^{
        NSLog(@"Loaded appstagram into %@", [[NSRunningApplication currentApplication] bundleIdentifier]);
        controller = [[AppstagramController alloc] init];
        controller.appstagramRunning = YES;
        [[NSDistributedNotificationCenter defaultCenter] addObserver:controller selector:@selector(changeFilter:) name:AppstagramChangedNotification object:[[NSRunningApplication currentApplication] bundleIdentifier]];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:controller selector:@selector(appstagramQuitting:) name:AppstagramQuittingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(windowUpdated:) name:NSWindowDidUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(windowUpdated:) name:NSWindowDidBecomeMainNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(becameFrontApp:) name:NSApplicationWillBecomeActiveNotification object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:controller selector:@selector(appstagramStarted:) name:AppstagramStartedNotification object:nil];
        
        NSString* filterName = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
        [controller useFilterNamed:filterName];
        [controller sendFilterAnnouncement];

    });
}

- (void)sendFilterAnnouncement {
    NSString* currentFilter = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
    if(currentFilter != nil) {
        NSString* bundleId = [[NSRunningApplication currentApplication] bundleIdentifier];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:currentFilter forKey:AppstagramFilterNameKey];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:AppstagramFilterAnnouncementNotification object:bundleId userInfo:userInfo];
    }
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

- (void)becameFrontApp:(NSNotification*)notification {
    [self sendFilterAnnouncement];
}

- (void)useFilterNamed:(NSString*)filterName forWindows:(NSArray*)windows {
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
    if(filterName != nil && self.appstagramRunning) {
        [self useFilterNamed:filterName forWindows:[NSArray arrayWithObject:window]];
    }
}

- (void)changeFilter:(NSNotification*)notification {
    NSString* filterName = [[notification userInfo] objectForKey:AppstagramFilterNameKey];
    [[NSUserDefaults standardUserDefaults] setObject:filterName forKey:AppstagramFilterNameKey];
    [self useFilterNamed:filterName];
}

- (void)appstagramStarted:(NSNotification*)notification {
    self.appstagramRunning = YES;
    NSString* filterName = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramFilterNameKey];
    [self useFilterNamed:filterName];
    [self sendFilterAnnouncement];
}

- (void)appstagramQuitting:(NSNotification*)notification {
    self.appstagramRunning = NO;
    [self useFilterNamed:nil];
}

@end
