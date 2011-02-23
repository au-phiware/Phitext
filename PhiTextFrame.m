//
//  PhiTextFrame.m
//  Phitext
//
//  Created by Corin Lawson on 5/03/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextFrame.h"
#import "PhiTextRange.h"
#import "PhiTextPosition.h"
#import "PhiTextDocument.h"
#import "PhiTextStorage.h"
#import "PhiTextLine.h"
#import "PhiTextStyle.h"
#import "PhiTextParagraphStyle.h"

#ifndef PHI_FRAME_USE_CTLINE_API
#define PHI_FRAME_USE_CTLINE_API 1
#endif

#ifdef DEVELOPER
#define DEBUG_CONTENT_ACCESS 1
#endif

NSUInteger textRangeLengthHint = 0;
NSUInteger textRangeLengthMax = 0;

NSString * const PhiTextFrameDidDiscardContentNotification = @"PhiTextFrameDidDiscardContentNotification";
NSString * const PhiTextFrameWillDiscardContentNotification = @"PhiTextFrameWillDiscardContentNotification";

/*
CFComparisonResult PhiTextFrameCompareByRect (id textFrame, id otherTextFrame, PhiTextFrameCompareFlags flags) {
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameCompareByRect ((%.1f, %.1f) (%.1f, %.1f), (%.1f, %.1f) (%.1f, %.1f), %d)", CGRectComp([textFrame CGRectValue]), CGRectComp([otherTextFrame CGRectValue]), flags);
#endif
	CGRect rect1 = [textFrame CGRectValue];
	CGRect rect2 = [otherTextFrame CGRectValue];
	CFComparisonResult result = kCFCompareGreaterThan;
	
	if (flags & kPhiTextCompareBackwards) {
		if (CGRectGetMinY(rect2) <= CGRectGetMaxY(rect1)) {
			result = kCFCompareLessThan;
		}
	} else {
		if (!CGRectEqualToRect(rect2, CGRectNull) && CGRectGetMinY(rect1) < CGRectGetMinY(rect2)) {
			result = kCFCompareLessThan;
		}
	}
	
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameCompareByRect:%d", result);
#endif
	return result;
}
 */
CFComparisonResult PhiTextFrameCompareByRect (id textFrame, id otherTextFrame, BOOL backwards) {
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameCompareByRect ((%.1f, %.1f) (%.1f, %.1f), (%.1f, %.1f) (%.1f, %.1f), %s)", CGRectComp([textFrame CGRectValue]), CGRectComp([otherTextFrame CGRectValue]), backwards?"YES":"NO");
#endif
	CGRect rect1 = [textFrame CGRectValue];
	CGRect rect2 = [otherTextFrame CGRectValue];
	CFComparisonResult result = kCFCompareGreaterThan;
	
	if (!CGRectEqualToRect(rect2, CGRectNull)) {
		if (CGRectEqualToRect(rect1, rect2))
			result = kCFCompareEqualTo;
		else if (CGRectGetMinY(rect1) < CGRectGetMinY(rect2) && CGRectGetMaxY(rect1) <= CGRectGetMaxY(rect2))
			result = kCFCompareLessThan;
	}
	
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameCompareByRect:%d", result);
#endif
	return result;
}
CFComparisonResult PhiTextFrameCompareByRectIn (id textFrame, id otherTextFrame, BOOL backwards) {
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameCompareByRect ((%.1f, %.1f) (%.1f, %.1f), (%.1f, %.1f) (%.1f, %.1f), %s)", CGRectComp([textFrame CGRectValue]), CGRectComp([otherTextFrame CGRectValue]), backwards?"YES":"NO");
#endif
	CGRect rect1 = [textFrame CGRectValue];
	CGRect rect2 = [otherTextFrame CGRectValue];
	CFComparisonResult result = kCFCompareGreaterThan;
	
	if (!CGRectEqualToRect(rect2, CGRectNull)) {
		if (CGRectIntersectsRect(rect1, rect2))
			result = kCFCompareEqualTo;
		else if (CGRectGetMinY(rect1) < CGRectGetMinY(rect2) && CGRectGetMaxY(rect1) <= CGRectGetMaxY(rect2))
			result = kCFCompareLessThan;
	}
	
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameCompareByRect:%d", result);
#endif
	return result;
}

