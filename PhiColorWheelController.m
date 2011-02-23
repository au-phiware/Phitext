//
//  PhiColorWheelController.m
//  ColorWheel
//
//  Created by Corin Lawson on 24/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiColorWheelController.h"
#import "PhiColorWheelView.h"

@implementation PhiColorWheelController

+ (PhiColorWheelController *)sharedColorWheelController {
	static PhiColorWheelController *sharedColorWheelController = nil;
	if (!sharedColorWheelController) {
		sharedColorWheelController = [[PhiColorWheelController alloc] init];
	}
	return sharedColorWheelController;
}

-(id)init {
	if (self = [super init]) {
		wheelView = nil;
		wheelVisible = NO;
		preferredSize = CGSizeMake(160.0, 260.0);
		minimumPreferredSize = CGSizeMake(150.0, 240.0);
		constraints = CGRectNull;
	}
	return self;
}

- (void)hideColorWheel {
	[self setWheelVisible:NO animated:YES];
}
-(PhiColorWheelView *)wheelView {
	if (!wheelView) {
		wheelView = [[PhiColorWheelView alloc] initWithFrame:CGRectMake(0, 0, preferredSize.width, preferredSize.height)];
		wheelView.hidden = YES;
		//wheelView.exclusiveTouch = YES;
		[wheelView.layer setAnchorPoint:CGPointMake(0.5, 1.0)];
	}
	return wheelView;
}

- (void)resetWheelView {
	if (wheelView) 
		[wheelView release];
	wheelView = nil;
}

