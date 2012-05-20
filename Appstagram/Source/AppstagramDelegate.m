//
//  AppstagramDelegate.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramDelegate.h"

#import "AppstagramCommon.h"
#import "BetterAuthorizationSampleLib.h"

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
    
    for(NSRunningApplication* application in [[NSWorkspace sharedWorkspace] runningApplications]) {
        [self injectIntoApp:application.bundleIdentifier named:application.localizedName pid:application.processIdentifier];
    }
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(filterAnnouncement:) name:AppstagramFilterAnnouncementNotification object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appOpened:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
}

- (void)appOpened:(NSNotification*)notification {
    NSRunningApplication* app = [notification.userInfo objectForKey:NSWorkspaceApplicationKey];
    [self injectIntoApp:app.bundleIdentifier named:app.localizedName pid:app.processIdentifier];
}

- (NSString*)pluginSourcePath {
    return [[NSBundle mainBundle] pathForResource:@"AppstagramOSAX" ofType:@"osax"];
}

- (NSString*)pluginDestinationPath {
    return @"/Library/ScriptingAdditions/AppstagramOSAX.osax";
}

- (BOOL)isPluginInstalledAtPath:(NSString*)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)isPluginInstalled {
    return [self isPluginInstalledAtPath:[self pluginDestinationPath]];
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;
{
	BOOL result = NO;
    
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				| 
    kAuthorizationFlagInteractionAllowed	|
    kAuthorizationFlagPreAuthorize			|
    kAuthorizationFlagExtendRights;
    
	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
		NSLog(@"Failed to create AuthorizationRef, return code %i", status);
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, (CFErrorRef *)error);
	}
    
    AuthorizationFree(authRef, kAuthorizationFlagDefaults);
	
	return result;
}

// Via http://www.stevestreeting.com/2012/03/05/follow-up-os-x-privilege-escalation-without-using-deprecated-methods/
- (BOOL)helperInstallPlugin:(NSString*)pluginPath authorization:(AuthorizationRef)auth {
    OSStatus err = noErr;
    NSString* bundleID = @"com.appstagram.install-appstagram";
    CFDictionaryRef response = NULL;
    
    NSDictionary* request = [NSDictionary dictionaryWithObjectsAndKeys:
               AppstagramInstallationCommand, @kBASCommandKey, 
               pluginPath, AppstagramInstallationSourcePathKey, nil];
    
    // Execute it.
    
	err = BASExecuteRequestInHelperTool(auth, AppstagramPrivilegedHelperCommandSet, (CFStringRef) bundleID, (CFDictionaryRef) request, &response);
    
    // If the above went OK, it means that the IPC to the helper tool worked.  We 
    // now have to check the response dictionary to see if the command's execution 
    // within the helper tool was successful.   
    
    if (err == noErr) {
        err = BASGetErrorFromResponse(response);
        
        NSString* respStr =  [(NSDictionary *)response objectForKey:AppstagramInstallationCommandResponseKey];
        
        
        if(respStr == nil) {
            [NSAlert alertWithMessageText:@"Installation succeeded! You will need to log out and log back in for the changes to take effect." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        }
        else {
            [NSAlert alertWithMessageText:respStr defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        }
        [[NSApplication sharedApplication] terminate:self];
    }
    
    if (response) 
        CFRelease(response);
    
    return (err == noErr);
}

// Via http://www.stevestreeting.com/2012/03/05/follow-up-os-x-privilege-escalation-without-using-deprecated-methods/
- (void)installPlugin {
    NSError* error = nil;
    [self blessHelperWithLabel:@"com.ognid.install-appstagram" error:&error];
    if(error != nil) {
        [[NSAlert alertWithError:error] runModal];
        [[NSApplication sharedApplication] terminate:self];
    }
    else {
        // The helper is installed. Execute it
        AuthorizationRef auth;
        if (AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &auth)) {
            [NSAlert alertWithMessageText:@"Unable to create authorization." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [[NSApplication sharedApplication] terminate:self];
        }
    	
        BASSetDefaultRules(auth, 
                           AppstagramPrivilegedHelperCommandSet, 
                           CFBundleGetIdentifier(CFBundleGetMainBundle()), 
                           NULL); // No separate strings file, use Localizable.strings
        [self helperInstallPlugin:[self pluginSourcePath] authorization:auth];
    }
}

- (void)uninstallPlugin {
    // TODO spawn uninstaller
}

- (void)uninstall:(id)sender {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Are you sure you want to uninstall Appstagram?" defaultButton:@"Uninstall" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"You will need to log out and log back in for the changes to take effect."];
    NSInteger result = [alert runModal];
    if(result == NSAlertDefaultReturn) {
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

- (void)installComponentsIfNecessary {
    [self installPluginIfNecessary];
}

- (void)filterAnnouncement:(NSNotification*)notification {
    NSString* bundleId = notification.object;
    NSString* filterName = [notification.userInfo objectForKey:AppstagramFilterNameKey];
    [self.filterMap setObject:filterName forKey:bundleId];
}

- (NSString*)frontApplicationBundleId {
    return [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];
}

- (void)injectIntoApp:(NSString*)bundleId named:(NSString*)name pid:(pid_t)pid {
    if(pid == [NSRunningApplication currentApplication].processIdentifier || bundleId == nil) {
        return;
    }
    // Taken from SIMBL Agent. Kick off the injection
    SBApplication* app = [SBApplication applicationWithProcessIdentifier:pid];
    
	AEEventID eventID = 'load';
    
    [app setTimeout:30];
    NSLog(@"injecting into %@", bundleId);
    [app setSendMode:kAENoReply | kAENeverInteract | kAEDontRecord];
	id initReply = [app sendEvent:kASAppleScriptSuite id:kGetAEUT parameters:0];
    if(initReply != nil) {
        NSLog(@"appstagram got init reply: %@", initReply);
    }
	
	// Inject!
	[app setSendMode:kAENoReply | kAENeverInteract | kAEDontRecord];
	id injectReply = [app sendEvent:'OGND' id:eventID parameters:0];
    
    if(injectReply != nil) {
        NSLog(@"appstagram got inject reply: %@", injectReply);
    }
}

- (void)choseItem:(NSMenuItem*)item {
    NSRunningApplication* application = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSString* bundleId = application.bundleIdentifier;
    [self.filterMap setObject:item.title forKey:bundleId];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:AppstagramChangedNotification object:bundleId userInfo:[NSDictionary dictionaryWithObject:item.title forKey:AppstagramFilterNameKey]];
}

- (void)quit:(NSMenuItem*)sender {
    [[NSApplication sharedApplication] terminate:self];
}



- (NSURL *)appURL
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

// Cribbed from http://stackoverflow.com/questions/815063/how-do-you-make-your-app-open-at-login

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
