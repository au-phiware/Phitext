//
//  PhiTextEditorView.m
//  FirstCoreText
//
//  Created by Corin Lawson on 4/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextView.h"
#import "PhiTextDocument.h"
#import "PhiTextFrame.h"
//#import "PhiTextSelectionView.h"
#import "PhiTextLine.h"
#import "PhiAATree.h"

#ifndef PHI_PIXEL_PERFECT_MAG
#define PHI_PIXEL_PERFECT_MAG 1
#endif

#ifdef DEVELOPER
#ifndef DRAW_OUTLINE
#define DRAW_OUTLINE 1
#endif
#endif

#ifdef DEVELOPER
#ifndef DEBUG_LINE_NUMBERS
#define DEBUG_LINE_NUMBERS 1
#endif
#endif

NSString * const kPhiTextViewLayerOwner = @"PhiTextViewLayerOwner";
NSString * const kPhiTextViewLayerNeedsClear = @"PhiTextViewLayerNeedsClear";

@interface PhiTextView ()

@property (nonatomic, readonly) CALayer *textLayer;
@property (nonatomic, readonly) CALayer *bgLayer;

- (void)setupLayers;
- (void)setupLinedBackground;

@end

#pragma mark -

@interface PhiTextViewLayerDelegate : NSObject {
	UIColor *lineColor;
	CGFloat lineWidth;
	BOOL displayDottedThirds;
}
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, retain) UIColor *lineColor;
@property (getter=shouldDrawDottedThirds) BOOL displayDottedThirds;
+ (PhiTextViewLayerDelegate *)sharedLayerDelegate;
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext;
@end

static PhiTextViewLayerDelegate *sharedTextLayerDelegate = nil;

@implementation PhiTextViewLayerDelegate

@synthesize lineColor, lineWidth, displayDottedThirds;

- (id<CAAction>)actionForLayer:(CALayer *)theLayer forKey:(NSString *)key {
	return (id<CAAction>)[NSNull null];
}

#define HALF_SIZE 8    // half the size of the pattern cell

static void PhiTextViewBackgroundPattern (void *info, CGContextRef context) {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	CGFloat magnification = 1.0;
#if PHI_PIXEL_PERFECT_MAG
	magnification = [defaults floatForKey:@"magnification"];
#endif
	CGContextAddRect(context,
					 CGRectMake(0, 0,
								HALF_SIZE * magnification, HALF_SIZE * magnification));
	CGContextAddRect(context,
					 CGRectMake(HALF_SIZE * magnification, HALF_SIZE * magnification,
								HALF_SIZE * magnification, HALF_SIZE * magnification));
    CGContextFillPath(context);
}

