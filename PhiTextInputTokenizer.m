//
//  PhiTextInputTokenizer.m
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

#import "PhiTextInputTokenizer.h"
#import "PhiTextEditorView.h"
#import "PhiTextDocument.h"
#import "PhiTextLine.h"
#import "PhiTextFrame.h"
#import "PhiTextRange.h"
#import "PhiTextPosition.h"
#import "PhiAATree.h"
#import "PhiTextStorage.h"

@interface PhiTextDocument (PhiTextInputTokenizer)
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity inRect:(CGRect)rect frameNode:(PhiAATreeNode **)frameNode;
@end

@implementation PhiTextInputTokenizer

- (id)initWithTextInput:(UIResponder < UITextInput > *)textInput {
	if (self = [super initWithTextInput:textInput]) {
		if ([textInput isKindOfClass:[PhiTextEditorView class]]) {
			owner = (PhiTextEditorView *)textInput;
		}
	}
	return self;
}


// Returns range of the enclosing text unit of the given granularity, or nil if there is no such enclosing unit.
// Whether a boundary position is enclosed depends on the given direction, using the same rule as isPosition:withinTextUnit:inDirection:
- (UITextRange *)rangeEnclosingPosition:(UITextPosition *)position
						withGranularity:(UITextGranularity)granularity
							inDirection:(UITextDirection)direction {
#ifdef TRACE
	NSLog(@"%@Executing [UITextInputStringTokenizer rangeEnclosingPosition:%@ withGranularity:%d inDirection:%d]...", traceIndent, position, granularity, direction);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	UITextRange *rv = nil;
	if (owner && granularity == UITextGranularityLine) {
		PhiTextLine *line = [owner.textDocument searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:owner.selectionAffinity];
		if ([(PhiTextPosition *)position compare:(PhiTextPosition *)[line.textRange end]]) {
			if (direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionRight)
				rv = line.textRange;
		} else if ([(PhiTextPosition *)position compare:(PhiTextPosition *)[line.textRange start]]) {
			if (direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionLeft)
				rv = line.textRange;
		} else
			rv = line.textRange;
	} else
		rv = [super rangeEnclosingPosition:position withGranularity:granularity inDirection:direction];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UITextInputStringTokenizer rangeEnclosingPosition:withGranularity:inDirection:]:%@.", traceIndent, rv);
#endif
	return rv;
}

// Returns YES only if a position is at a boundary of a text unit of the specified granularity in the particular direction.
- (BOOL)isPosition:(UITextPosition *)position
		atBoundary:(UITextGranularity)granularity
	   inDirection:(UITextDirection)direction {
#ifdef TRACE
	NSLog(@"%@Executing [UITextInputStringTokenizer isPosition:%@ atBoundary:%d inDirection:%d]...", traceIndent, position, granularity, direction);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	BOOL rv = NO;
	if (owner && granularity == UITextGranularityLine) {
		PhiTextLine *line = [owner.textDocument searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:owner.selectionAffinity];
		if ((direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionRight)
			&& ([(PhiTextPosition *)position compare:(PhiTextPosition *)[line.textRange end]] == NSOrderedSame
				|| /* position compare line textRange end less one is NSOrderedSame AND next char is line break */
				PhiPositionOffset(position) == PhiPositionOffset(line.textRange.end) - 1 && [owner.textDocument.store isLineBreakAtIndex:PhiPositionOffset(position)]
				))
			rv = YES;
		else if ((direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionLeft)
			&& [(PhiTextPosition *)position compare:(PhiTextPosition *)[line.textRange start]] == NSOrderedSame)
			rv = YES;
	} else
		rv = [super isPosition:position atBoundary:granularity inDirection:direction];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UITextInputStringTokenizer isPosition:atBoundary:inDirection:]:%s.", traceIndent, rv?"YES":"NO");
#endif
	return rv;
}

