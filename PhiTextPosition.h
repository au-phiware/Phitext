//
//  PhiTextPosition.h
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

@class PhiTextLine;

#ifndef PhiPositionOffset
#define PhiPositionOffset(__POSITION__) [(PhiTextPosition *)(__POSITION__) position]
#endif

@interface PhiTextPosition : UITextPosition <NSCopying> {
	NSUInteger position;
	PhiTextLine *line;
}

@property (assign, nonatomic, readonly) NSUInteger position;
@property (retain, nonatomic, readonly) PhiTextLine *line;

+ (PhiTextPosition *)textPositionWithPosition:(NSUInteger)position;
+ (PhiTextPosition *)textPositionWithPosition:(NSUInteger)position inLine:(PhiTextLine *)line;
+ (PhiTextPosition *)textPositionWithPosition:(NSUInteger)position offset:(NSInteger)offset;
+ (PhiTextPosition *)textPositionWithTextPosition:(PhiTextPosition *)textPosition offset:(NSInteger)offset;

- (id)initWithPosition:(NSUInteger)position;
- (id)initWithPosition:(NSUInteger)position inLine:(PhiTextLine *)line;

- (id)textPositionWithOffset:(NSInteger)offset;

- (NSComparisonResult)compare:(PhiTextPosition *)other;
- (NSString *)description;

@end
