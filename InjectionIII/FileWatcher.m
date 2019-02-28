//
//  FileWatcher.m
//  InjectionIII
//
//  Created by John Holdsworth on 08/03/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import "FileWatcher.h"

@implementation FileWatcher {
    FSEventStreamRef fileEvents;
}

static void fileCallback(ConstFSEventStreamRef streamRef,
                         void *clientCallBackInfo,
                         size_t numEvents, void *eventPaths,
                         const FSEventStreamEventFlags eventFlags[],
                         const FSEventStreamEventId eventIds[]) {
    FileWatcher *self = (__bridge FileWatcher *)clientCallBackInfo;
    [self performSelectorOnMainThread: @selector(filesChanged:)
                           withObject: (__bridge id)eventPaths waitUntilDone:NO];
}

- (instancetype)initWithRoot:(NSString *)projectRoot plugin:(InjectionCallback)callback;
{
    if ((self = [super init])) {
        self.callback = callback;
        self.changed = [NSMutableSet new];
        static struct FSEventStreamContext context;
        context.info = (__bridge void *)self;
        fileEvents = FSEventStreamCreate(kCFAllocatorDefault,
                                         fileCallback, &context,
                                         (__bridge CFArrayRef) @[ projectRoot ],
                                         kFSEventStreamEventIdSinceNow, .1,
                                         kFSEventStreamCreateFlagUseCFTypes |
                                         kFSEventStreamCreateFlagFileEvents);
        FSEventStreamScheduleWithRunLoop(fileEvents, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        FSEventStreamStart(fileEvents);
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(inject_changed_files) name:@"INJECT_CHANGED_FILES" object:nil];
    }

    return self;
}

- (void)filesChanged:(NSArray *)changes;
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    

    for (NSString *path in changes){
        if (path.length > 0 && [path rangeOfString: INJECTABLE_PATTERN
                        options: NSRegularExpressionSearch].location != NSNotFound &&
            [path rangeOfString: @"DerivedData/|InjectionProject/|main.mm?$"
                        options: NSRegularExpressionSearch].location == NSNotFound &&
            [fileManager fileExistsAtPath: path]) {
            
            [self.changed addObject: path];
        }

    }
    
}

- (void)dealloc;
{
    FSEventStreamStop(fileEvents);
    FSEventStreamInvalidate(fileEvents);
    FSEventStreamRelease(fileEvents);
}

- (void) inject_changed_files
{
    NSLog(@"INJECT_CHANGED_FILES");
    
    if (self.changed.count > 0) {
        self.callback([[self.changed objectEnumerator] allObjects]);
        [self.changed removeAllObjects];
    }
}



@end