/*
CFComparisonResult PhiTextFrameCompareByRange (id textFrame, id otherTextFrame, PhiTextFrameCompareFlags flags) {
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameCompareByRange ((%d, %d, %d), (%d, %d, %d), %d)", [textFrame rangeValue].location, [textFrame rangeValue].length, [textFrame rangeValue].location + [textFrame rangeValue].length, [otherTextFrame rangeValue].location, [otherTextFrame rangeValue].length, [otherTextFrame rangeValue].location + [otherTextFrame rangeValue].length, flags);
#endif
	NSRange range1 = [textFrame rangeValue];
	NSRange range2 = [otherTextFrame rangeValue];
	CFComparisonResult result = kCFCompareGreaterThan;
	
	if (flags & kPhiTextCompareBackwards) {
		if (range2.location <= NSMaxRange(range1)) {
			result = kCFCompareLessThan;
		}
	} else {
		if (range1.location <= range2.location) {
			result = kCFCompareLessThan;
		}
	}
	
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameCompareByRange:%d", result);
#endif
	return result;
}
*/
CFComparisonResult PhiTextFrameCompareByRange (id textFrame, id otherTextFrame, BOOL backwards) {
/*	id autoEndContentAccess[] = {nil, nil};
	//TODO:	if ([textFrame conformsToProtocol:@protocol(NSDiscardableContent)])
	if ([textFrame respondsToSelector:@selector(beginContentAccess)] && [textFrame respondsToSelector:@selector(endContentAccess)])
		if ([textFrame beginContentAccess])
			autoEndContentAccess[0] = textFrame;
	//TODO:	if ([otherTextFrame conformsToProtocol:@protocol(NSDiscardableContent)])
	if ([otherTextFrame respondsToSelector:@selector(beginContentAccess)] && [otherTextFrame respondsToSelector:@selector(endContentAccess)])
		if ([otherTextFrame beginContentAccess])
			autoEndContentAccess[1] = otherTextFrame;
 */
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameCompareByRange ((%d, %d, %d), (%d, %d, %d), %s)", [textFrame rangeValue].location, [textFrame rangeValue].length, [textFrame rangeValue].location + [textFrame rangeValue].length, [otherTextFrame rangeValue].location, [otherTextFrame rangeValue].length, [otherTextFrame rangeValue].location + [otherTextFrame rangeValue].length, backwards?"YES":"NO");
#endif
	NSRange range1 = [textFrame rangeValue];
	NSRange range2 = [otherTextFrame rangeValue];
	NSUInteger loc1;
	NSUInteger loc2;
	CFComparisonResult result = kCFCompareGreaterThan;
	if (backwards) {
		loc1 = NSMaxRange(range1);
		loc2 = NSMaxRange(range2);
	} else {
		loc1 = range1.location;
		loc2 = range2.location;
	}

	
//	if (range1.location == range2.location && range1.length == range2.length) {
//		result = kCFCompareEqualTo;
//	} else
		if (
			   loc1 <= loc2 // needs to be inclusive so that last position in the first frame is included
			) {
		result = kCFCompareLessThan;
	}
	/*
	[autoEndContentAccess[0] endContentAccess];
	[autoEndContentAccess[1] endContentAccess];
*/
#ifdef TRACE
	char *str = result==kCFCompareEqualTo ? "=" : (result==kCFCompareLessThan ? "<" : ">");
	char *row = NSMaxRange(range1) < range2.location ? "<<" : (NSMaxRange(range1) > NSMaxRange(range2) ? ">>" : "<>");
	NSLog(@" %s | %s | %s | %s || %s | %s | %s |", row,
		  (!backwards && range1.location <  range2.location) ? str : " ",
		  (!backwards && range1.location >= range2.location && range1.location <= NSMaxRange(range2)) ? str : " ",
		  (!backwards && range1.location  > NSMaxRange(range2)) ? str : " ",
		  (backwards && range1.location <  range2.location) ? str : " ",
		  (backwards && range1.location >= range2.location && range1.location <= NSMaxRange(range2)) ? str : " ",
		  (backwards && range1.location  > NSMaxRange(range2)) ? str : " "
		  );
#endif
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameCompareByRange:%s", result==kCFCompareEqualTo?"kCFCompareEqualTo":(result==kCFCompareLessThan?"kCFCompareLessThan":"kCFCompareGreaterThan"));
#endif
	return result;
}

CFComparisonResult PhiTextFrameCompareByRangeIn (id textFrame, id otherTextFrame, BOOL backwards) {
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameCompareByRange ((%d, %d, %d), (%d, %d, %d), %s)", [textFrame rangeValue].location, [textFrame rangeValue].length, [textFrame rangeValue].location + [textFrame rangeValue].length, [otherTextFrame rangeValue].location, [otherTextFrame rangeValue].length, [otherTextFrame rangeValue].location + [otherTextFrame rangeValue].length, backwards?"YES":"NO");
#endif
	NSRange range1 = [textFrame rangeValue];
	NSRange range2 = [otherTextFrame rangeValue];
	CFComparisonResult result = kCFCompareGreaterThan;
	
	if ((range2.location >= range1.location && range2.location <= NSMaxRange(range1))
		|| (NSMaxRange(range2) >= range1.location && NSMaxRange(range2) <= NSMaxRange(range1))) {
		result = kCFCompareEqualTo;
	} else if (range1.location < range2.location && NSMaxRange(range1) <= NSMaxRange(range2)) {
		result = kCFCompareLessThan;
	}
	
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameCompareByRange:%s", result==kCFCompareEqualTo?"kCFCompareEqualTo":(result==kCFCompareLessThan?"kCFCompareLessThan":"kCFCompareGreaterThan"));
#endif
	return result;
}

