//
//  PhiColorPatch.h
//  ColorWheel
//
//  Created by Corin Lawson on 25/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhiColorWheelController.h"

@interface PhiColorPatchControl : UIControl <PhiColorWheelResponder> {
	id delegate;
	BOOL didInitColor;
}

@property (nonatomic, retain) UIColor *color;

- (void)editColor:(id)sender animated:(BOOL)animate;
- (IBAction)editColor:(id)sender;
- (BOOL)becomeFirstResponderAnimated:(BOOL)animate;
- (BOOL)resignFirstResponderAnimated:(BOOL)animate;

@end
