//
//  PhiTextRange.m
//  FirstCoreText
//
//  Created by Corin Lawson on 4/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextRange.h"
#import "PhiTextPosition.h"

@implementation PhiTextRange

@synthesize range;

+ (PhiTextRange *)textRangeWithRange:(NSRange)aRange {
	//TODO: caching
	return [[[PhiTextRange alloc] initWithRange:aRange] autorelease];
}
+ (PhiTextRange *)textRangeWithCFRange:(CFRange)aRange {
	NSUInteger location = 0, length = 0;
	if (aRange.length < 0) {
		location = aRange.length;
	}
	location += aRange.location;
	length = ABS(aRange.length);
	if (location < 0) {
		length += location;
		location = 0;
	}
	if (length < 0)
		length = 0;
	return [PhiTextRange textRangeWithRange:NSMakeRange(location, length)];
}
+ (PhiTextRange *)textRangeWithPosition:(PhiTextPosition *)position {
	return [PhiTextRange textRangeWithRange:NSMakeRange(PhiPositionOffset(position), 0)];
}
+ (PhiTextRange *)textRangeUnionWithRange:(PhiTextRange *)range otherRange:(PhiTextRange *)otherRange {
	return [PhiTextRange textRangeWithRange:NSUnionRange([range range], [otherRange range])];
}
- (PhiTextRange *)textRangeUnionWithRange:(PhiTextRange *)aRange {
	return [PhiTextRange textRangeUnionWithRange:self otherRange:aRange];
}
+ (PhiTextRange *)textRangeIntersectionWithRange:(PhiTextRange *)range otherRange:(PhiTextRange *)otherRange {
	return [PhiTextRange textRangeWithRange:NSIntersectionRange([range range], [otherRange range])];
}
- (PhiTextRange *)textRangeIntersectionWithRange:(PhiTextRange *)aRange {
	return [PhiTextRange textRangeIntersectionWithRange:self otherRange:aRange];
}
+ (PhiTextRange *)clampRange:(PhiTextRange *)range toRange:(PhiTextRange *)constraints {
	if (NSLocationInRange(PhiPositionOffset([range end]), [constraints range]) && NSLocationInRange(PhiPositionOffset([range start]), [constraints range])) {
		return [[range copy] autorelease];
	}
	NSRange clampedRange, unclampedRange, clampRange;
	unclampedRange = [range range];
	clampRange = [constraints range];
	clampedRange.location = MAX(unclampedRange.location, clampRange.location);
	clampedRange.length = MAX(0, MIN(unclampedRange.length - MAX(0, clampedRange.location - unclampedRange.location),
									     clampRange.length - MAX(0, clampedRange.location -     clampRange.location)));
	return [PhiTextRange textRangeWithRange:clampedRange];
}

- (id)initWithRange:(NSRange)aRange {
#ifdef TRACE
	//NSLog(@"Entering initWithRange:%d, %d...", aRange.location, aRange.length);
#endif
	if (self = [self init]) {
		range = aRange;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	return [self retain];
}

- (NSUInteger)length {
	return range.length;
}

- (BOOL)isEmpty {
	// TODO: What if range is unset??
	BOOL empty = range.length == 0;
#ifdef TRACE
	NSLog(@"Getting empty:%s", empty?"YES":"NO");
#endif
	return empty;
}

- (UITextPosition *)start {
	PhiTextPosition *p = [PhiTextPosition textPositionWithPosition:range.location];
#ifdef TRACE
	NSLog(@"Getting start:%d", p.position);
#endif
	return p;
}

- (UITextPosition *)end {
	PhiTextPosition *p = [PhiTextPosition textPositionWithPosition:NSMaxRange(range)];
#ifdef TRACE
	NSLog(@"Getting end:%d", p.position);
#endif
	return p;
}

- (NSRange)rangeValue {
	return self.range;
}

- (BOOL)isEqual:(id)object {
	if (self == object)
		return YES;
	if ([object respondsToSelector:@selector(rangeValue)])
		return NSEqualRanges(self.range, [object rangeValue]);
	return NO;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%d, %d", range.location, range.length];
}

@end