- (void)drawLayer:(CALayer *)layer
        inContext:(CGContextRef)context {
	CGContextSaveGState(context);
	PhiTextView *view = [layer valueForKey:kPhiTextViewLayerOwner];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
#ifdef DEVELOPER
	NSLog(@"%@Entering -[PhiTextView drawLayer:%@ inRect:(%.1f, %.1f) (%.1f, %.1f)] layer.bounds:(%.1f, %.1f) (%.1f, %.1f)...", traceIndent, layer, CGRectComp(CGContextGetClipBoundingBox(context)), CGRectComp(layer.bounds));
#endif
	PhiAATreeRange *textFrameRange;
	PhiTextFrame *textFrame;
	CGFloat magnification = 1.0;
#if PHI_PIXEL_PERFECT_MAG
	magnification = [defaults floatForKey:@"magnification"];
	CGContextScaleCTM(context, magnification, magnification);
#endif
	CGRect rect = CGContextGetClipBoundingBox(context);
	CGRect documentBounds = CGRectOffset(rect, -[view.document paddingLeft], -[view.document paddingTop]);
#ifdef DEVELOPER
	NSLog(@"%@Drawing rect:(%.1f, %.1f) (%.1f, %.1f) view.frame:(%.1f, %.1f) (%.1f, %.1f)...", traceIndent, CGRectComp(rect), CGRectComp(view.frame));
#endif
	
#ifdef DRAW_HOLDING_PATTERN
	{
		CGPatternRef pattern;
		CGColorSpaceRef baseSpace;
		CGColorSpaceRef patternSpace;
		
		baseSpace = CGColorSpaceCreateDeviceRGB();
		patternSpace = CGColorSpaceCreatePattern (baseSpace);
		CGContextSetFillColorSpace (context, patternSpace);
		CGColorSpaceRelease(patternSpace);
		CGColorSpaceRelease(baseSpace);
		static const CGPatternCallbacks callbacks = {
			0, &PhiTextViewBackgroundPattern, NULL};
		static const float color[4] = { 0, 0, 0, 0.2 };
		
		pattern = CGPatternCreate(NULL,
								  CGRectMake(0, 0,
											 HALF_SIZE * 2 * magnification, HALF_SIZE * 2 * magnification),
								  CGAffineTransformIdentity,
								  HALF_SIZE * 2 * magnification, HALF_SIZE * 2 * magnification + 0.5,
								  kCGPatternTilingConstantSpacing,
								  false, &callbacks);
		
		CGContextSetFillPattern (context, pattern, color);
		CGPatternRelease (pattern);
		CGContextFillRect (context, rect);
	}
#else
	if (view.opaque) {
		CGContextSetFillColorWithColor(context, view.backgroundColor.CGColor);
		CGContextFillRect(context, rect);
	} else
		CGContextClearRect(context, rect);
#endif
	@synchronized(view.document.store) {//Thanks Philippe
		textFrameRange = [view.document beginContentAccessInRect:documentBounds updateDisplay:NO];
#ifdef DRAW_HOLDING_PATTERN
		CGContextClearRect(context, rect);
#endif
		
		//Draw Text
		CGContextSaveGState(context); {
			CGContextTranslateCTM(context, [view.document paddingLeft], [view.document paddingTop]);
			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextSetFillColorWithColor(context, view.document.currentColor.CGColor);
			CGContextSetStrokeColorWithColor(context, view.document.currentColor.CGColor);
			CGContextSetTextMatrix(context, CGAffineTransformIdentity);
			if (textFrameRange) {
#ifdef DRAW_OUTLINE
				PhiAATreeNode *currentNode = textFrameRange.start;
#endif
				CGRect textFrameRect;
				for (textFrame in textFrameRange) {
					textFrameRect = [textFrame rect];
					if (CGRectIntersectsRect(documentBounds, textFrameRect)) {
#ifdef DRAW_OUTLINE
						//Draw text frame outlines
						CGContextSaveGState(context); {
							CGContextScaleCTM(context, 1.0, -1.0);
							CGContextSetBlendMode(context, kCGBlendModeNormal);
							if (textFrame == [view.document lastEmptyFrame]) {
								CGContextSetFillColorWithColor(context, [[[UIColor brownColor] colorWithAlphaComponent:0.5] CGColor]);
							} else {
								CGRect top, bottom;
								CGRectDivide(textFrameRect, &top, &bottom, ((CGFloat)[view.document tileHeightHint]) - 12.0, CGRectMinYEdge);
								if (![currentNode up] || currentNode == [[currentNode up] left])
									CGContextSetFillColorWithColor(context, [[[UIColor redColor] colorWithAlphaComponent:(CGFloat)((int)[currentNode level])/6.0] CGColor]);
								else
									CGContextSetFillColorWithColor(context, [[[UIColor magentaColor] colorWithAlphaComponent:(CGFloat)((int)[currentNode level])/6.0] CGColor]);
								CGContextFillRect(context, textFrameRect);
								textFrameRect = bottom;
							}
							CGContextFillRect(context, textFrameRect);
							currentNode = currentNode.next;
						} CGContextRestoreGState(context);
#endif
						CGContextSaveGState(context); {
							CGContextTranslateCTM(context, 0.0, -1.0 * (textFrameRect.size.height + textFrameRect.origin.y + textFrame.tileOffset.y));
							if (self.lineWidth != 0.0f && self.lineColor
								&& ![self.lineColor isEqual:[UIColor clearColor]]) {
								CGContextSaveGState(context); {
									CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
									CGContextSetLineWidth(context, self.lineWidth);
									CGContextSaveGState(context); {
										CGContextBeginPath(context);
										CGPoint lineOrigin;
										CFIndex count = textFrame.lineCount;
										CFRange lineRange = CFRangeMake(0, 1);
										for (; lineRange.location < count; lineRange.location++) {
											CTFrameRef _frame = [textFrame copyCTFrame];
											//line = [textFrame lineAtIndex:lineRange.location];
											CTFrameGetLineOrigins(_frame, lineRange, &lineOrigin);
											CGContextMoveToPoint(context, CGRectGetMinX(view.frame) - [view.document paddingLeft], lineOrigin.y - self.lineWidth / 2.0);
											CGContextAddLineToPoint(context, CGRectGetMaxX(view.frame), lineOrigin.y - self.lineWidth / 2.0);
											CFRelease(_frame);
										}
										CGContextStrokePath(context);
									} CGContextRestoreGState(context);
									if (self.displayDottedThirds) {
										CGContextSaveGState(context); {
											CGFloat lengths[] = {3, PHI * 3};
											CGFloat xheight;
											CGContextSetLineDash(context, 10, lengths, 2);
											CGContextBeginPath(context);
											PhiTextLine *line;
											CFIndex count = textFrame.lineCount;
											CFRange lineRange = CFRangeMake(0, 1);
											for (; lineRange.location < count; lineRange.location++) {
												line = [textFrame lineAtIndex:lineRange.location];
												//CFIndex attrCount = CFDictionaryGetCount((CFDictionaryRef) CTRunGetAttributes((CTRunRef)CFArrayGetValueAtIndex((CFArrayRef)CTLineGetGlyphRuns([line textLine]), 0)));
												//CFStringRef keys[attrCount], values[attrCount];
												//CFDictionaryGetKeysAndValues((CFDictionaryRef)CTRunGetAttributes((CFTypeRef)CFArrayGetValueAtIndex((CFArrayRef)CTLineGetGlyphRuns([line textLine]), 0)), &keys, &values);
												xheight = CTFontGetXHeight((CTFontRef)CFDictionaryGetValue(CTRunGetAttributes((CTRunRef)CFArrayGetValueAtIndex(CTLineGetGlyphRuns([line textLine]), 0)), kCTFontAttributeName));
												CGFloat xMin = CGRectGetMinX(view.frame) - [view.document paddingLeft];
												CGFloat xMax = CGRectGetMaxX(view.frame);
												CGFloat yXheight = line.originInFrame.y + xheight; //- self.lineWidth / 2.0;
												CGFloat yDescent = line.originInFrame.y - line.descent; //- self.lineWidth / 2.0;
												if (xheight) {
													CGContextMoveToPoint(context, xMin, yXheight);
													CGContextAddLineToPoint(context, xMax, yXheight);
												}
												CGContextMoveToPoint(context, xMin, yDescent);
												CGContextAddLineToPoint(context, xMax, yDescent);
											}
											CGContextStrokePath(context);
										} CGContextRestoreGState(context);
									}
								} CGContextRestoreGState(context);
							}
#if DEBUG_LINE_NUMBERS
							CGContextSaveGState(context); {
								CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Helvetica");
								CGContextSetFont(context, font);
								CGContextSetFontSize(context, 10.0);
								CGFontRelease(font);
								for (int i = 0; i < [textFrame lineCount]; i++) {
									PhiTextLine *line = [textFrame lineAtIndex:i];
									NSString *numberText = [NSString stringWithFormat:@"%i", [line number]];
									CGGlyph glyphStr[[numberText length]];
									const char *charStr = [numberText UTF8String];
									for (int j = 0; j < [numberText length]; j++)
										glyphStr[j] = charStr[j] - 29;
									CGContextShowGlyphsAtPoint(context, 2.0 - [view.document paddingLeft], line.originInFrame.y, glyphStr, [numberText length]);
								}
							} CGContextRestoreGState(context);
#endif
							CTFrameRef _frame = [textFrame copyCTFrame];
							CTFrameDraw(_frame, context);
							CFRelease(_frame);
						} CGContextRestoreGState(context);
					}
				}
			}
		} CGContextRestoreGState(context);
		[view.textLayer setValue:[NSNumber numberWithBool:NO] forKey:kPhiTextViewLayerNeedsClear];
		for (textFrame in textFrameRange)
            [textFrame endContentAccess];
	}
	
	CGContextRestoreGState(context);
	
	//Draw view outline
#ifdef DRAW_OUTLINE
	CGContextSaveGState(context); {
		CGContextSetBlendMode(context, kCGBlendModeNormal);

		CGContextSetLineWidth(context, 16.0f);
		CGContextSetStrokeColorWithColor(context, [[[UIColor greenColor] colorWithAlphaComponent:0.75] CGColor]);
		CGContextStrokeRect(context, [layer bounds]);

		CGContextSetLineWidth(context, 8.0f);
		CGContextSetStrokeColorWithColor(context, [[[UIColor cyanColor] colorWithAlphaComponent:.75] CGColor]);
		CGContextStrokeRect(context, CGContextGetClipBoundingBox(context));
	} CGContextRestoreGState(context);
#endif
#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}

#pragma mark Singleton methods

+ (PhiTextViewLayerDelegate *)sharedLayerDelegate {
    @synchronized(self)
    {
        if (sharedTextLayerDelegate == nil)
			sharedTextLayerDelegate = [[PhiTextViewLayerDelegate alloc] init];
    }
    return sharedTextLayerDelegate;
}
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedTextLayerDelegate == nil) {
            sharedTextLayerDelegate = [super allocWithZone:zone];
            return sharedTextLayerDelegate;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}
