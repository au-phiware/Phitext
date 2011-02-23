//
//  PhiTextStyleInfo.h
//  Phitext
//
//  Created by Corin Lawson on 18/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@class PhiTextFont;
@class PhiTextParagraphStyle;

typedef enum {
	kPhiNoCharactersSelector          = 0,
	kPhiTraditionalCharactersSelector = 1,
	kPhiSimplifiedCharactersSelector  = 2,
	kPhiJIS1978CharactersSelector     = 3,
	kPhiJIS1983CharactersSelector     = 4,
	kPhiJIS1990CharactersSelector     = 5,
	kPhiTraditionalAltOneSelector     = 6,
	kPhiTraditionalAltTwoSelector     = 7,
	kPhiTraditionalAltThreeSelector   = 8,
	kPhiTraditionalAltFourSelector    = 9,
	kPhiTraditionalAltFiveSelector    = 10,
	kPhiExpertCharactersSelector      = 11
} PhiCharacterShapeType;

typedef enum {
	kPhiOnlyEssentialLigatures = 0,
	kPhiStandardLigatures      = 1,
	kPhiAllLigatures           = 2
} PhiLigaturesType;

typedef enum {
	kPhiStrokeAndFill = -1,
	kPhiStrokeOnly    = 1
} PhiStrokeStyleType;

typedef enum {
	kPhiUnderlinePatternSolid      = 0x0000,
	kPhiUnderlinePatternDot        = 0x0100,
	kPhiUnderlinePatternDash       = 0x0200,
	kPhiUnderlinePatternDashDot    = 0x0300,
	kPhiUnderlinePatternDashDotDot = 0x0400
} PhiUnderlinePatternType;
typedef enum {
	kPhiUnderlineScaleOff,
	kPhiUnderlineScaleXXLong,
	kPhiUnderlineScaleXLong,
	kPhiUnderlineScaleLong,
	kPhiUnderlineScaleMedium,
	kPhiUnderlineScaleSmall,
	kPhiUnderlineScaleXSmall,
	kPhiUnderlineScaleXXSmall
} PhiUnderlineScaleType;

/*! Encapsulates the string attributes to which Core Text responds. !*/
@interface PhiTextStyle : NSObject <NSCopying> {
	CFMutableDictionaryRef attributes;
	PhiTextFont *font;
	PhiTextParagraphStyle *paragraphStyle;
	PhiStrokeStyleType strokeStyle;
	PhiUnderlinePatternType underlinePattern;
	PhiUnderlineScaleType underlineScale;
}

+ (PhiTextStyle *)styleWithDictionary:(NSDictionary *)attributes;
- (PhiTextStyle *)styleWithAddedStyle:(PhiTextStyle *)style;

// Access the underlying CFDictionary
@property(nonatomic, readonly) CFDictionaryRef attributes;

@property(nonatomic, assign) PhiCharacterShapeType characterShape;
@property(nonatomic, retain) PhiTextFont *font;
@property(nonatomic, assign) float kern;
@property(nonatomic, assign) PhiLigaturesType ligature;
@property(nonatomic, assign) BOOL shouldUseCurrentColor;
@property(nonatomic) CGColorRef color;
@property(nonatomic, retain) PhiTextParagraphStyle *paragraphStyle;
@property(nonatomic, assign) PhiStrokeStyleType strokeStyle;
@property(nonatomic, assign) float strokeWidth;
@property(nonatomic) CGColorRef strokeColor;
@property(nonatomic, assign, getter=isSuperscript) BOOL superscript;
@property(nonatomic, assign, getter=isSubscript) BOOL subscript;
@property(nonatomic, assign, getter=isUnderlined) BOOL underlined;
@property(nonatomic, assign) PhiUnderlinePatternType underlinePattern;
@property(nonatomic, assign) PhiUnderlineScaleType underlineScale;
@property(nonatomic, assign, getter=isUnderlineDouble) BOOL underlineDouble;
@property(nonatomic) CGColorRef underlineColor;
@property(nonatomic, assign) BOOL shouldUseVerticalForms;

- (void)unsetCharacterShape;
- (void)unsetFont;
- (void)unsetKern;
- (void)unsetLigature;
- (void)unsetShouldUseCurrentColor;
- (void)unsetColor;
- (void)unsetParagraphStyle;
- (void)unsetStrokeWidth;
- (void)unsetStrokeColor;
- (void)unsetSuperscript;
- (void)unsetSubscript;
- (void)unsetUnderline;
- (void)unsetUnderlineColor;
- (void)unsetShouldUseVerticalForms;

@end
