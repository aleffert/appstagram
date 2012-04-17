//
//  AppstagramFilterView.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramFilterView.h"

@implementation AppstagramFilterView

@synthesize image = mImage;

- (void)dealloc {
    self.image = nil;
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor clearColor] set];
    NSRectFill(self.bounds);
    NSRect imageRect = NSMakeRect(0, 0, self.image.size.width, self.image.size.height);
    [self.image drawInRect:self.bounds fromRect:imageRect operation:NSCompositeCopy fraction:1.];
}

@end
