//
//  PhiTextSelectionView.m
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

@synthesize owner, delegate;
@synthesize startCaret, endCaret;
@synthesize startHandle, endHandle;

- (PhiTextRange *)selectedTextRange {
	return [self.delegate textSelectionViewSelectedTextRange:self];
}

- (BOOL)shouldShowSelectionHandle:(PhiTextSelectionHandle *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:shouldShowSelectionHandle:)]) {
		return [self.delegate textSelectionView:self shouldShowSelectionHandle:view];
	}
	return YES;
}
- (void)didShowSelectionHandle:(PhiTextSelectionHandle *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:didShowSelectionHandle:)]) {
		[self.delegate textSelectionView:self didShowSelectionHandle:view];
	}
}
- (BOOL)shouldHideSelectionHandle:(PhiTextSelectionHandle *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:shouldHideSelectionHandle:)]) {
		return [self.delegate textSelectionView:self shouldHideSelectionHandle:view];
	}
	return NO;
}
- (void)didHideSelectionHandle:(PhiTextSelectionHandle *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:didHideSelectionHandle:)]) {
		[self.delegate textSelectionView:self didHideSelectionHandle:view];
	}
}

- (BOOL)shouldShowSelectionCaret:(PhiTextCaretView *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:shouldShowSelectionCaret:)]) {
		return [self.delegate textSelectionView:self shouldShowSelectionCaret:view];
	}
	return YES;
}
- (void)didShowSelectionCaret:(PhiTextCaretView *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:didShowSelectionCaret:)]) {
		[self.delegate textSelectionView:self didShowSelectionCaret:view];
	}
}
- (BOOL)shouldHideSelectionCaret:(PhiTextCaretView *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:shouldHideSelectionCaret:)]) {
		return [self.delegate textSelectionView:self shouldHideSelectionCaret:view];
	}
	return NO;
}
- (void)didHideSelectionCaret:(PhiTextCaretView *)view {
	if ([self.delegate respondsToSelector:@selector(textSelectionView:didHideSelectionCaret:)]) {
		[self.delegate textSelectionView:self didHideSelectionCaret:view];
	}
}

- (BOOL)isHandlesShown {
	return flags.handlesShown;
}

- (BOOL)isHandlesEnabled {
	return flags.handlesEnabled;
}
- (void)setHandlesEnabled:(BOOL)flag {
	if (flags.handlesEnabled != flag) {
		flags.handlesEnabled = flag;
		if (!flags.handlesEnabled) {
			[endHandle setHidden:YES];
			[startHandle setHidden:YES];
		}
		[self setNeedsLayout];
	}
}

- (BOOL)caretsEnabled {
	return flags.caretsEnabled;
}
- (void)setCaretsEnabled:(BOOL)flag {
	if (flags.caretsEnabled != flag) {
		flags.caretsEnabled = flag;
		if (!flags.caretsEnabled) {
			[endCaret setHidden:YES];
			[startCaret setHidden:YES];
		}
		[self setNeedsLayout];
	}
}

- (BOOL)pixelAligned {
	return flags.caretsEnabled;
}
- (void)setPixelAligned:(BOOL)flag {
	if (flags.pixelAligned != flag) {
		flags.pixelAligned = flag;
		[self setNeedsLayout];
		[self setNeedsDisplay];
	}
}

