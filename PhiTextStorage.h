//
//  PhiTextStorage.h
//  Phitext
//
//  Created by Corin Lawson on 22/03/10.
//  Copyright 2010 Phiware. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhiTextDocument;

@interface PhiTextStorage : NSObject {
@protected
	PhiTextDocument *owner;
	NSMutableAttributedString *text;
}

@property (nonatomic, assign) id owner;
@property (nonatomic, copy) NSAttributedString *attributedString;

#pragma mark Creating a Text Storage Object

- (id)initWithString:(NSString *)string;
- (id)initWithAttributedString:(NSAttributedString *)aString;
- (id)initWithString:(NSString *)string attributes:(NSDictionary *)attributes;

#pragma mark Extracting Text and Substrings

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range;
- (NSString *)substringWithRange:(NSRange)range;
- (unichar)characterAtIndex:(NSUInteger)index;
- (NSString *)string;

#pragma mark Retrieving Charater and Attribute Information

- (NSUInteger)length;
- (BOOL)isLineBreakAtIndex:(NSUInteger)index;
- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange;
- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit;
- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange;
- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit;

#pragma mark Changing Charaters

- (void)deleteCharactersInRange:(NSRange)range;
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

#pragma mark Changing Attributes

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange;
- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)aRange;
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)aRange;
- (void)removeAttribute:(NSString *)name range:(NSRange)aRange;

#pragma mark Changing Charaters and Attributes

- (void)appendAttributedString:(NSAttributedString *)attributedString;
- (void)insertAttributedString:(NSAttributedString *)attributedString atIndex:(NSUInteger)index;
- (void)replaceCharactersInRange:(NSRange)aRange withAttributedString:(NSAttributedString *)attributedString;

@end
