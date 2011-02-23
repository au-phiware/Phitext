//
//  PhiTextEditorView.h
//  FirstCoreText
//
//  Created by Corin Lawson on 15/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

/*!
    @header PhiTextEditorView
    @abstract   Intended as a replacement for UITextView.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Phitext/PhiTextSelectionView.h>

@class PhiTextDocument;
@class PhiTextView;
@class PhiTextSelectionView;
@class PhiTextMagnifier;
@class PhiTextSelectionHandleRecognizer;
@class PhiTextRange;
@class PhiTextPosition;
@class PhiTextStyle;

#ifndef PHI_CLAMP
#define PHI_CLAMP(X, X_MIN, X_MAX) (MIN(MAX(X, X_MIN), X_MAX))
#endif

/*!
    @enum       PhiTextStorageDirection
    @abstract   Compatible with UITextStorageDirection
    @see        closestSnapPositionToPoint:inDirection:
    @discussion Adds a constant to UITextStorageDirection to indicate that direction is unimportant.
    @constant   PhiTextStorageDirectionAny Indicates that direction is not important.
    @constant   PhiTextStorageDirectionForward Equivalent to UITextStorageDirectionForward.
    @constant   PhiTextStorageDirectionBackward Equivalent to UITextStorageDirectionBackward.
*/
typedef enum {
    PhiTextStorageDirectionAny = -1,
    PhiTextStorageDirectionForward = 0,
    PhiTextStorageDirectionBackward
} PhiTextStorageDirection;


@class PhiTextEditorView;

@protocol PhiTextViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (BOOL)textViewShouldBeginEditing:(PhiTextEditorView *)textView;
- (BOOL)textViewShouldEndEditing:(PhiTextEditorView *)textView;

- (void)textViewDidBeginEditing:(PhiTextEditorView *)textView;
- (void)textViewDidEndEditing:(PhiTextEditorView *)textView;

- (BOOL)textView:(PhiTextEditorView *)textView shouldChangeTextInRange:(PhiTextRange *)range replacementText:(NSString *)text;
- (void)textViewDidChange:(PhiTextEditorView *)textView;

- (void)textViewDidChangeSelection:(PhiTextEditorView *)textView;

@end


/*!
    @class PhiTextEditorView
    @abstract    A rich text view.
    @discussion  Implements the UITextInput protocol and backed by NSAttributedString.
*/
@interface PhiTextEditorView : UIScrollView <UITextInput, UIScrollViewDelegate, PhiTextSelectionViewDelegate> {
@private
	
	PhiTextDocument *textDocument;
	PhiTextSelectionView *selectionView;
	PhiTextSelectionView *markedTextView;
	NSMutableArray *textViews;
	NSMutableSet *reusableTextViews;
	NSMutableArray *undoStack;
	NSMutableArray *redoStack;
	
	struct _PhiTextEditorViewBitFields {
		unsigned int willTextChange :1;
		unsigned int willSelectionChange :1;

		unsigned int wordSelected :1;
		unsigned int wordCopied :1;
		unsigned int shouldNotifyInputDelegate :1;
		unsigned int shouldInvalidateTextDocument :1;
		unsigned int blinkingPaused :1;
		unsigned int magnifierShown :1;
		unsigned int editable :1;

		unsigned int enablesReturnKeyAutomatically :1;                  // default is NO (when YES, will automatically disable return key when text widget has zero-length contents, and will automatically enable when text widget has non-zero-length contents)
		unsigned int secureTextEntry :1;                                // default is NO
		
		unsigned int keepMenuVisible :1;
		unsigned int menuShown :1;
		unsigned int enableMenuPaging :1;
		unsigned int enableMenuPositionAdjustment :1;
		unsigned int menuArrowDirectionOverride :1;

		unsigned int reserved :16;
	} flags;
	PhiTextMagnifier *magnifier;
	PhiTextSelectionHandleRecognizer *selectionModifier;
	PhiTextRange *initialHandleRange;
	UIView *inputAccessoryView;
	UIView *inputView;
	CGRect keyboardFrame;
	NSTimer *autoScrollTimer;
	
