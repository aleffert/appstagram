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

NSString* AppstagramAffectedSandboxesKey = @"AppstagramAffectedSandboxesKey";

@interface AppstagramDelegate ()

@property (retain, nonatomic) NSMutableDictionary* filterMap;
@property (retain, nonatomic) NSMenu* filterMenu;
@property (retain, nonatomic) NSStatusItem* statusItem;
@property (retain, nonatomic) NSMenuItem* openOnLoginItem;

- (void)setStartAtLogin:(BOOL)enabled;

- (void)installComponentsIfNecessary;

@end

@implementation AppstagramDelegate

@synthesize filterMap = mFilterMap;
@synthesize filterMenu = mFilterMenu;
@synthesize openOnLoginItem = mOpenOnLoginItem;
@synthesize statusItem = mStatusItem;

- (NSArray*)filterNames {
    return [NSArray arrayWithObjects:@"Boring", @"Ennui", @"Shootout", @"La Vie en Rose", @"Cobb", @"Haze", @"Wastebasket", @"Apollo", @"Glow", @"Roebling", @"Spring", nil];
}

- (void)makeFilterMenu {
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    NSArray* items = [self filterNames];
    for(NSString* item in items) {
        [menu addItemWithTitle:item action:@selector(choseItem:) keyEquivalent:@""];
    }
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Open on Login" action:@selector(toggleOpenOnLogin:) keyEquivalent:@""];
    self.openOnLoginItem = [menu.itemArray lastObject];
    [menu addItemWithTitle:@"Uninstall…" action:@selector(uninstall:) keyEquivalent:@""];
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
    
    [self installComponentsIfNecessary];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(filterAnnouncement:) name:AppstagramFilterAnnouncementNotification object:nil];
}

- (NSString*)pluginSourcePath {
    return [[NSBundle mainBundle] pathForResource:@"AppstagramSIMBL" ofType:@"bundle"];
}

- (NSString*)bundleName {
    return @"AppstagramSIMBL.bundle";
}

- (NSString*)pluginDestinationPathFromApplicationSupport:(NSString*)appSupportPath {
    NSString* SIMBLPluginsPath = [[appSupportPath stringByAppendingPathComponent:@"SIMBL"] stringByAppendingPathComponent:@"Plugins"];
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:SIMBLPluginsPath withIntermediateDirectories:YES attributes:nil error:&error];
    if(error != nil) {
        [[NSAlert alertWithError:error] runModal];
    }
    
    
    NSString* pluginPath = [SIMBLPluginsPath stringByAppendingPathComponent:[self bundleName]];
    return pluginPath;

}

- (NSString*)pluginDestinationPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths objectAtIndex:0];
    return [self pluginDestinationPathFromApplicationSupport:applicationSupportDirectory];
}

- (NSString*)SIMBLUninstallerPath {
    
    return [[NSBundle mainBundle] pathForResource:@"SIMBL Uninstaller" ofType:@"app"];
}

- (BOOL)isPluginInstalledAtPath:(NSString*)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)isPluginInstalled {
    return [self isPluginInstalledAtPath:[self pluginDestinationPath]];
}

- (NSString*)sandboxPath:(NSString*)bundleId {
    
    NSString* path = [[NSString stringWithFormat:@"~/Library/Containers/%@", bundleId] stringByExpandingTildeInPath];
    return path;
}

- (NSString*)pluginDestinationInSandbox:(NSString*)bundleId {
    NSString* sandboxPath = [self sandboxPath:bundleId];
    NSString* dataPath = [sandboxPath stringByAppendingPathComponent:@"Data"];
    NSString* libraryPath = [dataPath stringByAppendingPathComponent:@"Library"];
    NSString* appSupportPath = [libraryPath stringByAppendingPathComponent:@"Application Support"];
    return [self pluginDestinationPathFromApplicationSupport:appSupportPath];
}

- (BOOL)isPluginInstalledInSandbox:(NSString*)bundleId {
    return [self isPluginInstalledAtPath:[self pluginDestinationInSandbox:bundleId]];
}

- (void)installPluginAtPath:(NSString*)path {
    NSError* error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:[self pluginSourcePath] toPath:path error:&error];
    if(error != nil) {
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
}

- (void)addSandboxToInstallationList:(NSString*)bundleId {
    NSArray* array = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramAffectedSandboxesKey];
    if(array == nil) {
        array = [NSArray array];
    }
    NSArray* newObjects = [array arrayByAddingObject:bundleId];
    [[NSUserDefaults standardUserDefaults] setObject:newObjects forKey:AppstagramAffectedSandboxesKey];
}

- (void)installPluginInSandbox:(NSString*)bundle {
    [self installPluginAtPath:[self pluginDestinationInSandbox:bundle]];
    [self addSandboxToInstallationList:bundle];
}

- (void)installPlugin {
    [self installPluginAtPath:[self pluginDestinationPath]];
}

- (void)uninstallSIMBL {
    [[NSWorkspace sharedWorkspace] openFile:[self SIMBLUninstallerPath]];
}

- (void)uninstallPlugin {
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self pluginDestinationPath] error:&error];
    if(error != nil) {
        [[NSAlert alertWithError:error] runModal];
    }
    NSArray* affectedSandboxes = [[NSUserDefaults standardUserDefaults] objectForKey:AppstagramAffectedSandboxesKey];
    for(NSString* bundleId in affectedSandboxes) {
        [[NSFileManager defaultManager] removeItemAtPath:[self pluginDestinationInSandbox:bundleId] error:NULL];
    }
}

