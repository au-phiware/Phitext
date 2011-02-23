//
//  PhiTextPosition.m
//  FirstCoreText
//
//  Created by Corin Lawson on 4/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextPosition.h"
#import "PhiTextLine.h"
#import "PhiTextFrame.h"

@interface PhiTextPosition ()
@property (retain, nonatomic, readwrite) PhiTextLine *line;
@end

@implementation PhiTextPosition

@synthesize position, line;

+ (PhiTextPosition *)textPositionWithPosition:(NSUInteger)aPosition {
	static PhiTextPosition *zeroTextPosition = nil;
	if (!zeroTextPosition) {
		zeroTextPosition = [[PhiTextPosition alloc] initWithPosition:0];
	}
	//TODO: caching
	if (aPosition == 0) {
		return zeroTextPosition;
	}
	return [[[PhiTextPosition alloc] initWithPosition:aPosition] autorelease];
}

+ (PhiTextPosition *)textPositionWithPosition:(NSUInteger)aPosition inLine:(PhiTextLine *)aLine {
	return [[[PhiTextPosition alloc] initWithPosition:aPosition inLine:aLine] autorelease];
}

+ (PhiTextPosition *)textPositionWithPosition:(NSUInteger)aPosition offset:(NSInteger)offset {
	//TODO: caching
	return [PhiTextPosition textPositionWithPosition:aPosition + offset];
}

+ (PhiTextPosition *)textPositionWithTextPosition:(PhiTextPosition *)textPosition offset:(NSInteger)offset {
	//TODO: caching
	return [PhiTextPosition textPositionWithPosition:textPosition.position + offset];
}


- (id)initWithPosition:(NSUInteger)aPosition {
#ifdef TRACE
	//NSLog(@"Entering initWithPosition:%d...", aPosition);
#endif
	if (self = [self init]) {
		position = aPosition;
	}
	return self;
}

- (id)initWithPosition:(NSUInteger)aPosition inLine:(PhiTextLine *)aLine {
#ifdef TRACE
	//NSLog(@"Entering initWithPosition:%d...", aPosition);
#endif
	if (self = [self init]) {
		position = aPosition;
		self.line = aLine;
	}
	return self;
}

- (void)unsetLine {
	self.line = nil;
}
- (void)setLine:(PhiTextLine *)aLine {
	if (line != aLine) {
		if (line) {
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:PhiTextFrameWillDiscardContentNotification
														  object:line.frame];
			[line release];
		}
		line = aLine;
		if (line) {
			[line retain];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(unsetLine)
														 name:PhiTextFrameWillDiscardContentNotification
													   object:line.frame];			
		}
	}
}

- (id)textPositionWithOffset:(NSInteger)offset {
	PhiTextPosition *rv = [PhiTextPosition textPositionWithPosition:MAX(0, (NSInteger)(position + offset))];
	if (self.line && PhiPositionOffset(rv) <= PhiPositionOffset([self.line.textRange end])) {
		rv.line = self.line;
	}
	return rv;
}

- (id)copyWithZone:(NSZone *)zone {
	if (line)
		return [[PhiTextPosition allocWithZone:zone] initWithPosition:position];
	else
		return [self retain];
}

- (NSComparisonResult)compare:(PhiTextPosition *)other {
	return [self isEqual:other] ? NSOrderedSame : (self.position < other.position ? NSOrderedAscending : NSOrderedDescending);
}

- (NSUInteger)hash {
	return position;
}
- (BOOL)isEqual:(id)object {
	return self == object || ([object isKindOfClass:[PhiTextPosition class]] && [self position] == [object position]);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%d", self.position];
}

- (void) dealloc {
	self.line = nil;
	[super dealloc];
}
@end