CFComparisonResult PhiTextFrameComparePositionToLine (CFIndex offset, CTLineRef line, BOOL selectionAffinityBackward, BOOL hasLineBreak) {
	CFComparisonResult rv = kCFCompareEqualTo;
	CFRange stringRange = CTLineGetStringRange(line);
	if (offset < stringRange.location
		|| (selectionAffinityBackward && /*!hasLineBreak &&*/ offset == stringRange.location)
	) {
		rv = kCFCompareLessThan;
	}
	if (offset > stringRange.location + stringRange.length
		|| (!selectionAffinityBackward && !hasLineBreak && offset == stringRange.location + stringRange.length)) {
		rv = kCFCompareGreaterThan;
	}
#ifdef TRACE
	char *str = rv==kCFCompareEqualTo ? "=" : (rv==kCFCompareLessThan ? "<" : ">");
	if (offset == stringRange.location)
	NSLog(@" C | %s | %s | %s | %s |",
		   selectionAffinityBackward &&  hasLineBreak ? str : " ",
		  !selectionAffinityBackward &&  hasLineBreak ? str : " ",
		  !selectionAffinityBackward && !hasLineBreak ? str : " ",
		   selectionAffinityBackward && !hasLineBreak ? str : " "
		  );
	if (offset == stringRange.location + stringRange.length)
	NSLog(@" D | %s | %s | %s | %s |",
		   selectionAffinityBackward &&  hasLineBreak ? str : " ",
		  !selectionAffinityBackward &&  hasLineBreak ? str : " ",
		  !selectionAffinityBackward && !hasLineBreak ? str : " ",
		   selectionAffinityBackward && !hasLineBreak ? str : " "
		  );
#endif
	return rv;
}
CFIndex PhiTextFrameBSearchLineWithPosition (CFArrayRef theArray, NSRange range, CFIndex position, BOOL selectionAffinityBackward, BOOL hasLineBreak, BOOL searchBackwards) {
	CFIndex pivot;
	while (range.length > 1) {
		pivot = range.location + range.length / 2;
		if ((PhiTextFrameComparePositionToLine(position, CFArrayGetValueAtIndex(theArray, pivot), selectionAffinityBackward, hasLineBreak) == kCFCompareLessThan) ^ searchBackwards) {
			range.length = MAX(0, pivot - range.location);
		} else {
			range.length = MAX(0, range.length - pivot + range.location);
			range.location = pivot;
		}
	}
	return range.location;
}
CFComparisonResult PhiTextFrameComparePointToLine (CGPoint point, CTLineRef line, CGPoint lineOrigin, CGRect rect) {
#ifdef TRACE
	NSLog(@"Entering PhiTextFrameComparePointToLine((%.f, %.f), %@, (%.f, %.f), (%.f, %.f) (%.f, %.f))", point.x, point.y, line, lineOrigin.x, lineOrigin.y, CGRectComp(rect));
#endif
	CFComparisonResult result = kCFCompareEqualTo;
	CGFloat ascent, descent, leading, bottomBound, topBound;
	CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
	topBound = rect.origin.y + rect.size.height - lineOrigin.y - ascent - leading / 2.0;
	bottomBound = rect.origin.y + rect.size.height - lineOrigin.y + descent + leading / 2.0;
	
	if (point.y < topBound) 
		result = kCFCompareLessThan;
	else if (point.y > bottomBound)
		result = kCFCompareGreaterThan;
#ifdef TRACE
	NSLog(@"Exiting PhiTextFrameComparePointToLine:%s", result==kCFCompareEqualTo?"kCFCompareEqualTo":(result==kCFCompareLessThan?"kCFCompareLessThan":"kCFCompareGreaterThan"));
#endif
	return result;
}
CFIndex PhiTextFrameBSearchLineWithPoint (CTFrameRef textFrame, CFArrayRef textLines, CFRange range, CGPoint point, CGRect rect) {
	CFIndex pivot;
	CTLineRef line;
	CGPoint lineOrigin;
	while (range.length > 1) {
		pivot = range.location + range.length / 2;
		line = CFArrayGetValueAtIndex(textLines, pivot);
		CTFrameGetLineOrigins(textFrame, CFRangeMake(pivot, 1), &lineOrigin);
		if (PhiTextFrameComparePointToLine(point, line, lineOrigin, rect) == kCFCompareLessThan) {
			range.length = MAX(0, pivot - range.location);
		} else {
			range.length = MAX(0, range.length - pivot + range.location);
			range.location = pivot;
		}
	}
	return range.location;
}

@implementation PhiTextFrame

