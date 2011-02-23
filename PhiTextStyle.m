//
//  PhiTextStyleInfo.m
//  Phitext
//
//  Created by Corin Lawson on 18/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextStyle.h"
#import "PhiTextFont.h"
#import "PhiTextParagraphStyle.h"

@interface PhiTextStyle()

- (void)setAttributes:(CFDictionaryRef)attr;

@end

void PhiAddToStyleDictionaryCallBack (const void *key, const void *value, CFMutableDictionaryRef dictionary) {
	CFDictionarySetValue(dictionary, key, value);
}

@implementation PhiTextStyle

+(PhiTextStyle *)styleWithDictionary:(NSDictionary *)attr {
	PhiTextStyle *rv = [[PhiTextStyle alloc] init];
	[rv setAttributes:(CFDictionaryRef)attr];
	return [rv autorelease];
}

- (PhiTextStyle *)styleWithAddedStyle:(PhiTextStyle *)style {
	CFDictionaryRef addAttr = [style attributes];
	CFMutableDictionaryRef newAttr = CFDictionaryCreateMutableCopy(NULL, 12, [self attributes]);
	
	CFDictionaryApplyFunction(addAttr, (CFDictionaryApplierFunction)PhiAddToStyleDictionaryCallBack, newAttr);
	
	PhiTextStyle *rv = [PhiTextStyle styleWithDictionary:(NSDictionary *)newAttr];
	CFRelease(newAttr);
	return rv;
}

- (id)init {
	if (self = [super init]) {
		attributes = CFDictionaryCreateMutable(NULL, 12, NULL, &kCFTypeDictionaryValueCallBacks);
		strokeStyle = kPhiStrokeOnly;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	PhiTextStyle *rv = [[PhiTextStyle allocWithZone:zone] init];
	rv.attributes = self.attributes;
	return rv;
}

- (CFDictionaryRef)attributes {
	if (paragraphStyle) {
		CTParagraphStyleRef value = paragraphStyle.CTParagraphStyle;
		if (value) {
			CFDictionarySetValue(attributes, kCTParagraphStyleAttributeName, value);
		}
	}
	if (font) {
		CTFontRef value = [font copyCTFont];
		CFDictionarySetValue(attributes, kCTFontAttributeName, value);
		CFRelease(value);
	}
	return attributes;
}
- (void)setAttributes:(CFDictionaryRef)attr {
	if (paragraphStyle)
		[paragraphStyle release];
	paragraphStyle = nil;
	if (font)
		[font release];
	font = nil;

	if (attributes)
		CFRelease(attributes);

	if (attr)
		attributes = CFDictionaryCreateMutableCopy(NULL, 12, attr);
	else
		attributes = NULL;
}

- (PhiCharacterShapeType)characterShape {
	PhiCharacterShapeType type = kPhiNoCharactersSelector;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTCharacterShapeAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &type);
	}
	return type;
}
- (void)setCharacterShape:(PhiCharacterShapeType)type {
	CFNumberRef value;
	value = CFNumberCreate(NULL, kCFNumberIntType, &type);
	CFDictionarySetValue(attributes, kCTCharacterShapeAttributeName, value);
	CFRelease(value);
}
- (void)unsetCharacterShape {
	CFDictionaryRemoveValue(attributes, kCTCharacterShapeAttributeName);
}

- (PhiTextFont *)font {
	if (!font) {
		CTFontRef value;
		if (CFDictionaryGetValueIfPresent(attributes, kCTFontAttributeName, (const void **)&value))
			font = [[PhiTextFont fontWithCTFont:value] retain];
	}
	return font;
}
- (void)setFont:(PhiTextFont *)aFont {
	if (font != aFont) {
		[self unsetFont];
		if (aFont)
			font = [aFont retain];
	}
}
- (void)unsetFont {
	CFDictionaryRemoveValue(attributes, kCTFontAttributeName);
	if (font)
		[font release];
	font = nil;
}

