//
//  PhiTextMagnifier.m
//  FirstCoreText
//
//  Created by Corin Lawson on 16/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextMagnifier.h"

@interface PhiTextMagnifierAction : NSObject <CAAction>
{
	CAKeyframeAnimation *anchorPointAction;
	CAAnimationGroup *hiddenAction;
	CGPoint center;
	PhiTextMagnifier *owner;
	BOOL swappingHands;
}
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) PhiTextMagnifier *owner;
- (id)init;
@end

@implementation PhiTextMagnifierAction

@synthesize center, owner;
- (id)init {
	if (self = [super init]) {
		anchorPointAction = [[CAKeyframeAnimation animationWithKeyPath:@"anchorPoint"] retain];
		anchorPointAction.duration = 0.25;
		anchorPointAction.delegate = self;
		anchorPointAction.calculationMode = kCAAnimationPaced;
		center = CGPointMake(0.5, 0.5);
		[anchorPointAction setValue:[NSNumber numberWithBool:NO] forKey:@"running"];
		swappingHands = NO;

		hiddenAction = [[CAAnimationGroup animation] retain];
		hiddenAction.duration = 0.25;
		hiddenAction.delegate = self;
		hiddenAction.animations = [NSArray arrayWithObjects:
									  [CABasicAnimation animationWithKeyPath:@"hidden"],
									  [CABasicAnimation animationWithKeyPath:@"bounds.size"],
									  [CABasicAnimation animationWithKeyPath:@"shadowPath"],
									  [CABasicAnimation animationWithKeyPath:@"position"],
									  nil];
	}
	return self;
}
- (void)runActionForKey:(NSString *)key object:(id)object arguments:(NSDictionary *)dict {
	CALayer *layer = (CALayer *)object;
	if ([key isEqualToString:@"anchorPoint"]) {
		CGPoint anchorPoint = [[layer presentationLayer] anchorPoint];
		[layer removeAnimationForKey:key];
		CGFloat radius;
		CGFloat x, y, rise, run, a1, a2, b1, b2;
		CGMutablePathRef arc = CGPathCreateMutable();
		x = anchorPoint.x;
		y = anchorPoint.y;
		anchorPoint = [layer anchorPoint];
		
		if (!swappingHands && (anchorPoint.x < 0.5 && 0.5 < x || anchorPoint.x > 0.5 && 0.5 > x)) {
			//NSLog(@"old: (%.2f, %.2f) new: (%.2f, %.2f)\n", x, y, anchorPoint.x, anchorPoint.y);
			swappingHands = YES;
			owner.active = NO;
			CGPathMoveToPoint(arc, NULL, x,y);
			run = x - center.x;
			rise = center.y - y;
			radius = sqrtf(run * run + rise * rise);
			a1 = run / rise;
			a2 = (anchorPoint.x - center.x) / (center.y - anchorPoint.y);
			b1 = y - a1 * x;
			b2 = anchorPoint.y - a2 * anchorPoint.x;
			x = (b2 - b1) / (a1 - a2);
			y = a1 * x + b1;
			CGPathAddArcToPoint(arc, NULL, x,y, anchorPoint.x,anchorPoint.y, radius);
			
			anchorPointAction.path = arc;
			anchorPointAction.keyPath = key;
			[layer addAnimation:anchorPointAction forKey:key];
		} else if (swappingHands) {
			[layer removeAnimationForKey:key];
		}
		CGPathRelease(arc);
	} else if ([key isEqualToString:@"hidden"]) {
		CGMutablePathRef path;
		if (layer.hidden) {
			CABasicAnimation *shrink = [hiddenAction.animations objectAtIndex:1];
			CABasicAnimation *shrinkShadow = [hiddenAction.animations objectAtIndex:2];
			CABasicAnimation *fly = [hiddenAction.animations objectAtIndex:3];
			
			shrink.fromValue = [NSValue valueWithCGSize:[[layer presentationLayer] bounds].size];
			shrink.toValue = [NSValue valueWithCGSize:CGSizeZero];

			path = CGPathCreateMutable();
			CGPathAddEllipseInRect(path, NULL, CGRectZero);
			shrinkShadow.fromValue = (id)[[layer presentationLayer] shadowPath];
			shrinkShadow.toValue = (id)path;
			CGPathRelease(path);
			
			fly.keyPath = @"position";
			fly.fromValue = [NSValue valueWithCGPoint:[[layer presentationLayer] position]];
			fly.toValue = [NSValue valueWithCGPoint:[layer position]];
		} else {
			CABasicAnimation *grow = [hiddenAction.animations objectAtIndex:1];
			CABasicAnimation *growShadow = [hiddenAction.animations objectAtIndex:2];
			CABasicAnimation *fly = [hiddenAction.animations objectAtIndex:3];
			grow.toValue = [NSValue valueWithCGSize:[layer bounds].size];
			grow.fromValue = [NSValue valueWithCGSize:CGSizeZero];
			
			path = CGPathCreateMutable();
			CGPathAddEllipseInRect(path, NULL, CGRectZero);
			growShadow.toValue = (id)[[layer presentationLayer] shadowPath];
			growShadow.fromValue = (id)path;
			CGPathRelease(path);
			
			fly.keyPath = nil;
		}
		CABasicAnimation *hide = [hiddenAction.animations objectAtIndex:0];
		hide.fromValue = [NSNumber numberWithBool:!layer.hidden];
		hide.toValue = [NSNumber numberWithBool:layer.hidden];
		[layer addAnimation:hiddenAction forKey:nil];
	}
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	[owner setActive:YES];
	if ([anim isKindOfClass:[CAPropertyAnimation class]] && [[(CAPropertyAnimation *)anim keyPath] isEqualToString:@"anchorPoint"])
		swappingHands = NO;
//	if ([anim isKindOfClass:[CAAnimationGroup class]] && [[(CAAnimationGroup *)anim animations] count]
//		&& [anim = [[(CAAnimationGroup *)anim animations] objectAtIndex:0] isKindOfClass:[CAPropertyAnimation class]] && [[(CAPropertyAnimation *)anim keyPath] isEqualToString:@"hidden"])
	else
		owner.window.hidden = owner.hidden;
}