+ (PhiTextFrame *)textFrameInPath:(CGPathRef)constraints beginningAt:(CFIndex)stringIndex forDocument:(PhiTextDocument *)document {
	return [PhiTextFrame textFrameInPath:constraints beginningAt:stringIndex forDocument:document attributes:nil];
}
+ (PhiTextFrame *)textFrameWithFrame:(CTFrameRef)frame forDocument:(PhiTextDocument *)document {
	return [PhiTextFrame textFrameWithFrame:frame forDocument:document attributes:nil];
}
+ (PhiTextFrame *)textFrameInPath:(CGPathRef)constraints beginningAt:(CFIndex)stringIndex forDocument:(PhiTextDocument *)document attributes:(NSDictionary *)attributes {
	return [[[PhiTextFrame alloc] initInPath:constraints beginningAt:stringIndex forDocument:document attributes:attributes] autorelease];
}
+ (PhiTextFrame *)textFrameWithFrame:(CTFrameRef)frame forDocument:(PhiTextDocument *)document attributes:(NSDictionary *)attributes {
	CFRange range = CTFrameGetStringRange(frame);
	CFIndex stringIndex = range.location;
	return [PhiTextFrame textFrameInPath:CTFrameGetPath(frame) beginningAt:stringIndex forDocument:document attributes:attributes];
}

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	NSInteger aNSInt;
	CFNumberRef aNumberValue;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("textRangeLengthMax"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		aNSInt = 1 << 12;
		aNumberValue = CFNumberCreate(NULL, kCFNumberNSIntegerType, &aNSInt);
		CFPreferencesSetAppValue(CFSTR("textRangeLengthHint"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		aNSInt = NSIntegerMax;
		aNumberValue = CFNumberCreate(NULL, kCFNumberNSIntegerType, &aNSInt);
		CFPreferencesSetAppValue(CFSTR("textRangeLengthMax"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}
@synthesize textRange, rect, hasEmptyLastLine;
@synthesize document, frameAttributes, firstStringIndex, firstLineNumber;

- (PhiTextLine *)_lineAtIndex:(CFIndex)index fromTextLines:(CFArrayRef)textLines {
	if (!textLines) {
		textLines = CTFrameGetLines(textFrame);
	}
	//TODO: cache or at least keep in sparse array
	return [PhiTextLine textLineWithLine:CFArrayGetValueAtIndex(textLines, index) index:index frame:self];
}

- (id)initInPath:(CGPathRef)constraints beginningAt:(CFIndex)stringIndex forDocument:(PhiTextDocument *)doc attributes:(NSDictionary *)attributes {
	if (!textRangeLengthHint) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"com.phitext"];
		
		textRangeLengthHint = [defaults integerForKey:@"textRangeLengthHint"];
		textRangeLengthMax = [defaults integerForKey:@"textRangeLengthMax"];
		//TODO: listen for NSUserDefault notification
	}
	if (self = [super init]) {
		accessCount = 1;
		deferEndAccess = NO;
		path = constraints;
		CGPathRetain(path);
		firstStringIndex = stringIndex;
		if (firstStringIndex == 0)
			firstLineNumber = 1;
		else
			firstLineNumber = 0;
		stringIndexDiff = staleStringLength = 0;
		rect = CGRectZero;
		staleRect = CGRectNull;
		//lineCount = 0;
		document = doc;
		self.frameAttributes = attributes;
		hasEmptyLastLine = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discardContentIfPossible) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	return self;
}

- (void)validateFrameRect {
	CGRect bounds;
	bounds = CGPathGetBoundingBox(path);
	if (CGPointEqualToPoint(rect.origin, CGPointZero)) {
		rect.origin = bounds.origin;
		staleRect.origin = rect.origin;
	}
	if (rect.size.height == 0.0) {
		CFArrayRef textLines = CTFrameGetLines(textFrame);
		CFIndex count = 0;
		if (textLines)
			count = CFArrayGetCount(textLines);
		else
			count = 0;
		tileOffset = CGPointZero;
		rect.size = bounds.size;
		if (count) {
			PhiTextStyle *topStyle;
			PhiTextStyle *bottomStyle;
			CGFloat spacingAfter = 0.0;
			CGFloat spacingBefore = 0.0;
#if PHI_FRAME_USE_CTLINE_API
			CGPoint originInFrame;
			CGFloat descent;
			CTLineRef firstLine = CFArrayGetValueAtIndex(textLines, 0);
			CTLineRef lastLine = CFArrayGetValueAtIndex(textLines, count - 1);
			CFRange lineRange;
			CTFrameGetLineOrigins(textFrame, CFRangeMake(count - 1, 1), &originInFrame);
			CTLineGetTypographicBounds(firstLine, NULL, NULL, &spacingBefore);
			CTLineGetTypographicBounds(lastLine, NULL, &descent, NULL);
			rect.size.height = bounds.size.height - originInFrame.y + descent;
			lineRange = CTLineGetStringRange(lastLine);
			lineRange.location += firstStringIndex;
			bottomStyle = [document styleFromPosition:[PhiTextPosition textPositionWithPosition:lineRange.location]
						  toFarthestEffectivePosition:NULL
									notBeyondPosition:[PhiTextPosition textPositionWithPosition:lineRange.location + lineRange.length]];
			lineRange = CTLineGetStringRange(firstLine);
			lineRange.location += firstStringIndex;
			topStyle = [document styleFromPosition:[PhiTextPosition textPositionWithPosition:lineRange.location]
						  toFarthestEffectivePosition:NULL
									notBeyondPosition:[PhiTextPosition textPositionWithPosition:lineRange.location + lineRange.length]];
#else
			PhiTextLine *firstLine = [self _lineAtIndex:0 fromTextLines:textLines];
			PhiTextLine *lastLine = [self _lineAtIndex:count - 1 fromTextLines:textLines];
			rect.size.height = bounds.size.height - lastLine.originInFrame.y + lastLine.descent;
			bottomStyle = [lastLine textStyle];
			topStyle = [firstLine textStyle];
			spacingBefore = [firstLine leading];
#endif
			PhiTextParagraphStyle *paraStyle;
			paraStyle = [bottomStyle paragraphStyle];
			if ([[document store] isLineBreakAtIndex:firstStringIndex + staleStringLength - 1])
				spacingAfter += [paraStyle paragraphSpacing];
			spacingAfter += [paraStyle lineSpacing];
			paraStyle = [topStyle paragraphStyle];
			if (firstStringIndex == 0 || [[document store] isLineBreakAtIndex:firstStringIndex - 1])
				spacingBefore += [paraStyle paragraphSpacingBefore];
			rect.size.height += spacingAfter;
			tileOffset.y = bounds.size.height - rect.size.height;
			rect.size.height += spacingBefore;
		}
		staleRect.size = rect.size;
		[self.document adjustSizeToTextFrame:self exansionOnly:YES];
	}
}

- (void)_validateFrame {
#ifdef TRACE
	NSLog(@"%@Entering -[%x _validateFrame]...", traceIndent, self);
#endif
	NSRange range;
	CFRange visibleRange;
	NSAttributedString *attributedSubstring;
	NSUInteger maxStringLength = MIN(MAX([[document store] length] - firstStringIndex, 0), textRangeLengthMax);
	if (textRange) {
		range = NSMakeRange(firstStringIndex, MIN(PhiRangeLength(textRange) + 2, maxStringLength));
		[textRange release];
		textRange = nil;
	} else {
		range = NSMakeRange(firstStringIndex, MIN(MAX(textRangeLengthHint, 2), maxStringLength));
	}
#if !PHI_FRAMESETTER_MEMBER
	CTFramesetterRef framesetter = NULL;
#endif
	
	hasEmptyLastLine = NO;
	do {
		if (!framesetter) {
			attributedSubstring = [[document store] attributedSubstringFromRange:range];
			framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedSubstring);
		}
		textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, range.length), path, (CFDictionaryRef)frameAttributes);
		visibleRange = CTFrameGetVisibleStringRange(textFrame);
		CFIndex lineCount = 0;
		if (textFrame) {
			CFArrayRef lines = CTFrameGetLines(textFrame);
			if (lines)
				lineCount = CFArrayGetCount(lines);
		}
		// Grow path if it is too small for any text
		if (!textFrame || !visibleRange.length || !lineCount) {
			if (textFrame) {
				CFRelease(textFrame);
				textFrame = NULL;
			}
			CGRect pathBounds = CGPathGetBoundingBox(path);
			if (pathBounds.size.height > 0.0) {
				pathBounds.size.height *= 1.5;
			} else {
				pathBounds.size.height = 10.0;
			}
			CGPathRelease(path);
			path = CGPathCreateMutable();
			CGPathAddRect((CGMutablePathRef)path, NULL, pathBounds);
		}
		// Workaround for line ending at string end rendering issue
		else if (range.length > visibleRange.length) {
			visibleRange.location = range.location;
		} else if (range.length == maxStringLength) {
			//TODO: drop last line to ensure the frame is whole (long line check)
			//if (maxStringLength == textRangeLengthMax) {}
			visibleRange.location = range.location;
		} else {
			CFRelease(framesetter);
			framesetter = NULL;
			CFRelease(textFrame);
			textFrame = NULL;
			range.length = MIN(range.length * 2, maxStringLength);
		}
	} while (!textFrame);
	if (framesetter) {
		CFRelease(framesetter);
		framesetter = NULL;
	}
