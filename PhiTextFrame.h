//
//  PhiTextFrame.h
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

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UITextInput.h>

@class PhiTextRange;
@class PhiTextPosition;
@class PhiTextStorage;
@class PhiTextDocument;
@class PhiTextLine;

#ifndef PhiFrameOffset
#define PhiFrameOffset(__FRAME__) ([(PhiTextFrame *)(__FRAME__) firstStringIndex])
#endif

extern NSString * const PhiTextFrameWillDiscardContentNotification;
extern NSString * const PhiTextFrameDidDiscardContentNotification;

enum {
	kPhiTextCompareBackwards = 1,
	kPhiTextCompareCommutative = 1 << 1,
//	kPhiTextCompare = 1 << 1,
};
typedef CFOptionFlags PhiTextFrameCompareFlags;

typedef CFComparisonResult (*PhiTextFrameComparatorFunction)(id searchValue, id value, BOOL backwards);

/*!
 Compares the rectangles of two the specified PhiTextFrames or NSValues.
 Returns kCFCompareGreaterThan if the top of the otherTextFrame is below
 or at the bottom of the textFrame, kCFCompareLessThan otherwise.
 The textFrames are not validated in the compare process.
 Note this is non-commutative!
 Any object that responds to CGRectValue will work.
 */
CFComparisonResult PhiTextFrameCompareByRect (id textFrame, id otherTextFrame, BOOL backwards);
CFComparisonResult PhiTextFrameCompareByRectIn (id textFrame, id otherTextFrame, BOOL backwards);

/*!
 Compares the ranges of two the specified PhiTextFrames or PhiTextRanges.
 The text in the range is not compared and the textFrames are not automatically validated in the compare process.
 Note this is non-commutative!
 Any object that responds to rangeValue will work.
 */
CFComparisonResult PhiTextFrameCompareByRange (id textFrame, id otherTextFrame, BOOL backwards);
CFComparisonResult PhiTextFrameCompareByRangeIn (id textFrame, id otherTextFrame, BOOL backwards);

#ifndef PHI_FRAMESETTER_MEMBER
#define PHI_FRAMESETTER_MEMBER 0
#endif

@interface PhiTextFrame : NSObject /*TODO:<NSDiscardableContent>*/ {
@protected
	CGPathRef path;
	CFIndex firstStringIndex;
	CFIndex staleStringLength;
	CFIndex stringIndexDiff;
	NSUInteger firstLineNumber;
	//NSUInteger lineCount;
	PhiTextDocument *document;
	NSDictionary *frameAttributes;

	CGRect rect;
	CGRect staleRect;
	CGPoint tileOffset;
	PhiTextRange *textRange;
#if PHI_FRAMESETTER_MEMBER
	CTFramesetterRef framesetter;
#endif
	CTFrameRef textFrame;
	BOOL hasEmptyLastLine;
	
	int accessCount;
	BOOL deferEndAccess;
}

+ (PhiTextFrame *)textFrameInPath:(CGPathRef)constraints beginningAt:(CFIndex)stringIndex forDocument:(PhiTextDocument *)document;
+ (PhiTextFrame *)textFrameWithFrame:(CTFrameRef)frame forDocument:(PhiTextDocument *)document;
+ (PhiTextFrame *)textFrameInPath:(CGPathRef)constraints beginningAt:(CFIndex)stringIndex forDocument:(PhiTextDocument *)document attributes:(NSDictionary *)attributes;
+ (PhiTextFrame *)textFrameWithFrame:(CTFrameRef)frame forDocument:(PhiTextDocument *)document attributes:(NSDictionary *)attributes;

@property (nonatomic, readonly) PhiTextRange *textRange;
@property (nonatomic, readonly) BOOL hasEmptyLastLine;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic, readonly) CGPoint tileOffset;
@property (nonatomic, readonly) CFIndex firstStringIndex;
@property (nonatomic, readonly) NSUInteger firstLineNumber;
@property (nonatomic, assign) PhiTextDocument *document;
@property (nonatomic, retain) NSDictionary *frameAttributes;
- (CTFrameRef)copyCTFrame;

- (id)initInPath:(CGPathRef)constraints beginningAt:(CFIndex)stringIndex forDocument:(PhiTextDocument *)document attributes:(NSDictionary *)attributes;

- (NSUInteger)lineCount;
- (PhiTextLine *)lineAtIndex:(CFIndex)index;
- (CGRect)CGRectValue;
- (CGFloat)realWidth;
- (NSRange)rangeValue;

// Use the NSDiscardableContent methods instead
- (void)invalidateFrame;
//- (void)validateFrameRect;
//- (void)validateFrame;
- (BOOL)beginContentAccess;
- (void)endContentAccess;
- (PhiTextFrame *)autoEndContentAccess;
- (void)discardContentIfPossible;
- (BOOL)isContentDiscarded;

- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)selectionAffinity;
- (PhiTextLine *)searchLineWithRange:(PhiTextRange *)range andPoint:(CGPoint)point;

@end
