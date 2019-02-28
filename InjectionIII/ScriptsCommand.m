

#import "ScriptsCommand.h"

#import "AppDelegate.h"


@implementation ScriptsCommand


- (id) performDefaultImplementation
{
    
    NSLog(@"Works at last");
    
    AppDelegate * delegate = ((AppDelegate *)[[NSApplication sharedApplication] delegate]);
    [delegate autoInject: nil];
    
    return nil;
}


@end