- (float)kern {
	float kern = 0.0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTKernAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberFloatType, &kern);
	}
	return kern;
}
- (void)setKern:(float)kern {
	CFNumberRef value;
	value = CFNumberCreate(NULL, kCFNumberFloatType, &kern);
	CFDictionarySetValue(attributes, kCTKernAttributeName, value);
	CFRelease(value);
}
- (void)unsetKern {
	CFDictionaryRemoveValue(attributes, kCTKernAttributeName);
}

- (PhiLigaturesType)ligature {
	PhiLigaturesType type = kPhiStandardLigatures;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTLigatureAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &type);
	}
	return type;
}
- (void)setLigature:(PhiLigaturesType)type {
	CFNumberRef value;
	value = CFNumberCreate(NULL, kCFNumberIntType, &type);
	CFDictionarySetValue(attributes, kCTLigatureAttributeName, value);
	CFRelease(value);
}
- (void)unsetLigature {
	CFDictionaryRemoveValue(attributes, kCTLigatureAttributeName);
}

- (BOOL)shouldUseCurrentColor {
	BOOL flag = NO;
	CFBooleanRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTForegroundColorFromContextAttributeName, (const void **)&value)) {
		flag = CFBooleanGetValue(value);
	}
	return flag;
}
- (void)setShouldUseCurrentColor:(BOOL)flag {
	CFBooleanRef value = flag ? kCFBooleanTrue : kCFBooleanFalse;
	CFDictionarySetValue(attributes, kCTForegroundColorFromContextAttributeName, value);
}
- (void)unsetShouldUseCurrentColor {
	CFDictionaryRemoveValue(attributes, kCTForegroundColorFromContextAttributeName);
}

- (CGColorRef)color {
	CGColorRef color;
	if (!CFDictionaryGetValueIfPresent(attributes, kCTForegroundColorAttributeName, (const void **)&color)) {
		color = NULL;
	}
	return color;
}
- (void)setColor:(CGColorRef)color {
	if (color) {
		CFDictionarySetValue(attributes, kCTForegroundColorAttributeName, color);
	} else {
		CFDictionaryRemoveValue(attributes, kCTForegroundColorAttributeName);
	}
}
- (void)unsetColor {
	CFDictionaryRemoveValue(attributes, kCTForegroundColorAttributeName);
}

- (PhiTextParagraphStyle *)paragraphStyle {
	if (!paragraphStyle) {
		CTParagraphStyleRef value;
		if (CFDictionaryGetValueIfPresent(attributes, kCTParagraphStyleAttributeName, (const void **)&value))
			paragraphStyle = [[PhiTextParagraphStyle paragraphStyleWithCTParagraphStyle:value] retain];
		else
			paragraphStyle = [[PhiTextParagraphStyle alloc] init];
	}
	return paragraphStyle;
}
- (void)setParagraphStyle:(PhiTextParagraphStyle *)aParagraphStyle {
	if (paragraphStyle != aParagraphStyle) {
		[self unsetParagraphStyle];
		if (aParagraphStyle)
			paragraphStyle = [aParagraphStyle retain];
	}
}
- (void)unsetParagraphStyle {
	CFDictionaryRemoveValue(attributes, kCTParagraphStyleAttributeName);
	if (paragraphStyle)
		[paragraphStyle release];
	paragraphStyle = nil;
}

- (PhiStrokeStyleType)strokeStyle {
	float strokeWidth = [self strokeWidth];
	if (strokeWidth < 0.0)
		strokeStyle = kPhiStrokeAndFill;
	else if (strokeWidth > 0.0)
		strokeStyle = kPhiStrokeOnly;
	return strokeStyle;
}
- (void)setStrokeStyle:(PhiStrokeStyleType)type {
	strokeStyle = type;
	
	float strokeWidth = [self strokeWidth] * -1.0;
	CFNumberRef value;
	value = CFNumberCreate(NULL, kCFNumberFloatType, &strokeWidth);
	if ((strokeWidth > 0.0 && strokeStyle == kPhiStrokeOnly)
		|| (strokeWidth < 0.0 && strokeStyle == kPhiStrokeAndFill)) {
		CFDictionarySetValue(attributes, kCTStrokeWidthAttributeName, value);
	}
	CFRelease(value);
}