	UITextAutocapitalizationType autocapitalizationType; // default is UITextAutocapitalizationTypeNone
	UITextAutocorrectionType autocorrectionType;         // default is UITextAutocorrectionTypeDefault
	UIKeyboardType keyboardType;                         // default is UIKeyboardTypeDefault
	UIKeyboardAppearance keyboardAppearance;             // default is UIKeyboardAppearanceDefault
	UIReturnKeyType returnKeyType;                       // default is UIReturnKeyDefault (See note under UIReturnKeyType enum)
	
	UITextStorageDirection selectionAffinity;
	UITextRange *selectedTextRange;
	PhiTextStyle *currentTextStyle;
	UITextRange *markedTextRange;                       // Nil if no marked text.
	NSDictionary *markedTextStyle;                          // Describes how the marked text should be drawn.
	id <UITextInputDelegate> inputDelegate;				// Don't set this 
	NSObject <UITextInputTokenizer> *tokenizer;
	id<PhiTextViewDelegate> delegate;
	
	PhiTextPosition *eod;
	PhiTextPosition *bod;
	
	CGFloat tileHeightHint, tileWidthHint;
	CGFloat autoScrollGap, autoScrollDuration, autoScrollSpeed; 
	CGFloat scrollBuffer;
	
	NSMutableArray *menuPages;
	NSUInteger menuPageNumber;
	UIMenuItem *moreMenuItem;
	CGRect menuTargetRect;
}

+ (NSString *)versionString;

@property (getter=shouldEnableMenuPositionAdjustment) BOOL enableMenuPositionAdjustment;
@property (nonatomic, readonly, getter=isMenuShown) BOOL menuShown;
@property (nonatomic, assign) BOOL enableMenuPaging;
@property (nonatomic, readonly) CGRect menuTargetRect;
@property (nonatomic, getter=isEditable) BOOL editable;
@property (readwrite, retain) UIView *inputAccessoryView;
@property (readwrite, retain) UIView *inputView;

- (void)setKeepMenuVisible;
- (void)changeSelectedRange:(PhiTextRange *)textRange;
- (void)changeSelectedRange:(PhiTextRange *)textRange scroll:(BOOL)scrollToSelection;
- (void)changeSelectedRange:(PhiTextRange *)textRange scroll:(BOOL)scrollToSelection endUndoGrouping:(BOOL)ensureUndoGroupingEnded;
- (void)changeTextInRange:(PhiTextRange *)range replacementText:(NSString *)text;
- (void)changeSelectedText:(NSString *)text;

@property (nonatomic, retain) PhiTextStyle *textStyleForSelectedRange;
- (void)addTextStyleForSelectedRange:(PhiTextStyle *)style;

#pragma mark UITextInput Properties

@property (nonatomic, readonly) UITextRange *markedTextRange;                       // Nil if no marked text.
@property (nonatomic, copy) NSDictionary *markedTextStyle;                          // Describes how the marked text should be drawn.
//@property (nonatomic, assign) id <UITextInputDelegate> inputDelegate;
@property (nonatomic, readonly) id <UITextInputTokenizer> tokenizer;
@property(nonatomic, assign) id<PhiTextViewDelegate> delegate;

#pragma mark UITextInputTraits Properties

