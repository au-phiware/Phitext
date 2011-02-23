//
//  PhiTextSelectionView.m
//  FirstCoreText
//
//  Created by Corin Lawson on 19/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextSelectionView.h"
#import "PhiTextEditorView.h"
#import "PhiTextDocument.h"
#import "PhiTextRange.h"
#import "PhiTextCaretView.h"
#import "PhiTextSelectionHandle.h"

@interface PhiTextSelectionView ()

- (void)setupLayer;
- (void)setupSubviews;

@end


@implementation PhiTextSelectionView

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	CFNumberRef aNumberValue;
	CFMutableArrayRef anArray;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("selectionRGBAColorComponents"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.384f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.690f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.21f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("selectionRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}

+ (Class)layerClass {
	return [CAShapeLayer class];
}

@synthesize owner, handlesShown;
@synthesize startCaret, endCaret;
@synthesize startHandle, endHandle;

- (BOOL)needsUpdate {
	return needsUpdate
			||
		   CGSizeEqualToSize(CGSizeZero, self.endCaret.frame.size) && CGRectContainsPoint(self.superview.bounds, self.endCaret.frame.origin)
			||
	       CGSizeEqualToSize(CGSizeZero, self.startCaret.frame.size) && CGRectContainsPoint(self.superview.bounds, self.startCaret.frame.origin);
}

- (void)layoutSubviews {
	[self update];
	[self.owner bringSubviewToFront:self];
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	// End access to text frame that were used in update
	for (PhiAATreeRange *nodes in dirtyTextFrames)
		for (PhiTextFrame *textFrame in nodes)
			[textFrame endContentAccess];
	[dirtyTextFrames removeAllObjects];
#endif
}
- (void)update {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if ([self needsUpdate]) {
		PhiTextRange *selectedRange = (PhiTextRange *)[owner selectedTextRange];
		BOOL startChanged, endChanged, rangeChanged;
		endChanged   = CGSizeEqualToSize(CGSizeZero,   endCaret.bounds.size) || !lastSelectedTextRange || [[self owner] comparePosition:[selectedRange end] toPosition:[lastSelectedTextRange end]] != NSOrderedSame;
		startChanged = CGSizeEqualToSize(CGSizeZero, startCaret.bounds.size) || !lastSelectedTextRange || [[self owner] comparePosition:[selectedRange start] toPosition:[lastSelectedTextRange start]] != NSOrderedSame;
		rangeChanged = endChanged || startChanged;
		if (selectedRange && ![self isHidden]) {
			CGRect startRect;
			CGRect endRect = [self convertRect:[[self owner] visibleCaretRectForPosition:[selectedRange end]] fromView:[self owner]];
			if (!endChanged && !CGSizeEqualToSize(CGSizeZero, endRect.size)) {// Maybe the rect has...
				endChanged = !CGRectEqualToRect(endRect, [endCaret frame]);
			}
			if (![selectedRange isEmpty]) {
#ifdef DEVELOPER
				NSLog(@"Selected range is not empty.");
#endif
				startRect = [self convertRect:[[self owner] visibleCaretRectForPosition:[selectedRange start]] fromView:[self owner]];
				if (!startChanged && !CGSizeEqualToSize(CGSizeZero, startRect.size)) {// Maybe the rect has...
					startChanged = !CGRectEqualToRect(startRect, [startCaret frame]);
				}
				rangeChanged = endChanged || startChanged;
				if (startChanged) {
					[startCaret setFrame:startRect];
					if (!CGSizeEqualToSize(CGSizeZero, startRect.size)) {
						[startHandle setCenter:CGPointMake(CGRectGetMidX(startRect), CGRectGetMinY(startRect))];
					}
				}
				if (rangeChanged) {
					CGSize proximityDistance = CGSizeMake(CGRectGetMidX(endRect) - CGRectGetMidX(startRect), CGRectGetMidY(endRect) - CGRectGetMidY(startRect));
					[startHandle setProximityDistance:proximityDistance];
					[endHandle setProximityDistance:proximityDistance];
				}
				if (!handlesShown && [[self owner] isFirstResponder]) {
#ifdef DEVELOPER
					NSLog(@"Handles and start caret is hidden, show them now.");
#endif
					[self stopBlinking];
					[startCaret setHidden:NO];
					[startHandle setHidden:NO];
					[endHandle setHidden:NO];
					[[self owner] didShowSelectionHandles];
					handlesShown = YES;
				}
				if (handlesShown && !CGSizeEqualToSize(CGSizeZero, startRect.size)) {
					[startHandle setHidden:NO];
				} else {
					[startHandle setHidden:YES];
				}
			}
			
			if (endChanged) {
				[endCaret setFrame:endRect];
				if (!CGSizeEqualToSize(CGSizeZero, endRect.size)) {
					[endHandle setCenter:CGPointMake(CGRectGetMidX(endRect), CGRectGetMaxY(endRect))];
					if (handlesShown)
						[endHandle setHidden:NO];
				} else {
					[endHandle setHidden:YES];
				}
			}
			if ([[self owner] isFirstResponder])
				[endCaret setHidden:NO];
			[self.owner bringSubviewToFront:self];
		}
		if (handlesShown && (!selectedRange || [selectedRange isEmpty] || ![[self owner] isFirstResponder])) {
#ifdef DEVELOPER
			NSLog(@"Will hide start caret and handles.");
#endif
			[startHandle setHidden:YES];
			[endHandle setHidden:YES];
			[[self owner] didHideSelectionHandles];
			[startCaret setHidden:YES];
			[self startBlinking];
			handlesShown = NO;
		}
		if (!selectedRange || ![[self owner] isFirstResponder]) {
			[endCaret setHidden:YES];
		}
		if (selectionPathValid && (!selectedRange || rangeChanged)) {
//			CGPathRelease(selectionPath);
//			selectionPath = NULL;
			selectionPathValid = NO;
			if (!selectedRange)
				((CAShapeLayer *)self.layer).path = NULL;
		}
		needsUpdate = NO;
		
		rangeChanged = endChanged || startChanged;
		if (rangeChanged && (selectedRange && ![selectedRange isEmpty] || lastSelectedTextRange && ![lastSelectedTextRange isEmpty]))
			[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[lastSelectedTextRange release];
		lastSelectedTextRange = [selectedRange copy];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}

- (void)setNeedsDisplay {
	//[super setNeedsDisplay];
	//if (selectionPathValid) {
	//	CGPathRelease(selectionPath);
	//	selectionPath = NULL;
		selectionPathValid = NO;
	//}
	[self selectionPath];
	//[self.owner setSelectionNeedsDisplay];
}

- (void)setNeedsLayout {
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	// Begin access to text frames that will be needed in update
	if ([owner selectedTextRange] && ![self isHidden]) {
		PhiAATreeRange *nodes = [self.owner.textDocument beginContentAccessInRect:self.owner.bounds];
		[dirtyTextFrames addObject:nodes];
	}
#endif
	[super setNeedsLayout];
	needsUpdate = YES;
}

- (CGPathRef)selectionPath {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	[self update];
	if (!selectionPathValid || handlesShown) {
		//if (selectionPathValid) {
		//	CGPathRelease(selectionPath);
		//	selectionPath = NULL;
			selectionPathValid = NO;
		//}
		if (handlesShown) {
			CGMutablePathRef path = CGPathCreateMutable();
			[[self.owner textDocument] buildPath:path withFirstRect:[self convertRect:[startCaret frame] toView:[self owner]] toLastRect:[self convertRect:[endCaret frame] toView:[self owner]]];
			//selectionPath = path;
			selectionPathValid = YES;
			shape.path = path;
			CGPathRelease(path);
		} else {
			PhiTextRange *selectedRange = (PhiTextRange *) [self.owner selectedTextRange];
			if ([selectedRange length]) {
				CGMutablePathRef path = CGPathCreateMutable();
				[[self.owner textDocument] buildPath:path forRange:selectedRange];
				//selectionPath = path;
				selectionPathValid = YES;
				shape.path = path;
				CGPathRelease(path);
			} else {
				shape.path = NULL;
			}

		}
	}
	return shape.path;
}

- (void)setSelectionColor:(UIColor *)color {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	shape.fillColor = color.CGColor;
}
- (UIColor *)selectionColor {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	return [UIColor colorWithCGColor:shape.fillColor];
}
/*
- (void)drawRect:(CGRect)rect {
	CGRect tRect = [self convertRect:CGRectMake(0, 0, 1, 1) fromView:[self owner]];
	CGPathRef path = self.selectionPath;
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (path && CGRectIntersectsRect([self convertRect:rect toView:[self owner]], CGPathGetBoundingBox(path))) {
		CGContextBeginPath(context);
		CGContextSaveGState(context); {
			CGContextTranslateCTM(context, tRect.origin.x, tRect.origin.y);
			CGContextScaleCTM(context, tRect.size.width, tRect.size.height);
			CGContextAddPath(context, path);
			
			[selectionColor set];
			CGContextFillPath(context);
		} CGContextRestoreGState(context);
	}
	//Draw view outline
#ifdef DEVELOPER
	CGContextSaveGState(context); {
		CGContextSetLineWidth(context, 2.5);
		[[[UIColor yellowColor] colorWithAlphaComponent:0.5] set];
		UIRectFrameUsingBlendMode(self.bounds, kCGBlendModeScreen);
	} CGContextRestoreGState(context);
#endif
}
- (void)drawSelectionRect:(CGRect)rect inContext:(CGContextRef)context {
	[self drawSelectionRect:rect inContext:context withOffset:CGPointZero];
}
- (void)drawSelectionRect:(CGRect)rect inContext:(CGContextRef)context withOffset:(CGPoint)offset {
	CGPathRef path = self.selectionPath;
	if (path && CGRectIntersectsRect(rect, CGPathGetBoundingBox(path))) {
		CGContextBeginPath(context);
		CGContextSaveGState(context); {
			if (!CGPointEqualToPoint(offset, CGPointZero)) {
				CGContextTranslateCTM(context, -offset.x, -offset.y);
			}
			CGContextAddPath(context, path);
			
			CGContextSetFillColorWithColor(context, self.selectionColor.CGColor);
			CGContextFillPath(context);

			//CGContextSetFillColorWithColor(context, self.lightestSelectionColor.CGColor);
			//CGContextSetBlendMode(context, kCGBlendModeMultiply);
			//CGContextFillPath(context);
			//CGContextSetFillColorWithColor(context, self.darkestSelectionColor.CGColor);
			//CGContextSetBlendMode(context, kCGBlendModeScreen);
			//CGContextFillPath(context);
		} CGContextRestoreGState(context);
	}
}
/**/

- (void)setupLayer {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	shape.shouldRasterize = YES;
	NSArray *colorComponents = [defaults arrayForKey:@"selectionRGBAColorComponents"];
	self.selectionColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
										  green:[[colorComponents objectAtIndex:1] floatValue]
										   blue:[[colorComponents objectAtIndex:2] floatValue]
										  alpha:[[colorComponents objectAtIndex:3] floatValue]];
}
- (void)setupSubviews {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	[self setOpaque:NO];
	[self setUserInteractionEnabled:NO];
	blinking = YES;
	lastSelectedTextRange = nil;
	needsUpdate = YES;
	
	[self setStartCaret:[[[PhiTextCaretView alloc] initWithFrame:CGRectZero] autorelease]];
	[self setEndCaret:[[[PhiTextCaretView alloc] initWithFrame:CGRectZero] autorelease]];

	[self setStartHandle:[[[PhiTextSelectionHandle alloc] initWithFrame:CGRectZero] autorelease]];
	[self setEndHandle:[[[PhiTextSelectionHandle alloc] initWithFrame:CGRectZero] autorelease]];
	
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	dirtyTextFrames = [[NSMutableSet alloc] init];
#endif
}

- (void)setOwner:(PhiTextEditorView *)view {
	owner = view;
	[startHandle setOwner:owner];
	[endHandle setOwner:owner];
	[startCaret setOwner:owner];
	[endCaret setOwner:owner];
}

- (void)setStartCaret:(PhiTextCaretView *)view {
	if (startCaret != view) {
		if (startCaret) {
			[startCaret setOwner:nil];
			[startHandle setCaret:nil];
			[startCaret removeFromSuperview];
			[startCaret release];
		}
		startCaret = view;
		needsUpdate = YES;
		if (startCaret) {
			[startCaret setOwner:owner];
			[startHandle setCaret:startCaret];
			if (handlesShown) {
				[startHandle setHidden:NO];
				[startCaret setHidden:NO];
			} else {
				[startHandle setHidden:YES];
				[startCaret setHidden:YES];
			}
			[self addSubview:startCaret];
			[self sendSubviewToBack:startCaret];
			[startCaret retain];
		}
	}
}
- (void)setEndCaret:(PhiTextCaretView *)view {
	if (endCaret != view) {
		if (endCaret) {
			[endCaret setOwner:nil];
			[endHandle setCaret:nil];
			[endCaret removeFromSuperview];
			[endCaret release];
		}
		endCaret = view;
		needsUpdate = YES;
		if (endCaret) {
			[endCaret setOwner:owner];
			[endHandle setCaret:endCaret];
			if (handlesShown)
				[endHandle setHidden:NO];
			else
				[endHandle setHidden:YES];
			[self addSubview:endCaret];
			[self sendSubviewToBack:endCaret];
			[endCaret retain];
		}
	}
}

- (void)setStartHandle:(PhiTextSelectionHandle *)view {
	if (startHandle != view) {
		if (startHandle) {
			[startHandle setOwner:nil];
			[startHandle setCaret:nil];
			[startHandle removeFromSuperview];
			[startHandle release];
		}
		startHandle = view;
		needsUpdate = YES;
		if (startHandle) {
			[startHandle retain];
			[startHandle setOwner:owner];
			[startHandle setHandleType:-1];
			[startHandle setCaret:self.startCaret];
			if (handlesShown) {
				[startHandle setHidden:NO];
				[startCaret setHidden:NO];
			} else {
				[startHandle setHidden:YES];
				[startCaret setHidden:YES];
			}
			[self addSubview:startHandle];
			[self bringSubviewToFront:startHandle];
		}
	}
}
- (PhiTextSelectionHandle *)startHandle {
	if (needsUpdate) [self update];
	return [[startHandle retain] autorelease];
}
- (void)setEndHandle:(PhiTextSelectionHandle *)view {
	if (endHandle != view) {
		if (endHandle) {
			[endHandle setOwner:nil];
			[endHandle setCaret:nil];
			[endHandle removeFromSuperview];
			[endHandle release];
		}
		endHandle = view;
		needsUpdate = YES;
		if (endHandle) {
			[endHandle retain];
			[endHandle setOwner:owner];
			[endHandle setHandleType:1];
			[endHandle setCaret:self.endCaret];
			if (handlesShown)
				[endHandle setHidden:NO];
			else
				[endHandle setHidden:YES];
			[self addSubview:endHandle];
			[self bringSubviewToFront:endHandle];
		}
	}
}
- (PhiTextSelectionHandle *)endHandle {
	if (needsUpdate) [self update];
	return [[endHandle retain] autorelease];
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self setupSubviews];
		[self setupLayer];
	}
	return self;
}

- (void)dealloc {
	self.selectionColor = nil;
	//self.lightestSelectionColor = nil;
	//self.darkestSelectionColor = nil;
	self.startCaret = nil;
	self.endCaret = nil;
	//if (selectionPath) {
	//	CGPathRelease(selectionPath);
	//	selectionPath = NULL;
	//}
	if (lastSelectedTextRange)
		[lastSelectedTextRange release];
	lastSelectedTextRange = nil;
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	[dirtyTextFrames release];
#endif
    [super dealloc];
}

- (BOOL)isBlinking {
#ifdef TRACE
	NSLog(@"%@Getting %s:%s (%d)...", traceIndent, __FUNCTION__, (blinking > 0)?"YES":"NO", blinking);
#endif
	return (blinking > 0);
}

- (void)stopBlinking {
#ifdef TRACE
	NSLog(@"%@Entering %s:%d...", traceIndent, __FUNCTION__, blinking);
#endif
	if ([self isBlinking]) {
		[[self startCaret] setBlinkLength:0.0];
		[[self endCaret] setBlinkLength:0.0];
		blinking = NO;
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:%d.", traceIndent, __FUNCTION__, blinking);
#endif
}
- (void)startBlinking {
#ifdef TRACE
	NSLog(@"%@Entering %s:%d...", traceIndent, __FUNCTION__, blinking);
#endif
	if (![self isBlinking]) {
		[[self startCaret] setBlinkLength:1.0];
		[[self endCaret] setBlinkLength:1.0];
		blinking = YES;
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:%d.", traceIndent, __FUNCTION__, blinking);
#endif
}
- (void)pauseBlinking {
#ifdef TRACE
	NSLog(@"%@Entering %s:%d...", traceIndent, __FUNCTION__, blinking);
#endif
	if (blinking == 1) {
#ifdef DEVELOPER
		NSLog(@"Stop blinking now...");
#endif
		[[self startCaret] saveState];
		[[self endCaret] saveState];
		[[self startCaret] setBlinkLength:0.0];
		[[self endCaret] setBlinkLength:0.0];
	}
	blinking--;
#ifdef TRACE
	NSLog(@"%@Exiting %s:%d.", traceIndent, __FUNCTION__, blinking);
#endif
	return;
}
- (void)resumeBlinking {
#ifdef TRACE
	NSLog(@"%@Entering %s:%d...", traceIndent, __FUNCTION__, blinking);
#endif
	if (blinking == 0) {
#ifdef DEVELOPER
		NSLog(@"Start blinking now...");
#endif
		[[self startCaret] restoreState];
		[[self endCaret] restoreState];
	}
	blinking++;
#ifdef TRACE
	NSLog(@"%@Exiting %s:%d.", traceIndent, __FUNCTION__, blinking);
#endif
	return;
}

- (void)setHidden:(BOOL)hidden {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if (hidden) {
		[self pauseBlinking];
	} else {
		[self resumeBlinking];
	}

	[super setHidden:hidden];
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}

@end