#ifdef DEVELOPER
	NSLog(@"visibleRange: %@", NSStringFromRange(NSMakeRange(visibleRange.location, visibleRange.length)));
#endif
	if (visibleRange.length > 0
		&& (visibleRange.length == 1 || [[document store] isLineBreakAtIndex:range.location + visibleRange.length - 2])
		&& [[document store] isLineBreakAtIndex:range.location + visibleRange.length - 1]) {
		hasEmptyLastLine = YES;
		//if (visibleRange.length > 1)
		//	visibleRange.length--;
	}
	textRange = [[PhiTextRange textRangeWithCFRange:visibleRange] retain];
	stringIndexDiff += visibleRange.length - staleStringLength;
	staleStringLength = visibleRange.length;
#ifdef DEVELOPER
	NSLog(@"textRange: %@", NSStringFromRange([textRange range]));
#endif
	rect.size = CGSizeZero;
#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}
- (void)validateFrame:(BOOL)includeGeometry {
	NSAssert(accessCount > 0, @"The content of this PhiTextFrame has been discarded and can not be used, call the beginContentAccess method first.");

#ifdef TRACE
	NSLog(@"%@Entering -[%@ validateFrame]...", traceIndent, self);
#endif
	if (firstStringIndex >= 0 && path && document && [document store]) {
		if (!textFrame) {
			[self _validateFrame];
		}
		if (includeGeometry)
			[self validateFrameRect];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}

- (BOOL)beginTextAccess {
	accessCount++;
	[self validateFrame:NO];
	if (![self isContentDiscarded])
		return YES;
	accessCount--;
	return NO;
}

- (BOOL)beginContentAccess {
	accessCount++;
	[self validateFrame:YES];
	if (![self isContentDiscarded])
		return YES;
	accessCount--;
	return NO;
}

- (void)endContentAccess {
	NSAssert(accessCount > 0, @"Access to the content of this PhiTextFrame has not began, call the beginContentAccess method first.");
	accessCount--;
	if (!deferEndAccess)
		[self discardContentIfPossible];
}

- (void)deferedEndContentAccess {
	deferEndAccess = NO;
	[self performSelector:@selector(endContentAccess) withObject:nil afterDelay:0.2];
	//[self endContentAccess];
}

- (PhiTextFrame *)autoEndContentAccess {
#if DEBUG_CONTENT_ACCESS
	[self endContentAccess];
#else
	NSAssert(accessCount > 0, @"Access to the content of this PhiTextFrame has not began, call the beginContentAccess method first.");
	if (deferEndAccess) {
		accessCount--;
	}
	else {
		[self performSelectorOnMainThread:@selector(deferedEndContentAccess) withObject:nil waitUntilDone:NO];
		deferEndAccess = YES;
	}
#endif
	return self;
}

- (void)invalidateFrame {
#ifdef TRACE
	NSLog(@"%@Entering -[%x invalidateFrame]...", traceIndent, self);
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:PhiTextFrameWillDiscardContentNotification object:self];
#if PHI_FRAMESETTER_MEMBER
	if (framesetter) {
		CFRelease(framesetter);
		framesetter = NULL;
	}
#endif
	if (textFrame) {
		CFRelease(textFrame);
		textFrame = NULL;
	}
	//TODO: invalidate any PhiTextLines associated with this frame
	//TODO: should we use (NAN, NAN) instead of (0, 0)??
	rect.size = CGSizeZero;
	[[NSNotificationCenter defaultCenter] postNotificationName:PhiTextFrameDidDiscardContentNotification object:self];
}
- (void)discardContentIfPossible {
#ifdef TRACE
	NSLog(@"%@Entering -[%x discardContentIfPossible] %d...", traceIndent, self, accessCount);
#endif
	if (accessCount <= 0 || (accessCount == 1 && deferEndAccess)) {
		[self invalidateFrame];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}
- (BOOL)isContentDiscarded {
	return textFrame == NULL || accessCount <= 0;
}

/*! Since CTFrame is immutable (and has no copy method) retain is used instead of copy. */
- (CTFrameRef)copyCTFrame {
	CTFrameRef rv = NULL;
	if ([self beginContentAccess]) {
		rv = CFRetain(textFrame);
		[self autoEndContentAccess];
	}
	
	return rv;
}

- (void)setOrigin:(CGPoint)origin {
	if (!CGPointEqualToPoint(rect.origin, origin)) {
		rect.origin = origin;
		staleRect.origin = origin;
		if (![self isContentDiscarded])
			[self.document adjustSizeToTextFrame:self exansionOnly:YES];
	}
}

- (CGPoint)origin {
	CGPoint rv = CGPointZero;
	if ([self beginContentAccess]) {
		rv = rect.origin;
		[self autoEndContentAccess];
	}

	return rv;
}

- (CGPoint)tileOffset {
	CGPoint rv = CGPointZero;
	if ([self beginContentAccess]) {
		rv = tileOffset;
		[self autoEndContentAccess];
	}
	
	return rv;
}

- (CGSize)tileSize {
	CGSize rv = CGSizeZero;

	if (path) {
		CGRect pathBounds = CGPathGetBoundingBox(path);
		rv = pathBounds.size;
	}
	
	return rv;
}

- (CGSize)size {
	CGSize rv = CGSizeZero;
	if ([self beginContentAccess]) {
		rv = rect.size;
		[self autoEndContentAccess];
	}
	
	return rv;
}

- (CGFloat)realWidth {
	CGFloat width = rect.size.width;
	if ([self isContentDiscarded]) {
		if ([self beginContentAccess]) {
			width = rect.size.width;
			if (width == CGFLOAT_MAX) {
				CFArrayRef lines = CTFrameGetLines(textFrame);
				CGFloat maxWidth = 0.0;
				CFIndex count = CFArrayGetCount(lines);
				for (CFIndex i = 0; i < count; i++) {
					width = CTLineGetTypographicBounds(CFArrayGetValueAtIndex(lines, i), NULL, NULL, NULL);
					maxWidth = MAX(maxWidth, width);
				}
				width = rect.size.width = maxWidth;
			}
			[self autoEndContentAccess];
		}
	}
	return width;
}

- (CGRect)rect {
	CGRect rv = CGRectNull;
	if ([self beginContentAccess]) {
		rv = rect;
		[self autoEndContentAccess];
	}
	
	return rv;
}

- (CGRect)CGRectValue {
	return staleRect;
}

- (NSRange)rangeValue {
	if (firstStringIndex >= 0) {
		return NSMakeRange(firstStringIndex, staleStringLength);
	}
	return NSMakeRange(0, 0);
}
- (PhiTextRange *)textRange {
	PhiTextRange *rv = nil;
	if ([self beginTextAccess]) {
		rv = [[textRange retain] autorelease];
		[self autoEndContentAccess];
	}
	
	return rv;
}

- (CFIndex)changeInTextRange {
	CFIndex rv = stringIndexDiff;
	stringIndexDiff = 0;
	return rv;
}
- (void)setFirstStringIndex:(CFIndex)index {
	firstStringIndex = index;
	if (firstStringIndex == 0)
		firstLineNumber = 1;
	if (textRange) {
		[textRange release];
		textRange = [[PhiTextRange textRangeWithRange:NSMakeRange(firstStringIndex, staleStringLength)] retain];
	}
}
- (void)setFirstLineNumber:(NSUInteger)number {
	firstLineNumber = number;
}
- (void)setTextRange:(PhiTextRange *)aRange {
	if (![textRange isEqual:aRange]) {
		if (textFrame) {
			CFRelease(textFrame);
			textFrame = NULL;
		}

		CGRect pathBounds = CGPathGetBoundingBox(path);
		pathBounds.size.height *= 2;
		CGPathRelease(path);
		path = CGPathCreateMutable();
		CGPathAddRect((CGMutablePathRef)path, NULL, pathBounds);
		
		if (textRange) {
			[textRange release];
			textRange = nil;
		}
		textRange = [aRange retain];
		NSRange range = [textRange range];
		CFRange visibleRange;
		NSAttributedString *attributedSubstring;
#if !PHI_FRAMESETTER_MEMBER
		CTFramesetterRef framesetter = NULL;
#endif
		
		if (firstStringIndex >= 0 && path && document && [document store]) {
			hasEmptyLastLine = NO;
			do {
				if (framesetter) {
					CFRelease(framesetter);
					framesetter = NULL;
				}
				attributedSubstring = [[document store] attributedSubstringFromRange:range];
				framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedSubstring);
				textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, range.length), path, (CFDictionaryRef)frameAttributes);
				visibleRange = CTFrameGetVisibleStringRange(textFrame);
				CFIndex lineCount = CFArrayGetCount(CTFrameGetLines(textFrame));
				// Grow path if it is too small for any text
				if (!textFrame || !visibleRange.length || !lineCount) {
					if (textFrame) {
						CFRelease(textFrame);
						textFrame = NULL;
					}
					CGRect pathBounds = CGPathGetBoundingBox(path);
					if (pathBounds.size.height) {
						pathBounds.size.height *= 1.5;
					} else {
						pathBounds.size.height = 10.0;
					}
					CGPathRelease(path);
					path = CGPathCreateMutable();
					CGPathAddRect((CGMutablePathRef)path, NULL, pathBounds);
				}
				// Workaround for line ending at string end rendering issue
				visibleRange.location = range.location;
			} while (!textFrame);
			if (framesetter) {
				CFRelease(framesetter);
				framesetter = NULL;
			}
			
			if (visibleRange.length > 0
				&& (visibleRange.length == 1 || [[document store] isLineBreakAtIndex:range.location + visibleRange.length - 2])
				&& [[document store] isLineBreakAtIndex:range.location + visibleRange.length - 1]) {
				hasEmptyLastLine = YES;
			}
			if (visibleRange.length != range.length) {
				[textRange release];
				textRange = [[PhiTextRange textRangeWithCFRange:visibleRange] retain];
			}

			stringIndexDiff += visibleRange.length - staleStringLength;
			staleStringLength = visibleRange.length;
			rect.size = CGSizeZero;

			[self validateFrameRect];

			CGPathRelease(path);
			path = CGPathCreateMutable();
			CGPathAddRect((CGMutablePathRef)path, NULL, rect);
		}
	}
}

