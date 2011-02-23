//
//  PhiColorWheelController.h
//  ColorWheel
//
//  Created by Corin Lawson on 24/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

@protocol PhiColorWheelResponder

- (BOOL)canBecomeFirstResponder;
- (BOOL)becomeFirstResponder;

- (BOOL)canResignFirstResponder;
- (BOOL)resignFirstResponder;

- (BOOL)isFirstResponder;

@end

@class PhiColorWheelView;

@interface PhiColorWheelController : NSObject {
	PhiColorWheelView *wheelView;
	CGSize preferredSize;
	CGSize minimumPreferredSize;
	CGRect constraints;
	CGPoint targetPoint;
	BOOL wheelVisible;
}

+ (PhiColorWheelController *)sharedColorWheelController;

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) PhiColorWheelView *wheelView;

@property (nonatomic, assign, getter=isWheelVisible) BOOL wheelVisible;
-(void)setWheelVisible:(BOOL)visible animated:(BOOL)animate;

-(void)setWheelColor:(CGColorRef)color;

-(CGPoint)targetPointInView:(UIView *)view;
-(void)setTargetPoint:(CGPoint)point inView:(UIView *)view;

-(CGRect)constraintsInView:(UIView *)view;
-(void)setConstraints:(CGRect)constraints inView:(UIView *)view;
-(void)constrainToView:(UIView *)view;

-(CGSize)minimumPreferredSizeInView:(UIView *)view;
-(void)setMinimumPreferredSize:(CGSize)size inView:(UIView *)view;

-(CGSize)preferredSizeInView:(UIView *)view;
-(void)setPreferredSize:(CGSize)size inView:(UIView *)view;

@end
