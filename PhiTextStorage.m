//
//  PhiTextStorage.m
//  Phitext
//
//  Created by Corin Lawson on 22/03/10.
//  Copyright 2010 Phiware. All rights reserved.
//

#import "PhiTextStorage.h"
#import "PhiTextDocument.h"
#import "PhiTextUndoManager.h"

@interface PhiTextDocument (PhiTextStorage)

- (CGRect)invalidateDocumentNSRange:(NSRange)range;

@end

@implementation PhiTextStorage

@synthesize owner;

- (id)init {
	if (self = [super init]) {
		text = [[NSMutableAttributedString alloc] initWithString:@""];
	}
	return self;
}

- (id)initWithString:(NSString *)string {
	if (self = [super init]) {
		text = [[NSMutableAttributedString alloc] initWithString:string];
	}
	return self;
}
- (id)initWithAttributedString:(NSAttributedString *)aString {
	if (self = [super init]) {
		text = [[NSMutableAttributedString alloc] initWithAttributedString:aString];
	}
	return self;
}
- (id)initWithString:(NSString *)string attributes:(NSDictionary *)attributes {
	if (self = [super init]) {
		text = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
	}
	return self;
}

- (NSAttributedString *)attributedString {
	NSAttributedString *rv = nil;
	@synchronized(self) {
		rv = [[text copy] autorelease];
	}
	return rv;
}
- (void)setAttributedString:(NSAttributedString *)attributedString {
	@synchronized(self) {
		if (text != attributedString) {
			[[owner undoManager] registerUndoWithTarget:self selector:@selector(setAttributedString:) object:text];
			if (text) {
				[text release];
				text = nil;
			}
			if (attributedString) {
				text = [attributedString mutableCopy];
			}
			[owner invalidateDocument];
		}
	}
}

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range {
	NSAttributedString *rv = nil;
	@synchronized(self) {
		rv = [text attributedSubstringFromRange:range];
	}
	return rv;
}
- (NSString *)substringWithRange:(NSRange)range {
	NSString *rv = nil;
	@synchronized(self) {
		rv = [[text attributedSubstringFromRange:range] string];
	}
	return rv;
}

- (NSUInteger)length {
	NSUInteger size = 0;
	if (text) {
		@synchronized(self) {
			size = [text length];
		}
	}
	return size;
}
- (unichar)characterAtIndex:(NSUInteger)index {
	unichar rv;
	@synchronized(self) {
		rv = [[text string] characterAtIndex:index];
	}
	return rv;
}
- (BOOL)isLineBreakAtIndex:(NSUInteger)index {
	if (index < 0)
		return NO;
	if (index >= [self length])
		return YES;

	return [self characterAtIndex:index] == '\n';
}
- (NSString *)string {
	NSString *rv;
	@synchronized(self) {
		rv = [text string];
	}
	return rv;
}

