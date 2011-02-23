//
//  PhiTextCaretView.m
//  FirstCoreText
//
//  Created by Corin Lawson on 16/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextCaretView.h"

typedef struct PhiCaretState {
	CGColorRef backgroundColor;
	NSTimeInterval blinkLength;
	NSTimeInterval blinkTranistionDuration;
	NSTimeInterval blinkDelay;
	double blinkOnRatio;
} PhiCaretState;

@interface PhiTextCaretView ()

/*!
    @method     
    @abstract   Sets the properties of this object to their initial values.
    @discussion All the properties declared in this class, and this view's 
		backgroundColor, are set to initial values. The default backgroundColor
		is blue. See the indivual properties for their
		initial values.
*/
- (void)setDefaults;

@end

@implementation PhiTextCaretView

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	double aDouble;
	CFNumberRef aNumberValue;
	CFMutableArrayRef anArray;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("caretRGBAColorComponents"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		aDouble = 1.0;
		aNumberValue = CFNumberCreate(NULL, kCFNumberDoubleType, &aDouble);
		CFPreferencesSetAppValue(CFSTR("blinkLength"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		aDouble = PHI;
		aNumberValue = CFNumberCreate(NULL, kCFNumberDoubleType, &aDouble);
		CFPreferencesSetAppValue(CFSTR("blinkOnRatio"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		aDouble = 0.1;
		aNumberValue = CFNumberCreate(NULL, kCFNumberDoubleType, &aDouble);
		CFPreferencesSetAppValue(CFSTR("blinkTranistionDuration"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		aDouble = 0.8;
		aNumberValue = CFNumberCreate(NULL, kCFNumberDoubleType, &aDouble);
		CFPreferencesSetAppValue(CFSTR("blinkDelay"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("caretRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}

+ (Class)layerClass {
	return [CAShapeLayer class];
}

@synthesize owner;
@synthesize blinkLength, blinkOnRatio, blinkDelay, blinkTranistionDuration;

- (void)setupOrderActions {
	NSMutableDictionary *customActions = [NSMutableDictionary dictionaryWithDictionary:self.layer.actions];
	CATransition *orderAction = [[CATransition alloc] init];
	orderAction.duration = self.blinkTranistionDuration;
	orderAction.type = kCATransitionFade;
	[customActions setObject:orderAction forKey:kCAOnOrderOut];
	[customActions setObject:orderAction forKey:kCAOnOrderIn];
	self.layer.actions = customActions;
	[orderAction release];
}
- (void)setDefaults {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	blinkLength = [defaults floatForKey:@"blinkLength"];
	blinkOnRatio = [defaults floatForKey:@"blinkOnRatio"];
	self.opaque = NO;
	NSArray *colorComponents = [defaults arrayForKey:@"caretRGBAColorComponents"];
	[(CAShapeLayer *)self.layer setFillColor:[[UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
										   green:[[colorComponents objectAtIndex:1] floatValue]
											blue:[[colorComponents objectAtIndex:2] floatValue]
										   alpha:[[colorComponents objectAtIndex:3] floatValue]] CGColor]];
	self.layer.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge;
	self.layer.masksToBounds = YES;
	blinkTranistionDuration = [defaults floatForKey:@"blinkTranistionDuration"];;
	blinkDelay = [defaults floatForKey:@"blinkDelay"];;

	[self setupOrderActions];
	
	[super setHidden:YES];
	if (stateStack) [stateStack release];
	stateStack = [[NSMutableArray alloc] initWithCapacity:3];
	
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}

- (void)saveState {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	PhiCaretState state;// = (PhiCaretState *)malloc(sizeof(PhiCaretState));
	state.blinkDelay = self.blinkDelay;
	state.blinkLength = self.blinkLength;
	state.blinkOnRatio = self.blinkOnRatio;
	state.blinkTranistionDuration = self.blinkTranistionDuration;
	state.backgroundColor = [self.backgroundColor CGColor];
	CGColorRetain(state.backgroundColor);
	[stateStack addObject:[NSValue value:&state withObjCType:@encode(PhiCaretState)]];
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}
- (void)restoreState {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	PhiCaretState state;
	if ([stateStack count]) {
		[[stateStack lastObject] getValue:&state];
		[stateStack removeLastObject];

		BOOL needsNewOrderActions = blinkTranistionDuration != state.blinkTranistionDuration;
		blinkDelay = state.blinkDelay;
		blinkLength = state.blinkLength;
		blinkOnRatio = state.blinkOnRatio;
		blinkTranistionDuration = state.blinkTranistionDuration;
		if (needsNewOrderActions)
			[self setupOrderActions];
		self.backgroundColor = [UIColor colorWithCGColor:state.backgroundColor];
		CGColorRelease(state.backgroundColor);
	} else {
		[self setDefaults];
	}
	if (![self isHidden]) {
		[self setHidden:NO];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		blinkOnTimer = nil;
		blinkOffTimer = nil;
        [self setDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if(self = [super initWithCoder:aDecoder]) {
		blinkOnTimer = nil;
		blinkOffTimer = nil;
        [self setDefaults];
	}
	return self;
}

- (void)setFrame:(CGRect)rect {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectMake(0.0, -1.0, rect.size.width, rect.size.height + 2.0));
	[(CAShapeLayer *)self.layer setPath: path];
	[super setFrame:rect];
	[self.layer setBounds:CGRectMake(-1.0, 0.0, rect.size.width + 2.0, rect.size.height)];
	CGPathRelease(path);
}

- (void)setBounds:(CGRect)rect {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectMake(rect.origin.x, rect.origin.y - 1.0, rect.size.width, rect.size.height + 2.0));
	[(CAShapeLayer *)self.layer setPath: path];
	[super setBounds:rect];
	[self.layer setBounds:CGRectMake(rect.origin.x - 1.0, rect.origin.y, rect.size.width + 2.0, rect.size.height)];
	CGPathRelease(path);
}

- (void)setHidden:(BOOL)hidden {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextCaretView setHidden:%s]...", traceIndent, hidden?"YES":"NO");
#endif
	if(blinkOnTimer) {
		[blinkOnTimer invalidate];
		[blinkOnTimer release];
		blinkOnTimer = nil;
	}
	if(blinkOffTimer) {
		[blinkOffTimer invalidate];
		[blinkOffTimer release];
		blinkOffTimer = nil;
		self.alpha = 1.0f;
	}
	if(!hidden && self.blinkOnRatio > 0.0) {
		if (self.blinkLength > 0.0 && self.blinkOnRatio < 1.0) {
			NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
			NSDate *soon = [[NSDate alloc] initWithTimeIntervalSinceNow:self.blinkDelay];
			NSDate *later = [[NSDate alloc] initWithTimeInterval:self.blinkLength * (1.0 - self.blinkOnRatio) sinceDate:soon];
			blinkOffTimer = [[NSTimer alloc] initWithFireDate:soon  interval:self.blinkLength target:self selector:@selector(blinkOff:) userInfo:NULL repeats:YES];
			blinkOnTimer  = [[NSTimer alloc] initWithFireDate:later interval:self.blinkLength target:self selector:@selector(blinkOn:)  userInfo:NULL repeats:YES];
			[runLoop addTimer:blinkOnTimer  forMode:NSDefaultRunLoopMode];
			[runLoop addTimer:blinkOffTimer forMode:NSDefaultRunLoopMode];
			[soon release];
			[later release];
		}
		[super setHidden:NO];
	} else if (![super isHidden]) {
		[super setHidden:YES];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}

- (void)setBlinkLength:(NSTimeInterval)interval {
	blinkLength = interval;
	[self setHidden:[self isHidden]];
}

- (void)setBlinkOnRatio:(double)onRatio {
	blinkOnRatio = onRatio;
	[self setHidden:[self isHidden]];
}

- (void)setBlinkTranistionDuration:(NSTimeInterval)interval {
	if (blinkTranistionDuration != interval) {
		blinkTranistionDuration = interval;
		[self setupOrderActions];
	}
	[self setHidden:[self isHidden]];
}

- (void)blinkOn:(id)sender {
	[UIView beginAnimations:NULL context:NULL];
	[UIView setAnimationDuration:self.blinkTranistionDuration];
	self.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)blinkOff:(id)sender {
	[UIView beginAnimations:NULL context:NULL];
	[UIView setAnimationDuration:self.blinkTranistionDuration];
	self.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void)dealloc {
	if(blinkOnTimer) {
		[blinkOnTimer invalidate];
		[blinkOnTimer release];
		blinkOnTimer = nil;
	}
	if(blinkOffTimer) {
		[blinkOffTimer invalidate];
		[blinkOffTimer release];
		blinkOffTimer = nil;
	}
	if (stateStack) {
		[stateStack release];
		stateStack = nil;
	}
    [super dealloc];
}


@end
