//
//  PhiTextRange.h
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
