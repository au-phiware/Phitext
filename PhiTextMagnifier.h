//
//  PhiTextMagnifier.h
//  FirstCoreText
//
//  Created by Corin Lawson on 16/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
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