- (float)strokeWidth {
	float strokeWidth = 0.0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTStrokeWidthAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberFloatType, &strokeWidth);
	}
	return ABS(strokeWidth);
}
- (void)setStrokeWidth:(float)strokeWidth {
	strokeWidth = ABS(strokeWidth) * strokeStyle;
	CFNumberRef value;
	value = CFNumberCreate(NULL, kCFNumberFloatType, &strokeWidth);
	CFDictionarySetValue(attributes, kCTStrokeWidthAttributeName, value);
	CFRelease(value);
}
- (void)unsetStrokeWidth{
	CFDictionaryRemoveValue(attributes, kCTStrokeWidthAttributeName);
}

- (CGColorRef)strokeColor {
	CGColorRef strokeColor;
	if (!CFDictionaryGetValueIfPresent(attributes, kCTStrokeColorAttributeName, (const void **)&strokeColor)) {
		strokeColor = NULL;
	}
	return strokeColor;
}
- (void)setStrokeColor:(CGColorRef)strokeColor {
	if (strokeColor) {
		CFDictionarySetValue(attributes, kCTStrokeColorAttributeName, strokeColor);
	} else {
		CFDictionaryRemoveValue(attributes, kCTStrokeColorAttributeName);
	}
}
- (void)unsetStrokeColor {
	CFDictionaryRemoveValue(attributes, kCTStrokeColorAttributeName);
}

- (BOOL)isSuperscript {
	int type = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTSuperscriptAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &type);
	}
	return type == 1;
}
- (void)setSuperscript:(BOOL)flag {
	int type = 1;
	CFNumberRef value;
	if (flag && ![self isSuperscript]) {
		value = CFNumberCreate(NULL, kCFNumberIntType, &type);
		CFDictionarySetValue(attributes, kCTSuperscriptAttributeName, value);
		CFRelease(value);
	}
	else if (!flag && [self isSuperscript]) {
		type = 0;
		value = CFNumberCreate(NULL, kCFNumberIntType, &type);
		CFDictionarySetValue(attributes, kCTSuperscriptAttributeName, value);
		CFRelease(value);
	}
}
- (void)unsetSuperscript {
	CFDictionaryRemoveValue(attributes, kCTSuperscriptAttributeName);
}

- (BOOL)isSubscript {
	int type = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTSuperscriptAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &type);
	}
	return type == -1;
}
- (void)setSubscript:(BOOL)flag {
	int type = -1;
	CFNumberRef value;
	if (flag && ![self isSubscript]) {
		value = CFNumberCreate(NULL, kCFNumberIntType, &type);
		CFDictionarySetValue(attributes, kCTSuperscriptAttributeName, value);
		CFRelease(value);
	}
	else if (!flag && [self isSubscript]) {
		type = 0;
		value = CFNumberCreate(NULL, kCFNumberIntType, &type);
		CFDictionarySetValue(attributes, kCTSuperscriptAttributeName, value);
		CFRelease(value);
	}
}
- (void)unsetSubscript {
	[self unsetSuperscript];
}

- (PhiUnderlineScaleType)underlineScale {
	CTUnderlineStyle style = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &style);
	}
	return underlineScale = (style & 0x07);
}
- (void)setUnderlineScale:(PhiUnderlineScaleType)oneToSeven {
	underlineScale = oneToSeven &= 0x07;
	[self setUnderlined:oneToSeven > 0];
}