- (BOOL)needsUpdate {
	return flags.needsUpdate
			|| flags.caretsEnabled && (
		   CGSizeEqualToSize(CGSizeZero, self.endCaret.frame.size) && CGRectContainsPoint(self.superview.bounds, self.endCaret.frame.origin)
			||
	       CGSizeEqualToSize(CGSizeZero, self.startCaret.frame.size) && CGRectContainsPoint(self.superview.bounds, self.startCaret.frame.origin));
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
	BOOL rangeChanged = NO;
	PhiTextRange *saveLastSelectedTextRange = [lastSelectedTextRange retain];
	PhiTextRange *selectedRange = nil;
	
	@synchronized(self) {
		if ([self needsUpdate]) {
			selectedRange = (PhiTextRange *)[self selectedTextRange];
			BOOL startChanged, endChanged;
			endChanged   = CGSizeEqualToSize(CGSizeZero,   endCaret.bounds.size) || !lastSelectedTextRange || [[self owner] comparePosition:[selectedRange end] toPosition:[lastSelectedTextRange end]] != NSOrderedSame;
			startChanged = CGSizeEqualToSize(CGSizeZero, startCaret.bounds.size) || !lastSelectedTextRange || [[self owner] comparePosition:[selectedRange start] toPosition:[lastSelectedTextRange start]] != NSOrderedSame;
			rangeChanged = endChanged || startChanged;
			if (selectedRange && ![self isHidden]) {
				CGRect startRect;
				CGRect endRect = [self convertRect:[[self owner] visibleCaretRectForPosition:[selectedRange end] alignPixels:YES toView:self] fromView:[self owner]];
				if (!endChanged && !CGSizeEqualToSize(CGSizeZero, endRect.size)) {// Maybe the rect has...
					endChanged = !CGRectEqualToRect(endRect, [endCaret frame]);
				}
				if (![selectedRange isEmpty]) {
#ifdef DEVELOPER
					NSLog(@"Selected range is not empty.");
#endif
					startRect = [self convertRect:[[self owner] visibleCaretRectForPosition:[selectedRange start] alignPixels:YES toView:self] fromView:[self owner]];
					if (!startChanged && !CGSizeEqualToSize(CGSizeZero, startRect.size)) {// Maybe the rect has...
						startChanged = !CGRectEqualToRect(startRect, [startCaret frame]);
					}
					rangeChanged = endChanged || startChanged;
					if (flags.caretsEnabled & startChanged) {
						[startCaret setFrame:startRect];
					}
					if (flags.handlesEnabled & startChanged) {
						if (!CGSizeEqualToSize(CGSizeZero, startRect.size)) {
							[startHandle setCenter:CGPointMake(CGRectGetMidX(startRect), CGRectGetMinY(startRect))];
						}
					}
					if (flags.handlesEnabled & rangeChanged) {
						CGSize proximityDistance = CGSizeMake(CGRectGetMidX(endRect) - CGRectGetMidX(startRect), CGRectGetMidY(endRect) - CGRectGetMidY(startRect));
						[startHandle setProximityDistance:proximityDistance];
						[endHandle setProximityDistance:proximityDistance];
					}
#ifdef DEVELOPER
					NSLog(@"Handles and start caret might be hidden, show them now.");
#endif
					if (flags.caretsEnabled) {
						if ([startCaret isHidden] && [self shouldShowSelectionCaret:startCaret]) {
							[self stopBlinking];
							[startCaret setHidden:NO];
							[self didShowSelectionCaret:startCaret];
						}
					}
					if (flags.handlesEnabled) {
						if ([startHandle isHidden] && !CGSizeEqualToSize(CGSizeZero, startRect.size)
							&& [self shouldShowSelectionHandle:startHandle]) {
							[startHandle setHidden:NO];
							flags.handlesShown = YES;
							[self didShowSelectionHandle:startHandle];
						}
						if ([endHandle isHidden] && !CGSizeEqualToSize(CGSizeZero, endRect.size)
							&& [self shouldShowSelectionHandle:endHandle]) {
							[endHandle setHidden:NO];
							flags.handlesShown = YES;
							[self didShowSelectionHandle:endHandle];
						}
					}
				}
				
				if (flags.caretsEnabled & endChanged)
					[endCaret setFrame:endRect];
				if (flags.handlesEnabled & endChanged) {
					if (!CGSizeEqualToSize(CGSizeZero, endRect.size)) {
						[endHandle setCenter:CGPointMake(CGRectGetMidX(endRect), CGRectGetMaxY(endRect))];
						if (flags.handlesShown && [endHandle isHidden] && [self shouldShowSelectionHandle:endHandle]) {
							[endHandle setHidden:NO];
							[self didShowSelectionHandle:endHandle];
						}
					} else if (![endHandle isHidden]) {
						[endHandle setHidden:YES];
						[self didHideSelectionHandle:endHandle];
					}
				}
				if (flags.caretsEnabled & [endCaret isHidden] && [self shouldShowSelectionCaret:endCaret]) {
					[endCaret setHidden:NO];
					[self didShowSelectionCaret:endCaret];
				}
				
			}
			if (flags.caretsEnabled & flags.handlesShown) {
				if (![startCaret isHidden] && (!selectedRange || [selectedRange isEmpty] || [self shouldHideSelectionCaret:startCaret])) {
					[startCaret setHidden:YES];
					[self startBlinking];
					[self didHideSelectionCaret:startCaret];
				}
			}
			if (flags.handlesEnabled & flags.handlesShown) {
#ifdef DEVELOPER
				NSLog(@"Will hide start caret and handles.");
#endif
				if ((!selectedRange || [selectedRange isEmpty] || [self shouldHideSelectionHandle:startHandle])) {
					[startHandle setHidden:YES];
					[self didHideSelectionHandle:startHandle];
				}
				if ((!selectedRange || [selectedRange isEmpty] || [self shouldHideSelectionHandle:endHandle])) {
					[endHandle setHidden:YES];
					[self didHideSelectionHandle:endHandle];
				}
				flags.handlesShown = ![startHandle isHidden] || ![endHandle isHidden];
			}
			if (flags.caretsEnabled && ![endCaret isHidden] && (!selectedRange || [self shouldHideSelectionCaret:endCaret])) {
				[endCaret setHidden:YES];
				[self didHideSelectionCaret:endCaret];
			}
			if (flags.selectionPathValid && (!selectedRange || rangeChanged)) {
				flags.selectionPathValid = NO;
				if (!selectedRange)
					((CAShapeLayer *)self.layer).path = NULL;
			}
			flags.needsUpdate = NO;
			
			rangeChanged = endChanged || startChanged;
			[lastSelectedTextRange release];
			lastSelectedTextRange = [selectedRange copy];
		}
	}

	if (rangeChanged && (selectedRange && ![selectedRange isEmpty] || saveLastSelectedTextRange && ![saveLastSelectedTextRange isEmpty]))
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
	[saveLastSelectedTextRange release];
	
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}

