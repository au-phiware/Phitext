//
//  PhiTextParagraphInfo.m
//  Phitext
//
//  Created by Corin Lawson on 18/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextParagraphStyle.h"

const CFStringRef kPhiTextTabIgnoreAlignmentAttributeName = CFSTR("PhiTextTabIgnoreAlignmentAttributeName");

Boolean PhiTextTabEqualCallBack (CTTextTabRef tab1, CTTextTabRef tab2, BOOL ignoreAlignment) {
	if (CTTextTabGetLocation(tab1) == CTTextTabGetLocation(tab2)) {
		if (ignoreAlignment || CTTextTabGetAlignment(tab1) == CTTextTabGetAlignment(tab2)) {
			return YES;
		}
	}
	return NO;
}

@implementation PhiTextParagraphStyle

+ (id)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)paragraphStyle {
	PhiTextParagraphStyle *rv = [[[PhiTextParagraphStyle alloc] init] autorelease];
	size_t valueBufferSize = MAX(sizeof(CTTextAlignment), MAX(sizeof(CGFloat), MAX(sizeof(CFArrayRef), MAX(sizeof(CTLineBreakMode), sizeof(CTWritingDirection)))));
	void *valueBuffer = malloc(valueBufferSize);
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierAlignment,
											 sizeof(CTTextAlignment), valueBuffer)) {
		[rv setAlignment:*((CTTextAlignment *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierFirstLineHeadIndent,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setFirstLineHeadIndent:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierHeadIndent,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setHeadIndent:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierTailIndent,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setTailIndent:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierTabStops,
											 sizeof(CFArrayRef), valueBuffer)) {
		[rv setTabStops:*((CFArrayRef *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierDefaultTabInterval,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setDefaultTabInterval:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierLineBreakMode,
											 sizeof(CTLineBreakMode), valueBuffer)) {
		[rv setLineBreakMode:*((CTLineBreakMode *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierLineHeightMultiple,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setLineHeightMultiple:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierMaximumLineHeight,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setMaximumLineHeight:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierMinimumLineHeight,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setMinimumLineHeight:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierLineSpacing,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setLineSpacing:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierParagraphSpacing,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setParagraphSpacing:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierParagraphSpacingBefore,
											 sizeof(CGFloat), valueBuffer)) {
		[rv setParagraphSpacingBefore:*((CGFloat *)valueBuffer)];
	}
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle,
											 kCTParagraphStyleSpecifierBaseWritingDirection,
											 sizeof(CTWritingDirection), valueBuffer)) {
		[rv setBaseWritingDirection:*((CTWritingDirection *)valueBuffer)];
	}
	free(valueBuffer);
	return rv;
}

- (id)init {
	if (self = [super init]) {
		tabStops = NULL;
		_CTParagraphStyle = NULL;
		
		[self unsetAlignment];
		[self unsetFirstLineHeadIndent];
		[self unsetHeadIndent];
		[self unsetTailIndent];
		[self unsetTabStops];
		[self unsetDefaultTabInterval];
		[self unsetLineBreakMode];
		[self unsetLineHeightMultiple];
		[self unsetMaximumLineHeight];
		[self unsetMinimumLineHeight];
		[self unsetLineSpacing];
		[self unsetParagraphSpacing];
		[self unsetParagraphSpacingBefore];
		[self unsetBaseWritingDirection];
	}
	return self;
}

- (CTParagraphStyleRef)CTParagraphStyle {
	if (!_CTParagraphStyle) {
		CTParagraphStyleSetting buffer[15];
		CFIndex count = 0;
		
		if (flags.alignment) {
			buffer[count].spec = kCTParagraphStyleSpecifierAlignment;
			buffer[count].valueSize = sizeof(CTTextAlignment);
			buffer[count].value = &alignment;
			count++;
		}
		if (flags.firstLineHeadIndent) {
			buffer[count].spec = kCTParagraphStyleSpecifierFirstLineHeadIndent;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &firstLineHeadIndent;
			count++;
		}
		if (flags.headIndent) {
			buffer[count].spec = kCTParagraphStyleSpecifierHeadIndent;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &headIndent;
			count++;
		}
		if (flags.tailIndent) {
			buffer[count].spec = kCTParagraphStyleSpecifierTailIndent;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &tailIndent;
			count++;
		}
		if (flags.tabStops && tabStops) {
			buffer[count].spec = kCTParagraphStyleSpecifierTabStops;
			buffer[count].valueSize = sizeof(CFArrayRef);
			buffer[count].value = &tabStops;
			count++;
		}
		if (flags.defaultTabInterval) {
			buffer[count].spec = kCTParagraphStyleSpecifierDefaultTabInterval;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &defaultTabInterval;
			count++;
		}
		if (flags.lineBreakMode) {
			buffer[count].spec = kCTParagraphStyleSpecifierLineBreakMode;
			buffer[count].valueSize = sizeof(CTLineBreakMode);
			buffer[count].value = &lineBreakMode;
			count++;
		}
		if (flags.lineHeightMultiple) {
			buffer[count].spec = kCTParagraphStyleSpecifierLineHeightMultiple;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &lineHeightMultiple;
			count++;
		}
		if (flags.maximumLineHeight) {
			buffer[count].spec = kCTParagraphStyleSpecifierMaximumLineHeight;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &maximumLineHeight;
			count++;
		}
		if (flags.minimumLineHeight) {
			buffer[count].spec = kCTParagraphStyleSpecifierMinimumLineHeight;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &minimumLineHeight;
			count++;
		}
		if (flags.lineSpacing) {
			buffer[count].spec = kCTParagraphStyleSpecifierLineSpacing;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &lineSpacing;
			count++;
		}
		if (flags.paragraphSpacing) {
			buffer[count].spec = kCTParagraphStyleSpecifierParagraphSpacing;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &paragraphSpacing;
			count++;
		}
		if (flags.paragraphSpacingBefore) {
			buffer[count].spec = kCTParagraphStyleSpecifierParagraphSpacingBefore;
			buffer[count].valueSize = sizeof(CGFloat);
			buffer[count].value = &paragraphSpacingBefore;
			count++;
		}
		if (flags.baseWritingDirection) {
			buffer[count].spec = kCTParagraphStyleSpecifierBaseWritingDirection;
			buffer[count].valueSize = sizeof(CTWritingDirection);
			buffer[count].value = &baseWritingDirection;
			count++;
		}
		if (count) {
			/*
			 buffer[count].spec = kCTParagraphStyleSpecifierCount;
			 buffer[count].valueSize = sizeof(CFIndex);
			 buffer[count].value = &count;
			 count++;
			 */
			_CTParagraphStyle = CTParagraphStyleCreate(buffer, count);
		} else {
			_CTParagraphStyle = NULL;
		}
	}
	
	return _CTParagraphStyle;
}

- (void)invalidate {
	if (_CTParagraphStyle)
		CFRelease(_CTParagraphStyle);
	_CTParagraphStyle = NULL;
}

- (CTTextAlignment)alignment {
	if (flags.alignment)
		return alignment;
	return kCTNaturalTextAlignment;
}
- (void)setAlignment:(CTTextAlignment)value {
	[self invalidate];
	flags.alignment = YES;
	alignment = value;
}

- (CGFloat)firstLineHeadIndent {
	if (flags.firstLineHeadIndent)
		return firstLineHeadIndent;
	return 0.0;
}
- (void)setFirstLineHeadIndent:(CGFloat)value {
	[self invalidate];
	flags.firstLineHeadIndent = YES;
	firstLineHeadIndent = value;
}
- (CGFloat)headIndent {
	if (flags.headIndent)
		return headIndent;
	return 0.0;
}
- (void)setHeadIndent:(CGFloat)value {
	[self invalidate];
	flags.headIndent = YES;
	headIndent = value;
}
- (CGFloat)tailIndent {
	if (flags.tailIndent)
		return tailIndent;
	return 0.0;
}
- (void)setTailIndent:(CGFloat)value {
	[self invalidate];
	flags.tailIndent = YES;
	tailIndent = value;
}
- (CFArrayRef)copyTabStops {
	return CFArrayCreateCopy(NULL, tabStops);
}
- (void)setTabStops:(CFArrayRef)value {
	if (tabStops != value) {
		[self invalidate];
		if (tabStops)
			CFRelease(tabStops);
		tabStops = NULL;
		if (value) {
			flags.tabStops = YES;
			tabStops = CFArrayCreateMutableCopy(NULL, 12, value);
		}
	}
}
- (void)addTabStop:(double)location {
	[self addTabStop:location withAlignment:kCTNaturalTextAlignment];
}
- (void)addTabStop:(double)location withAlignment:(CTTextAlignment)tabAlignment {
	[self addTabStop:location withAlignment:tabAlignment columnTerminators:NULL];
}
- (void)addTabStop:(double)location withAlignment:(CTTextAlignment)tabAlignment columnTerminators:(CFCharacterSetRef)terminators {
	[self invalidate];
	flags.tabStops = YES;
	CFMutableDictionaryRef dict = NULL;
	if (terminators) {
		dict = CFDictionaryCreateMutable(NULL, 1, NULL, &kCFTypeDictionaryValueCallBacks);
		CFDictionaryAddValue(dict, kCTTabColumnTerminatorsAttributeName, terminators);
	}
	CTTextTabRef tab = CTTextTabCreate(tabAlignment, location, dict);
	CFArrayAppendValue(tabStops, tab);
	if (dict)
		CFRelease(dict);
	CFRelease(tab);
}
- (void)removeTabStopsAtLocation:(double)location {
	[self invalidate];
	flags.tabStops = YES;
	CTTextTabRef tab = CTTextTabCreate(kCTNaturalTextAlignment, location, NULL);
	CFIndex count = CFArrayGetCount(tabStops);
	for (CFIndex i = 0; i < count; i++) {
		if (PhiTextTabEqualCallBack(tab, CFArrayGetValueAtIndex(tabStops, i), YES)) {
			CFArrayRemoveValueAtIndex(tabStops, i);
			count--;
		}
	}
}
- (void)removeTabStopsAtLocation:(double)location withAlignment:(CTTextAlignment)tabAlignment {
	[self invalidate];
	flags.tabStops = YES;
	CTTextTabRef tab = CTTextTabCreate(tabAlignment, location, NULL);
	CFIndex count = CFArrayGetCount(tabStops);
	for (CFIndex i = 0; i < count; i++) {
		if (PhiTextTabEqualCallBack(tab, CFArrayGetValueAtIndex(tabStops, i), NO)) {
			CFArrayRemoveValueAtIndex(tabStops, i);
			count--;
		}
	}
}
- (void)removeAllTabStops {
	[self invalidate];
	flags.tabStops = YES;
	CFArrayRemoveAllValues(tabStops);
}
- (CGFloat)defaultTabInterval {
	if (flags.defaultTabInterval)
		return defaultTabInterval;
	return 0.0;
}
- (void)setDefaultTabInterval:(CGFloat)value {
	[self invalidate];
	flags.defaultTabInterval = YES;
	defaultTabInterval = value;
}
- (CTLineBreakMode)lineBreakMode {
	if (flags.lineBreakMode)
		return lineBreakMode;
	return kCTLineBreakByWordWrapping;
}
- (void)setLineBreakMode:(CTLineBreakMode)value {
	[self invalidate];
	flags.lineBreakMode = YES;
	lineBreakMode = value;
}
- (CGFloat)lineHeightMultiple {
	if (flags.lineHeightMultiple)
		return lineHeightMultiple;
	return 0.0;
}
- (void)setLineHeightMultiple:(CGFloat)value {
	[self invalidate];
	flags.lineHeightMultiple = YES;
	lineHeightMultiple = value;
}
- (CGFloat)maximumLineHeight {
	if (flags.maximumLineHeight)
		return maximumLineHeight;
	return 0.0;
}
- (void)setMaximumLineHeight:(CGFloat)value {
	[self invalidate];
	flags.maximumLineHeight = YES;
	maximumLineHeight = value;
}
- (CGFloat)minimumLineHeight {
	if (flags.minimumLineHeight)
		return minimumLineHeight;
	return 0.0;
}
- (void)setMinimumLineHeight:(CGFloat)value {
	[self invalidate];
	flags.minimumLineHeight = YES;
	minimumLineHeight = value;
}
- (CGFloat)lineSpacing {
	if (flags.lineSpacing)
		return lineSpacing;
	return 0.0;
}
- (void)setLineSpacing:(CGFloat)value {
	[self invalidate];
	flags.lineSpacing = YES;
	lineSpacing = value;
}
- (CGFloat)paragraphSpacing {
	if (flags.paragraphSpacing)
		return paragraphSpacing;
	return 0.0;
}
- (void)setParagraphSpacing:(CGFloat)value {
	[self invalidate];
	flags.paragraphSpacing = YES;
	paragraphSpacing = value;
}
- (CGFloat)paragraphSpacingBefore {
	if (flags.paragraphSpacingBefore)
		return paragraphSpacingBefore;
	return 0.0;
}
- (void)setParagraphSpacingBefore:(CGFloat)value {
	[self invalidate];
	flags.paragraphSpacingBefore = YES;
	paragraphSpacingBefore = value;
}
- (CTWritingDirection)baseWritingDirection {
	if (flags.baseWritingDirection)
		return baseWritingDirection;
	return kCTWritingDirectionNatural;
}
- (void)setBaseWritingDirection:(CTWritingDirection)value {
	[self invalidate];
	flags.baseWritingDirection = YES;
	baseWritingDirection = value;
}

- (void)unsetAlignment {
	[self invalidate];
	flags.alignment = NO;
	alignment = kCTNaturalTextAlignment;
}
- (void)unsetFirstLineHeadIndent {
	[self invalidate];
	flags.firstLineHeadIndent = NO;
	firstLineHeadIndent = 0.0;
}
- (void)unsetHeadIndent {
	[self invalidate];
	flags.headIndent = NO;
	headIndent = 0.0;
}
- (void)unsetTailIndent {
	[self invalidate];
	flags.tailIndent = NO;
	tailIndent = 0.0;
}
- (void)unsetTabStops {
	[self invalidate];
	flags.tabStops = NO;
	if (tabStops)
		CFRelease(tabStops);
	tabStops = CFArrayCreateMutable(NULL, 12, &kCFTypeArrayCallBacks);
	for (CGFloat location = 28.0; location <= 12.0 * 28.0; location += 28.0) {
		CTTextTabRef tab = CTTextTabCreate(kCTLeftTextAlignment, location, NULL);
		CFArrayAppendValue(tabStops, tab);
		CFRelease(tab);
	}
}
- (void)unsetDefaultTabInterval {
	[self invalidate];
	flags.defaultTabInterval = NO;
	defaultTabInterval = 0.0;
}
- (void)unsetLineBreakMode {
	[self invalidate];
	flags.lineBreakMode = NO;
	lineBreakMode = kCTLineBreakByWordWrapping;
}
- (void)unsetLineHeightMultiple {
	[self invalidate];
	flags.lineHeightMultiple = NO;
	lineHeightMultiple = 0.0;
}
- (void)unsetMaximumLineHeight {
	[self invalidate];
	flags.maximumLineHeight = NO;
	maximumLineHeight = 0.0;
}
- (void)unsetMinimumLineHeight {
	[self invalidate];
	flags.minimumLineHeight = NO;
	minimumLineHeight = 0.0;
}
- (void)unsetLineSpacing {
	[self invalidate];
	flags.lineSpacing = NO;
	lineSpacing = 0.0;
}
- (void)unsetParagraphSpacing {
	[self invalidate];
	flags.paragraphSpacing = NO;
	paragraphSpacing = 0.0;
}
- (void)unsetParagraphSpacingBefore {
	[self invalidate];
	flags.paragraphSpacingBefore = NO;
	paragraphSpacingBefore = 0.0;
}
- (void)unsetBaseWritingDirection {
	[self invalidate];
	flags.baseWritingDirection = NO;
	baseWritingDirection = kCTWritingDirectionNatural;
}

- (void)dealloc {
	if (_CTParagraphStyle)
		CFRelease(_CTParagraphStyle);
	_CTParagraphStyle = NULL;
	if (tabStops)
		CFRelease(tabStops);
	tabStops = NULL;
	[super dealloc];
}

@end
