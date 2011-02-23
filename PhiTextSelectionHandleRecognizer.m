//
//  PhiTextSelectionHandleRecognizer.m
//  Phitext
//
//  Created by Corin Lawson on 24/03/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <objc/runtime.h>
#import "PhiTextSelectionHandleRecognizer.h"
#import "PhiTextEditorView.h"
#import "PhiTextSelectionView.h"
#import "PhiTextSelectionHandle.h"

#define UIGestureRecognizerStateCString(__STATE__) (__STATE__==UIGestureRecognizerStatePossible?"Possible":(__STATE__==UIGestureRecognizerStateBegan?"Began":(__STATE__==UIGestureRecognizerStateChanged?"Changed":(__STATE__==UIGestureRecognizerStateEnded?"Ended":(__STATE__==UIGestureRecognizerStateCancelled?"Cancelled":"Failed")))))

@interface PhiTextSelectionHandleRecognizer ()

- (NSUInteger)countTaps:(NSSet *)touches;

@end

@implementation PhiTextSelectionHandleRecognizer

@synthesize owner, currentHandle, tapCount, gotLongPress, gotMovement, numberOfTouches;
@synthesize maximumNumberOfTouches, minimumNumberOfTouches;
@synthesize allowableMovement, minimumPressDuration;

- (id)initWithTarget:(id)target action:(SEL)action {
	if (self = [super initWithTarget:target action:action]) {
		allowableMovement = 10.0;
		minimumPressDuration = 0.4;
		gotLongPress = NO;
		gotEnoughTaps = NO;
		tooMuchMovement = NO;
		gotMovement = NO;
	}
	return self;
}
- (void)reset {
	[super reset];
	currentHandle = nil;
	gotLongPress = NO;
	gotEnoughTaps = NO;
	tooMuchMovement = NO;
	gotMovement = NO;
	tapCount = 0;
//	firstTouchTime = 0;
//	lastTouchTime = 0;
//	firstScreenLocation = CGPointZero;
//	lastScreenLocation = CGPointZero;
	velocity = CGPointZero;
	previousVelocity = CGPointZero;
}
- (CGPoint)lastLocationInView:(UIView *)view {
	if (view) {
		return [view convertPoint:lastScreenLocation fromView:nil];
	}
	return lastScreenLocation;
}
- (void)fail {
	self.state = UIGestureRecognizerStateFailed;
}

- (void)updateLocationForEvent:(UIEvent *)event {
	CGPoint location;
	NSSet *touches = [event touchesForGestureRecognizer:self];
	numberOfTouches = [touches count];
	lastTouchTime = 0;
	lastScreenLocation = CGPointZero;
	for (UITouch *touch in touches) {
		location = [touch locationInView:nil];
		lastTouchTime = MAX(lastTouchTime, touch.timestamp);
		lastScreenLocation.x += location.x;
		lastScreenLocation.y += location.y;
	}
	lastScreenLocation.x = lastScreenLocation.x / numberOfTouches;
	lastScreenLocation.y = lastScreenLocation.y / numberOfTouches;
}

