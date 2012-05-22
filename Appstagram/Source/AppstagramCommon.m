//
//  AppstagramCommon.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppstagramCommon.h"

NSString* AppstagramFilterAnnouncementNotification = @"AppstagramFilterAnnouncementNotification";
NSString* AppstagramChangedNotification = @"AppstagramChangedNotification";
NSString* AppstagramQuittingNotification = @"AppstagramQuittingNotification";
NSString* AppstagramStartedNotification = @"AppstagramStartedNotification";

NSString* AppstagramFilterNameKey = @"AppstagramFilterNameKey";

NSString* AppstagramInstallationSourcePathKey = @"AppstagramInstallationSourcePathKey";
NSString* AppstagramInstallationCommand = @"AppstagramInstallationCommand";
NSString* AppstagramInstallationCommandResponseKey = @"AppstagramInstallationCommandResponseKey";

const BASCommandSpec AppstagramPrivilegedHelperCommandSet[] = {
    {	"AppstagramInstallationCommand",         // commandName
        "com.ognid.install-appstagram",       // rightName
        "default",                              // rightDefaultRule    -- by default, you have to have admin credentials (see the "default" rule in the authorization policy database, currently "/etc/authorization")
        "AuthInstallCommandLineToolPrompt",				// rightDescriptionKey -- key for custom prompt in "Localizable.strings
        NULL                                    // userData
	},
    
    {	NULL,                                   // the array is null terminated
        NULL, 
        NULL, 
        NULL,
        NULL
	}
};
