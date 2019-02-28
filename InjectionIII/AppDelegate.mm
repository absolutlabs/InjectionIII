//
//  AppDelegate.mm
//  InjectionIII
//
//  Created by John Holdsworth on 06/11/2017.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//

#import "AppDelegate.h"
#import "SignerService.h"
#import "InjectionServer.h"

//#import "HelperInstaller.h"
//#import "HelperProxy.h"

//#import <Carbon/Carbon.h>
//#import <AppKit/NSEvent.h>
//#import "DDHotKeyCenter.h"

#import "InjectionIII-Swift.h"

#ifdef XPROBE_PORT
#import "../XprobePlugin/Classes/XprobePluginMenuController.h"
#endif

AppDelegate *appDelegate;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *startItem, *xprobeItem, *windowItem;
    IBOutlet NSStatusItem *statusItem;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    appDelegate = self;
    [InjectionServer startServer:INJECTION_ADDRESS];

    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:statusBar.thickness];
    statusItem.toolTip = @"Code Injection";
    statusItem.highlightMode = TRUE;
    statusItem.menu = statusMenu;
    statusItem.enabled = TRUE;
    statusItem.title = @"";

    [self setMenuIcon:@"InjectionIdle"];
#if 0
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKeyWithKeyCode:kVK_ANSI_Equal
                                                     modifierFlags:NSEventModifierFlagControl
                                                            target:self action:@selector(autoInject:) object:nil];
#endif
}

- (IBAction)openProject:sender {
    [self application:NSApp openFile:nil];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSOpenPanel *open = [NSOpenPanel new];
    open.prompt = NSLocalizedString(@"Select Project Directory", @"Project Directory");
    //    open.allowsMultipleSelection = TRUE;
    if (filename)
        open.directory = filename;
    open.canChooseDirectories = TRUE;
    open.canChooseFiles = FALSE;
    //    open.showsHiddenFiles = TRUE;
    if ([open runModal] == NSFileHandlingPanelOKButton) {
        NSArray<NSString *> *fileList = [[NSFileManager defaultManager]
                                         contentsOfDirectoryAtPath:open.URL.path error:NULL];
        if(NSString *projectFile =
           [self fileWithExtension:@"xcworkspace" inFiles:fileList] ?:
           [self fileWithExtension:@"xcodeproj" inFiles:fileList]) {
            self.selectedProject = [open.URL.path stringByAppendingPathComponent:projectFile];
            [self.lastConnection setProject:self.selectedProject];
            [[NSDocumentController sharedDocumentController]
             noteNewRecentDocumentURL:open.URL];
            return TRUE;
        }
    }
    return FALSE;
}

- (NSString * _Nullable)fileWithExtension:(NSString * _Nonnull)extension inFiles:(NSArray * _Nonnull)files {
    for (NSString *file in files)
        if ([file.pathExtension isEqualToString:extension])
            return file;
    return nil;
}

- (void)setMenuIcon:(NSString *)tiffName {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSString *path = [NSBundle.mainBundle pathForResource:tiffName ofType:@"tif"]) {
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
//            image.template = TRUE;
            statusItem.image = image;
            statusItem.alternateImage = statusItem.image;
            // startItem.enabled = [tiffName isEqualToString:@"InjectionIdle"];
            xprobeItem.enabled = !startItem.enabled;
        }
    });
}

- (IBAction)toggleState:(NSMenuItem *)sender {
    sender.state = !sender.state;
}

- (IBAction)autoInject:(NSMenuItem *)sender {
    NSLog(@"---- auto inject ! ----");
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"INJECT_CHANGED_FILES" object:nil];
    
//    [[NSAlert alertWithMessageText: @"Injection Helper"
//                     defaultButton: @"OK" alternateButton:@"Cancel" otherButton:nil
//         informativeTextWithFormat: @"balibump"] runModal];
//    
        
#if 0
    NSError *error = nil;
    // Install helper tool
    if ([HelperInstaller isInstalled] == NO) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([[NSAlert alertWithMessageText:@"Injection Helper"
                             defaultButton:@"OK" alternateButton:@"Cancel" otherButton:nil
                 informativeTextWithFormat:@"InjectionIII needs to install a privileged helper to be able to inject code into "
              "an app running in the iOS simulator. This is the standard macOS mechanism.\n"
              "You can remove the helper at any time by deleting:\n"
              "/Library/PrivilegedHelperTools/com.johnholdsworth.InjectorationIII.Helper.\n"
              "If you'd rather not authorize, patch the app instead."] runModal] == NSAlertAlternateReturn)
            return;
#pragma clang diagnostic pop
        if ([HelperInstaller install:&error] == NO) {
            NSLog(@"Couldn't install Smuggler Helper (domain: %@ code: %d)", error.domain, (int)error.code);
            [[NSAlert alertWithError:error] runModal];
            return;
        }
    }

    // Inject Simulator process
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iOSInjection" ofType:@"bundle"];
    if ([HelperProxy inject:bundlePath error:&error] == FALSE) {
        NSLog(@"Couldn't inject Simulator (domain: %@ code: %d)", error.domain, (int)error.code);
        [[NSAlert alertWithError:error] runModal];
    }
#endif
}

- (IBAction)runXprobe:(NSMenuItem *)sender {
    if (!xprobePlugin) {
        xprobePlugin = [XprobePluginMenuController new];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wnonnull"
        [xprobePlugin applicationDidFinishLaunching:nil];
        #pragma clang diagnostic pop
        xprobePlugin.injectionPlugin = self;
    }
    [self.lastConnection writeString:@"XPROBE"];
    windowItem.hidden = FALSE;
}

- (void)evalCode:(NSString *)swift {
    [self.lastConnection writeString:[@"EVAL " stringByAppendingString:swift]];
}

- (IBAction)donate:sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://johnholdsworth.com/cgi-bin/injection3.cgi"]];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
#if 0
    [[DDHotKeyCenter sharedHotKeyCenter] unregisterHotKeyWithKeyCode:kVK_ANSI_Equal
                                                       modifierFlags:NSEventModifierFlagControl];
#endif
}

@end
