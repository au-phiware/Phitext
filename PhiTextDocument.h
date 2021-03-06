//
//  PhiTextDocument.h
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
#import <CoreText/CoreText.h>

@class PhiTextEditorView;
@class PhiTextPosition;
@class PhiTextRange;
@class PhiTextFrame;
@class PhiTextStorage;
@class PhiTextStyle;
@class PhiTextLine;
@class PhiTextUndoManager;
@class PhiAATree;
@class PhiAATreeNode;
@class PhiAATreeRange;

@interface PhiTextDocument : NSObject {
@private
	PhiTextEditorView *owner;
	PhiTextStorage *store;
	
	UIColor *currentColor;
	PhiTextStyle *baseStyle;
	PhiTextStyle *defaultStyle;
	CGFloat paddingLeft, paddingTop, paddingRight, paddingBottom;
	BOOL wrap;
	int selectionAffinity;
	CGFloat tileHeightHint;
	
	CFDictionaryRef frameAttributes;
	PhiAATree *textFrames;
	
	NSInteger oldLength, diffLength;
	NSRange invalidRange;
	PhiAATreeNode *lastValidTextFrameNode;
	
	PhiTextFrame *lastEmptyFrame;
	
	PhiTextUndoManager *undoManager;
}

@property (assign) PhiTextEditorView *owner;
@property (retain) PhiTextStorage *store;
@property (retain) PhiTextUndoManager *undoManager;

@property (nonatomic, readonly) PhiAATree *textFrames;
@property (nonatomic, retain) UIColor *currentColor;
@property (nonatomic, retain) PhiTextStyle *baseStyle;
@property (nonatomic, retain) PhiTextStyle *defaultStyle;
@property (nonatomic) CGFloat paddingLeft, paddingTop, paddingRight, paddingBottom;
@property (nonatomic, getter=willWrap) BOOL wrap;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat tileHeightHint;
@property (nonatomic, retain, readonly) PhiTextFrame *lastEmptyFrame;

- (void)invalidateDocument;
- (CGRect)invalidateTextFrameRange:(PhiAATreeRange *)range;
- (CGRect)invalidateDocumentRange:(PhiTextRange *)textRange;
- (void)textWillChange;
- (void)textDidChange;

- (CGRect)firstRectForRange:(PhiTextRange *)range;
- (CGRect)lastRectForRange:(PhiTextRange *)range;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity inRect:(CGRect)rect;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity autoExpand:(BOOL)flag;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity autoExpand:(BOOL)flag inRect:(CGRect)rect;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity inRect:(CGRect)rect alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity autoExpand:(BOOL)flag alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity autoExpand:(BOOL)flag inRect:(CGRect)rect alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;
- (UITextPosition *)closestPositionToPoint:(CGPoint)point;
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(PhiTextRange *)range;
- (UITextRange *)characterRangeAtPoint:(CGPoint)point;
- (CGSize)approximateTextSize;
- (CGSize)suggestTextSize;
- (CGSize)suggestTextSizeWithConstraints:(CGSize)constraints;
- (PhiTextPosition *)positionFromPosition:(PhiTextPosition *)position withLineOffset:(NSInteger)offset selectionAffinity:(UITextStorageDirection *)inoutAffinity;

- (PhiTextRange *)textRangeOfDocument;
- (CGRect)lineRectForRange:(PhiTextRange *)range withPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity;
- (CGRect)lineRectForRange:(PhiTextRange *)range withPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity includeLeading:(BOOL)includeLeading;
- (CGRect)rectForLine:(PhiTextLine *)line;
- (CGRect)rectForLine:(PhiTextLine *)line withOffset:(CGPoint)offset;
- (CGRect)rectForLine:(PhiTextLine *)line withOffset:(CGPoint)offset includeLeading:(BOOL)includeLeading;
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity;
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity inRect:(CGRect)rect;
- (PhiTextLine *)searchLineWithPoint:(CGPoint)point;
- (PhiTextLine *)searchLineWithRange:(PhiTextRange *)range andPoint:(CGPoint)point;

- (void)setSize:(CGSize)size invalidate:(BOOL)invalidate;
- (void)adjustSizeToTextFrame:(PhiTextFrame *)textFrame exansionOnly:(BOOL)exansionOnly;
- (void)adjustSizeToTextFrame:(PhiTextFrame *)textFrame;
- (void)adjustHeightToTextFrame:(PhiTextFrame *)textFrame exansionOnly:(BOOL)exansionOnly;
- (void)adjustWidthToTextFrame:(PhiTextFrame *)textFrame exansionOnly:(BOOL)exansionOnly;

- (PhiAATreeRange *)beginContentAccessInRect:(CGRect)rect;
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range;
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range andRect:(CGRect)rect;
- (PhiAATreeRange *)beginContentAccessInRect:(CGRect)rect updateDisplay:(BOOL)shouldUpdateDisplay;
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range updateDisplay:(BOOL)shouldUpdateDisplay;
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range andRect:(CGRect)rect updateDisplay:(BOOL)shouldUpdateDisplay;
/*! Constructs a path in the specified path that encloses the specified range of the receiver's text.
 */
- (void)buildPath:(CGMutablePathRef)path forRange:(PhiTextRange *)range;
- (void)buildPath:(CGMutablePathRef)path withFirstRect:(CGRect)firstRect toLastRect:(CGRect)lastRect;
- (void)buildPath:(CGMutablePathRef)path withFirstRect:(CGRect)firstRect toLastRect:(CGRect)lastRect alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;
- (void)buildPath:(CGMutablePathRef)path forRange:(PhiTextRange *)range alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;

- (void)addBaseStyle:(PhiTextStyle *)style;
- (void)addDefaultStyle:(PhiTextStyle *)style;
- (PhiTextStyle *)styleAtEndOfDocument;
- (PhiTextStyle *)styleAtPosition:(PhiTextPosition *)position inDirection:(UITextStorageDirection)direction;
- (PhiTextStyle *)styleFromPosition:(PhiTextPosition *)position toFarthestEffectivePosition:(PhiTextPosition **)endPtr notBeyondPosition:(PhiTextPosition *)limitingPosition;
- (void)setStyle:(PhiTextStyle *)style range:(PhiTextRange *)range;
- (void)addStyle:(PhiTextStyle *)style range:(PhiTextRange *)range;

@end