- (void)setNeedsDisplay {
	flags.selectionPathValid = NO;
	[self selectionPath];
}

- (void)setNeedsLayout {
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	// Begin access to text frames that will be needed in update
	if ([self selectedTextRange] && ![self isHidden]) {
		PhiAATreeRange *nodes = [self.owner.textDocument beginContentAccessInRect:self.owner.bounds];
		[dirtyTextFrames addObject:nodes];
	}
#endif
	[super setNeedsLayout];
	flags.needsUpdate = YES;
}

- (CGPathRef)selectionPath {
	BOOL allHandlesShown = ![startCaret isHidden] && ![endCaret isHidden];
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	[self update];
	if (allHandlesShown) {
		CGMutablePathRef path = CGPathCreateMutable();
		[[self.owner textDocument] buildPath:path withFirstRect:[self convertRect:[startCaret frame] toView:[self owner]] toLastRect:[self convertRect:[endCaret frame] toView:[self owner]] alignPixels:flags.pixelAligned toView:self];
		flags.selectionPathValid = YES;
		shape.path = path;
		CGPathRelease(path);
	} else if (!flags.selectionPathValid) {
		PhiTextRange *selectedRange = (PhiTextRange *) [self selectedTextRange];
		if ([selectedRange length]) {
			CGMutablePathRef path = CGPathCreateMutable();
			[[self.owner textDocument] buildPath:path forRange:selectedRange alignPixels:flags.pixelAligned toView:self];
			flags.selectionPathValid = YES;
			shape.path = path;
			CGPathRelease(path);
		} else {
			shape.path = NULL;
		}
	}

	return shape.path;
}

- (void)setSelectionColor:(UIColor *)color {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	if (color) {
		shape.fillColor = color.CGColor;
	} else {
		shape.fillColor = nil;
	}
}
- (UIColor *)selectionColor {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	CGColorRef color = shape.fillColor;
	if (color)
		return [UIColor colorWithCGColor:color];
	return nil;
}

- (void)setSelectionStrokeColor:(UIColor *)color {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	if (color) {
		shape.strokeColor = color.CGColor;
	} else {
		shape.strokeColor = nil;
	}
}
- (UIColor *)selectionStrokeColor {
	CAShapeLayer *shape = (CAShapeLayer *)self.layer;
	CGColorRef color = shape.strokeColor;
	if (color)
		return [UIColor colorWithCGColor:color];
	return nil;
}

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
- (void)didMoveToWindow {
	UIScreen *screen = [[self window] screen];
	if ([screen respondsToSelector:@selector(scale)]) {
		self.layer.rasterizationScale = [screen scale];
	}
}
- (void)setupSubviews {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	[self setOpaque:NO];
	[self setUserInteractionEnabled:NO];
	blinking = YES;
	lastSelectedTextRange = nil;
	flags.needsUpdate = YES;
	flags.caretsEnabled = YES;
	flags.handlesEnabled = YES;
	flags.pixelAligned = YES;
	
	[self setStartCaret:[[[PhiTextCaretView alloc] initWithFrame:CGRectZero] autorelease]];
	[self setEndCaret:[[[PhiTextCaretView alloc] initWithFrame:CGRectZero] autorelease]];

	[self setStartHandle:[[[PhiTextSelectionHandle alloc] initWithFrame:CGRectZero] autorelease]];
	[self setEndHandle:[[[PhiTextSelectionHandle alloc] initWithFrame:CGRectZero] autorelease]];
	
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	dirtyTextFrames = [[NSMutableSet alloc] init];
#endif
}

