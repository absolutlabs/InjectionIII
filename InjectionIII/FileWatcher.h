//
//  FileWatcher.h
//  InjectionIII
//
//  Created by John Holdsworth on 08/03/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import <Foundation/Foundation.h>

#define INJECTABLE_PATTERN @"[^~]\\.(mm?|swift|storyboard|xib)$"

typedef void (^InjectionCallback)(NSArray *filesChanged);

@interface FileWatcher : NSObject

@property(copy) InjectionCallback callback;
@property(strong) NSMutableSet *changed;

- (instancetype)initWithRoot:(NSString *)projectRoot plugin:(InjectionCallback)callback;

@end