- (CGPoint)_translationInView:(UIView *)view {
	CGPoint translation = CGPointMake(lastScreenLocation.x - firstScreenLocation.x,
									  lastScreenLocation.y - firstScreenLocation.y);
	if (view) {
		return [view convertPoint:translation fromView:nil];
	}
	return translation;
}
- (CGPoint)translationInView:(UIView *)view {
	if (gotMovement) {
		return [self _translationInView:view];
	}
	return PhiPointNull;
}
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view {
	if (view)
		translation = [view convertPoint:translation fromView:nil];
	firstScreenLocation.x = lastScreenLocation.x - translation.x;
	firstScreenLocation.y = lastScreenLocation.y - translation.y;
	velocity = CGPointZero;
}
- (CGPoint)velocityInView:(UIView *)view {
	if (gotMovement) {
		CGRect mean = CGRectMake(0, 0, (velocity.x + previousVelocity.x) / 2, (velocity.y + previousVelocity.y) / 2);
		if (view) {
			mean = [view convertRect:mean fromView:nil];
		}
		return CGPointMake(mean.size.width, mean.size.height);
	}
	return PhiPointNull;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[%@ touchesBegan:%@ withEvent:%@]...", traceIndent, NSStringFromClass([self class]), touches, event);
#endif
	[super touchesBegan:touches withEvent:event];
	
	[self updateLocationForEvent:event];
	firstTouchTime = lastTouchTime;
	firstScreenLocation = lastScreenLocation;
	
	tapCount = (([self countTaps:touches] - 1) % 4) + 1;
	if (tapCount > 1)
		currentHandle = nil;
	else if ([[owner selectionView] isHandlesShown] && [[[owner selectionView] startHandle] pointInside:[self locationInView:[[owner selectionView] startHandle]] withEvent:event]) {
		currentHandle = [[owner selectionView] startHandle];
	} else if ([[owner selectionView] isHandlesShown] && [[[owner selectionView] endHandle] pointInside:[self locationInView:[[owner selectionView] endHandle]] withEvent:event]) {
		currentHandle = [[owner selectionView] endHandle];
	} else
		currentHandle = nil;
	gotEnoughTaps = YES;
	[self performSelector:@selector(beginLongPress) withObject:nil afterDelay:self.minimumPressDuration];
}
- (void)beginLongPress {
	gotLongPress = YES;
	if (gotEnoughTaps && (currentHandle || !tooMuchMovement || tapCount > 1)) {
		if (self.state == UIGestureRecognizerStatePossible) {
			self.state = UIGestureRecognizerStateBegan;
		}
	} else if (currentHandle == nil) {
		if (self.state == UIGestureRecognizerStatePossible) {
			self.state = UIGestureRecognizerStateFailed;
		} else {
			self.state = UIGestureRecognizerStateCancelled;
		}
	}
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[%@ touchesMoved:%@ withEvent:%@]...", traceIndent, NSStringFromClass([self class]), touches, event);
#endif
	[super touchesMoved:touches withEvent:event];
	
	NSTimeInterval previousTouchTime = lastTouchTime;
	CGPoint previousScreenLocation = lastScreenLocation;
	previousVelocity = velocity;
	[self updateLocationForEvent:event];
	velocity = CGPointMake((lastScreenLocation.x - previousScreenLocation.x) / (lastTouchTime - previousTouchTime),
						   (lastScreenLocation.y - previousScreenLocation.y) / (lastTouchTime - previousTouchTime));

	CGPoint translation = [self _translationInView:[owner selectionView]];
	tooMuchMovement |= hypot(translation.x, translation.y) > self.allowableMovement;
	
	if (self.state == UIGestureRecognizerStatePossible
		&& numberOfTouches >= minimumNumberOfTouches && numberOfTouches <= maximumNumberOfTouches && tooMuchMovement) {
		if (currentHandle || tapCount == 2) {
			gotMovement = YES;
			self.state = UIGestureRecognizerStateBegan;
		} else {
			gotEnoughTaps = NO;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginLongPress) object:nil];
			self.state = UIGestureRecognizerStateFailed;
		}
	} else if (self.state == UIGestureRecognizerStateBegan) {
		self.state = UIGestureRecognizerStateChanged;
	}
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[%@ touchesEnded:%@ withEvent:%@]...", traceIndent, NSStringFromClass([self class]), touches, event);
#endif
	[super touchesEnded:touches withEvent:event];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginLongPress) object:nil];

	//FIXME: This is skating close to Private/Undocumented APIs
	//       but really UIScrollView should prevent this and treat it as a UIControl
	if ([touches count] == 1 && (strncmp((char *)class_getName([[[touches anyObject] view] class]), "UIAutocorrectInlinePrompt", 25) == 0
								 || [[[touches anyObject] view] isKindOfClass:[UIControl class]]
								 )) {
		self.state = UIGestureRecognizerStateFailed;
	}
	if (self.state == UIGestureRecognizerStatePossible) {
		self.state = UIGestureRecognizerStateRecognized;
	}
	if ([touches count] == 1 || ![self countTaps:touches]) {
		gotEnoughTaps = NO;
		self.state = UIGestureRecognizerStateEnded;
	}
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[%@ touchesCancelled:%@ withEvent:%@]...", traceIndent, NSStringFromClass([self class]), touches, event);
#endif
	[super touchesCancelled:touches withEvent:event];
	
	NSTimeInterval previousTouchTime = lastTouchTime;
	CGPoint previousScreenLocation = lastScreenLocation;
	previousVelocity = velocity;
	[self updateLocationForEvent:event];
	velocity = CGPointMake((lastScreenLocation.x - previousScreenLocation.x) / (lastTouchTime - previousTouchTime),
						   (lastScreenLocation.y - previousScreenLocation.y) / (lastTouchTime - previousTouchTime));
}

- (NSUInteger)countTaps:(NSSet *)touches {
	NSUInteger count = 0;
	for (UITouch *touch in touches) {
		count += [touch tapCount];
	}
	return count;
}

@end

