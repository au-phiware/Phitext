//
//  PhiTextEditorView.h
//  FirstCoreText
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#ifndef PHI_DIRTY_FRAMES_IN_VIEW
#define PHI_DIRTY_FRAMES_IN_VIEW 0
#endif

@class PhiTextDocument;
//@class PhiTextSelectionView;

@interface PhiTextView : UIView {
#if PHI_DIRTY_FRAMES_IN_VIEW
	NSMutableSet *dirtyTextFrames;
#endif
@private
	PhiTextDocument *document;
//	PhiTextSelectionView *selectionView;
	CALayer *bgLayer;
	CALayer *textLayer;
//	CALayer *selectionLayer;
}

@property (nonatomic, assign) PhiTextDocument *document;
//@property (nonatomic, assign) PhiTextSelectionView *selectionView;

/*! Called before adding the reciever to a container view. */
- (void)prepareForReuse;

@end
