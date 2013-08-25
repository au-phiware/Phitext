//
//  PhiTextParagraphInfo.h
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

@interface PhiTextParagraphStyle : NSObject {
	CTParagraphStyleRef _CTParagraphStyle;
	
	struct _PhiTextParagraphStyleBitFields {
		unsigned int alignment :1;
		unsigned int firstLineHeadIndent :1;
		unsigned int headIndent :1;
		unsigned int tailIndent :1;
		unsigned int tabStops :1;
		unsigned int defaultTabInterval :1;
		unsigned int lineBreakMode :1;
		unsigned int lineHeightMultiple :1;
		unsigned int maximumLineHeight :1;
		unsigned int minimumLineHeight :1;
		unsigned int lineSpacing :1;
		unsigned int paragraphSpacing :1;
		unsigned int paragraphSpacingBefore :1;
		unsigned int baseWritingDirection :1;
		
		unsigned int reserved :17;
	} flags;
	
	CTTextAlignment alignment;
	CGFloat firstLineHeadIndent;
	CGFloat headIndent;
	CGFloat tailIndent;
	CFMutableArrayRef tabStops;
	CGFloat defaultTabInterval;
	CTLineBreakMode lineBreakMode;
	CGFloat lineHeightMultiple;
	CGFloat maximumLineHeight;
	CGFloat minimumLineHeight;
	CGFloat lineSpacing;
	CGFloat paragraphSpacing;
	CGFloat paragraphSpacingBefore;
	CTWritingDirection baseWritingDirection;
}

+ (id)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)paragraphStyle;



@property (nonatomic, readonly) CTParagraphStyleRef CTParagraphStyle;

@property (nonatomic, assign) CTTextAlignment alignment;
@property (nonatomic, assign) CGFloat firstLineHeadIndent;
@property (nonatomic, assign) CGFloat headIndent;
@property (nonatomic, assign) CGFloat tailIndent;
@property (nonatomic, assign) CGFloat defaultTabInterval;
@property (nonatomic, assign) CTLineBreakMode lineBreakMode;
@property (nonatomic, assign) CGFloat lineHeightMultiple;
@property (nonatomic, assign) CGFloat maximumLineHeight;
@property (nonatomic, assign) CGFloat minimumLineHeight;
@property (nonatomic, assign) CGFloat lineSpacing;
@property (nonatomic, assign) CGFloat paragraphSpacing;
@property (nonatomic, assign) CGFloat paragraphSpacingBefore;
@property (nonatomic, assign) CTWritingDirection baseWritingDirection;

- (CFArrayRef)copyTabStops;
- (void)setTabStops:(CFArrayRef)newTabStops;
- (void)addTabStop:(double)location;
- (void)addTabStop:(double)location withAlignment:(CTTextAlignment) alignment;
- (void)addTabStop:(double)location withAlignment:(CTTextAlignment) alignment columnTerminators:(CFCharacterSetRef)terminators;
- (void)removeTabStopsAtLocation:(double)location;
- (void)removeTabStopsAtLocation:(double)location withAlignment:(CTTextAlignment) alignment;
- (void)removeAllTabStops;

- (void)unsetAlignment;
- (void)unsetFirstLineHeadIndent;
- (void)unsetHeadIndent;
- (void)unsetTailIndent;
- (void)unsetTabStops;
- (void)unsetDefaultTabInterval;
- (void)unsetLineBreakMode;
- (void)unsetLineHeightMultiple;
- (void)unsetMaximumLineHeight;
- (void)unsetMinimumLineHeight;
- (void)unsetLineSpacing;
- (void)unsetParagraphSpacing;
- (void)unsetParagraphSpacingBefore;
- (void)unsetBaseWritingDirection;

@end
