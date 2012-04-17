//
//  NSWindow+AppstagramFilter.h
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CGSPrivate.h"

@class AppstagramOverlayWindow;

@interface NSWindow (AppstagramFilter)

@property (assign, nonatomic) NSArray* appstagramFilters;
@property (retain, nonatomic) AppstagramOverlayWindow* appstagramOverlayWindow;

@end
