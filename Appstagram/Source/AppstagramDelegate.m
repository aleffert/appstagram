//
//  AppstagramDelegate.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramDelegate.h"

#import "AppstagramCommon.h"
#import "AppstagramFilter.h"

#import "CGSPrivate.h"


@interface AppstagramDelegate ()

@property (retain, nonatomic) NSMenu* filterMenu;
@property (retain, nonatomic) NSStatusItem* statusItem;

@end

@implementation AppstagramDelegate

@synthesize filterMenu = mFilterMenu;
@synthesize statusItem = mStatusItem;

- (void)makeFilterMenu {
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    NSArray* items = [AppstagramFilter filterNames];
    for(NSString* item in items) {
        [menu addItemWithTitle:item action:@selector(choseItem:) keyEquivalent:@""];
    }
    
    [menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@""];
    
    self.filterMenu = menu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self makeFilterMenu];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.title = @"Filter!";
    self.statusItem.menu = self.filterMenu;
    
    CGSConnection connection = 0;
    CGSNewConnection(NULL, &connection);
}

- (NSString*)frontApplicationBundleId {
    return [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];
}

- (void)choseItem:(NSMenuItem*)item {
    NSString* bundleId = [self frontApplicationBundleId];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:AppstagramChangedNotification object:bundleId userInfo:[NSDictionary dictionaryWithObject:item.title forKey:AppstagramFilterNameKey]];    
}

- (void)quit:(NSMenuItem*)sender {
    [[NSApplication sharedApplication] terminate:self];
}

@end
