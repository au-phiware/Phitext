//
//  PhiTextPosition.h
//  FirstCoreText
//
//  Created by Corin Lawson on 4/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
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
