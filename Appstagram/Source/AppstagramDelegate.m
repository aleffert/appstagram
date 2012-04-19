//
//  AppstagramDelegate.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramDelegate.h"

#import "AppstagramCommon.h"

#import "CGSPrivate.h"


@interface AppstagramDelegate ()

@property (retain, nonatomic) NSMutableDictionary* filterMap;
@property (retain, nonatomic) NSMenu* filterMenu;
@property (retain, nonatomic) NSStatusItem* statusItem;

@end

@implementation AppstagramDelegate

@synthesize filterMap = mFilterMap;
@synthesize filterMenu = mFilterMenu;
@synthesize statusItem = mStatusItem;

- (NSArray*)filterNames {
    return [NSArray arrayWithObjects:@"Boring", @"Ennui", @"Shootout", @"La Vie en Rose", @"Haze", @"Glow", @"Bushwick", nil];
}

- (void)makeFilterMenu {
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    NSArray* items = [self filterNames];
    for(NSString* item in items) {
        [menu addItemWithTitle:item action:@selector(choseItem:) keyEquivalent:@""];
    }
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@""];
    
    self.filterMenu = menu;
    self.filterMenu.delegate = self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self makeFilterMenu];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"menu-icon"];
    self.statusItem.highlightMode = YES;
    self.statusItem.menu = self.filterMenu;
    self.filterMap = [NSMutableDictionary dictionary];
    
    CGSConnection connection = 0;
    CGSNewConnection(NULL, &connection);
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(filterAnnouncement:) name:AppstagramFilterAnnouncementNotification object:nil];
}

- (void)filterAnnouncement:(NSNotification*)notification {
    NSString* bundleId = notification.object;
    NSString* filterName = [notification.userInfo objectForKey:AppstagramFilterNameKey];
    [self.filterMap setObject:filterName forKey:bundleId];
}

- (NSString*)frontApplicationBundleId {
    return [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];
}

- (void)choseItem:(NSMenuItem*)item {
    NSString* bundleId = [self frontApplicationBundleId];
    [self.filterMap setObject:item.title forKey:bundleId];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:AppstagramChangedNotification object:bundleId userInfo:[NSDictionary dictionaryWithObject:item.title forKey:AppstagramFilterNameKey]];    
}

- (void)quit:(NSMenuItem*)sender {
    [[NSApplication sharedApplication] terminate:self];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSString* currentFilter = [self.filterMap objectForKey:[self frontApplicationBundleId]];
    if(currentFilter == nil) {
        currentFilter = @"Plain";
    }
    
    BOOL foundItem;
    
    for(NSMenuItem* item in menu.itemArray) {
        item.state = [currentFilter isEqualToString:item.title];
        foundItem = foundItem || item.state;
    }
    if(!foundItem) {
        [[menu.itemArray objectAtIndex:0] setState:NSOnState];
    }
}

@end