- (void)setDocument:(PhiTextDocument *)doc {
	if (document != doc) {
		[self invalidateFrame];
		stringIndexDiff = staleStringLength = firstStringIndex = 0;
		firstLineNumber = 1;
		rect = CGRectZero;
		staleRect = CGRectNull;
		document = doc;
	}
}

- (void)setFrameAttributes:(NSDictionary *)attributes {
	if (frameAttributes != attributes) {
		[self invalidateFrame];
		if (frameAttributes)
			[frameAttributes release];
		frameAttributes = attributes;
		if (frameAttributes)
			[frameAttributes retain];
	}
}

- (void)dealloc {
#if PHI_FRAMESETTER_MEMBER
	if (framesetter) {
		CFRelease(framesetter);
		framesetter = NULL;
	}
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (textFrame) {
		CFRelease(textFrame);
		textFrame = NULL;
	}
	if (path) {
		CGPathRelease(path);
		path = NULL;
	}
	if (textRange) {
		[textRange release];
		textRange = nil;
	}
	document = NULL;
	if (frameAttributes) {
		[frameAttributes release];
		frameAttributes = nil;
	}
	[super dealloc];
}

- (NSUInteger)lineCount {
	CFIndex rv = 0;
	if ([self beginTextAccess]) {
		CFArrayRef textLines = CTFrameGetLines(textFrame);
		rv = CFArrayGetCount(textLines);
		[self autoEndContentAccess];
	}
	return (NSUInteger)rv;
}

