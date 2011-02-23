//
//  PhiTextLine.h
//  Phitext
//
//  Created by Corin Lawson on 14/07/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

@class PhiTextRange;
@class PhiTextPosition;
@class PhiTextFrame;

@interface PhiTextLine : NSObject {
	PhiTextFrame *frame;
	CTLineRef textLine;
	CFIndex index;
	CGPoint origin;
	PhiTextRange *textRange;

	CGFloat width;
	CGFloat ascent;
	CGFloat descent;
	CGFloat leading;
}

@property (nonatomic, readonly) PhiTextFrame *frame;
@property (nonatomic, readonly) PhiTextRange *textRange;
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;
@property (nonatomic, readonly) CTLineRef textLine;
@property (nonatomic, readonly) CFIndex index;
@property (nonatomic, readonly) NSUInteger number;
@property (nonatomic, readonly) CGPoint originInFrame;
@property (nonatomic, readonly) CGPoint originInDocument;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;
@property (nonatomic, readonly) CGFloat height;

+ (id)textLineWithLine:(CTLineRef)line index:(CFIndex)index frame:(PhiTextFrame *)frame;
+ (id)textLineWithIndex:(CFIndex)index frame:(PhiTextFrame *)frame;

- (id)initWithLine:(CTLineRef)line index:(CFIndex)i frame:(PhiTextFrame *)textFrame;

/*! exclusive of document's bounds.origin */
- (CGFloat)offsetForPosition:(PhiTextPosition *)position;
- (PhiTextPosition *)positionForPoint:(CGPoint)point;
	
@end