-(BOOL)isWheelVisible {
	return wheelVisible;
}
-(void)setWheelVisible:(BOOL)visible {
	[self setWheelVisible:visible animated:NO];
}
-(void)setOrientation {
	PhiColorWheelView *view = self.wheelView;
	CGRect container;
	CGRect frame = CGRectMake(targetPoint.x - preferredSize.width * 0.5, targetPoint.y - preferredSize.height, preferredSize.width, preferredSize.height);
	CGRect minFrame = CGRectMake(targetPoint.x - minimumPreferredSize.width * 0.5, targetPoint.y - minimumPreferredSize.height, minimumPreferredSize.width, minimumPreferredSize.height);
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	CGRect windowFrame = [[[UIApplication sharedApplication] keyWindow] bounds];
	CGRect statusFrame = [[UIApplication sharedApplication] statusBarFrame];
	if (statusFrame.size.height) {
		windowFrame.origin.y += statusFrame.size.height;
		windowFrame.size.height -= statusFrame.size.height;
	}
	if (CGRectEqualToRect(constraints, CGRectNull)) {
		container = CGRectUnion(CGRectMake(targetPoint.x, targetPoint.y, 0, 0), windowFrame);
	} else {
		container = CGRectUnion(CGRectMake(targetPoint.x, targetPoint.y, 0, 0), CGRectIntersection(windowFrame, constraints));
	}

	CGFloat height = MIN(frame.size.height, targetPoint.y - container.origin.y);
	do {
		// Can wedge fit above target?
		if (CGRectContainsRect(container, minFrame)) {
			// Does it need shrinking?
			if (!CGRectContainsRect(container, frame)) {
				frame.size.width = MAX(minFrame.size.width, frame.size.width * frame.size.height / height);
				frame.size.height = height;
				frame.origin = CGPointMake(targetPoint.x - frame.size.width * 0.5, targetPoint.y - frame.size.height);
			}
		}
		if (CGRectContainsRect(container, minFrame) && CGRectContainsRect(container, frame))
			break;
		// Wedge cannot fit above target (too high or too wide)
		CGFloat wedgeAngle;
		// Is wedge just too wide?
		if (height >= minFrame.size.height) {
			// Just lean it against the side
			CGFloat angle;
			if ((CGRectGetMaxX(container) - targetPoint.x) < (targetPoint.x - CGRectGetMinX(container))) {
				// right side
				angle = -asinf((frame.size.width * 0.5 - CGRectGetMaxX(container) + targetPoint.x) / height);
			} else {
				// left side
				angle = asinf((frame.size.width * 0.5 - targetPoint.x + CGRectGetMinX(container)) / height);
			}
			frame.size.height = height;
			transform = CGAffineTransformMakeRotation(angle);
			break;
		} else {
			wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / frame.size.height);
			// Can we still jam it into the top using max height?
			CGFloat minTopAngle = acosf(height / frame.size.height);
			CGFloat minWedgeAngle = 2.0 * asinf(minFrame.size.width * 0.5 / frame.size.height);
			if (minTopAngle + minWedgeAngle < M_PI * 0.5) {
				// Yes (jam to top with max height), left side? TODO: consider left-handers
				if ((targetPoint.x - CGRectGetMinX(container)) >= frame.size.height) {
					// Yes (left side, comfortably), can we use max width?
					if ((minTopAngle + wedgeAngle <= M_PI * 0.5)
						|| (frame.size.height * sinf(minTopAngle + wedgeAngle - M_PI * 0.5) <= CGRectGetMaxY(container) - targetPoint.y)
						) {
						transform = CGAffineTransformMakeRotation(-minTopAngle - 0.5 * wedgeAngle);
					} else {
						// Determine the largest possible width
						frame.size.width = MAX(MIN(frame.size.height * sinf(M_PI * 0.5 - minTopAngle) + CGRectGetMaxY(container) - targetPoint.y,
												   frame.size.width),
											   minFrame.size.width);
						//wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / frame.size.height);
						transform = CGAffineTransformMakeRotation(minTopAngle + asinf(frame.size.width * 0.5 / frame.size.height));
					}
					break;
				} else if((targetPoint.x - CGRectGetMinX(container)) >= (CGRectGetMaxX(container) - targetPoint.x)) {
					// Yes (left side is the biggest), is left side big enough?
					if (frame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (targetPoint.x - CGRectGetMinX(container))) {
						// Determine the largest possible width
						CGFloat d = (targetPoint.x - CGRectGetMinX(container));
						CGFloat a = (d - frame.size.height * sinf(minTopAngle));
						CGFloat b = height - sqrtf(frame.size.height * frame.size.height - d * d);
						frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
												   frame.size.width),
											   minFrame.size.width);
						transform = CGAffineTransformMakeRotation(minTopAngle + asinf(frame.size.width * 0.5 / frame.size.height));
						break;
					}
				} else {
					// No (right side is the biggest), is right side big enough?
					if (frame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (CGRectGetMaxX(container) - targetPoint.x)) {
						// Determine the largest possible width
						CGFloat d = (CGRectGetMaxX(container) - targetPoint.x);
						CGFloat a = (d - frame.size.height * sinf(minTopAngle));
						CGFloat b = height - sqrtf(frame.size.height * frame.size.height - d * d);
						frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
												   frame.size.width),
											   minFrame.size.width);
						transform = CGAffineTransformMakeRotation(minTopAngle + asinf(frame.size.width * 0.5 / frame.size.height));
						break;
					}
				}
			} else {
				// Can we still jam it into the top using min height?
				CGFloat minTopAngle = acosf(height / minFrame.size.height);
				CGFloat minWedgeAngle = 2.0 * asinf(minFrame.size.width * 0.5 / minFrame.size.height);
				if (minTopAngle + minWedgeAngle < M_PI * 0.5) {
					wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / minFrame.size.height);
					// Yes (jam to top with min height), left side? TODO: consider left-handers
					if ((targetPoint.x - CGRectGetMinX(container)) >= minFrame.size.height) {
						// Yes (left side, comfortably), can we use max width?
						if ((minTopAngle + wedgeAngle <= M_PI * 0.5)
							|| (minFrame.size.height * sinf(minTopAngle + wedgeAngle - M_PI * 0.5) <= CGRectGetMaxY(container) - targetPoint.y)
							) {
							transform = CGAffineTransformMakeRotation(-minTopAngle - 0.5 * wedgeAngle);
						} else {
							// Determine the largest possible width
							frame.size.width = MAX(MIN(minFrame.size.height * sinf(M_PI * 0.5 - minTopAngle) + CGRectGetMaxY(container) - targetPoint.y,
													   frame.size.width),
												   minFrame.size.width);
							transform = CGAffineTransformMakeRotation(minTopAngle + asinf(frame.size.width * 0.5 / frame.size.height));
						}
						break;
					} else if((targetPoint.x - CGRectGetMinX(container)) >= (CGRectGetMaxX(container) - targetPoint.x)) {
						// Yes (left side is the biggest), is left side big enough?
						if (minFrame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (targetPoint.x - CGRectGetMinX(container))) {
							// Determine the largest possible width
							CGFloat d = (targetPoint.x - CGRectGetMinX(container));
							CGFloat a = (d - minFrame.size.height * sinf(minTopAngle));
							CGFloat b = height - sqrtf(minFrame.size.height * minFrame.size.height - d * d);
							frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
													   frame.size.width),
												   minFrame.size.width);
							transform = CGAffineTransformMakeRotation(minTopAngle + asinf(frame.size.width * 0.5 / minFrame.size.height));
							break;
						}
					} else {
						// No (right side is the biggest), is right side big enough?
						if (minFrame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (CGRectGetMaxX(container) - targetPoint.x)) {
							// Determine the largest possible width
							CGFloat d = (CGRectGetMaxX(container) - targetPoint.x);
							CGFloat a = (d - minFrame.size.height * sinf(minTopAngle));
							CGFloat b = height - sqrtf(minFrame.size.height * minFrame.size.height - d * d);
							frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
													   frame.size.width),
												   minFrame.size.width);
							transform = CGAffineTransformMakeRotation(-minTopAngle - asinf(frame.size.width * 0.5 / minFrame.size.height));
							break;
						}
					}
				}
			}
		}
		// Can wedge fit below target?
		frame = CGRectMake(targetPoint.x - preferredSize.width * 0.5, targetPoint.y, preferredSize.width, preferredSize.height);
		minFrame = CGRectMake(targetPoint.x - minimumPreferredSize.width * 0.5, targetPoint.y, minimumPreferredSize.width, minimumPreferredSize.height);
		transform = CGAffineTransformMakeRotation(M_PI);
		height = MIN(frame.size.height, CGRectGetMaxY(container) - targetPoint.y);
		if (CGRectContainsRect(container, minFrame)) {
			// Does it need shrinking?
			if (!CGRectContainsRect(container, frame)) {
				frame.size.width = MAX(minFrame.size.width, frame.size.width * frame.size.height / height);
				frame.size.height = height;
				frame.origin = CGPointMake(targetPoint.x - frame.size.width * 0.5, targetPoint.y);
			}
		}
		if (!CGRectContainsRect(container, minFrame) || !CGRectContainsRect(container, frame)) {
			// Wedge cannot fit below target (too high or too wide)
			CGFloat wedgeAngle;
			//wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / height);
			// Is wedge just too wide?
			if (height >= minFrame.size.height) {
				// Just lean it against the side
				CGFloat angle;
				if ((CGRectGetMaxX(container) - targetPoint.x) < (targetPoint.x - CGRectGetMinX(container))) {
					// right side
					angle = -asinf((frame.size.width * 0.5 - CGRectGetMaxX(container) + targetPoint.x) / height);
				} else {
					// left side
					angle = asinf((frame.size.width * 0.5 - targetPoint.x + CGRectGetMinX(container)) / height);
				}
				frame.size.height = height;
				transform = CGAffineTransformMakeRotation(M_PI - angle);
				break;
			} else {
				wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / frame.size.height);
				// Can we still jam it into the bottom using max height?
				CGFloat minTopAngle = acosf(height / frame.size.height);
				CGFloat minWedgeAngle = 2.0 * asinf(minFrame.size.width * 0.5 / frame.size.height);
				if (minTopAngle + minWedgeAngle < M_PI * 0.5) {
					// Yes (jam to top with max height), left side? TODO: consider left-handers
					if ((targetPoint.x - CGRectGetMinX(container)) >= frame.size.height) {
						// Yes (left side, comfortably), can we use max width?
						if ((minTopAngle + wedgeAngle <= M_PI * 0.5)
							|| (frame.size.height * sinf(minTopAngle + wedgeAngle - M_PI * 0.5) <= targetPoint.y - CGRectGetMinY(container))
							) {
							transform = CGAffineTransformMakeRotation(M_PI - (minTopAngle + 0.5 * wedgeAngle));
						} else {
							// Determine the largest possible width
							frame.size.width = MAX(MIN(frame.size.height * sinf(M_PI * 0.5 - minTopAngle) + targetPoint.y - CGRectGetMinY(container),
													   frame.size.width),
												   minFrame.size.width);
							//wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / frame.size.height);
							transform = CGAffineTransformMakeRotation(M_PI - (minTopAngle + asinf(frame.size.width * 0.5 / frame.size.height)));
						}
						break;
					} else if((targetPoint.x - CGRectGetMinX(container)) >= (CGRectGetMaxX(container) - targetPoint.x)) {
						// Yes (left side is the biggest), is left side big enough?
						if (frame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (targetPoint.x - CGRectGetMinX(container))) {
							// Determine the largest possible width
							CGFloat d = (targetPoint.x - CGRectGetMinX(container));
							CGFloat a = (d - frame.size.height * sinf(minTopAngle));
							CGFloat b = height - sqrtf(frame.size.height * frame.size.height - d * d);
							frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
													   frame.size.width),
												   minFrame.size.width);
							transform = CGAffineTransformMakeRotation(M_PI - (minTopAngle + asinf(frame.size.width * 0.5 / frame.size.height)));
							break;
						}
					} else {
						// No (right side is the biggest), is right side big enough?
						if (frame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (CGRectGetMaxX(container) - targetPoint.x)) {
							// Determine the largest possible width
							CGFloat d = (CGRectGetMaxX(container) - targetPoint.x);
							CGFloat a = (d - frame.size.height * sinf(minTopAngle));
							CGFloat b = height - sqrtf(frame.size.height * frame.size.height - d * d);
							frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
													   frame.size.width),
												   minFrame.size.width);
							transform = CGAffineTransformMakeRotation(M_PI - (-minTopAngle - asinf(frame.size.width * 0.5 / frame.size.height)));
							break;
						}
					}
				} else {
					// Can we still jam it into the bottom using min height?
					CGFloat minTopAngle = acosf(height / minFrame.size.height);
					CGFloat minWedgeAngle = 2.0 * asinf(minFrame.size.width * 0.5 / minFrame.size.height);
					if (minTopAngle + minWedgeAngle < M_PI * 0.5) {
						wedgeAngle = 2.0 * asinf(frame.size.width * 0.5 / minFrame.size.height);
						// Yes (jam to top with min height), left side? TODO: consider left-handers
						if ((targetPoint.x - CGRectGetMinX(container)) >= minFrame.size.height) {
							// Yes (left side, comfortably), can we use max width?
							if ((minTopAngle + wedgeAngle <= M_PI * 0.5)
								|| (minFrame.size.height * sinf(minTopAngle + wedgeAngle - M_PI * 0.5) <= targetPoint.y - CGRectGetMinY(container))
								) {
								transform = CGAffineTransformMakeRotation(M_PI - (minTopAngle + 0.5 * wedgeAngle));
							} else {
								// Determine the largest possible width
								frame.size.width = MAX(MIN(minFrame.size.height * sinf(M_PI * 0.5 - minTopAngle) + targetPoint.y - CGRectGetMinY(container),
														   frame.size.width),
													   minFrame.size.width);
								transform = CGAffineTransformMakeRotation(M_PI - (minTopAngle + asinf(frame.size.width * 0.5 / minFrame.size.height)));
							}
							break;
						} else if((targetPoint.x - CGRectGetMinX(container)) >= (CGRectGetMaxX(container) - targetPoint.x)) {
							// Yes (left side is the biggest), is left side big enough?
							if (minFrame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (targetPoint.x - CGRectGetMinX(container))) {
								// Determine the largest possible width
								CGFloat d = (targetPoint.x - CGRectGetMinX(container));
								CGFloat a = (d - minFrame.size.height * sinf(minTopAngle));
								CGFloat b = height - sqrtf(minFrame.size.height * minFrame.size.height - d * d);
								frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
														   frame.size.width),
													   minFrame.size.width);
								transform = CGAffineTransformMakeRotation(M_PI - (minTopAngle + asinf(frame.size.width * 0.5 / minFrame.size.height)));
								break;
							}
						} else {
							// No (right side is the biggest), is right side big enough?
							if (minFrame.size.height * cosf(M_PI * 0.5 - minTopAngle - minWedgeAngle) <= (CGRectGetMaxX(container) - targetPoint.x)) {
								// Determine the largest possible width
								CGFloat d = (CGRectGetMaxX(container) - targetPoint.x);
								CGFloat a = (d - minFrame.size.height * sinf(minTopAngle));
								CGFloat b = height - sqrtf(minFrame.size.height * minFrame.size.height - d * d);
								frame.size.width = MAX(MIN(sqrtf(a * a + b * b),
														   frame.size.width),
													   minFrame.size.width);
								transform = CGAffineTransformMakeRotation(M_PI - (-minTopAngle - asinf(frame.size.width * 0.5 / minFrame.size.height)));
								break;
							}
						}
					}
				}
			}
		}
	} while (NO);
	frame.origin = CGPointZero;
	view.bounds = frame;
	view.center = targetPoint;
	view.transform = transform;
}
-(void)setWheelVisible:(BOOL)visible animated:(BOOL)animate {
	PhiColorWheelView *view = self.wheelView;
	if (visible) {
		if (!wheelVisible || !animate) {
			[[[UIApplication sharedApplication] keyWindow] addSubview:view];
			[self setOrientation];
			if (animate) {
				view.alpha = 0.0;
				[UIView beginAnimations:@"phiShowColorWheel" context:nil];
				[UIView setAnimationDuration:0.3];
				view.hidden = NO;
				view.alpha = 1.0;
				[UIView commitAnimations];
			} else {
				view.hidden = NO;
				view.alpha = 1.0;
			}
		} else {
			[UIView beginAnimations:@"phiMoveColorWheel" context:nil];
			[UIView setAnimationDuration:0.3];
			[self setOrientation];
			[UIView commitAnimations];
		}
		if (!wheelVisible) {
			wheelVisible = YES;
			if ([self.delegate conformsToProtocol:@protocol(PhiColorWheelResponder)]
					&& ![self.delegate isFirstResponder] && [self.delegate canBecomeFirstResponder])
				[self.delegate becomeFirstResponder];
		}
	} else {
		if (wheelVisible) {
			if (animate) {
				[UIView beginAnimations:@"phiHideColorWheel" context:nil];
				[UIView setAnimationDuration:0.3];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
				view.hidden = YES;
				view.alpha = 0.0;
				[UIView commitAnimations];
			} else {
				view.hidden = YES;
			}
			[view removeFromSuperview];
			wheelVisible = NO;
			if ([self.delegate conformsToProtocol:@protocol(PhiColorWheelResponder)]
					&& [self.delegate isFirstResponder] && [self.delegate canResignFirstResponder])
				[self.delegate resignFirstResponder];
			[view setDelegate:nil];
		}
	}
	//wheelView.exclusiveTouch = wheelVisible;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([animationID isEqual:@"phiHideColorWheel"]) {
		if (wheelVisible) {
			PhiColorWheelView *view = self.wheelView;
			view.alpha = 0.0;
			[UIView beginAnimations:@"phiShowColorWheel" context:nil];
			[UIView setAnimationDuration:0.3];
			view.hidden = NO;
			view.alpha = 1.0;
			[UIView commitAnimations];
		}
	}
}