- (void)uninstall:(id)sender {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Are you sure you want to uninstall Appstagram?" defaultButton:@"Uninstall" alternateButton:@"Cancel" otherButton:@"Uninstall SIMBL too" informativeTextWithFormat:@"You will need to log out and log back in for the changes to take effect."];
    NSInteger result = [alert runModal];
    if(result == NSAlertOtherReturn) {
        [self uninstallSIMBL];
    }
    if(result == NSAlertAlternateReturn || result == NSAlertDefaultReturn) {
        [self setStartAtLogin:NO];
        [self uninstallPlugin];
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (void)installPluginIfNecessary {
    if(![self isPluginInstalled]) {
        [self installPlugin];
    }
}

- (BOOL)isSIMBLInstalled {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/ScriptingAdditions/SIMBL.osax"];
}

- (void)installSIMBL {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"SIMBL" ofType:@"pkg"];
    [[NSWorkspace sharedWorkspace] openFile:path];
    [[NSApplication sharedApplication] terminate:self];
}

- (void)askToInstallSIMBL {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Appstagram needs to install SIMBL to work properly. Do you want to install SIMBL now? Once you do that, you will need to log out, log back in, and reopen Appstagram for the changes to take effect." defaultButton:@"Install SIMBL" alternateButton:@"Quit" otherButton:nil informativeTextWithFormat:@"For more information about SIMBL see http://www.culater.net/software/SIMBL/SIMBL.php"];
    NSInteger result = [alert runModal];
    if(result == NSAlertDefaultReturn) {
        [self installSIMBL];
    }
    else {
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (void)installSIMBLIfNecessary {
    if(![self isSIMBLInstalled]) {
        [self askToInstallSIMBL];
    }
}

- (void)installComponentsIfNecessary {
    [self installPluginIfNecessary];
    [self installSIMBLIfNecessary];
}

- (void)filterAnnouncement:(NSNotification*)notification {
    NSString* bundleId = notification.object;
    NSString* filterName = [notification.userInfo objectForKey:AppstagramFilterNameKey];
    [self.filterMap setObject:filterName forKey:bundleId];
}

- (NSString*)frontApplicationBundleId {
    return [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];
}

- (BOOL)isAppSandboxed:(NSString*)bundleId {;
    NSString* path = [self sandboxPath:bundleId];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)attemptToInstallInSandboxedApp:(NSString*)bundleId named:(NSString*)name pid:(pid_t)pid {
    [self installPluginInSandbox:bundleId];
    
    // Taken from SIMBL Agent. Kick off the injection
    SBApplication* app = [SBApplication applicationWithProcessIdentifier:pid];
    
    
	AEEventID eventID = 'load';
    
    [app setSendMode:kAEWaitReply | kAENeverInteract | kAEDontRecord];
	id initReply = [app sendEvent:kASAppleScriptSuite id:kGetAEUT parameters:0];
    if(initReply != nil) {
        NSLog(@"appstagram got init reply: %@", initReply);
    }
    
	// the reply here is of some unknown type - it is not an Objective-C object
	// as near as I can tell because trying to print it using "%@" or getting its
	// class both cause the application to segfault. The pointer value always seems
	// to be 0x10000 which is a bit fishy. It does not seem to be an AEDesc struct
	// either.
	// since we are waiting for a reply, it seems like this object might need to
	// be released - but i don't know what it is or how to release it.
	// NSLog(@"initReply: %p '%64.64s'", initReply, (char*)initReply);
	
	// Inject!
	[app setSendMode:kAENoReply | kAENeverInteract | kAEDontRecord];
	id injectReply = [app sendEvent:'SIMe' id:eventID parameters:0];
    
    if(injectReply != nil) {
        NSLog(@"appstagram got inject reply: %@", injectReply);
    }
}

- (void)choseItem:(NSMenuItem*)item {
    NSRunningApplication* application = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSString* bundleId = application.bundleIdentifier;
    if([self isAppSandboxed:bundleId] && ![self isPluginInstalledInSandbox:bundleId]) {
        [self attemptToInstallInSandboxedApp:bundleId named:application.localizedName pid:application.processIdentifier];
    }
    [self.filterMap setObject:item.title forKey:bundleId];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:AppstagramChangedNotification object:bundleId userInfo:[NSDictionary dictionaryWithObject:item.title forKey:AppstagramFilterNameKey]];
}

- (void)quit:(NSMenuItem*)sender {
    [[NSApplication sharedApplication] terminate:self];
}


// Cribbed from http://stackoverflow.com/questions/815063/how-do-you-make-your-app-open-at-login

- (NSURL *)appURL
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL) willStartAtLogin
{
    NSURL* itemURL = [self appURL];
    Boolean foundIt=false;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
            if (err == noErr) {
                foundIt = CFEqual(URL, itemURL);
                CFRelease(URL);
                
                if (foundIt)
                    break;
            }
        }
        CFRelease(loginItems);
    }
    return (BOOL)foundIt;
}

- (void) setStartAtLogin:(BOOL)enabled
{
    NSURL* itemURL = [self appURL];
    LSSharedFileListItemRef existingItem = NULL;
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
            if (err == noErr) {
                Boolean foundIt = CFEqual(URL, itemURL);
                CFRelease(URL);
                
                if (foundIt) {
                    existingItem = item;
                    break;
                }
            }
        }
        
        if (enabled && (existingItem == NULL)) {
            LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
                                          NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
            
        } else if (!enabled && (existingItem != NULL))
            LSSharedFileListItemRemove(loginItems, existingItem);
        
        CFRelease(loginItems);
    }       
}

- (void)toggleOpenOnLogin:(id)sender {
    [self setStartAtLogin:![self willStartAtLogin]];
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
    
    self.openOnLoginItem.state = [self willStartAtLogin];
}

@end
