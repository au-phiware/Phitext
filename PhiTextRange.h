//
//  PhiTextRange.h
//  FirstCoreText
//
//  Created by Corin Lawson on 4/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PhiTextPosition;

#ifndef PhiRangeRange
#define PhiRangeRange(__RANGE__) ([(PhiTextRange *)(__RANGE__) range])
#endif

#ifndef PhiRangeLength
#define PhiRangeLength(__RANGE__) (([(PhiTextRange *)(__RANGE__) range]).length)
#endif

#ifndef PhiRangeOffset
#define PhiRangeOffset(__RANGE__) (([(PhiTextRange *)(__RANGE__) range]).location)
#endif

@interface PhiTextRange : UITextRange <NSCopying> {
	NSRange range;
}

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;
@property (nonatomic, readonly) NSUInteger length;

+ (PhiTextRange *)textRangeWithRange:(NSRange)range;
+ (PhiTextRange *)textRangeWithCFRange:(CFRange)range;
+ (PhiTextRange *)textRangeWithPosition:(PhiTextPosition *)position;
+ (PhiTextRange *)textRangeUnionWithRange:(PhiTextRange *)range otherRange:(PhiTextRange *)otherRange;
+ (PhiTextRange *)textRangeIntersectionWithRange:(PhiTextRange *)range otherRange:(PhiTextRange *)otherRange;
+ (PhiTextRange *)clampRange:(PhiTextRange *)range toRange:(PhiTextRange *)contraints;

- (PhiTextRange *)textRangeUnionWithRange:(PhiTextRange *)aRange;
- (PhiTextRange *)textRangeIntersectionWithRange:(PhiTextRange *)aRange;

- (id)initWithRange:(NSRange)range;

- (UITextPosition *)start;
- (UITextPosition *)end;

- (NSString *)description;

@end
