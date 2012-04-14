//
//  AppstagramFilter.h
//  Appstagram
//
//  Created by Akiva Leffert on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppstagramFilter : NSObject

+ (AppstagramFilter*)filterNamed:(NSString*)name;
+ (NSArray*)filterNames;

+ (AppstagramFilter*)plainFilter;

- (void)applyToWindow:(NSWindow*)window;
- (void)removeFromWindow:(NSWindow*)window;


@end
