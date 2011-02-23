//
//  PhiTextSelectionHandle.h
//  FirstCoreText
//
//  Created by Corin Lawson on 19/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

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
