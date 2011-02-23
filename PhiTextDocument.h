//
//  PhiTextDocument.h
//  Phitext
//
//  Created by Corin Lawson on 10/03/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
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
@property (nonatomic, retain) PhiTextStyle *defaultStyle;
@property (nonatomic) CGFloat paddingLeft, paddingTop, paddingRight, paddingBottom;
@property (nonatomic, getter=willWrap) BOOL wrap;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat tileHeightHint;
@property (nonatomic, retain, readonly) PhiTextFrame *lastEmptyFrame;

- (void)invalidateDocument;
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

- (CGRect)invalidateTextFrameRange:(PhiAATreeRange *)range;
- (CGRect)invalidateDocumentRange:(PhiTextRange *)textRange;
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

- (PhiTextStyle *)styleAtEndOfDocument;
- (PhiTextStyle *)styleAtPosition:(PhiTextPosition *)position inDirection:(UITextStorageDirection)direction;
- (PhiTextStyle *)styleFromPosition:(PhiTextPosition *)position toFarthestEffectivePosition:(PhiTextPosition **)endPtr notBeyondPosition:(PhiTextPosition *)limitingPosition;
- (void)setStyle:(PhiTextStyle *)style range:(PhiTextRange *)range;
- (void)addStyle:(PhiTextStyle *)style range:(PhiTextRange *)range;

@end
