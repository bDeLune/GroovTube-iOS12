#import "SimpleImageAppDelegate.h"
#import "GCDQueue.h"
#import "FirstViewController.h"

#import "SecondViewController.h"
#import "SplashViewController.h"

@interface SimpleImageAppDelegate ()
{
    UIImageView  *startupImageView;
    NSTimer      *startupTimer;
    SplashViewController *temproot;
}
@end

@implementation SimpleImageAppDelegate


@synthesize window = _window;

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    FirstViewController  *fvc=self.tabBarController.viewControllers[0];
    //[fvc foreground];
    
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    FirstViewController  *fvc=self.tabBarController.viewControllers[0];
    //[fvc background];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    temproot=[[SplashViewController alloc]initWithNibName:@"SplashViewController" bundle:nil];
    self.window.rootViewController = temproot;
    
    //startupImageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Default.png"]];
    // [self.window.rootViewController.view addSubview:startupImageView];
    //  self.tabBarController.view.alpha=0.0;
    [[GCDQueue mainQueue]queueBlock:^{
        //   self.tabBarController.view.alpha=1.0;
        FirstViewController *viewController1;
        SecondViewController*viewController2;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            viewController1 = [[FirstViewController alloc] initWithNibName:@"FirstViewController_iPhone" bundle:nil];
            viewController2 = [[SecondViewController alloc] initWithNibName:@"SecondViewController_iPhone" bundle:nil];
        } else {
            viewController1 = [[FirstViewController alloc] initWithNibName:@"FirstViewController_iPad" bundle:nil];
            viewController2 = [[SecondViewController alloc] initWithNibName:@"SecondViewController_iPad" bundle:nil];
        }
        [viewController2 setSettinngsDelegate:viewController1];
        
        self.tabBarController = [[UITabBarController alloc] init];
        self.tabBarController.viewControllers = @[viewController1, viewController2];
        self.window.rootViewController = self.tabBarController;
        
        [startupImageView removeFromSuperview];
        NSLog(@"gone!!!!!!!");
        
        [viewController1 foreground];
    } afterDelay:6];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end

                    
