//
//  AppstagramOverlayWindow.h
//  Appstagram
//
//  Created by Akiva Leffert on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface AppstagramOverlayWindow : NSWindow

- (id)initWithParentWindow:(NSWindow*)window;

- (void)useOverlayImage:(NSImage*)image;

@end
