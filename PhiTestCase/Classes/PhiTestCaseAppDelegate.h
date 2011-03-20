//
//  PhiTestCaseAppDelegate.h
//  PhiTestCase
//
//  Created by Philippe Hausler on 3/28/10.
//  Copyright Philippe Hausler 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhiTestCaseViewController;

@interface PhiTestCaseAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    PhiTestCaseViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet PhiTestCaseViewController *viewController;

@end

