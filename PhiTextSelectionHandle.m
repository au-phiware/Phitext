//
//  PhiTextSelectionHandle.m
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

#import "PhiTextSelectionHandle.h"
#import "PhiTextEditorView.h"
#import "PhiTextRange.h"
#import "PhiTextPosition.h"

@interface PhiTextSelectionHandle ()

- (void)initSubviews;

@end


@implementation PhiTextSelectionHandle

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	CFNumberRef aNumberValue;
	CFMutableArrayRef anArray;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("handleGlowRGBAColorComponents"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		anArray = CFArrayCreateMutable(NULL, 2, &kCFTypeArrayCallBacks);
		aFloat = 14.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("handleSize"), anArray, suiteName);
		CFRelease(anArray);
		
		anArray = CFArrayCreateMutable(NULL, 2, &kCFTypeArrayCallBacks);
		aFloat = 80.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("handleHitSize"), anArray, suiteName);
		CFRelease(anArray);
		
		aFloat = 61.8f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("wordSnapVelocityThreshold"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("handleRimRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.471f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.929f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("handleHighRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.208f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.506f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("handleLowRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.2f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.65f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.9f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("handleGlowRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}

@synthesize owner, handleType, hitSize, proximityDistance, wordSnapVelocityThreshold, caret;
@synthesize rimColor, fillHighColor, fillLowColor, glowColor;

#ifdef PHI_USE_LAYER_SHADOW
- (void)setupShadowPath {
	CGPathRef shadowPath = CGPathCreateMutable();
	CGRect rimRect = CGRectInset(self.bounds, 2.0, 0.5);
	rimRect.size.height = rimRect.size.width;
	CGPathAddEllipseInRect(shadowPath, NULL, rimRect);
	self.layer.shadowPath = shadowPath;
	CGPathRelease(shadowPath);
}
#endif
- (void)initSubviews {
	NSArray *sizeComponents;
	NSArray *colorComponents;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	self.clipsToBounds = NO;
	self.opaque = NO;
	self.userInteractionEnabled = NO;
	sizeComponents = [defaults arrayForKey:@"handleHitSize"];
	self.hitSize = CGSizeMake([[sizeComponents objectAtIndex:0] floatValue], [[sizeComponents objectAtIndex:1] floatValue]);
	sizeComponents = [defaults arrayForKey:@"handleSize"];
	self.bounds = CGRectMake(0.0, 0.0, [[sizeComponents objectAtIndex:0] floatValue], [[sizeComponents objectAtIndex:1] floatValue]);
	self.proximityDistance = self.hitSize;
	self.wordSnapVelocityThreshold = [[NSUserDefaults standardUserDefaults] floatForKey:@"wordSnapVelocityThreshold"];
	colorComponents = [defaults arrayForKey:@"handleRimRGBAColorComponents"];
	self.rimColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
									green:[[colorComponents objectAtIndex:1] floatValue]
									 blue:[[colorComponents objectAtIndex:2] floatValue]
									alpha:[[colorComponents objectAtIndex:3] floatValue]];
	colorComponents = [defaults arrayForKey:@"handleHighRGBAColorComponents"];
	self.fillHighColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
									green:[[colorComponents objectAtIndex:1] floatValue]
									 blue:[[colorComponents objectAtIndex:2] floatValue]
									alpha:[[colorComponents objectAtIndex:3] floatValue]];
	colorComponents = [defaults arrayForKey:@"handleLowRGBAColorComponents"];
	self.fillLowColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
									green:[[colorComponents objectAtIndex:1] floatValue]
									 blue:[[colorComponents objectAtIndex:2] floatValue]
									alpha:[[colorComponents objectAtIndex:3] floatValue]];
	colorComponents = [defaults arrayForKey:@"handleGlowRGBAColorComponents"];
	self.glowColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
									green:[[colorComponents objectAtIndex:1] floatValue]
									 blue:[[colorComponents objectAtIndex:2] floatValue]
									alpha:[[colorComponents objectAtIndex:3] floatValue]];
#ifdef PHI_USE_LAYER_SHADOW
	self.layer.shadowOffset = CGSizeMake(0.0, 2.0);
	self.layer.shadowRadius = 1.0;
	self.layer.shadowOpacity = 0.5;
	[self setupShadowPath];
#endif
}
#ifdef PHI_USE_LAYER_SHADOW
- (void)layoutSubviews {
	[self setupShadowPath];
}
#endif
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGRect rimRect = CGRectInset(self.bounds, 2.0, 0.5);
	rimRect.size.height = rimRect.size.width;
	
#ifndef PHI_USE_LAYER_SHADOW
	//Shadow (if not drawn by CALayer)
	CGContextSaveGState(context); {
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rimRect);
		[self.rimColor set];
		CGContextSetShadow(context, CGSizeMake(0.0, 2.0), 2.0);
		CGContextDrawPath(context, kCGPathFill);
	} CGContextRestoreGState(context);
	/**/
