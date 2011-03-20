//
//  PhiTestCaseAppDelegate.m
//  PhiTestCase
//
//  Created by Philippe Hausler on 3/28/10.
//  Copyright Philippe Hausler 2010. All rights reserved.
//

#import "PhiTestCaseAppDelegate.h"
#import "PhiTestCaseViewController.h"

@implementation PhiTestCaseAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    // Override point for customization after app launch
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	[application setApplicationSupportsShakeToEdit:YES];

	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