// Returns the next boundary position of a text unit of the given granularity in the given direction, or nil if there is no such position.
- (UITextPosition *)positionFromPosition:(UITextPosition *)position
							  toBoundary:(UITextGranularity)granularity
							 inDirection:(UITextDirection)direction {
#ifdef TRACE
	NSLog(@"%@Executing [UITextInputStringTokenizer positionFromPosition:%@ toBoundary:%d inDirection:%d]...", traceIndent, position, granularity, direction);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	UITextPosition *rv = nil;
	if (owner && granularity == UITextGranularityLine) {
		//TODO: confirm this is the correct selectionAffinity or should we use owner.selectionAffinity?
		PhiAATreeNode *node;
		PhiTextLine *line = [owner.textDocument searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:owner.selectionAffinity inRect:CGRectNull frameNode:&node];
		if (direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionRight) {
			rv = line.textRange.start;
			if (PhiPositionOffset(rv) > 0 && PhiPositionOffset(rv) == PhiPositionOffset(position)) {
				if (line.index > 0) {
					line = [[line frame] lineAtIndex:line.index - 1];
				} else {
					node = node.previous;
					CFIndex nol = [(PhiTextFrame *)node.object lineCount];
					line = [(PhiTextFrame *)node.object lineAtIndex:nol - 1];
				}
				rv = line.textRange.end;
				if (PhiPositionOffset(rv) > 0 && [owner.textDocument.store isLineBreakAtIndex:PhiPositionOffset(rv) - 1]) {
					rv = [PhiTextPosition textPositionWithPosition:PhiPositionOffset(rv) - 1 inLine:line];
				} else if (PhiPositionOffset(rv) > 0 && PhiPositionOffset(rv) == PhiPositionOffset(position)) {
					rv = line.textRange.start;
				}
			}
		} else if (direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionLeft) {
			if ([owner.textDocument.store isLineBreakAtIndex:PhiPositionOffset(line.textRange.end) - 1]) {
				rv = [PhiTextPosition textPositionWithPosition:PhiPositionOffset(line.textRange.end) - 1 inLine:line];
			} else {
				rv = line.textRange.end;
			}
			if (PhiPositionOffset(rv) == PhiPositionOffset(position)) {
				CFIndex nol = [[line frame] lineCount];
				if (line.index < nol - 1) {
					line = [[line frame] lineAtIndex:line.index + 1];
				} else if (node.next) {
					line = [(PhiTextFrame *)node.next.object lineAtIndex:0];
				}
				rv = line.textRange.start;
				if (PhiPositionOffset(rv) == PhiPositionOffset(position)) {
					rv = line.textRange.end;
				}
			}
		}
	} else
		rv = [super positionFromPosition:position toBoundary:granularity inDirection:direction];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UITextInputStringTokenizer positionFromPosition:toBoundary:inDirection:]:%@.", traceIndent, rv);
#endif
	return rv;
}

// Returns YES if position is within a text unit of the given granularity.  If the position is at a boundary, returns YES only if the boundary is part of the text unit in the given direction.
- (BOOL)isPosition:(UITextPosition *)position
	withinTextUnit:(UITextGranularity)granularity
	   inDirection:(UITextDirection)direction {
#ifdef TRACE
	NSLog(@"%@Executing [UITextInputStringTokenizer isPosition:%@ withinTextUnit:%d inDirection:%d]...", traceIndent, position, granularity, direction);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	BOOL rv = YES;
	if (owner && granularity == UITextGranularityLine) {
		if ((PhiPositionOffset(position) == 0 && direction == UITextStorageDirectionBackward)
			|| (PhiPositionOffset(position) == [owner.textDocument.store length] && UITextStorageDirectionForward))
			rv = NO;
	} else
		rv = [super isPosition:position withinTextUnit:granularity inDirection:direction];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UITextInputStringTokenizer isPosition:withinTextUnit:inDirection:]:%s.", traceIndent, rv?"YES":"NO");
#endif
	return rv;
}

@end