+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	int anInt;
	CFNumberRef aNumberValue;
	CFMutableArrayRef anArray;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("lineThickness"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		aFloat = DEFAULT_MAGNIFICATION;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("magnification"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		anInt = 0;
		aNumberValue = CFNumberCreate(NULL, kCFNumberIntType, &anInt);
		CFPreferencesSetAppValue(CFSTR("displayDottedThirds"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		anArray = CFArrayCreateMutable(NULL, 4, &kCFTypeArrayCallBacks);
		aFloat = 0.1f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 0.1f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = 1.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		aFloat = PHI;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFArrayAppendValue(anArray, aNumberValue);
		CFRelease(aNumberValue);
		CFPreferencesSetAppValue(CFSTR("linedRGBAColorComponents"), anArray, suiteName);
		CFRelease(anArray);
		
		aFloat = 0.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("lineThickness"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}
- (id)init {
	if (self = [super init]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"com.phitext"];
		
		NSArray *colorComponents = [defaults arrayForKey:@"linedRGBAColorComponents"];
		self.lineColor = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
									green:[[colorComponents objectAtIndex:1] floatValue]
									 blue:[[colorComponents objectAtIndex:2] floatValue]
									alpha:[[colorComponents objectAtIndex:3] floatValue]];
		self.lineWidth = [defaults floatForKey:@"lineThickness"];
		self.displayDottedThirds = [defaults boolForKey:@"displayDottedThirds"];
	}
	return self;
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return NSUIntegerMax;  // denotes an object that cannot be released
}
- (void)release {
    //do nothing
}
- (id)autorelease {
    return self;
}

@end

#pragma mark -
/*
@interface PhiTextViewSelectionLayerDelegate : NSObject
+ (PhiTextViewSelectionLayerDelegate *)sharedLayerDelegate;
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext;
@end

static PhiTextViewSelectionLayerDelegate *sharedSelectionLayerDelegate = nil;

@implementation PhiTextViewSelectionLayerDelegate

- (void)drawLayer:(CALayer *)layer
        inContext:(CGContextRef)context {
	PhiTextView *view = [layer valueForKey:kPhiTextViewLayerOwner];
	if (view.selectionView) {
		[view.selectionView drawSelectionRect:[layer bounds] inContext:context];
	}
}

#pragma mark Singleton methods

+ (PhiTextViewSelectionLayerDelegate *)sharedLayerDelegate {
    @synchronized(self)
    {
        if (sharedSelectionLayerDelegate == nil)
			sharedSelectionLayerDelegate = [[PhiTextViewSelectionLayerDelegate alloc] init];
    }
    return sharedSelectionLayerDelegate;
}
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedSelectionLayerDelegate == nil) {
            sharedSelectionLayerDelegate = [super allocWithZone:zone];
            return sharedSelectionLayerDelegate;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return NSUIntegerMax;  // denotes an object that cannot be released
}
- (void)release {
    //do nothing
}
- (id)autorelease {
    return self;
}

@end
*/
#pragma mark -

@implementation PhiTextView

@synthesize textLayer, bgLayer;

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	CFNumberRef aNumberValue;

	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("bgLayerDelegateClassName"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		aFloat = DEFAULT_MAGNIFICATION;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("magnification"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		//CFPreferencesSetAppValue(CFSTR("selectionLayerDelegateClassName"), CFSTR("PhiTextViewSelectionLayerDelegate"), suiteName);
		CFPreferencesSetAppValue(CFSTR("textLayerDelegateClassName"), CFSTR("PhiTextViewLayerDelegate"), suiteName);
		CFPreferencesSetAppValue(CFSTR("bgLayerDelegateClassName"), CFSTR(""), suiteName);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}

@synthesize document;//, selectionView;

#pragma mark View Methods

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setUserInteractionEnabled:NO];
		[self setupLayers];
		[self setupLinedBackground];
#if PHI_DIRTY_FRAMES_IN_VIEW
		dirtyTextFrames = [[NSMutableSet alloc] init];
#endif
	}
	return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self setUserInteractionEnabled:NO];
		[self setupLayers];
		[self setupLinedBackground];
