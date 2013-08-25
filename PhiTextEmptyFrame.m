//
//  PhiTextEmptyFrame.m
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

#import "PhiTextEmptyFrame.h"
#import "PhiTextFrame.h"
#import "PhiTextDocument.h"
#import "PhiTextPosition.h"
#import "PhiTextRange.h"
#import "PhiAATree.h"
#import "PhiTextStyle.h"

@interface PhiTextFrame (PhiTextEmptyFrame)
- (void)validateFrameRect;
- (PhiTextLine *)_lineAtIndex:(CFIndex)index fromTextLines:(CFArrayRef)textLines;
@end


@implementation PhiTextEmptyFrame

- (id)initInPath:(CGPathRef)constraints forDocument:(PhiTextDocument *)doc attributes:(NSDictionary *)attributes {
	if (self = [super initInPath:constraints beginningAt:0 forDocument:doc attributes:attributes]) {
		hasEmptyLastLine = YES;
	}
	return self;
}

/*
- (void)invalidateFrame {
	if (textFrame) {
		[super invalidateFrame];
		if ([[document textFrames] lastObject] == [document lastEmptyFrame]) {
			PhiAATreeNode *realLastFrameNode = [[[document textFrames] lastNode] previous];
			[document invalidateTextFrameRange:[PhiAATreeRange rangeWithStartNode:realLastFrameNode andEndNode:realLastFrameNode]];
		}
	}
}
*/
- (void)_validateFrame {
	if (!textFrame) {
		CTFramesetterRef framesetter;
		CFAttributedStringRef attributedString = CFAttributedStringCreate(NULL, CFSTR("\n"), (CFDictionaryRef)[[document styleAtEndOfDocument] attributes]);
		framesetter = CTFramesetterCreateWithAttributedString(attributedString);
		
		CGSize suggestedSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
		suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 1), (CFDictionaryRef)frameAttributes, suggestedSize, NULL);
		CGRect suggestedRect = CGPathGetBoundingBox(path);
		suggestedRect.size.width = MAX(suggestedRect.size.width, suggestedSize.width);
		suggestedRect.size.height = MAX(suggestedRect.size.height, suggestedSize.height);
		CGPathRelease(path);
		path = CGPathCreateMutable();
		CGPathAddRect((CGMutablePathRef)path, NULL, suggestedRect);

		do {
			textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 1), path, (CFDictionaryRef)frameAttributes);
			CFRange visibleRange = CTFrameGetVisibleStringRange(textFrame);
			CFIndex nol = CFArrayGetCount(CTFrameGetLines(textFrame));
			if (!textFrame || !visibleRange.length || !nol) {
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
		} while (!textFrame);

		if (framesetter) {
			CFRelease(framesetter);
			framesetter = NULL;
		}
		if (attributedString) {
			CFRelease(attributedString);
			attributedString = NULL;
		}
		rect.size = CGSizeZero;
	}
	[self.document adjustHeightToTextFrame:self exansionOnly:NO];
}

- (NSRange)rangeValue {
	return NSMakeRange([[document store] length], 0);
}

- (CFIndex)firstStringIndex {
	return [[document store] length];
}
- (void)setFirstStringIndex:(CFIndex)index {
//	[self invalidateFrame];
}
- (void)setWidth:(CGFloat)width {
	rect.size.width = width;
}

- (PhiTextRange *)textRange {
	return [PhiTextRange textRangeWithRange:[self rangeValue]];
}

- (void)setTextRange:(PhiTextRange *)aRange {
	//Do nothing
}

- (NSUInteger)lineCount {
	return 1;
}
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)selectionAffinity {
	PhiTextLine *line = nil;
	if ([self beginContentAccess] && [position position] == [[document store] length]) {
		line = [self _lineAtIndex:0 fromTextLines:NULL];
		[self endContentAccess];
	}

	return line;
}

- (PhiTextLine *)searchLineWithRange:(PhiTextRange *)range andPoint:(CGPoint)point {
	PhiTextLine *line = nil;
	if ([self beginContentAccess]) {
		line = [self _lineAtIndex:0 fromTextLines:NULL];
		[self endContentAccess];
	}
	return line;
}
@end