-(void)setWheelColor:(CGColorRef)color {
	[self.wheelView setBaseAndAddColorForColor:color];
}

-(CGPoint)targetPointInView:(UIView *)view {
	return view?[view convertPoint:targetPoint fromView:nil]:targetPoint;
}
-(void)setTargetPoint:(CGPoint)point inView:(UIView *)view{
	targetPoint = view?[view convertPoint:point toView:nil]:point;
}

-(CGRect)constraintsInView:(UIView *)view {
	return view?[view convertRect:constraints fromView:nil]:constraints;
}
-(void)setConstraints:(CGRect)rect inView:(UIView *)view {
	constraints = view?[view convertRect:rect toView:nil]:rect;
}
-(void)constrainToView:(UIView *)view {
	if (!view)
		constraints = CGRectNull;
	else
		constraints = [view convertRect:view.bounds toView:nil];
}

-(CGSize)minimumPreferredSizeInView:(UIView *)view {
	return view?[view convertRect:CGRectMake(0, 0, minimumPreferredSize.width, minimumPreferredSize.height) fromView:nil].size:minimumPreferredSize;
}
-(void)setMinimumPreferredSize:(CGSize)size inView:(UIView *)view {
	minimumPreferredSize = view?[view convertRect:CGRectMake(0, 0, size.width, size.height) fromView:nil].size:size;
}

-(CGSize)preferredSizeInView:(UIView *)view {
	return view?[view convertRect:CGRectMake(0, 0, preferredSize.width, preferredSize.height) fromView:nil].size:preferredSize;
}
-(void)setPreferredSize:(CGSize)size inView:(UIView *)view {
	preferredSize = view?[view convertRect:CGRectMake(0, 0, size.width, size.height) fromView:nil].size:size;
}

- (id)delegate {
	return [self.wheelView delegate];
}

- (void)setDelegate:(id)delegate {
	[self.wheelView setDelegate:delegate];
}

- (void)dealloc {
	if (wheelView) 
		[wheelView release];
	wheelView = nil;
	
	[super dealloc];
}
@end
