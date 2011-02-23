//
//  PhiTextEditorView.h
//  FirstCoreText
//
//  Created by Corin Lawson on 4/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/NSAttributedString.h>
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