#endif	
	//Fill
	CGContextSaveGState(context); {
		CGColorRef colorGradient[2] =  {
			self.fillHighColor.CGColor,// Start color
			self.fillLowColor.CGColor  // End color
		};
		CFArrayRef colorGradientArray = CFArrayCreate(NULL, (const void **)colorGradient, 2, NULL);
		CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorGradientArray, NULL);

		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rimRect);
		CGContextClip(context);
		//CGContextSetBlendMode(context, kCGBlendModeScreen);
		CGContextDrawLinearGradient(context, gradient,
									rimRect.origin,
									CGPointMake(CGRectGetMinX(rimRect), CGRectGetMaxY(rimRect)),
									kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation
									);

		CGGradientRelease(gradient);
		CFRelease(colorGradientArray);
	} CGContextRestoreGState(context);
	/**/
	//Inner glow
	CGContextSaveGState(context); {
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rimRect);
		CGContextClip(context);
		CGContextAddEllipseInRect(context, rimRect);
		[self.rimColor set];
		CGContextSetShadowWithColor(context, CGSizeZero, 4.0, self.glowColor.CGColor);
		CGContextDrawPath(context, kCGPathStroke);
	} CGContextRestoreGState(context);
	/**/
	//Rim
	CGContextSaveGState(context); {
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rimRect);
		[self.rimColor set];
		CGContextSetLineWidth(context, 1.0);
		CGContextDrawPath(context, kCGPathStroke);
	} CGContextRestoreGState(context);
	/**/
	CGColorSpaceRelease(colorSpace);
}
- (void)setOwner:(PhiTextEditorView<UITextInput> *)view {
	owner = view;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self initSubviews];
	}
	return self;
}

- (void)setHandleType:(int)pos {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	CGPoint anchorPoint = CGPointZero;
	handleType = pos;
	if (handleType == -1) {
		anchorPoint = CGPointMake(0.5, (self.bounds.size.height - 3.0) / self.bounds.size.height);
	} else if (handleType == 1) {
		anchorPoint = CGPointMake(0.5, 0.0);
	}
	[(CALayer *)[self layer] setAnchorPoint:anchorPoint];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextSelectionHandle pointInside:(%.f, %.f) withEvent:%@]...", traceIndent, point.x, point.y, event);
#endif
	CGPoint corner = [self convertPoint:self.center fromView:self.superview];
	corner.x -= self.hitSize.width * 0.5;
	corner.y -= self.hitSize.height * 0.5;
	CGRect hitBounds = CGRectMake(corner.x, corner.y, self.hitSize.width, self.hitSize.height);
	BOOL pointInside = CGRectContainsPoint(hitBounds, point);
	
	if (pointInside) {
		if (self.proximityDistance.height == 0) {
			if (ABS(self.proximityDistance.width) < self.hitSize.width) {
				CGFloat dx = (self.hitSize.width - self.proximityDistance.width) / 2.0;
				hitBounds.size.width -= dx;
				if (!(self.handleType < 0 ^ self.proximityDistance.width < 0))
					hitBounds.origin.x += dx;
				pointInside = CGRectContainsPoint(hitBounds, point);
			}
		} else {
			if (ABS(self.proximityDistance.height) < self.hitSize.height) {
				CGFloat dx = (self.hitSize.height - self.proximityDistance.height) / 2.0;
				hitBounds.size.height -= dx;
				if (!(self.handleType < 0 ^ self.proximityDistance.height < 0))
					hitBounds.origin.y += dx;
				pointInside = CGRectContainsPoint(hitBounds, point);
			}
		}
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:%s...", traceIndent, __FUNCTION__, pointInside?"YES":"NO");
#endif
	return pointInside;
}

