//
//  main.m
//  install-appstagram
//
//  Created by Akiva Leffert on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BetterAuthorizationSampleLib.h"
#import "AppstagramCommon.h"

static OSStatus AppstagramInstallOSAX(
                              AuthorizationRef			auth,
                              const void *                userData,
                              CFDictionaryRef				request,
                              CFMutableDictionaryRef      response,
                              aslclient                   asl,
                              aslmsg                      aslMsg
                                      ) {
    OSStatus					retval = noErr;
    
	// Pre-conditions
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL
    
    // Retrieve the source path
    CFStringRef srcPath = (CFStringRef)CFDictionaryGetValue(request, (CFStringRef)AppstagramInstallationSourcePathKey);
    
    
	asl_log(asl, aslMsg, ASL_LEVEL_INFO, "Starting installation from %s", [(NSString*)srcPath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/Library/ScriptingAdditions" withIntermediateDirectories:YES attributes:nil error:&error];
    if(error != nil) {
        CFDictionaryAddValue(response, AppstagramInstallationCommandResponseKey, error.localizedDescription);
    }
    
    asl_log(asl, aslMsg, ASL_LEVEL_INFO, "Created Container");

    error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:(NSString*)srcPath toPath:[@"/Library/ScriptingAdditions/" stringByAppendingPathComponent:[(NSString*)srcPath lastPathComponent]] error:&error];
    
    asl_log(asl, aslMsg, ASL_LEVEL_INFO, "Copied File");
    if(error != nil) {
        CFDictionaryAddValue(response, AppstagramInstallationCommandResponseKey, error.localizedDescription);
    }
    
    return retval;
}

int main(int argc, const char * argv[])
{
    BASCommandProc commandProcs[] = {
        AppstagramInstallOSAX,
        NULL
    };

    @autoreleasepool {
        return BASHelperToolMain(AppstagramPrivilegedHelperCommandSet, commandProcs);
    }
    return 0;
}

