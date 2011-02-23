//
//  PhiTextSelectionView.h
//  FirstCoreText
//
//  Created by Corin Lawson on 19/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhiTextEditorView;
@class PhiTextRange;
@class PhiTextCaretView;
@class PhiTextSelectionHandle;

@interface PhiTextSelectionView : UIView {
	PhiTextEditorView *owner;
	//UIColor *darkestSelectionColor, *lightestSelectionColor;
	PhiTextCaretView *startCaret, *endCaret;
	PhiTextSelectionHandle *startHandle, *endHandle;
	int blinking;
	BOOL handlesShown;
	BOOL needsUpdate;
	BOOL selectionPathValid;
	//CGPathRef selectionPath;
	PhiTextRange *lastSelectedTextRange;
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	NSMutableSet *dirtyTextFrames;
#endif
}

@property (nonatomic, assign) PhiTextEditorView *owner;
@property (nonatomic, retain) UIColor *selectionColor;
//@property (nonatomic, retain) UIColor *darkestSelectionColor, *lightestSelectionColor;
@property (nonatomic, readonly, getter=isHandlesShown) BOOL handlesShown;
@property (nonatomic, retain) PhiTextSelectionHandle *startHandle, *endHandle;
@property (nonatomic, retain) PhiTextCaretView *startCaret, *endCaret;
@property (nonatomic, readonly) CGPathRef selectionPath;

- (void)update;

- (BOOL)isBlinking;
- (void)stopBlinking;
- (void)startBlinking;
- (void)pauseBlinking;
- (void)resumeBlinking;

@end