- (BOOL)moveToPosition:(PhiTextPosition *)p animate:(BOOL)animate {
#ifdef TRACE
	NSLog(@"%@Entering -[PhiTextSelectionHandle moveToPosition:%@]...", traceIndent, p);
#endif
	UITextRange *selectedRange = [self.owner selectedTextRange];
	UITextRange *newSelectedRange = nil;
	UITextPosition *max;
	if (selectedRange) {
		if (self.handleType == -1) {
			max = [self.owner positionFromPosition:selectedRange.end offset:-1];
			if ([self.owner comparePosition:p toPosition:max] != NSOrderedAscending) {
				p = (PhiTextPosition *)max;
			}
			if ([self.owner comparePosition:p toPosition:selectedRange.start] != NSOrderedSame)
				newSelectedRange = [self.owner textRangeFromPosition:p toPosition:selectedRange.end];
		} else if (self.handleType == 1) {
			max = [self.owner positionFromPosition:selectedRange.start offset:1];
			if ([self.owner comparePosition:p toPosition:max] != NSOrderedDescending) {
				p = (PhiTextPosition *)max;
			}
			if ([self.owner comparePosition:p toPosition:selectedRange.end] != NSOrderedSame)
				newSelectedRange = [self.owner textRangeFromPosition:selectedRange.start toPosition:p];
			else {
				return NO;
			}
			
		}
		if (newSelectedRange) {
			if (animate) {
				destinationFrame = [self.owner caretRectForPosition:p];
				if (self.handleType == -1) {
					destinationCaretCenter = CGPointMake(CGRectGetMidX(destinationFrame), CGRectGetMinY(destinationFrame));
				} else {
					destinationCaretCenter = CGPointMake(CGRectGetMidX(destinationFrame), CGRectGetMaxY(destinationFrame));
				}
				destinationSelectionRange = [newSelectedRange retain];
				arrivalTimestamp = 0.0;
				CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(move:)];
				[displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
			} else {
				[self.owner changeSelectedRange:(PhiTextRange *)newSelectedRange];
			}
		}
	}
	return animate;
}
- (void)moveToPosition:(PhiTextPosition *)p {
	[self moveToPosition:p animate:NO];
}
- (BOOL)moveToClosestSnapPositionToPoint:(CGPoint)point {
	int dir = -1;
	if (self.handleType == -1) {
		dir = UITextStorageDirectionForward;
	} else if (self.handleType == 1) {
		dir = UITextStorageDirectionBackward;
	}
	point = [self convertPoint:point toView:self.owner];
	return [self moveToPosition:(PhiTextPosition *)[self.owner closestSnapPositionToPoint:point inDirection:dir] animate:YES];
}
- (void)moveToClosestSnapPositionToPoint:(CGPoint)point inView:(UIView *)view {
	point = [view convertPoint:point toView:self.owner];
	[self moveToClosestSnapPositionToPoint:point];
}
- (void)moveToClosestPositionToPoint:(CGPoint)point {
	point = [self convertPoint:point toView:self.owner];
	[self moveToPosition:(PhiTextPosition *)[self.owner closestPositionToPoint:point]];
}
- (BOOL)moveToClosestPositionToPoint:(CGPoint)point withVelocity:(CGPoint)velocity {
	CGFloat velocityMagSq = velocity.x * velocity.x + velocity.y * velocity.y;
	if (velocityMagSq > self.wordSnapVelocityThreshold * self.wordSnapVelocityThreshold) {
		return [self moveToClosestSnapPositionToPoint:point];
	} else {
		[self moveToClosestPositionToPoint:point];
		return NO;
	}
}
- (void)moveToClosestPositionToPoint:(CGPoint)point inView:(UIView *)view {
	point = [view convertPoint:point toView:self];
	[self moveToClosestPositionToPoint:point];
}
- (void)move:(CADisplayLink *)sender {
	CFIndex stepCount = 1;
	if (arrivalTimestamp == 0.0) {
		arrivalTimestamp = sender.timestamp + 0.3;
	}
	if (arrivalTimestamp - sender.timestamp > sender.duration * sender.frameInterval) {
		stepCount = (CFIndex) ((arrivalTimestamp - sender.timestamp) / (sender.duration * sender.frameInterval));
	}
	CGPoint currentCenter = self.center;
	CGRect currentFrame = self.caret.frame;
	CGPoint point = [[self superview] convertPoint:destinationCaretCenter fromView:[self owner]];
	CGRect rect = [[[self caret] superview] convertRect:destinationFrame fromView:[self owner]];
	
	self.center = CGPointMake((point.x + currentCenter.x * (stepCount - 1)) / stepCount, (point.y + currentCenter.y * (stepCount - 1)) / stepCount);
	self.caret.frame = CGRectMake((rect.origin.x + currentFrame.origin.x * (stepCount - 1)) / stepCount,
								  (rect.origin.y + currentFrame.origin.y * (stepCount - 1)) / stepCount,
								  (rect.size.width + currentFrame.size.width * (stepCount - 1)) / stepCount,
								  (rect.size.height + currentFrame.size.height * (stepCount - 1)) / stepCount);
	[self.superview setNeedsDisplay];
	if (stepCount == 1) {
		//Too careful?
		[[[sender retain] autorelease] invalidate];
		[self.owner changeSelectedRange:destinationSelectionRange];
//		[self.owner setKeepMenuVisible];
		[self.owner showMenu];
		[destinationSelectionRange release];
		destinationSelectionRange = nil;
	}
}

- (void)setFrame:(CGRect)rect {
	[super setFrame:rect];
	absoluteBounds = [self convertRect:self.bounds toView:self.owner];
	absoluteCenter = [self.superview convertPoint:self.center toView:self.owner];
}

- (void)setBounds:(CGRect)rect {
	[super setBounds:rect];
	absoluteBounds = [self convertRect:rect toView:self.owner];
	if (handleType == -1)
		[[self layer] setAnchorPoint:CGPointMake(0.5, (rect.size.height - 3.0) / rect.size.height)];
}

- (void)setCenter:(CGPoint)point {
	[super setCenter:point];
	absoluteCenter = [self.superview convertPoint:point toView:self.owner];
}

- (void)update {
	[super setBounds:[self  convertRect:absoluteBounds fromView:self.owner]];
	[super setCenter:[self.superview convertPoint:absoluteCenter fromView:self.owner]];
}

- (void)dealloc {
	self.rimColor = nil;
	self.fillHighColor = nil;
	self.fillLowColor = nil;
	self.glowColor = nil;
	
    [super dealloc];
}


@end
