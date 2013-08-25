//
//  PhiTextSelectionHandle.h
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
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/CALayer.h>

@class PhiTextEditorView;
@class PhiTextRange;
@class PhiTextPosition;

@interface PhiTextSelectionHandle : UIView {
@private
	PhiTextEditorView *owner;
	int handleType;
	CGSize hitSize;
	CGSize proximityDistance;
	CGFloat wordSnapVelocityThreshold;
	UIView *caret;
	PhiTextRange *destinationSelectionRange;
	CGPoint destinationCaretCenter;
	CGRect destinationFrame;
	CFTimeInterval arrivalTimestamp;

	CGRect absoluteBounds;
	CGPoint absoluteCenter;

	UIColor *rimColor;
	UIColor *fillHighColor;
	UIColor *fillLowColor;
	UIColor *glowColor;	
}

@property (nonatomic, assign) PhiTextEditorView *owner;
@property (nonatomic, assign) int handleType;
@property (nonatomic, assign) CGSize hitSize;
@property (nonatomic, assign) CGSize proximityDistance;
@property (nonatomic, assign) CGFloat wordSnapVelocityThreshold;
@property (nonatomic, retain) UIView *caret;
@property (nonatomic, retain) UIColor *rimColor;
@property (nonatomic, retain) UIColor *fillHighColor;
@property (nonatomic, retain) UIColor *fillLowColor;
@property (nonatomic, retain) UIColor *glowColor;

- (void)moveToClosestPositionToPoint:(CGPoint)point inView:(UIView *)view;
/*!
 Returns YES if move animated.
 */
- (BOOL)moveToClosestPositionToPoint:(CGPoint)point withVelocity:(CGPoint)velocity;

- (void)update;

@end
