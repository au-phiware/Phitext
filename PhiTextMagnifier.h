//
//  PhiTextMagnifier.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PhiTextMagnifier : UIView {
@private
	//CGSize originalSize;
	UIView *subjectView;
	CGFloat magnification;
	CGRect clippingBounds;
	CGFloat offscreenThreshold;
	UIColor *defaultSubjectBackgoundColor;
	UIColor *glassTintColor;
	//CALayer *loupeLayer;
	BOOL active;
	BOOL rightHandPreferred;
	CGPoint originInSubjectView;
	UIWindow *overlay;
}

@property (nonatomic, retain) UIColor *defaultSubjectBackgoundColor;
@property (nonatomic, retain) UIColor *glassTintColor;
@property (nonatomic, assign) UIView *subjectView;
@property (nonatomic, assign) CGFloat magnification;
@property (nonatomic, assign) CGRect clippingBounds;
@property (nonatomic, assign) CGFloat offscreenThreshold;
@property (nonatomic, assign, getter=isActive) BOOL active;
@property (nonatomic, assign, getter=isRightHandPreferred) BOOL rightHandPreferred;

- (id)initWithOrigin:(CGPoint)origin;
/*! Animates the receiver from zero width and height to current bounds.
 */
- (void)growFromPoint:(CGPoint)pointInSubjectView;
/*! Animates the receiver to zero width and height and specified point.
 */
- (void)shrinkToPoint:(CGPoint)point;

@end
