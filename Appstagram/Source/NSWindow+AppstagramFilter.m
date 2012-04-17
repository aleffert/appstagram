//
//  NSWindow+AppstagramFilter.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSWindow+AppstagramFilter.h"

#import <objc/runtime.h>

static const NSString* AppstagramFilterKey = @"AppstagramFilterKey";
static const NSString* AppstagramOverlayWindowKey = @"AppstagramOverlayWindowKey";

@implementation NSWindow (AppstagramFilter)

- (void)setAppstagramFilter:(NSArray*)appstagramFilter {
    objc_setAssociatedObject(self, AppstagramFilterKey, appstagramFilter, OBJC_ASSOCIATION_RETAIN);
}

- (AppstagramFilter*)appstagramFilter {
    return objc_getAssociatedObject(self, AppstagramFilterKey);
}

- (void)setAppstagramOverlayWindow:(AppstagramOverlayWindow *)overlayWindow {
    objc_setAssociatedObject(self, AppstagramOverlayWindowKey, overlayWindow, OBJC_ASSOCIATION_RETAIN);
}

- (AppstagramOverlayWindow*)appstagramOverlayWindow {
    return objc_getAssociatedObject(self, AppstagramOverlayWindowKey);
}

@end
