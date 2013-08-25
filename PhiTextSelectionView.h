//
//  PhiTextSelectionView.h
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

@class PhiTextEditorView;
@class PhiTextRange;
@class PhiTextCaretView;
@class PhiTextSelectionHandle;
@class PhiTextSelectionView;

@protocol PhiTextSelectionViewDelegate

- (PhiTextRange *)textSelectionViewSelectedTextRange:(PhiTextSelectionView *)view;

@optional

- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldShowSelectionHandle:(PhiTextSelectionHandle *)handle;
- (void)textSelectionView:(PhiTextSelectionView *)view didShowSelectionHandle:(PhiTextSelectionHandle *)handle;
- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldHideSelectionHandle:(PhiTextSelectionHandle *)handle;
- (void)textSelectionView:(PhiTextSelectionView *)view didHideSelectionHandle:(PhiTextSelectionHandle *)handle;

- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldShowSelectionCaret:(PhiTextCaretView *)caret;
- (void)textSelectionView:(PhiTextSelectionView *)view didShowSelectionCaret:(PhiTextCaretView *)caret;
- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldHideSelectionCaret:(PhiTextCaretView *)caret;
- (void)textSelectionView:(PhiTextSelectionView *)view didHideSelectionCaret:(PhiTextCaretView *)caret;

@end


@interface PhiTextSelectionView : UIView {
	PhiTextEditorView *owner;
	id<PhiTextSelectionViewDelegate, NSObject> delegate;
	//UIColor *darkestSelectionColor, *lightestSelectionColor;
	PhiTextCaretView *startCaret, *endCaret;
	PhiTextSelectionHandle *startHandle, *endHandle;
	int blinking;
	struct _PhiTextSelectionViewBitFields {
		unsigned int handlesShown :1;
		unsigned int needsUpdate :1;
		unsigned int selectionPathValid :1;
		
		unsigned int handlesEnabled :1;
		unsigned int caretsEnabled :1;
		
		unsigned int pixelAligned :1;
		
		unsigned int reserved :26;
	} flags;
	//CGPathRef selectionPath;
	PhiTextRange *lastSelectedTextRange;
#ifdef PHI_DIRTY_FRAMES_IN_SELECTION
	NSMutableSet *dirtyTextFrames;
#endif
}

@property (nonatomic, assign) PhiTextEditorView *owner;
@property (nonatomic, assign) id<PhiTextSelectionViewDelegate, NSObject> delegate;
@property (nonatomic, retain) UIColor *selectionColor;
@property (nonatomic, retain) UIColor *selectionStrokeColor;
@property (nonatomic, readonly, getter=isHandlesShown) BOOL handlesShown;
@property (nonatomic, retain) PhiTextSelectionHandle *startHandle, *endHandle;
@property (nonatomic, retain) PhiTextCaretView *startCaret, *endCaret;
@property (nonatomic, readonly) CGPathRef selectionPath;
@property (nonatomic, assign, getter=isHandlesEnabled) BOOL handlesEnabled;
@property (nonatomic, assign, getter=isCaretsEnabled) BOOL caretsEnabled;
@property (nonatomic, assign, getter=isPixelAligned) BOOL pixelAligned;

- (void)update;

- (BOOL)isBlinking;
- (void)stopBlinking;
- (void)startBlinking;
- (void)pauseBlinking;
- (void)resumeBlinking;

@end