@end

@implementation PhiTextMagnifier

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	BOOL aBool;
	CFNumberRef aNumberValue;
	CFMutableArrayRef anArray;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("magnifierSize"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		aFloat = DEFAULT_MAGNIFICATION;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("magnification"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		aFloat = 32.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("magnifierOffscreenThreshold"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		aBool = YES;
		aNumberValue = CFNumberCreate(NULL, kCFNumberSInt8Type, &aBool);
		CFPreferencesSetAppValue(CFSTR("magnifierRightHandPreferred"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.769f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.922f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.1f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("magnifierGlassTintRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
		anArray = CFArrayCreateMutable(NULL, 2, &kCFTypeArrayCallBacks);
		aFloat = 125.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("magnifierSize"), anArray, suiteName);
		CFRelease(anArray);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}
@synthesize subjectView, magnification, clippingBounds, offscreenThreshold, rightHandPreferred, defaultSubjectBackgoundColor, glassTintColor, active;

- (id<CAAction>)actionForLayer:(CALayer *)theLayer forKey:(NSString *)key {
	if ([theLayer presentationLayer] && [key isEqualToString:@"anchorPoint"] || [key isEqualToString:@"hidden"]) {
		return nil;
	}
	return [super actionForLayer:(CALayer *)theLayer forKey:(NSString *)key];
}
- (void)setupActions {
	NSMutableDictionary *customActions = [NSMutableDictionary dictionaryWithDictionary:self.layer.actions];
	PhiTextMagnifierAction *action = [[PhiTextMagnifierAction alloc] init];
	action.owner = self;
	[customActions setObject:action forKey:@"anchorPoint"];
	[customActions setObject:action forKey:@"hidden"];
	self.layer.actions = customActions;
	[action release];
}
- (void)setupLayers {
	CGMutablePathRef path;
	
	path = CGPathCreateMutable();
	CGPathAddEllipseInRect(path, NULL, CGRectInset(self.clippingBounds, -2.0, -2.0));
	[[self layer] setShadowPath:path];
	CGPathRelease(path);
	[[self layer] setShadowOffset:CGSizeMake(0.0, 2.0)];
	[[self layer] setShadowRadius:4.0];
	[[self layer] setShadowOpacity:1.0/3.0];

	[[self layer] setAnchorPoint:CGPointMake(0.5, 1.0)];
}
- (void)didChangeOrientation:(NSNotification *)notification {
	if (self.window) {
		switch ([[UIApplication sharedApplication] statusBarOrientation]) {
			case UIInterfaceOrientationLandscapeRight:
				self.window.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				self.window.transform = CGAffineTransformMakeRotation(M_PI);
				break;
			case UIInterfaceOrientationLandscapeLeft:
				self.window.transform = CGAffineTransformMakeRotation(-M_PI / 2.0);
				break;
			default:
				self.window.transform = CGAffineTransformIdentity;
				break;
		}
	}
	if (!CGPointEqualToPoint(originInSubjectView, CGPointMake(-CGFLOAT_MAX, -CGFLOAT_MAX)))
	{
		[self performSelectorOnMainThread:@selector(growFromPoint:) withObject:[NSValue valueWithCGPoint:originInSubjectView] waitUntilDone:NO];
		originInSubjectView = CGPointMake(-CGFLOAT_MAX, -CGFLOAT_MAX);
	}
}
- (void)willChangeOrientation:(NSNotification *)notification {
	if (self.window && !self.window.hidden)
	{
		originInSubjectView = [self.window convertPoint:self.center toView:self.subjectView];
		[self shrinkToPoint:self.center];
	}
}
- (void)setupObservers {
	originInSubjectView = CGPointMake(-CGFLOAT_MAX, -CGFLOAT_MAX);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (id)initWithOrigin:(CGPoint)origin {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	NSArray *sizeComponents = [defaults arrayForKey:@"magnifierSize"];
	CGSize originalSize = CGSizeMake([[sizeComponents objectAtIndex:0] floatValue], [[sizeComponents objectAtIndex:1] floatValue]);

    if (self = [super initWithFrame:CGRectMake(origin.x, origin.y, originalSize.width, originalSize.height)]) {
		clippingBounds = CGRectMake(5.0, 3.0, originalSize.width - 10.0, originalSize.height - 7.0);
		magnification = [defaults floatForKey:@"magnification"];
		offscreenThreshold = [defaults floatForKey:@"magnifierOffscreenThreshold"];
		rightHandPreferred = [defaults boolForKey:@"magnifierRightHandPreferred"];
		active = YES;

		NSArray *colorComponents = [defaults arrayForKey:@"magnifierGlassTintRGBAColorComponents"];
		self.glassTintColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
											   green:[[colorComponents objectAtIndex:1] floatValue]
												blue:[[colorComponents objectAtIndex:2] floatValue]
											   alpha:[[colorComponents objectAtIndex:3] floatValue]];
		self.defaultSubjectBackgoundColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0];
		self.opaque = NO;
		self.hidden = YES;
		self.clipsToBounds = NO;
		
		[self setupActions];
		[self setupLayers];
		[self setupObservers];
    }
    return self;
}
- (void)setActive:(BOOL)flag {
	if (active != flag) {
		active = flag;
		[self setNeedsDisplay];
	}
}
- (void)setCenter:(CGPoint)point {
	CGPoint appPoint = [self.superview convertPoint:point toView:nil];
	if (appPoint.y < self.bounds.size.height - self.offscreenThreshold) {
		BOOL rightHandForced = self.rightHandPreferred;
		if (appPoint.x < self.bounds.size.width - self.offscreenThreshold) 
			rightHandForced = NO;
		if (appPoint.x > self.window.bounds.size.width - self.bounds.size.width + self.offscreenThreshold)
			rightHandForced = YES;
		CGPoint newAnchorPoint;
		newAnchorPoint = CGPointMake(0.5, (self.offscreenThreshold + appPoint.y) / self.bounds.size.height);
		CGFloat dx = sqrtf(newAnchorPoint.y - newAnchorPoint.y * newAnchorPoint.y);
		if (rightHandForced)
			newAnchorPoint.x += dx;
		else
			newAnchorPoint.x -= dx;
		self.layer.anchorPoint = newAnchorPoint;
	} else {
		self.layer.anchorPoint = CGPointMake(0.5, 1.0);
	}
	[super setCenter:point];
	[self setNeedsDisplay];
}

- (UIView *)subjectView {
	if (subjectView)
		return subjectView;
	return [[UIApplication sharedApplication] keyWindow];
}

- (void)growFromPoint:(CGPoint)pointInSubjectView {
	if (!overlay) {
		overlay = [[UIWindow alloc] initWithFrame:
							  self.subjectView.window.screen.bounds];
		switch ([[UIApplication sharedApplication] statusBarOrientation]) {
			case UIInterfaceOrientationLandscapeRight:
				overlay.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				overlay.transform = CGAffineTransformMakeRotation(M_PI);
				break;
			case UIInterfaceOrientationLandscapeLeft:
				overlay.transform = CGAffineTransformMakeRotation(-M_PI / 2.0);
				break;
			default:
				break;
		}
		overlay.screen = self.subjectView.window.screen;
		overlay.windowLevel = UIWindowLevelStatusBar;
		[overlay addSubview:self];
	} else if (self.window != overlay) {
		[overlay addSubview:self];
	}
	overlay.hidden = NO;

	[self setCenter:[self.window convertPoint:pointInSubjectView fromView:self.subjectView]];
	self.hidden = NO;
}

- (void)shrinkToPoint:(CGPoint)point {
	self.center = [self convertPoint:point toView:self.superview];
	self.hidden = YES;
}

- (void)drawRect:(CGRect)rect {
#ifdef TRACE
	NSLog(@"Entering [PhiTextMagnifier drawRect:(%.f, %.f), (%.f, %.f)]...", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif
	CGContextRef context;
	CGPoint subjectOrigin;
	//CGRect subjectClippingBounds;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGRect glassRect = CGRectInset(self.clippingBounds,  1.0,  1.0);
	CGRect rimRect = CGRectInset(self.clippingBounds, -2.0, -2.0);
	UIColor *rimFillColor = [UIColor whiteColor];
	UIColor *rimStrokeColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
	
	//subjectClippingBounds = CGRectMake(0.0, 0.0,  self.clippingBounds.size.width, self.clippingBounds.size.height);
	subjectOrigin = CGPointMake(self.center.x, self.center.y);
	subjectOrigin = [self.superview convertPoint:subjectOrigin toView:self.subjectView];
	subjectOrigin.x -= self.clippingBounds.size.width / self.magnification / 2.0;
	subjectOrigin.y -= self.clippingBounds.size.height / self.magnification / 2.0;
	
	context = UIGraphicsGetCurrentContext();

	/*/Shadow and background
	UIColor *subjectBackgroundColor = self.subjectView.backgroundColor;
	if (subjectBackgroundColor == nil || [subjectBackgroundColor isEqual:[UIColor clearColor]]) {
		subjectBackgroundColor = self.defaultSubjectBackgoundColor;
	}
	if (self.active) {
		subjectBackgroundColor = [subjectBackgroundColor colorWithAlphaComponent:1.0];
	} else {
		//TODO: confirm 0.5
		subjectBackgroundColor = [subjectBackgroundColor colorWithAlphaComponent:0.5];
	}
	CGContextSaveGState(context); {
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rimRect);
		[subjectBackgroundColor set];
		CGContextSetShadow(context, CGSizeMake(0.0, 2.0), 4.0);
		CGContextDrawPath(context, kCGPathFill);
	} CGContextRestoreGState(context);
	/**/
	//Subject's content
	CGContextSaveGState(context); {
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, self.clippingBounds);
		CGContextClip(context);
		if (self.active) {
			//TODO: Use CGLayer in PhiTextView and reuse here
			CALayer *layer = self.subjectView.layer;// presentationLayer];
			//CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
			CGContextScaleCTM(context, self.magnification, self.magnification);
			CGContextTranslateCTM(context, -subjectOrigin.x, -subjectOrigin.y);
			[layer renderInContext:context];
		}
	} CGContextRestoreGState(context);
	/**/
	//Rim
	CGContextSaveGState(context); {
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rimRect);
		CGContextAddEllipseInRect(context, glassRect);
		[rimFillColor setFill];
		[rimStrokeColor setStroke];
		CGContextDrawPath(context, kCGPathEOFillStroke);
	} CGContextRestoreGState(context);
	/**/
	//Glass glow
	CGContextSaveGState(context); {
		CGFloat glowColorGradient[] =  {
			1.0f, 1.0f, 1.0f, 1.0f * 0.5f,   // Start color
			0.6f, 0.6f, 0.6f, 0.6f * 0.5f,   // mid point
			0.3f, 0.3f, 0.3f, 0.2f * 0.5f }; // End color
		CGFloat glowLocationGradient[] = {0.0f, 0.33f, 1.0f}; 
		CGGradientRef glowGradient = CGGradientCreateWithColorComponents(colorSpace, glowColorGradient, glowLocationGradient, 3);
		CGPoint glowOrigin = CGPointMake(CGRectGetMidX(glassRect), CGRectGetMaxY(glassRect) - 13.0f);

		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, glassRect);
		CGContextClip(context);
		CGContextBeginPath(context);
		CGContextDrawRadialGradient(context, glowGradient,
									glowOrigin, 12.5f,
									glowOrigin, CGRectGetMaxY(glassRect) - 26.0f,
									kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		CGContextAddEllipseInRect(context, glassRect);
		[self.glassTintColor setFill];
		CGContextDrawPath(context, kCGPathFill);
		
		CGGradientRelease(glowGradient);
	} CGContextRestoreGState(context);
	/**/
	//Glass gloss
	CGContextSaveGState(context); {
		CGFloat glossColorGradient[] =  {
			1.0f, 1.0f, 1.0f, 1.00f * 0.5f,// Start color
			1.0f, 1.0f, 1.0f, 0.35f * 0.5f // End color
		};
		CGFloat glossLocationGradient[] = {0.0f, 1.0f}; 
		CGGradientRef glossGradient = CGGradientCreateWithColorComponents(colorSpace, glossColorGradient, glossLocationGradient, 2);
		
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, glassRect);
		CGContextAddEllipseInRect(context, CGRectInset(glassRect, -glassRect.size.width * 0.22f, glassRect.size.height * 0.25f));
		CGContextEOClip(context);
		CGContextBeginPath(context);
		CGContextAddArc(context, CGRectGetMidX(glassRect), CGRectGetMidY(glassRect), glassRect.size.height * 0.5f, 0.0, M_PI, 1);
		CGContextClip(context);
		CGContextSetBlendMode(context, kCGBlendModeScreen);
		CGContextDrawLinearGradient(context, glossGradient,
									CGPointMake(CGRectGetMinX(glassRect), CGRectGetMinY(glassRect) + glassRect.size.height * 0.25f),
									CGPointMake(CGRectGetMinX(glassRect), CGRectGetMinY(glassRect) + glassRect.size.height * 1.25f),
									kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation
									);
		
		CGGradientRelease(glossGradient);
	} CGContextRestoreGState(context);
	/**/
	CGColorSpaceRelease(colorSpace);
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[overlay release];
	overlay = nil;
	self.subjectView = nil;
	self.glassTintColor = nil;
	self.defaultSubjectBackgoundColor = nil;
    [super dealloc];
}

@end
