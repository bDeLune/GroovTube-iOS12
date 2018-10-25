#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "SimpleImageViewController.h"

@interface SimpleImageAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
    SimpleImageViewController *rootViewController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end