- (PhiTextLine *)lineAtIndex:(CFIndex)index {
	PhiTextLine *rv = nil;
	if ([self beginTextAccess]) {
		CFArrayRef textLines = CTFrameGetLines(textFrame);
		rv = [self _lineAtIndex:index fromTextLines:textLines];
		[self autoEndContentAccess];
	}
	return rv;
}

- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)selectionAffinity {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextFrame searchLineWithPosition:%@ selectionAffinity:%s]...", traceIndent, position, selectionAffinity==UITextStorageDirectionForward?"UITextStorageDirectionForward":"UITextStorageDirectionBackward");
#endif
	CFArrayRef textLines = NULL;
	PhiTextLine *line = nil;
	/**/
	if ([self beginTextAccess]) {
		CFIndex i = NSNotFound, count = 0;
		textLines = CTFrameGetLines(textFrame);
		count = CFArrayGetCount(textLines);
		
		// Check position is in frame
		if (PhiPositionOffset(position) < PhiPositionOffset([textRange start]) || PhiPositionOffset(position) > PhiPositionOffset([textRange end])) {
			//Do nothing, can't be found!
		}
		// Otherwise, take a shortcut if we're at the beginning or end of the frame
		else if ([position compare:(PhiTextPosition *)[textRange start]] == NSOrderedSame) {
			i = 0;
			if (count) {
				line = [self _lineAtIndex:i fromTextLines:textLines];
			}
		} else if ([position compare:(PhiTextPosition *)[textRange end]] == NSOrderedSame) {
			i = count - 1;
			if (count) {
				line = [self _lineAtIndex:i fromTextLines:textLines];
			}
		}
		// Otherwise, search through lines.
		else {
			CFIndex offset = PhiPositionOffset(position) - PhiRangeOffset(textRange);
			if (offset <= 0) {
				i = PhiTextFrameBSearchLineWithPosition(textLines, NSMakeRange(0, count), offset, (BOOL)selectionAffinity, YES, NO);
			} else {
				BOOL hasForcedLineBreak = [[document store] isLineBreakAtIndex:PhiPositionOffset(position) - 1];
				//TODO: check document store length
				i = PhiTextFrameBSearchLineWithPosition(textLines, NSMakeRange(0, count), offset,
														(BOOL)selectionAffinity,
														//(BOOL)selectionAffinity && !(hasForcedLineBreak && [[document store] isLineBreakAtIndex:PhiPositionOffset(position)]),
														hasForcedLineBreak, NO);
			}
			line = [self _lineAtIndex:i fromTextLines:textLines];
		}
		[self autoEndContentAccess];
	}
	
	/**/
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@.", traceIndent, __FUNCTION__, line);
#endif
	return line;
}