#if PHI_DIRTY_FRAMES_IN_VIEW
		dirtyTextFrames = [[NSMutableSet alloc] init];
#endif
	}
	return self;
}
- (void)setupLinedBackground {}

- (id<CAAction>)actionForLayer:(CALayer *)theLayer forKey:(NSString *)key {
	return (id<CAAction>)[NSNull null];
//	return [super actionForLayer:(CALayer *)theLayer forKey:(NSString *)key];
}

// Should only be called once
- (void)setupLayers {
//	BOOL hasBackgroundLayer = NO;
	/**/
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	if (bgLayer) [bgLayer release]; // just in case
	bgLayer = nil;
	Class bgLayerDelegateClass = NSClassFromString([defaults stringForKey:@"bgLayerDelegateClassName"]);
	if (bgLayerDelegateClass && [bgLayerDelegateClass respondsToSelector:@selector(sharedLayerDelegate)]) {
		bgLayer = [[CALayer alloc] init];
		
		[bgLayer setAnchorPoint:CGPointMake(0, 0)];
		[bgLayer setNeedsDisplayOnBoundsChange:YES];
		[bgLayer setValue:self forKey:kPhiTextViewLayerOwner];
		[bgLayer setValue:[NSNumber numberWithBool:NO] forKey:kPhiTextViewLayerNeedsClear];
		[bgLayer setDelegate:[bgLayerDelegateClass sharedLayerDelegate]];
		[[self layer] addSublayer:bgLayer];
//		hasBackgroundLayer = YES;
	}
	
	Class textLayerDelegateClass = NSClassFromString([defaults stringForKey:@"textLayerDelegateClassName"]);
	if (!textLayerDelegateClass || ![textLayerDelegateClass respondsToSelector:@selector(sharedLayerDelegate)])
		textLayerDelegateClass = [PhiTextViewLayerDelegate class];
	
	if (textLayer) [textLayer release]; // just in case
	textLayer = [[CALayer alloc] init];

#if PHI_PIXEL_PERFECT_MAG
	CGFloat magnification = [defaults floatForKey:@"magnification"];
	[textLayer setAffineTransform:CGAffineTransformMakeScale(1.0f / magnification, 1.0f / magnification)];
#endif
	[textLayer setAnchorPoint:CGPointMake(0, 0)];
	[textLayer setNeedsDisplayOnBoundsChange:YES];
	[textLayer setValue:self forKey:kPhiTextViewLayerOwner];
	[textLayer setValue:[NSNumber numberWithBool:NO] forKey:kPhiTextViewLayerNeedsClear];
	[textLayer setDelegate:[textLayerDelegateClass sharedLayerDelegate]];
	[[self layer] addSublayer:textLayer];
/*	
	Class selectionLayerDelegateClass = NSClassFromString([defaults stringForKey:@"selectionLayerDelegateClassName"]);
	if (!selectionLayerDelegateClass || ![selectionLayerDelegateClass respondsToSelector:@selector(sharedLayerDelegate)])
		selectionLayerDelegateClass = [PhiTextViewSelectionLayerDelegate class];
/*	
	if (selectionLayer) [selectionLayer release]; // just in case
	selectionLayer = [[CALayer alloc] init];
	
	[selectionLayer setAnchorPoint:CGPointMake(0, 0)];
	[selectionLayer setNeedsDisplayOnBoundsChange:YES];
	[selectionLayer setValue:self forKey:kPhiTextViewLayerOwner];
	[selectionLayer setDelegate:[selectionLayerDelegateClass sharedLayerDelegate]];
	[[self layer] addSublayer:selectionLayer];
	[selectionLayer setHidden:YES];
}
- (void)setSelectionNeedsDisplay {
	[selectionLayer setNeedsDisplay];
	 /**/
}
- (void)setNeedsDisplay {
	//[super setNeedsDisplay];
	[textLayer setNeedsDisplay];
	//[selectionLayer setNeedsDisplay];
	[bgLayer setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect {
	//[super setNeedsDisplayInRect:rect];
	[textLayer setNeedsDisplayInRect:CGRectApplyAffineTransform(rect, CGAffineTransformInvert([textLayer affineTransform]))];
	//[selectionLayer setNeedsDisplayInRect:CGRectApplyAffineTransform(rect, CGAffineTransformInvert([selectionLayer affineTransform]))];
	if (bgLayer)
		[bgLayer setNeedsDisplayInRect:CGRectApplyAffineTransform(rect, CGAffineTransformInvert([bgLayer affineTransform]))];
}

- (void)prepareForReuse {
	[textLayer setValue:[NSNumber numberWithBool:YES] forKey:kPhiTextViewLayerNeedsClear];
	if (bgLayer) {
		[bgLayer setValue:[NSNumber numberWithBool:YES] forKey:kPhiTextViewLayerNeedsClear];
	}
	[self setFrame:CGRectZero];
	[self setNeedsDisplay];
}

- (void)layoutSubviews {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	CGRect textBounds = self.frame;
	if (bgLayer) {
		[bgLayer setPosition:CGPointZero];
		[bgLayer setBounds:CGRectApplyAffineTransform(textBounds, CGAffineTransformInvert([bgLayer affineTransform]))];
	}
	[textLayer setPosition:CGPointZero];
	[textLayer setBounds:CGRectApplyAffineTransform(textBounds, CGAffineTransformInvert([textLayer affineTransform]))];
	//[selectionLayer setPosition:CGPointZero];
	//[selectionLayer setBounds:CGRectApplyAffineTransform(textBounds, CGAffineTransformInvert([selectionLayer affineTransform]))];
}

- (void)setBackgroundColor:(UIColor *)color {
	[self.superview setBackgroundColor:color];
}
- (UIColor *)backgroundColor {
	return self.superview.backgroundColor;
}

- (void)setOpaque:(BOOL)flag {
	[self.superview setOpaque:flag];
}
- (BOOL)isOpaque {
	return self.superview.opaque;
}

- (void)dealloc {
	if (bgLayer) {
		[bgLayer removeFromSuperlayer];
		[bgLayer release];
		bgLayer = nil;
	}
	if (textLayer) {
		[textLayer removeFromSuperlayer];
		[textLayer release];
		textLayer = nil;
	}
	/*
	if (selectionLayer) {
		[selectionLayer removeFromSuperlayer];
		[selectionLayer release];
		selectionLayer = nil;
	}
	 
	 */
	
#if PHI_DIRTY_FRAMES_IN_VIEW
	[dirtyTextFrames release];
#endif
	[super dealloc];
}
@end