@property(nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property(nonatomic) UITextAutocorrectionType autocorrectionType;
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;
@property(nonatomic) UIReturnKeyType returnKeyType;
@property(nonatomic) BOOL enablesReturnKeyAutomatically;
@property(nonatomic,getter=isSecureTextEntry) BOOL secureTextEntry;

/*! @group Initialising Text Editor View */
#pragma mark Initialising Text Editor View

/*!
    @method     setDefaults
    @abstract   Creates receiver's text view, selection view and selected text range and set all other attributes to nil.
    @discussion All UITextInputTraits properties are set to their default values. The text view is created with the bounds
	of the receiver and made transparent. The selection view is created with the receiver's bounds and is initially hidden.
	
*/
- (void)setDefaults;
/*! Sets defaults and sets up gesture recognizers */
- (id)initWithFrame:(CGRect)frame;
/*! Sets defaults and sets up gesture recognizers */
- (id)initWithCoder:(NSCoder *)aDecoder;

/*! @group Text Storage Management */
#pragma mark Text Storage Management

/*!
	@method     clampRange:
	@abstract   Returns a valid range in the context of the receiver's textStore.
 */
- (NSRange)clampRange:(NSRange)range;
/*!
	@method     clampTextRange:
	@abstract   Returns a valid text range in the context of the receiver's textStore.
 */
- (PhiTextRange *)clampTextRange:(PhiTextRange *)range;
/*!
 @method     trimNewLinesFromRange:
 @abstract   Returns a valid range in the context of the receiver's textStore excluding new lines from both the start and end of the range.
 */
- (NSRange)trimNewLinesFromRange:(NSRange)range;
/*!
	@method     trimNewLinesFromRange:
	@abstract   Returns a valid text range in the context of the receiver's textStore excluding new lines from both the start and end of the range.
 */
- (PhiTextRange *)trimNewLinesFromTextRange:(PhiTextRange *)range;

/*!
    @method     hasDeletableTokenInDirection:
    @abstract   Returns YES if the range from hasDeletableTokenInDirection: is not empty.
    @see        hasDeletableTokenInDirection:
*/
- (BOOL)hasDeletableTokenInDirection:(UITextStorageDirection)direction;
/*!
    @method     rangeOfNextDeletableTokenInDirection:
    @abstract   Returns a range that can be deleted in the specified direction.
    @discussion If the currect selected range is not empty then this is always returned
	regardless of direction. Otherwise, the result is the range of the next character in
	the specified direction relative to the current selection .
*/
- (UITextRange *)rangeOfNextDeletableTokenInDirection:(UITextStorageDirection)direction;
/*!
	@method     deleteRange:
	@abstract   Deletes text in the specified range from the receiver's text store.
	@discussion No adjustment is made to the current selected text range.
 */
- (void)deleteRange:(PhiTextRange *)range;

/*!
    @method     hasText
    @abstract   Returns YES if text storage is of positive length, NO otherwise.
*/
- (BOOL)hasText;
/*!
    @method     insertText:
    @abstract   Replaces the current selected text with the specified text.
    @discussion If the text storage is empty a new attributed string is appended to the text store
	with the text view's current font and font color as the font and foreground color, resp. The
	selected range is updated to be at the end of the inserted text.
	
*/
- (void)insertText:(NSString *)text;

/*! Important: for the Text Input System only, do not call this method.
 (Use deleteAtSelectedTextRange:)
 */
- (void)deleteBackward;
/*!
 @method     deleteBackward
 @abstract   Deletes the current selected text or the text immediately before the selected text.
 @discussion If the selected text is empty the text immediately before the selected text is deleted.
 The resulting selected will be empty.
 @see        rangeOfNextDeletableTokenInDirection:
 */
- (void)deleteAtSelectedTextRange;

/*! @group Delegate Methods */
#pragma mark Delegate Methods

/*!
    @method     textWillChange
    @abstract   Called after the text storage has changed and before the display is updated.
    @discussion Does nothing if called out of turn (every call to textWillChange should be
	balanced with a subsequent call to textDidChange). Otherwise, textWillChange: is sent to
	the receiver's input delegate, the receiver's text view is invalidated and marked for 
	redisplay and the menu controller is hidden.
*/
- (void)textWillChange;
/*!
	@method     textDidChange
	@abstract   Called after the receiver receives textWillChange.
	@discussion Does nothing if called out of turn (every call to textWillChange should be
	balanced with a subsequent call to textDidChange). Otherwise, textDidChange: is sent to
	the receiver's input delegate, the receiver's selection view is sent an update message.
 */
- (void)textDidChange;
/*!
	@method     selectionWillChange
	@abstract   Called after the selected range has changed and before the display is updated.
 @discussion Does nothing if called out of turn (every call to selectionWillChange should be
 balanced with a subsequent call to selectionDidChange). Otherwise, selectionWillChange: is sent to
 the receiver's input delegate, the receiver's text view is marked for 
 redisplay and the menu controller is hidden.
 */
- (void)selectionWillChange;
/*!
	@method     selectionDidChange
 @abstract   Called after the receiver receives selectionWillChange.
 @discussion Does nothing if called out of turn (every call to selectionWillChange should be
 balanced with a subsequent call to selectionDidChange). Otherwise, selectionDidChange: is sent to
 the receiver's input delegate.
 */
- (void)selectionDidChange;

- (void)storageWillChange;
- (void)storageDidChange;

/*! @group Responder Interaction */
#pragma mark Responder Interaction

/*! Returns YES. */
- (BOOL)canBecomeFirstResponder;
/*! Shows the selection view and menu controller if necessary. */
- (BOOL)becomeFirstResponder;
/*! Hides the selection view and menu controller. */
- (BOOL)resignFirstResponder;

/*! @group Text View Interaction */
#pragma mark Text View

/*!
    @property    textDocument
    @abstract    Provides geometic values and performs hit testing.
*/
@property (nonatomic, retain) PhiTextDocument *textDocument;

/*!
 @method     caretRectForPosition:
 @abstract   Finds the rectangle of the caret at the specified position in the text.
 @discussion Delegated to this receiver's text view.
 @param      position in text.
 */
- (CGRect)caretRectForPosition:(UITextPosition *)position;
- (CGRect)visibleCaretRectForPosition:(UITextPosition *)position;
- (CGRect)visibleCaretRectForPosition:(UITextPosition *)position alignPixels:(BOOL)pixelsAligned toView:(UIView *)view;
/*!
 @method     lastRectForRange:
 @abstract   Finds the bounding rectangle of the text on the last line in the specified range.
 @discussion Delegated to this receiver's text view.
 @param      range of text.
 */
- (CGRect)lastRectForRange:(UITextRange *)range;
/*!
 @method     firstRectForRange:
 @abstract   Finds the bounding rectangle of the text on the first line in the specified range.
 @discussion Delegated to this receiver's text view.
 @param      range of text.
 */
- (CGRect)firstRectForRange:(UITextRange *)range;

/*!
    @method     closestPositionToPoint:
	@abstract   Finds the closest position to the specified point in the receiver's coooridinate system.
    @discussion Delegated to this receiver's text view.
	@param      point in the receiver's coooridinate system.
*/
- (UITextPosition *)closestPositionToPoint:(CGPoint)point;
/*!
 @method     closestPositionToPoint:withinRange:
 @abstract   Finds the closest position to the specified point in the receiver's coooridinate system within the specified range.
 @discussion Delegated to this receiver's text view.
 @param      point in the receiver's coooridinate system.
 @param      range in which to search.
 */
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range;
/*!
 @method     characterRangeAtPoint:
 @abstract   Finds the character under the specified point in the receiver's coooridinate system.
 @discussion Delegated to this receiver's text view.
 @param      point in the receiver's coooridinate system.
 */
- (UITextRange *)characterRangeAtPoint:(CGPoint)point;
/*!
    @method     closestSnapPositionToPoint:
    @abstract   Finds the closest (course grained) position to the specified point in the receiver's coooridinate system.
    @discussion Searches for the closest snap position in both directions.
	A snap position aligns with a word or paragraph boundry.
	@see        closestSnapPositionToPoint:inDirection:
	@param      point in the receiver's coooridinate system.
*/
- (UITextPosition *)closestSnapPositionToPoint:(CGPoint)point;
/*!
    @method     closestSnapPositionToPoint:inDirection:
    @abstract   Finds the closest (course grained) position to the specified point in the receiver's coooridinate system in the specified direction.
    @discussion A snap position aligns with a word or paragraph boundry.
*/
- (UITextPosition *)closestSnapPositionToPoint:(CGPoint)point inDirection:(PhiTextStorageDirection)direction;

/*! @group Selection Management */
#pragma mark Selection Management

- (void)scrollRangeToVisible:(PhiTextRange *)range;

- (void)scrollSelectionToVisible;

/*!
    @property   selectionView
    @abstract   Container for caret(s) and selection controls.
*/
@property (nonatomic, retain) PhiTextSelectionView *selectionView;
@property (nonatomic, retain) PhiTextSelectionView *markedTextView;
/*!
	@property   selectedTextRange
	@abstract   Specifies the text that is selected and the insertion point of the editor.
	@discussion An empty selected text range represents a caret.
 */
@property (readonly, copy) UITextRange *selectedTextRange;

@property (nonatomic) UITextStorageDirection selectionAffinity;
- (UITextStorageDirection)selectionAffinityForPosition:(PhiTextPosition *)position;

/*! Important: for the Text Input System only, do not call this method. (Use changeSelectedRange:)
 */
- (void)setSelectedTextRange:(UITextRange *)textRange;

/*!
    @method     selectWord
    @abstract   Convenience method for selectGranularity:UITextGranularityWord.
    @see        selectGranularity:
*/
- (void)selectWord;
/*!
    @method     selectGranularity:
    @abstract   Modify currect selected range to closest boundries of specified granularity.
    @discussion Ensures that the resulting selected range bounds align with boundries of the specified granularity.
	@param      granularity of selected range.
*/
- (void)selectGranularity:(UITextGranularity)granularity;
/*!
    @method     moveCaretToClosestPositionAtPoint:
    @abstract   Modify current selected range to closest position to the specified point in the receiver's coooridinate system.
    @discussion Resulting selected range will be empty.
	@see        closestPositionToPoint:
	@param      point in the receiver's coooridinate system. 
    @result     YES if the selection range changed, otherwise NO.
*/
- (BOOL)moveCaretToClosestPositionAtPoint:(CGPoint)point;
/*!
    @method     moveCaretToClosestSnapPositionAtPoint:
    @abstract   Modify current selected range to closest (course grained) position to the specified point in the receiver's coooridinate system.
    @discussion Resulting selected range will be empty.
	@see        closestSnapPositionToPoint:
	@param      point in the receiver's coooridinate system. 
	@result     YES if the selection range changed, otherwise NO.
*/
- (BOOL)moveCaretToClosestSnapPositionAtPoint:(CGPoint)point;

- (void)setSelectionNeedsDisplay;

/*! @group Magnifier Management */
#pragma mark Magnifier Methods

/*!
    @property   magnifier 
    @abstract   The magnifier used during long press gesture and selection handle panning.
    @discussion The same magnifier is shared for both the long press gesture and modifing the selection range.
*/
@property (nonatomic, retain) PhiTextMagnifier *magnifier;

/*!
 @method     showCaretMagnifierAtPoint:
 @abstract   Animates the appearance of the receiver's caret magnifier to the specified point in the receiver's coordinate system.
 @discussion The receiver becomes the subject view for it's caret magnifier and it is added to the topmost window.
 A PhiTextMagnifier will be created if the receiver has no caret magnifier.
 @param      point The point, in the receiver's coorindate system, to which the caret magnifier will grow.
 */
- (void)showCaretMagnifierAtPoint:(CGPoint)point;
/*!
 @method     moveCaretMagnifierToPoint:
 @abstract   Moves the receiver's caret magnifier to the specified point in the receiver's coordinate system.
 @discussion The specified point will be the 'focus point' of the receiver's caret magnifier and the caret magnifier
 will be positioned appropriately.
 @param      point The point, in the receiver's coorindate system, to which the caret magnifier will be moved.
 */
- (void)moveCaretMagnifierToPoint:(CGPoint)point;
/*!
 @method     hideCaretMagnifierToPoint:
 @abstract   Animates the disappearance of the receiver's caret magnifier to the specified point in the receiver's coordinate system.
 @discussion Also resets the subject view of the receiver's caret magnifier.
 @param      point The point, in the receiver's coorindate system, to which the caret magnifier will shrink.
 */
- (void)hideCaretMagnifierToPoint:(CGPoint)point;

/*!
 @method     showSelectionMagnifierAtPoint:
 @abstract   Animates the appearance of the receiver's selection magnifier to the specified point in the receiver's coordinate system.
 @discussion The receiver becomes the subject view for it's selection magnifier and it is added to the topmost window.
 A PhiTextMagnifier will be created if the receiver has no selection magnifier.
 @param      point The point, in the receiver's coorindate system, to which the selection magnifier will grow.
 */
- (void)showSelectionMagnifierAtPoint:(CGPoint)point;
/*!
 @method     moveSelectionMagnifierToPoint:
 @abstract   Moves the receiver's selection magnifier to the specified point in the receiver's coordinate system.
 @discussion The specified point will be the 'focus point' of the receiver's selection magnifier and the selection magnifier
 will be positioned appropriately.
 @param      point The point, in the receiver's coorindate system, to which the selection magnifier will be moved.
 */
- (void)moveSelectionMagnifierToPoint:(CGPoint)point;
/*!
 @method     hideSelectionMagnifierToPoint:
 @abstract   Animates the disappearance of the receiver's selection magnifier to the specified point in the receiver's coordinate system.
 @discussion Also resets the subject view of the receiver's selection magnifier.
 @param      point The point, in the receiver's coorindate system, to which the selection magnifier will shrink.
 */
- (void)hideSelectionMagnifierToPoint:(CGPoint)point;

/*! @group Edit Actions and Methods */
#pragma mark Edit Actions

- (void)addCustomMenuItem:(UIMenuItem *)menuItem;
- (void)addCustomMenuItem:(UIMenuItem *)menuItem atPage:(NSUInteger)pageNumber;

/*!
    @method     showMenu
    @abstract   Repositions and shows the menu controller.
    @discussion The menu controller is positioned near the first
*/
- (void)showMenu;
/*!
    @method     reshowMenu
    @abstract   Shows the menu controller if it is flagged to be visible.
    @discussion The showMenu message is sent to the receiver if it has been flagged to keep the
    menu controller visible in the event that the system hides it. This flagged is then cleared.
*/
- (void)reshowMenu;
/*!
    @method     hideMenu
    @abstract   Ensures that the menu controller is hidden.
    @discussion After receiving this message reshowMenu will not display the menu controller.
*/
- (void)hideMenu;
/*!
 @method     canPerformAction:withSender:
 @abstract   Requests the receiving responder to enable or disable the specified command in the user interface.
 @discussion Different menu options are enabled if the receiving view has a non empty selection.
 Paste is always enabled and delete is always disabled. Select and selectAll is only enabled if
 the no text is selected and cut and copy are only enabled if text is selected.
 */
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;
/*!
    @method     copy:
    @abstract   Places selected text on the general pasteboard
    @discussion Only plain text format of the selected text is copied to the general pasteboard.
*/
- (void)copy:(id)sender;
/*!
    @method     cut:
    @abstract   Places selected text on the general pasteboard and removes that text from the document.
    @discussion Only plain text format of the selected text is copied to the general pasteboard.
*/
- (void)cut:(id)sender;
/*!
    @method     delete:
    @abstract   Deletes the selected text from the document.
    @discussion Same as deleteBackward if document has non empty text selection.
*/
- (void)delete:(id)sender;
/*!
    @method     paste:
    @abstract   Inserts text from the general pasteboard into the document.
    @discussion No formatting attributes are copied, text only. Same as insertText:
    Also ensures that the menu controller is hidden if paste is sucessful.
*/
- (void)paste:(id)sender;
/*!
    @method     select:
    @abstract   Selects the word closest to the insertion point.
    @discussion Same as selectWord:
*/
- (void)select:(id)sender;
/*!
    @method     selectAll:
    @abstract   Selects the entire document.
    @discussion Extends the text selection from the beginning of the document to the end.
    @see beginningOfDocument
    @see endOfDocument
*/
- (void)selectAll:(id)sender;

/*
 selectedTextRange has been redeclared to be readonly because only the Text Input System
 is expected to use it (system callbacks are turned off inside this property's setter).
 Instead, use changeSelectedRange: 
 */
@end