- (BOOL)isUnderlined {
	CTUnderlineStyle style = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &style);
	}
	return (BOOL)(style & 0x07);
}
- (void)setUnderlined:(BOOL)flag {
	CTUnderlineStyle style = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &style);
	}
	if (flag && !underlineScale)
		underlineScale = 1;
	if (style == 0)
		style = underlinePattern;
	if (flag && underlineScale != style & 0x07) {
		style = style & 0xFFF8 | underlineScale;
		value = CFNumberCreate(NULL, kCFNumberIntType, &style);
		CFDictionarySetValue(attributes, kCTUnderlineStyleAttributeName, value);
		CFRelease(value);
	}
	else if (!flag && style) {
		style = 0;
		value = CFNumberCreate(NULL, kCFNumberIntType, &style);
		CFDictionarySetValue(attributes, kCTUnderlineStyleAttributeName, value);
		CFRelease(value);
	}
}
- (PhiUnderlinePatternType)underlinePattern {
	PhiUnderlinePatternType type = kPhiUnderlinePatternSolid;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &type);
	}
	return underlinePattern = type & 0xFF00;
}
- (void)setUnderlinePattern:(PhiUnderlinePatternType)type {
	CTUnderlineStyle style = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &style);
	}
	style = style & 0xFF | (underlinePattern = type & 0xFF00);
	value = CFNumberCreate(NULL, kCFNumberIntType, &style);
	CFDictionarySetValue(attributes, kCTUnderlineStyleAttributeName, value);
	CFRelease(value);
}
- (BOOL)isUnderlineDouble {
	CTUnderlineStyle style = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &style);
	}
	return (BOOL)(style & 0x08);
}
- (void)setUnderlineDouble:(BOOL)flag {
	CTUnderlineStyle style = 0;
	CFNumberRef value;
	if (CFDictionaryGetValueIfPresent(attributes, kCTUnderlineStyleAttributeName, (const void **)&value)) {
		CFNumberGetValue(value, kCFNumberIntType, &style);
	}
	if (flag && !(style & 0x08)) {
		style = style & 0xFF07 | 0x08;
		value = CFNumberCreate(NULL, kCFNumberIntType, &style);
		CFDictionarySetValue(attributes, kCTUnderlineStyleAttributeName, value);
		CFRelease(value);
	}
	else if (!flag && (style & 0x08)) {
		style = style & 0xFF07;
		value = CFNumberCreate(NULL, kCFNumberIntType, &style);
		CFDictionarySetValue(attributes, kCTUnderlineStyleAttributeName, value);
		CFRelease(value);
	}
}
- (void)unsetUnderline {
	underlinePattern = underlineScale = 0;
	CFDictionaryRemoveValue(attributes, kCTUnderlineStyleAttributeName);
}

- (CGColorRef)underlineColor {
	CGColorRef underlineColor;
	if (!CFDictionaryGetValueIfPresent(attributes, kCTUnderlineColorAttributeName, (const void **)&underlineColor)) {
		underlineColor = NULL;
	}
	return underlineColor;
}
- (void)setUnderlineColor:(CGColorRef)underlineColor {
	if (underlineColor) {
		CFDictionarySetValue(attributes, kCTUnderlineColorAttributeName, underlineColor);
	} else {
		CFDictionaryRemoveValue(attributes, kCTUnderlineColorAttributeName);
	}
}
- (void)unsetUnderlineColor {
	CFDictionaryRemoveValue(attributes, kCTUnderlineColorAttributeName);
}

- (BOOL)shouldUseVerticalForms {
	BOOL flag = NO;
	CFBooleanRef value;
	if (CFDictionaryGetValueIfPresent(attributes, @"CTVerticalFormsAttributeName", (const void **)&value)) {
		flag = CFBooleanGetValue(value);
	}
	return flag;
}
- (void)setShouldUseVerticalForms:(BOOL)flag {
	CFBooleanRef value = flag ? kCFBooleanTrue : kCFBooleanFalse;
	CFDictionarySetValue(attributes, @"CTVerticalFormsAttributeName", value);
}
- (void)unsetShouldUseVerticalForms {
	CFDictionaryRemoveValue(attributes, @"CTVerticalFormsAttributeName");
}

-(void)dealloc {
	if (paragraphStyle)
		[paragraphStyle release];
	paragraphStyle = nil;
	if (font)
		[font release];
	font = nil;
	
	if (attributes)
		CFRelease(attributes);
	attributes = NULL;
	
	[super dealloc];
}

@end
