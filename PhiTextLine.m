//
//  PhiTextLine.m
//  Phitext
//
//  Created by Corin Lawson on 14/07/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//


#import "PhiTextLine.h"
#import "PhiTextFrame.h"
#import "PhiTextRange.h"
#import "PhiTextPosition.h"
#import "PhiTextDocument.h"
#import "PhiTextStorage.h"

@interface PhiTextPosition (PhiTextLine)
@property (retain, nonatomic, readwrite) PhiTextLine *line;
@end

@implementation PhiTextLine

@synthesize index, frame, textLine;

+ (id)textLineWithLine:(CTLineRef)line index:(CFIndex)index frame:(PhiTextFrame *)frame {
	return [[[PhiTextLine alloc] initWithLine:line index:index frame:frame] autorelease];
}

+ (id)textLineWithIndex:(CFIndex)index frame:(PhiTextFrame *)frame {
	return [[[PhiTextLine alloc] initWithLine:NULL index:index frame:frame] autorelease];
}

- (id)initWithLine:(CTLineRef)line index:(CFIndex)i frame:(PhiTextFrame *)textFrame {
	if (self = [super init]) {
		if (line)
			textLine = CFRetain(line);
		else
			textLine = NULL;
		index = i;
		frame = [textFrame retain];
		origin = CGPointMake(NAN, NAN);
		width = NAN;
		ascent = NAN;
		descent = NAN;
		leading = NAN;
		textRange = nil;
	}
	return self;
}

- (void)dealloc {
	if (textRange) [textRange release];
	textRange = nil;

	if (textLine) CFRelease(textLine);
	textLine = NULL;
	
	if (frame) [frame release];
	frame = nil;
	
	[super dealloc];
}

- (NSUInteger)number {
	return [frame firstLineNumber] + index;
}

- (CTLineRef)textLine {
	if (frame && !textLine) {
		CTFrameRef _frame = [frame copyCTFrame];
		textLine = CFRetain(CFArrayGetValueAtIndex(CTFrameGetLines(_frame), index));
		CFRelease(_frame);
	}
	
	return textLine;
}

- (CGPoint)originInFrame {
	if (frame && (isnan(origin.x) || isnan(origin.y))) {
		CTFrameRef _frame = [frame copyCTFrame];
		CTFrameGetLineOrigins(_frame, CFRangeMake(index, 1), &origin);
		CFRelease(_frame);
	}
	
	return origin;
}

- (CGPoint)originInDocument {
	CGPoint oid = [self originInFrame];
	CGRect frameRect = [frame rect];
	
	oid.x += frameRect.origin.x;
	oid.y = frameRect.origin.y + frameRect.size.height + frame.tileOffset.y - oid.y;
	
	return oid;
}

- (CGFloat)width {
	if (isnan(width) && textLine)
		width = CTLineGetTypographicBounds(textLine, &ascent, &descent, &leading);
	
	return width;
}

- (CGFloat)height {
	return self.ascent + self.descent + self.leading;
}

- (CGFloat)ascent {
	if (isnan(ascent) && textLine)
		width = CTLineGetTypographicBounds(textLine, &ascent, &descent, &leading);
	
	return ascent;
}

- (CGFloat)descent {
	if (isnan(descent) && textLine)
		width = CTLineGetTypographicBounds(textLine, &ascent, &descent, &leading);
	
	return descent;
}

- (CGFloat)leading {
	if (isnan(leading) && textLine)
		width = CTLineGetTypographicBounds(textLine, &ascent, &descent, &leading);
	
	return leading;
}

/*! Relative to document. */
- (PhiTextRange *)textRange {
	if (!textRange) {
		CFRange lineRange = CTLineGetStringRange(textLine);
		lineRange.location += [frame firstStringIndex];
		textRange = [[PhiTextRange textRangeWithCFRange:lineRange] retain];
	}
	
	return textRange;
}

- (PhiTextStyle *)textStyle {
	PhiTextPosition *effectivePosition;
	PhiTextStyle *style = [[frame document] styleFromPosition:(PhiTextPosition *)[[self textRange] start]
								  toFarthestEffectivePosition:&effectivePosition
											notBeyondPosition:(PhiTextPosition *)[[self textRange] end]];
	effectivePosition.line = self;
	return style;
}

/*! exclusive of document's bounds.origin */
- (CGFloat)offsetForPosition:(PhiTextPosition *)position {
	CFIndex x = PhiPositionOffset(position);
	CGFloat offset;
	if (x > [frame firstStringIndex] &&
		x == PhiPositionOffset(self.textRange.end) &&
		[[[frame document] store] isLineBreakAtIndex:x - 1]) {
		x--;
	}
	offset = CTLineGetOffsetForStringIndex(textLine, x - [frame firstStringIndex], NULL);
	return offset;
}

- (PhiTextPosition *)positionForPoint:(CGPoint)point {
	CGPoint oid = [self originInDocument];
	CGPoint position = CGPointMake(point.x - oid.x, point.x - oid.x);
	CFIndex stringIndex = CTLineGetStringIndexForPosition(textLine, position);
	stringIndex += frame.firstStringIndex;
	if (stringIndex == PhiPositionOffset(self.textRange.end) && [[[frame document] store] isLineBreakAtIndex:stringIndex - 1]) {
		stringIndex--;
	}
	return [PhiTextPosition textPositionWithPosition:MAX(0, stringIndex) inLine:self];
}

- (BOOL)isEmpty {
	return (self.textRange.empty
		|| (
			PhiRangeLength(self.textRange) == 1
			&& [[[frame document] store] isLineBreakAtIndex:PhiPositionOffset(self.textRange.start)]
			)
		);
}

@end
