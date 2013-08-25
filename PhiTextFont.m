//
//  PhiTextFont.m
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

#import "PhiTextFont.h"
#import <UIKit/UIFont.h>

@implementation PhiTextFont

+ (id)fontWithCTFont:(CTFontRef)font {
	return [[[PhiTextFont alloc] initWithCTFont:font] autorelease];
}

+ (id)fontWithFont:(PhiTextFont *)font andSize:(CGFloat)size {
	CTFontDescriptorRef descriptor = [font copyCTFontDescriptor];
	CTFontRef ctFont = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
	id rv = [[[PhiTextFont alloc] initWithCTFont:ctFont] autorelease];
	CFRelease(ctFont);
	CFRelease(descriptor);
	return rv;
}

+ (id)fontWithCTFontDescriptor:(CTFontDescriptorRef)descriptor andSize:(CGFloat)size {
	CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
	id rv = [[[PhiTextFont alloc] initWithCTFont:font] autorelease];
	CFRelease(font);
	return rv;
}

- (id)initWithCTFont:(CTFontRef)font {
	if (self = [super init])
		_CTFont = CTFontCreateCopyWithAttributes(font, 0.0, NULL, NULL);
	return self;
}

- (PhiTextFont *)fontWithSize:(CGFloat)size {
	return [PhiTextFont fontWithFont:self andSize:size];
}

- (CTFontDescriptorRef)copyCTFontDescriptor {
	return CTFontCopyFontDescriptor(_CTFont);
}

- (CTFontRef)copyCTFont {
	return CTFontCreateCopyWithAttributes(_CTFont, 0.0, NULL, NULL);
}

- (void)setCTFont:(CTFontRef)font {
	if (_CTFont != font) {
		if (_CTFont) {
			CFRelease(_CTFont);
		}
		if (font) {
			_CTFont = CTFontCreateCopyWithAttributes(font, 0.0, NULL, NULL);
		} else {
			_CTFont = NULL;
		}
	}
}

- (UIFont *)UIFont {
#ifdef DEVELOPER
	NSLog(@"%@Creating UIFont withName:%@ size:%.1f...", traceIndent, [self postScriptName], [self size]);
#endif
	UIFont *rv = [UIFont fontWithName:[self postScriptName] size:[self size]];
	if (!rv)
		rv = [UIFont fontWithName:[self familyName] size:[self size]];
	return rv;
}

- (CGFloat)ascent {
	if (_CTFont)
		return CTFontGetAscent(_CTFont);
	return 0.0;
}

- (CGFloat)descent {
	if (_CTFont)
		return CTFontGetDescent(_CTFont);
	return 0.0;
}

- (CGFloat)leading {
	if (_CTFont)
		return CTFontGetLeading(_CTFont);
	return 0.0;
}

- (unsigned)unitsPerEm {
	if (_CTFont)
		return CTFontGetUnitsPerEm(_CTFont);
	return 0;
}

- (CFIndex)glyphCount {
	if (_CTFont)
		return CTFontGetGlyphCount(_CTFont);
	return 0;
}

- (CGRect)boundingBox {
	if (_CTFont)
		return CTFontGetBoundingBox(_CTFont);
	return CGRectNull;
}

- (CGFloat)underlinePosition {
	if (_CTFont)
		return CTFontGetUnderlinePosition(_CTFont);
	return 0.0;
}

- (CGFloat)underlineThickness {
	if (_CTFont)
		return CTFontGetUnderlineThickness(_CTFont);
	return 0.0;
}

- (CGFloat)slantAngle {
	if (_CTFont)
		return CTFontGetSlantAngle(_CTFont);
	return 0.0;
}

- (CGFloat)capHeight {
	if (_CTFont)
		return CTFontGetCapHeight(_CTFont);
	return 0.0;
}

- (CGFloat)xHeight {
	if (_CTFont)
		return CTFontGetXHeight(_CTFont);
	return 0.0;
}

- (NSString *)fullName {
	NSString *rv = (NSString *)CTFontCopyFullName(_CTFont);
	return [rv autorelease];
}

- (NSString *)postScriptName {
	NSString *rv = (NSString *)CTFontCopyPostScriptName(_CTFont);
	return [rv autorelease];
}

- (NSString *)displayName {
	NSString *rv = (NSString *)CTFontCopyDisplayName(_CTFont);
	return [rv autorelease];
}

- (NSString *)uniqueName {
	NSString *rv = (NSString *)CTFontCopyName(_CTFont, kCTFontUniqueNameKey);
	return [rv autorelease];
}

- (NSString *)familyName {
	NSString *rv = (NSString *)CTFontCopyFamilyName(_CTFont);
	return [rv autorelease];
}

- (CGFloat)size {
	return CTFontGetSize(_CTFont);
}

- (void)setSize:(CGFloat)points {
	if (points != self.size) {
		CTFontRef newFont = CTFontCreateCopyWithAttributes(_CTFont, points, NULL, NULL);
		if (_CTFont)
			CFRelease(_CTFont);
		_CTFont = newFont;
	}
}

- (void)dealloc {
	[self setCTFont:NULL];
	[super dealloc];
}
@end