- (void)deleteCharactersInRange:(NSRange)range {
	CGRect invalidRect = CGRectNull;
	[owner textWillChange];
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 insertAttributedString:[self attributedSubstringFromRange:range]
							atIndex:range.location];
		else
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 insertString:[[text attributedSubstringFromRange:range] string]
				  atIndex:range.location];
		[text deleteCharactersInRange:range];
		invalidRect = [owner invalidateDocumentNSRange:range];
	}
	[owner textDidChange];
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
	CGRect invalidRect = CGRectNull;
	[owner textWillChange];
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(range.location, [string length])
				 withAttributedString:[self attributedSubstringFromRange:range]];
		else
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(range.location, [string length])
						   withString:[[text attributedSubstringFromRange:range] string]];
		[text replaceCharactersInRange:range withString:string];
		invalidRect = [owner invalidateDocumentNSRange:NSMakeRange(range.location, MAX([string length], range.length))];
	}
	[owner textDidChange];
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)replaceCharactersInRange:(NSRange)aRange withAttributedString:(NSAttributedString *)attributedString {
	CGRect invalidRect = CGRectNull;
	[owner textWillChange];
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(aRange.location, [attributedString length])
				 withAttributedString:[self attributedSubstringFromRange:aRange]];
		else
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(aRange.location, [attributedString length])
						   withString:[[text attributedSubstringFromRange:aRange] string]];
		[text replaceCharactersInRange:aRange withAttributedString:attributedString];
		invalidRect = [owner invalidateDocumentNSRange:NSMakeRange(aRange.location, [attributedString length])];
	}
	[owner textDidChange];
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)appendAttributedString:(NSAttributedString *)attributedString {
	CGRect invalidRect = CGRectNull;
	[owner textWillChange];
	@synchronized(self) {
		NSUInteger length = [text length];
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(length, [attributedString length])
				 withAttributedString:[self attributedSubstringFromRange:NSMakeRange(length, 0)]];
		else
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(length, [attributedString length])
						   withString:[[text attributedSubstringFromRange:NSMakeRange(length, 0)] string]];
		[text appendAttributedString:attributedString];
		invalidRect = [owner invalidateDocumentNSRange:NSMakeRange(length, [attributedString length])];
	}
	[owner textDidChange];
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)insertAttributedString:(NSAttributedString *)attributedString atIndex:(NSUInteger)index {
	CGRect invalidRect = CGRectNull;
	[owner textWillChange];
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(index, [attributedString length])
				 withAttributedString:[self attributedSubstringFromRange:NSMakeRange(index, 0)]];
		else 
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:NSMakeRange(index, [attributedString length])
						   withString:[[text attributedSubstringFromRange:NSMakeRange(index, 0)] string]];
		[text insertAttributedString:attributedString atIndex:index];
		invalidRect = [owner invalidateDocumentNSRange:NSMakeRange(index, [attributedString length])];
	}
	[owner textDidChange];
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange {
	NSDictionary *rv = nil;
	@synchronized(self) {
		rv = [text attributesAtIndex:index effectiveRange:aRange];
	}
	return rv;
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit {
	NSDictionary *rv = nil;
	@synchronized(self) {
		rv = [text attributesAtIndex:index longestEffectiveRange:aRange inRange:rangeLimit];
	}
	return rv;
}

- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange {
	id rv = nil;
	@synchronized(self) {
		rv = [text attribute:attributeName atIndex:index effectiveRange:aRange];
	}
	return rv;
}
- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit {
	id rv = nil;
	@synchronized(self) {
		rv = [text attribute:attributeName atIndex:index longestEffectiveRange:aRange inRange:rangeLimit];
	}
	return rv;
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
	CGRect invalidRect = CGRectNull;
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:aRange
			     withAttributedString:[self attributedSubstringFromRange:aRange]];
		[text setAttributes:attributes range:aRange];
		invalidRect = [owner invalidateDocumentNSRange:aRange];
	}
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)aRange {
	CGRect invalidRect = CGRectNull;
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:aRange
				 withAttributedString:[self attributedSubstringFromRange:aRange]];
		[text addAttribute:name value:value range:aRange];
		invalidRect = [owner invalidateDocumentNSRange:aRange];
	}
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
	CGRect invalidRect = CGRectNull;
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:aRange
				 withAttributedString:[self attributedSubstringFromRange:aRange]];
		[text addAttributes:attributes range:aRange];
		invalidRect = [owner invalidateDocumentNSRange:aRange];
	}
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)removeAttribute:(NSString *)name range:(NSRange)aRange {
	CGRect invalidRect = CGRectNull;
	@synchronized(self) {
		if (![[owner undoManager] shouldIgnoreUndoAnyGroupings:PhiTextUndoManagerStylingGroupingType])
			[[[owner undoManager] prepareWithInvocationTarget:self]
			 replaceCharactersInRange:aRange
				 withAttributedString:[self attributedSubstringFromRange:aRange]];
		[text removeAttribute:name range:aRange];
		invalidRect = [owner invalidateDocumentNSRange:aRange];
	}
	[[owner owner] performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:YES];
}

- (void)dealloc {
	[text release];
	[super dealloc];
}

@end