- (id<PhiTextSelectionViewDelegate>)delegate {
	if (!delegate && [self.owner conformsToProtocol:@protocol(PhiTextSelectionViewDelegate)]) {
		delegate = self.owner;
	}
	return delegate;
}
- (PhiTextEditorView *)owner {
	UIView *view = self.superview;
	if (!owner && view) {
		do {
			if ([view isKindOfClass:[PhiTextEditorView class]]) {
				self.owner = (PhiTextEditorView *)view;
				break;
			}
		} while (view = view.superview);
	}
	return owner;
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
		BOOL caretHidden = YES;
		if (startCaret) {
			caretHidden = [startCaret isHidden];
			[startCaret setOwner:nil];
			[startHandle setCaret:nil];
			[startCaret removeFromSuperview];
			[startCaret release];
		}
		startCaret = view;
		flags.needsUpdate = YES;
		if (startCaret) {
			[startCaret setHidden:caretHidden];
			[startCaret setOwner:self.owner];
			[startHandle setCaret:startCaret];
			[self addSubview:startCaret];
			[self sendSubviewToBack:startCaret];
			[startCaret retain];
		}
	}
}
- (void)setEndCaret:(PhiTextCaretView *)view {
	if (endCaret != view) {
		BOOL caretHidden = YES;
		if (endCaret) {
			caretHidden = [endCaret isHidden];
			[endCaret setOwner:nil];
			[endHandle setCaret:nil];
			[endCaret removeFromSuperview];
			[endCaret release];
		}
		endCaret = view;
		flags.needsUpdate = YES;
		if (endCaret) {
			[endCaret setHidden:caretHidden];
			[endCaret setOwner:self.owner];
			[endHandle setCaret:endCaret];
			[self addSubview:endCaret];
			[self sendSubviewToBack:endCaret];
			[endCaret retain];
		}
	}
}

- (void)setStartHandle:(PhiTextSelectionHandle *)view {
	if (startHandle != view) {
		BOOL handleHidden = YES;
		if (startHandle) {
			handleHidden = [startHandle isHidden];
			[startHandle setOwner:nil];
			[startHandle setCaret:nil];
			[startHandle removeFromSuperview];
			[startHandle release];
		}
		startHandle = view;
		flags.needsUpdate = YES;
		if (startHandle) {
			[startHandle retain];
			[startHandle setHidden:handleHidden];
			[startHandle setOwner:self.owner];
			[startHandle setHandleType:-1];
			[startHandle setCaret:self.startCaret];
			[self addSubview:startHandle];
			[self bringSubviewToFront:startHandle];
		}
	}
}
- (PhiTextSelectionHandle *)startHandle {
	if (flags.needsUpdate) [self update];
	return [[startHandle retain] autorelease];
}
- (void)setEndHandle:(PhiTextSelectionHandle *)view {
	if (endHandle != view) {
		BOOL handleHidden = YES;
		if (endHandle) {
			handleHidden = [endHandle isHidden];
			[endHandle setOwner:nil];
			[endHandle setCaret:nil];
			[endHandle removeFromSuperview];
			[endHandle release];
		}
		endHandle = view;
		flags.needsUpdate = YES;
		if (endHandle) {
			[endHandle retain];
			[endHandle setHidden:handleHidden];
			[endHandle setOwner:self.owner];
			[endHandle setHandleType:1];
			[endHandle setCaret:self.endCaret];
			[self addSubview:endHandle];
			[self bringSubviewToFront:endHandle];
		}
	}
}
- (PhiTextSelectionHandle *)endHandle {
	if (flags.needsUpdate) [self update];
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
