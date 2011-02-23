//
//  PhiTextFont.h
//  Phitext
//
//  Created by Corin Lawson on 18/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIFont;

@interface PhiTextFont : NSObject {
	CTFontRef _CTFont;
}

@property (nonatomic, assign) CGFloat size;
@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;
@property (nonatomic, readonly) unsigned unitsPerEm;
@property (nonatomic, readonly) CFIndex glyphCount;
@property (nonatomic, readonly) CGRect boundingBox;
@property (nonatomic, readonly) CGFloat underlinePosition;
@property (nonatomic, readonly) CGFloat underlineThickness;
@property (nonatomic, readonly) CGFloat slantAngle;
@property (nonatomic, readonly) CGFloat capHeight;
@property (nonatomic, readonly) CGFloat xHeight;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *familyName;
@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, readonly) NSString *postScriptName;
@property (nonatomic, readonly) UIFont *UIFont;

+ (id)fontWithCTFont:(CTFontRef)font;
+ (id)fontWithFont:(PhiTextFont *)font andSize:(CGFloat)size;
+ (id)fontWithCTFontDescriptor:(CTFontDescriptorRef)descriptor andSize:(CGFloat)size;

- (id)initWithCTFont:(CTFontRef)font;
- (PhiTextFont *)fontWithSize:(CGFloat)size;

- (CTFontRef)copyCTFont;
- (CTFontDescriptorRef)copyCTFontDescriptor;


@end
