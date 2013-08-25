//
//  PhiTextCaretView.h
//  Phitext
//
// Copyright 2013 Corin Lawson
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  With thanks to Phillippe

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/*!
    @class
    @abstract    Displays a blinking caret.
    @discussion  
*/
@interface PhiTextCaretView : UIView {
@private
	UIView<UITextInput> *owner;
	NSTimer *blinkOnTimer;
	NSTimer *blinkOffTimer;
	NSTimeInterval blinkLength;
	NSTimeInterval blinkTranistionDuration;
	NSTimeInterval blinkDelay;
	double blinkOnRatio;
	NSMutableArray *stateStack;
}

@property (nonatomic, assign) UIView<UITextInput> *owner;

/*!
    @method     
    @abstract   Time interval for one blink cycle.
    @discussion  A value of 0.0 or less causes the caret not to blink. Default value is 1.0 second.
*/
@property (nonatomic, assign) NSTimeInterval blinkLength;
/*!
    @method     
    @abstract   Time interval delay before caret starts blinking.
    @discussion The caret is visible during this delay. Default is 0.8 seconds.
*/
@property (nonatomic, assign) NSTimeInterval blinkDelay;
/*!
    @method     
    @abstract   Time interval to fade caret on and off.
    @discussion Default is 0.1 seconds.
*/
@property (nonatomic, assign) NSTimeInterval blinkTranistionDuration;
/*!
    @method     
    @abstract   Proportion of the blinkLength that the caret is on.
    @discussion This property controls the amount of time that the caret is visible.
		A value of 0.5 means that the caret is on for half the blink cycle.
		A value of 0.0 or less turns off the caret.
		A value 1.0 or more causes the caret not to blink.
		Default value is phi, the golden ratio, approx. 0.618.
*/
@property (nonatomic, assign) double blinkOnRatio;

/*!
    @method     
    @abstract   Saves all state property values.
    @discussion 
*/
- (void)saveState;
/*!
 @method     
 @abstract   Restores all previously saved state property values.
 @discussion If no state was previously saved, default values are reinstated.
 */
- (void)restoreState;

@end
