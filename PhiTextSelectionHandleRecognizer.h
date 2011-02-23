//
//  PhiTextSelectionHandleRecognizer.h
//  Phitext
//
//  Created by Corin Lawson on 24/03/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

#ifndef PhiPointNull
#define PhiPointNull CGPointMake(NAN, NAN)
#endif

@class PhiTextEditorView;
@class PhiTextSelectionHandle;

@interface PhiTextSelectionHandleRecognizer : UIGestureRecognizer {
@package
	BOOL gotLongPress;
	BOOL gotEnoughTaps;
	BOOL tooMuchMovement;
	BOOL gotMovement;
	PhiTextEditorView *owner;
	PhiTextSelectionHandle *currentHandle;

	NSUInteger tapCount;
	CGFloat allowableMovement;
	CFTimeInterval minimumPressDuration;

	CGPoint firstScreenLocation;
    CGPoint lastScreenLocation;
    CFTimeInterval firstTouchTime;
    CFTimeInterval lastTouchTime;
    CGPoint velocity;
    CGPoint previousVelocity;
    //CGAffineTransform _transform;
    //NSMutableArray *_touches;
    NSUInteger numberOfTouches;
    NSUInteger maximumNumberOfTouches;
    NSUInteger minimumNumberOfTouches;
    //CGFloat _hysteresis;
	//BOOL _failsPastMaxTouches;
}

@property(nonatomic, assign) PhiTextEditorView *owner;
@property(nonatomic, assign) PhiTextSelectionHandle *currentHandle;
@property(nonatomic, readonly) NSUInteger tapCount;
@property(nonatomic, readonly) NSUInteger numberOfTouches;
@property(nonatomic, readonly, getter=hasLongPressOccurred) BOOL gotLongPress;
@property(nonatomic, readonly, getter=hasMovementOccurred) BOOL gotMovement;
@property(nonatomic) CGFloat allowableMovement;
@property(nonatomic) CFTimeInterval minimumPressDuration;

@property(nonatomic) NSUInteger maximumNumberOfTouches;
@property(nonatomic) NSUInteger minimumNumberOfTouches;
//@property(readonly, nonatomic) CGAffineTransform transform;

- (id)initWithTarget:(id)target action:(SEL)action;
- (void)fail;
- (CGPoint)lastLocationInView:(UIView *)view;
- (void)reset;
- (CGPoint)translationInView:(UIView *)view;
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view;
- (CGPoint)velocityInView:(UIView *)view;
//- (void)setFailsPastMaxTouches:(BOOL)failsPastMaxTouches;
//- (BOOL)failsPastMaxTouches;
//- (void)_setHysteresis:(CGFloat)hysteresis;
//- (float)_hysteresis;
//- (NSInteger)_maximumTouches;

@end