- (PhiTextLine *)searchLineWithRange:(PhiTextRange *)range andPoint:(CGPoint)point {
#ifdef TRACE
	NSLog(@"%@Entering -[PhiTextFrame searchLineWithRange:%@ andPoint:(%.f, %.f)]...", traceIndent, range, point.x, point.y);
#endif
	PhiTextLine *line = nil;
	if (range) {
		range = [PhiTextRange clampRange:range toRange:textRange];
	} else {
		range = textRange;
	}

	if ([self beginContentAccess]) {
		CFArrayRef textLines = CTFrameGetLines(textFrame);
		/**/
		CFIndex i, count;
		CGFloat bottomBound, topBound;
		CGRect bounds = rect;
		bounds.size.height += tileOffset.y;
		
		// Take a shortcut if point is below the frame (note range is clamped to textRange)
		line = [self searchLineWithPosition:(PhiTextPosition *)[range end] selectionAffinity:YES];
		count = line.index;
		//bottom bound of the 2nd last line
		bottomBound = bounds.origin.y + bounds.size.height - line.originInFrame.y - line.ascent - line.leading / 2.0;
#ifdef DEVELOPER
		NSLog(@"%@line %d width:%.f bottomBound:%.f", traceIndent, line.index, line.width, bottomBound);
#endif
		if (point.y <= bottomBound) {
			// Take a shortcut if we're above the frame (note range is clamped to textRange)
			line = [self searchLineWithPosition:(PhiTextPosition *)[range start] selectionAffinity:YES];
			i = line.index;
			//top bound of the 2nd line
			topBound = bounds.origin.y + bounds.size.height - line.originInFrame.y + line.descent + line.leading / 2.0;
#ifdef DEVELOPER
			NSLog(@"%@line %d width:%.f topBound:%.f", traceIndent, line.index, line.width, topBound);
#endif
			if (point.y >= topBound) {
				// Search through lines.
				i = PhiTextFrameBSearchLineWithPoint(textFrame, textLines, CFRangeMake(i, count - i), point, bounds);
				line = [self _lineAtIndex:i fromTextLines:textLines];
#ifdef DEVELOPER
				NSLog(@"%@line %d bottomBound:%.f topBound:%.f", traceIndent, line.index, bottomBound, topBound);
#endif
			} 
		}
		[self autoEndContentAccess];
	}
	/**/	
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@ origin:(%.f, %.f) lineIndex:%d.", traceIndent, __FUNCTION__, line);
#endif
	return line;
}
- (PhiTextLine *)searchLineWithPoint:(CGPoint)point {
	return [self searchLineWithRange:[self textRange] andPoint:point];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: 0x%x; %@; %@>", NSStringFromClass([self class]), self, NSStringFromRange([self rangeValue]), NSStringFromCGRect(rect)];
}

@end
