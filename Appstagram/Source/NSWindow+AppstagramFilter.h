//
//  NSWindow+AppstagramFilter.h
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CGSPrivate.h"

@class AppstagramFilter;
@class AppstagramOverlayWindow;

@interface NSWindow (AppstagramFilter)

@property (assign, nonatomic) AppstagramFilter* appstagramFilter;
@property (retain, nonatomic) AppstagramOverlayWindow* appstagramOverlayWindow;

@end
