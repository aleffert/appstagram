//
//  AppstagramOverlayWindow.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramOverlayWindow.h"

#import "NSWindow+AppstagramFilter.h"
#import "AppstagramFilterView.h"

@interface AppstagramOverlayWindow ()

@property (retain, nonatomic) AppstagramFilterView* overlayView;

@end

@implementation AppstagramOverlayWindow

@synthesize overlayView = mOverlayView;

- (void)dealloc {
    self.overlayView = nil;
    [super dealloc];
}

- (id)initWithParentWindow:(NSWindow *)window {
    CGRect rect = [window contentRectForFrameRect:window.frame];
    if((self = [super initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO])) {
        NSView* contentView = self.contentView;
        self.overlayView = [[[AppstagramFilterView alloc] initWithFrame:contentView.bounds] autorelease];
        self.overlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.contentView = self.overlayView;
        [window addChildWindow:self ordered:NSWindowAbove];
        [self setAlphaValue:1.];
        window.appstagramOverlayWindow = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentChangedSize:) name:NSWindowDidResizeNotification object:window];
        self.ignoresMouseEvents = YES;
    }
    return self;
}

- (void)removeFromParent {
    self.overlayView.image = nil;
    self.parentWindow.appstagramOverlayWindow = nil;
    [self.parentWindow removeChildWindow:self];
    [self orderOut:nil];
}

- (void)sendEvent:(NSEvent *)theEvent {
    [self.parentWindow sendEvent:theEvent];
}

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)ignoresMouseEvents {
    return YES;
}

- (void)parentChangedSize:(NSNotification*)notification {
    [self setFrame:self.parentWindow.frame display:YES];
}

- (void)useOverlayImage:(NSImage*)image {
    self.overlayView.image = image;
    [self.overlayView setNeedsDisplay:YES];
    [self setFrame:self.parentWindow.frame display:YES];
}

@end
