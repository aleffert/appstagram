//
//  NSWindow+AppstagramFilter.m
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSWindow+AppstagramFilter.h"

#import <objc/runtime.h>

static const NSString* AppstagramFiltersKey;

@implementation NSWindow (AppstagramFilter)

- (void)setAppstagramFilters:(NSArray*)appstagramFilters {
    objc_setAssociatedObject(self, AppstagramFiltersKey, appstagramFilters, OBJC_ASSOCIATION_COPY);
}

- (NSArray*)appstagramFilters {
    return objc_getAssociatedObject(self, AppstagramFiltersKey);
}

@end
