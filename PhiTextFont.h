//
//  PhiTextFont.h
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
