//
//  AppDelegate.m
//  iOSFrameworkExample
//
//  Created by on 2024-12-24.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Create window if it doesn't exist
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // Let the storyboard instantiate the view controller directly
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *rootVC = [mainStoryboard instantiateInitialViewController];
    
    NSLog(@"DEBUG: AppDelegate - Storyboard instantiated view controller with class: %@", NSStringFromClass([rootVC class]));
    
    // Check if it's our custom ViewController
    if ([rootVC isKindOfClass:[ViewController class]]) {
        ViewController *viewController = (ViewController *)rootVC;
        NSLog(@"DEBUG: AppDelegate - View controller is custom ViewController");
        NSLog(@"DEBUG: AppDelegate - activityIndicator outlet: %@", viewController.activityIndicator ? @"connected" : @"not connected");
    } else {
        NSLog(@"DEBUG: AppDelegate - ERROR: Expected ViewController, got %@", NSStringFromClass([rootVC class]));
    }
    
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    
    NSLog(@"DEBUG: AppDelegate - Created window and set root view controller");
    
    NSLog(@"DEBUG: AppDelegate - Created window and set root view controller");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) when the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
