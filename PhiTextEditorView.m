//
//  PhiTextEditorView.m
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

#import "PhiTextEditorView.h"
#import "PhiTextDocument.h"
#import "PhiTextStorage.h"
#import "PhiTextInputTokenizer.h"
#import "PhiTextRange.h"
#import "PhiTextPosition.h"
#import "PhiTextLine.h"
#import "PhiTextView.h"
#import "PhiTextFrame.h"
#import "PhiTextSelectionView.h"
#import "PhiTextMagnifier.h"
#import "PhiTextSelectionHandle.h"
#import "PhiTextSelectionHandleRecognizer.h"
#import "PhiTextUndoManager.h"
#import "PhiTextStyle.h"
#import "PhiTextFont.h"

#ifndef PHI_ACCESS_FRAME_BEFORE_DISPLAY
#define PHI_ACCESS_FRAME_BEFORE_DISPLAY 0
#endif

#if PHI_DIRTY_FRAMES_IN_VIEW
@interface PhiTextView (PhiTextEditorView)
@property (nonatomic, readonly) NSMutableSet *dirtyTextFrames;
@end

@implementation PhiTextView (PhiTextEditorView)
- (NSMutableSet *)dirtyTextFrames {
	return dirtyTextFrames;
}
@end
#endif

#pragma mark Global Fallback Defaults

#define PHI_TILE_WIDTH_HINT      [[UIScreen mainScreen] applicationFrame].size.width
#define PHI_TILE_HEIGHT_HINT     64.0
#define PHI_AUTO_SCROLL_GAP      50.0f
#define PHI_AUTO_SCROLL_DURATION 0.3f
#define PHI_AUTO_SCROLL_SPEED    1.62f

#pragma mark -

@interface PhiTextEditorView ()

@property (nonatomic, retain) PhiTextStyle *currentTextStyle;

- (void)setupGestures;
- (void)tearDownGestures;
- (void)_addMoreItems;

@end

@implementation PhiTextEditorView

@synthesize delegate;
@synthesize textDocument, selectionView, markedTextView;
@synthesize magnifier;
@synthesize inputView, inputAccessoryView;
@synthesize selectedTextRange, markedTextRange, markedTextStyle;
@synthesize autocapitalizationType, autocorrectionType, keyboardType, keyboardAppearance, returnKeyType;
@synthesize currentTextStyle;

#pragma mark Helper Methods

- (NSRange)clampRange:(NSRange)range {
#ifdef TRACE
	NSLog(@"%@Entering [clampRange:(%d, %d)]...", traceIndent, range.location, range.length);
#endif
	range.location = PHI_CLAMP(range.location, 0, [self.textDocument.store length]);
	range.length   = PHI_CLAMP(range.length,   0, [self.textDocument.store length] - range.location);
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%d, %d)...", traceIndent, __FUNCTION__, range.location, range.length);
#endif
	return range;
}
- (NSRange)trimNewLinesFromRange:(NSRange)range {
#ifdef TRACE
	NSLog(@"%@Entering [trimNewLinesFromRange:(%d, %d)]...", traceIndent, range.location, range.length);
#endif
	range = [self clampRange:range];
	//TODO: DOS Mode
	if (range.length && [self.textDocument.store isLineBreakAtIndex:range.location - 1]) {
#ifdef DEVELOPER
		NSLog(@"Trim start");
#endif
		range.location++;
		range.length--;
	}
	if (range.length && [self.textDocument.store isLineBreakAtIndex:range.location + range.length - 1]) {
#ifdef DEVELOPER
		NSLog(@"Trim end");
#endif
		range.length--;
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%d, %d)...", traceIndent, __FUNCTION__, range.location, range.length);
#endif
	return range;
}
- (PhiTextRange *)clampTextRange:(PhiTextRange *)range {
#ifdef TRACE
	NSLog(@"%@Entering [clampTextRange:%@]...", traceIndent, range);
#endif
	PhiTextRange *clamped = nil;
	if (range)
		clamped = [PhiTextRange textRangeWithRange:[self clampRange:[range range]]];
#ifdef TRACE
	NSLog(@"%@Exiting [%s]:%@.", traceIndent, __FUNCTION__, clamped);
#endif	
	return clamped;
}
- (PhiTextRange *)trimNewLinesFromTextRange:(PhiTextRange *)range {
#ifdef TRACE
	NSLog(@"%@Entering [trimNewLinesFromTextRange:%@]...", traceIndent, range);
#endif
	PhiTextRange *trimmed;
	trimmed = [PhiTextRange textRangeWithRange:[self trimNewLinesFromRange:[range range]]];
#ifdef TRACE
	NSLog(@"%@Exiting [%s]:%@.", traceIndent, __FUNCTION__, trimmed);
#endif	
	return trimmed;
}


- (void)setDefaults {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	[super setDelegate:self];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	Class textDocumentClass = NSClassFromString([defaults stringForKey:@"textDocumentClassName"]);
	if (!textDocumentClass)
		textDocumentClass = [PhiTextDocument class];
	self.textDocument = [[[textDocumentClass alloc] init] autorelease];
	
	tileWidthHint = MAX(0, [defaults floatForKey:@"tileWidthHint"]);
    if (tileWidthHint <= 0.0) tileWidthHint = PHI_TILE_WIDTH_HINT;
	tileHeightHint = MAX(0, [defaults floatForKey:@"tileHeightHint"]);
    if (tileHeightHint <= 0.0) tileHeightHint = PHI_TILE_HEIGHT_HINT;

	autoScrollGap = [defaults objectForKey:@"autoScrollGap"] ? [defaults floatForKey:@"autoScrollGap"] : PHI_AUTO_SCROLL_GAP;
	autoScrollDuration = [defaults objectForKey:@"autoScrollDuration"] ? [defaults floatForKey:@"autoScrollDuration"] : PHI_AUTO_SCROLL_DURATION;
	autoScrollSpeed = [defaults objectForKey:@"autoScrollSpeed"] ? [defaults floatForKey:@"autoScrollSpeed"] : PHI_AUTO_SCROLL_SPEED;
	scrollBuffer = [defaults floatForKey:@"scrollBuffer"];
	if (scrollBuffer <= 0.0)
		scrollBuffer = 2.5 * MIN(tileWidthHint, tileHeightHint);

	if (textViews)
		[textViews release];
	textViews = [[NSMutableArray alloc] init];
	if (reusableTextViews)
		[reusableTextViews release];
	reusableTextViews = [[NSMutableSet alloc] init];
	Class selectionViewClass = NSClassFromString([defaults stringForKey:@"selectionViewClassName"]);
	if (!selectionViewClass)
		selectionViewClass = [PhiTextSelectionView class];
	self.selectionView = [[[selectionViewClass alloc] initWithFrame:CGRectZero] autorelease];
	[selectionView setHidden:YES];
	if (autoScrollTimer) {
		[autoScrollTimer invalidate];
		[autoScrollTimer release];
	}
	autoScrollTimer = nil;
	
	PhiTextSelectionView *mtv = [[PhiTextSelectionView alloc] initWithFrame:CGRectZero];
	[mtv setCaretsEnabled:NO];
	[mtv setHandlesEnabled:NO];
	UIColor *mtc = [mtv selectionColor];
	[mtv setSelectionStrokeColor:mtc];
	[mtv setSelectionColor:[mtc colorWithAlphaComponent:0.1]];
	self.markedTextView = mtv;
	[mtv release];

	flags.willTextChange = flags.willSelectionChange = NO;
	flags.shouldNotifyInputDelegate = YES;
	flags.shouldInvalidateTextDocument = YES;
	
	autocapitalizationType = [defaults objectForKey:@"autocapitalizationType"] ? [defaults integerForKey:@"autocapitalizationType"] : UITextAutocapitalizationTypeSentences;
	autocorrectionType = [defaults integerForKey:@"autocorrectionType"];
	keyboardType = [defaults integerForKey:@"keyboardType"];
	keyboardAppearance = [defaults integerForKey:@"keyboardAppearance"];
	returnKeyType = [defaults integerForKey:@"returnKeyType"];
	flags.enablesReturnKeyAutomatically = [defaults boolForKey:@"enablesReturnKeyAutomatically"];
	flags.secureTextEntry = [defaults boolForKey:@"secureTextEntry"];
	
	if (menuPages)
		[menuPages release];
	menuPages = [[NSMutableArray alloc] initWithCapacity:2];
	[menuPages addObject:[NSMutableArray arrayWithCapacity:2]];
	flags.enableMenuPositionAdjustment = ![defaults boolForKey:@"disableMenuPositionAdjustment"];
	flags.enableMenuPaging = [defaults boolForKey:@"enableMenuPaging"];
	flags.menuArrowDirectionOverride = ![defaults boolForKey:@"disableMenuPositionAdjustment"];
	menuPageNumber = 0;
	menuTargetRect = CGRectNull;
	
	if (selectedTextRange)
		[selectedTextRange release];
	selectedTextRange = nil;
	if (markedTextRange)
		[markedTextRange release];
	markedTextRange = nil;
	self.markedTextStyle = nil;
	self.inputDelegate = nil;
	if (tokenizer) [tokenizer release];
	tokenizer = nil;
	
	self.contentSize = self.bounds.size;
	
	flags.keepMenuVisible = NO;
	flags.menuShown = NO;
	flags.wordSelected = NO;
	flags.wordCopied = NO;
	flags.blinkingPaused = NO;
	flags.magnifierShown = NO;
	
	flags.editable = ![defaults boolForKey:@"noneditable"];
	inputView = nil;
	inputAccessoryView = nil;
	keyboardFrame = CGRectZero;
	
	NSUInteger levelsOfUndo = [self.textDocument.undoManager levelsOfUndo];
	if (undoStack)
		[undoStack release];
	if (redoStack)
		[redoStack release];
	if (levelsOfUndo) {
		undoStack = [[NSMutableArray alloc] initWithCapacity:2 * levelsOfUndo];
		redoStack = [[NSMutableArray alloc] initWithCapacity:2 * levelsOfUndo];
	} else {
		undoStack = [[NSMutableArray alloc] init];
		redoStack = [[NSMutableArray alloc] init];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDefaults) name:NSUserDefaultsDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reshowMenu) name:UIMenuControllerDidHideMenuNotification object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustMenuPosition) name:UIMenuControllerWillShowMenuNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)reloadDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	if (([defaults objectForKey:@"tileWidthHint"] && tileWidthHint != [defaults floatForKey:@"tileWidthHint"])
		|| ([defaults objectForKey:@"tileHeightHint"] && tileHeightHint != [defaults floatForKey:@"tileHeightHint"])) {
        tileWidthHint = MAX(0, [defaults floatForKey:@"tileWidthHint"]);
        if (tileWidthHint <= 0.0) tileWidthHint = PHI_TILE_WIDTH_HINT;
        tileHeightHint = MAX(0, [defaults floatForKey:@"tileHeightHint"]);
        if (tileHeightHint <= 0.0) tileHeightHint = PHI_TILE_HEIGHT_HINT;

		if (textViews) {
			for (UIView *view in textViews)
				[view removeFromSuperview];
			[textViews release];
		}
		textViews = [[NSMutableArray alloc] init];
		if (reusableTextViews)
			[reusableTextViews release];
		reusableTextViews = [[NSMutableSet alloc] init];

		[self setNeedsLayout];
	}
	
	autoScrollGap = [defaults objectForKey:@"autoScrollGap"] ? [defaults floatForKey:@"autoScrollGap"] : PHI_AUTO_SCROLL_GAP;
	autoScrollDuration = [defaults objectForKey:@"autoScrollDuration"] ? [defaults floatForKey:@"autoScrollDuration"] : PHI_AUTO_SCROLL_DURATION;
	autoScrollSpeed = [defaults objectForKey:@"autoScrollSpeed"] ? [defaults floatForKey:@"autoScrollSpeed"] : PHI_AUTO_SCROLL_SPEED;
	scrollBuffer = [defaults floatForKey:@"scrollBuffer"];
	if (scrollBuffer <= 0.0)
		scrollBuffer = 2.5 * MIN(tileWidthHint, tileHeightHint);
	
	if (textDocument) {
		Class textDocumentClass = NSClassFromString([defaults stringForKey:@"textDocumentClassName"]);
		if (textDocumentClass && [self.textDocument class] != textDocumentClass) {
			id doc = [[[textDocumentClass alloc] init] autorelease];
			[doc setStore:self.textDocument.store];
			self.textDocument = doc;
		}
	}
	
	if (selectionModifier) {
		Class selectionModifierClass = NSClassFromString([defaults stringForKey:@"selectionModifierClassName"]);
		if (selectionModifierClass && [selectionModifier class] != selectionModifierClass) {
			[self setupGestures];
		}
	}

	if (magnifier) {
		Class magnifierClass = NSClassFromString([defaults stringForKey:@"magnifierClassName"]);
		if (magnifierClass && [magnifier class] != magnifierClass) {
			[magnifier release];
			magnifier = nil;
		}
	}

	if (tokenizer) {
		Class tokenizerClass = NSClassFromString([defaults stringForKey:@"tokenizerClassName"]);
		if (tokenizerClass && [tokenizer class] != tokenizerClass) {
			[tokenizer release];
			tokenizer = nil;
		}
	}

	if (selectionView) {
		Class selectionViewClass = NSClassFromString([defaults stringForKey:@"selectionViewClassName"]);
		if (selectionViewClass && [self.selectionView class] != selectionViewClass) {
			self.selectionView = [[[selectionViewClass alloc] initWithFrame:CGRectZero] autorelease];
		}
	}
}

- (void)keyboardWillShow:(NSNotification *)notification {
	[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
	keyboardFrame = [self convertRect:keyboardFrame toView:nil];
}
- (void)keyboardWillHide:(NSNotification *)notification {
	keyboardFrame = CGRectZero;
}

#pragma mark Object Methods

+ (NSString *)versionString {
	return @"1.1";
}

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setDefaults];
		[self setupGestures];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self setDefaults];
		[self setupGestures];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (eod) [eod release];
	eod = nil;
	if (bod) [bod release];
	bod = nil;
	if (textViews)
		[textViews release];
	textViews = nil;
	if (reusableTextViews)
		[reusableTextViews release];
	reusableTextViews = nil;
	if (autoScrollTimer) {
		[autoScrollTimer invalidate];
		[autoScrollTimer release];
	}
	autoScrollTimer = nil;
	
	[self setTextDocument:nil];
	[self setSelectionView:nil];
	[self setMarkedTextView:nil];
	
	if (tokenizer) [tokenizer release];
	tokenizer = nil;
	if (selectedTextRange)
		[selectedTextRange release];
	selectedTextRange = nil;
	if (currentTextStyle)
		[currentTextStyle release];
	currentTextStyle = nil;
	
	if (markedTextRange)
		[markedTextRange release];
	markedTextRange = nil;
	
	self.magnifier = nil;
	
	[self tearDownGestures];	
	
	if (moreMenuItem)
		[moreMenuItem release];
	moreMenuItem = nil;
	if (menuPages)
		[menuPages release];
	menuPages = nil;

    [super dealloc];
}

- (void)setTextDocument:(PhiTextDocument *)document {
#ifdef TRACE
	NSLog(@"%@Entering -[PhiTextEditorView setTextDocument:%@]...", traceIndent, document);
#endif
	if (textDocument != document) {
		if (textDocument) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:textDocument.undoManager];
			[textDocument setOwner:nil];
			[textDocument release];
		}
		textDocument = document;
		if (textDocument) {
			[textDocument retain];
			[textDocument setOwner:self];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didOpenUndoGroup:) name:NSUndoManagerDidOpenUndoGroupNotification object:textDocument.undoManager];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndo) name:NSUndoManagerDidUndoChangeNotification object:textDocument.undoManager];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRedo) name:NSUndoManagerDidRedoChangeNotification object:textDocument.undoManager];
			[self performSelectorInBackground:@selector(calculateContentSize) withObject:nil];
		}
	}
}

- (void)didOpenUndoGroup:(NSNotification *)notification {
	NSUndoManager *undoManager = (NSUndoManager *)[notification object];
	if ([undoManager groupingLevel] == 1) {
		if (![undoManager isUndoing]) {
			[redoStack removeAllObjects];
			if ([undoStack count] && [undoStack count] == 2 * [undoManager levelsOfUndo]) {
				[undoStack removeObjectAtIndex:0];
				[undoStack removeObjectAtIndex:0];
			}
			if ([self selectedTextRange]) {
				[undoStack addObject:[self selectedTextRange]];
			} else {
				[undoStack addObject:[NSNull null]];
			}
			if (self.currentTextStyle) {
				[undoStack addObject:self.currentTextStyle];
			} else {
				[undoStack addObject:[NSNull null]];
			}
		} else {
			if ([self selectedTextRange]) {
				[redoStack addObject:[self selectedTextRange]];
			} else {
				[redoStack addObject:[NSNull null]];
			}
			if (self.currentTextStyle) {
				[redoStack addObject:self.currentTextStyle];
			} else {
				[redoStack addObject:[NSNull null]];
			}
		}
	}
}
- (void)didUndo {
	if ([undoStack count]) {
		PhiTextRange *lastSelectedTextRange = nil;
		PhiTextStyle *lastCurrentTextStyle = nil;
		if ([undoStack lastObject] != [NSNull null]) {
			lastCurrentTextStyle = [undoStack lastObject];
			[lastCurrentTextStyle retain];
		}
		[undoStack removeLastObject];
		if ([undoStack lastObject] != [NSNull null]) {
			lastSelectedTextRange = [undoStack lastObject];
		}
		if ([self selectedTextRange]) {
			[redoStack addObject:[self selectedTextRange]];
		} else {
			[redoStack addObject:[NSNull null]];
		}
		if (self.currentTextStyle) {
			[redoStack addObject:self.currentTextStyle];
		} else {
			[redoStack addObject:[NSNull null]];
		}
		[self changeSelectedRange:lastSelectedTextRange scroll:YES endUndoGrouping:NO];
		[undoStack removeLastObject];
		if (lastSelectedTextRange && [lastSelectedTextRange.end isEqual:[self endOfDocument]]) {
			self.textDocument.defaultStyle = lastCurrentTextStyle;
			[[self selectionView] setNeedsLayout];
		}
		if (lastCurrentTextStyle != self.currentTextStyle) {
			self.currentTextStyle = lastCurrentTextStyle;
			[[self selectionView] setNeedsLayout];
		}

		[lastCurrentTextStyle release];
	}
}
- (void)didRedo {
	if ([redoStack count]) {
		PhiTextRange *lastSelectedTextRange = nil;
		PhiTextStyle *lastCurrentTextStyle = nil;
		if ([redoStack lastObject] != [NSNull null]) {
			lastCurrentTextStyle = [redoStack lastObject];
			[lastCurrentTextStyle retain];
		}
		[redoStack removeLastObject];
		if ([redoStack lastObject] != [NSNull null]) {
			lastSelectedTextRange = [redoStack lastObject];
		}
		if ([self selectedTextRange]) {
			[undoStack addObject:[self selectedTextRange]];
		} else {
			[undoStack addObject:[NSNull null]];
		}
		if (self.currentTextStyle) {
			[undoStack addObject:self.currentTextStyle];
		} else {
			[undoStack addObject:[NSNull null]];
		}
		[self changeSelectedRange:lastSelectedTextRange scroll:YES endUndoGrouping:NO];
		[redoStack removeLastObject];
		if (lastSelectedTextRange && [lastSelectedTextRange.end isEqual:[self endOfDocument]]) {
			self.textDocument.defaultStyle = lastCurrentTextStyle;
			[[self selectionView] setNeedsLayout];
		}
		if (lastCurrentTextStyle != self.currentTextStyle) {
			self.currentTextStyle = lastCurrentTextStyle;
			[[self selectionView] setNeedsLayout];
		}
		[lastCurrentTextStyle release];
	}
}
- (void)storageWillChange {
	[textDocument.undoManager removeAllActions];
	[undoStack removeAllObjects];
	[redoStack removeAllObjects];
}
- (void)storageDidChange {
	[self setSelectedTextRange:nil];
}

- (void)setSelectionView:(PhiTextSelectionView *)view {
	if (selectionView != view) {
		if (selectionView) {
			[selectionView removeFromSuperview];
			[selectionView setOwner:nil];
			if (flags.blinkingPaused) {
				[[self selectionView] resumeBlinking];
				flags.blinkingPaused = NO;
			}
			[selectionView release];
		}
		selectionView = view;
		if (selectionView) {
			[self addSubview:selectionView];
			[selectionView setOwner:self];
			[selectionView retain];
			flags.blinkingPaused = ![selectionView isBlinking];
		}
	}
	if (selectionView) {
		[self bringSubviewToFront:selectionView];
	}
}
- (void)setMarkedTextView:(PhiTextSelectionView *)view {
	if (markedTextView != view) {
		if (markedTextView) {
			[markedTextView removeFromSuperview];
			[markedTextView setOwner:nil];
			[markedTextView release];
		}
		markedTextView = view;
		if (markedTextView) {
			if (self.selectionView) {
				[self insertSubview:markedTextView belowSubview:self.selectionView];
			} else {
				[self addSubview:markedTextView];
			}
			[markedTextView setOwner:self];
			if (self.markedTextRange) {
				[markedTextView setHidden:YES];
			} else {
				[markedTextView setHidden:NO];
			}
			[markedTextView retain];
		}
	}
}

#pragma mark Convenience Methods

- (void)textWillChange {
#ifdef TRACE
	NSLog(@"%@Entering %s willTextChange:%s...", traceIndent, __FUNCTION__, flags.willTextChange?"YES":"NO");
#endif
	if (!flags.willTextChange) {
		flags.willTextChange = YES;
		if (inputDelegate && flags.shouldNotifyInputDelegate) {
#ifdef TRACE
			NSLog(@"%@Executing textWillChange...", traceIndent);
			traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
			[inputDelegate textWillChange:self];
#ifdef TRACE
			traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
			NSLog(@"%@Executed  textWillChange.", traceIndent);
#endif
		}
		if (flags.shouldInvalidateTextDocument) {
			[textDocument invalidateDocument];
		}
		[self hideMenu];
		[[self selectionView] pauseBlinking];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}
- (void)textDidChange {
#ifdef TRACE
	NSLog(@"%@Entering %s willTextChange:%s...", traceIndent, __FUNCTION__, flags.willTextChange?"YES":"NO");
#endif
	if (flags.willTextChange) {
		if (inputDelegate && flags.shouldNotifyInputDelegate) {
#ifdef TRACE
			NSLog(@"%@Executing textDidChange...", traceIndent);
			traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
			[inputDelegate textDidChange:self];
#ifdef TRACE
			traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
			NSLog(@"%@Executed  textDidChange.", traceIndent);
#endif
		}
		//[textViews makeObjectsPerformSelector:@selector(setNeedsDisplay)];
		[[self selectionView] resumeBlinking];
		flags.willTextChange = NO;
		if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
			[self.delegate textViewDidChange:self];
		}
	}
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
}
- (void)selectionWillChange {
#ifdef TRACE
	NSLog(@"%@Entering %s willSelectionChange:%s...", traceIndent, __FUNCTION__, flags.willSelectionChange?"YES":"NO");
#endif
	if (!flags.willSelectionChange) {
		flags.willSelectionChange = YES;
		if (inputDelegate && flags.shouldNotifyInputDelegate) {
#ifdef TRACE
			NSLog(@"%@Executing selectionWillChange...", traceIndent);
			traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
			[inputDelegate selectionWillChange:self];
#ifdef TRACE
			traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
			NSLog(@"%@Executed  selectionWillChange.", traceIndent);
#endif
		}
		[self hideMenu];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s...", traceIndent, __FUNCTION__);
#endif
}
- (void)selectionDidChange {
#ifdef TRACE
	NSLog(@"%@Entering %s willSelectionChange:%s...", traceIndent, __FUNCTION__, flags.willSelectionChange?"YES":"NO");
#endif
	if (flags.willSelectionChange) {
		if (inputDelegate && flags.shouldNotifyInputDelegate) {
#ifdef TRACE
			NSLog(@"%@Executing selectionDidChange...", traceIndent);
			traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
			[inputDelegate selectionDidChange:self];
#ifdef TRACE
			traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
			NSLog(@"%@Executed  selectionDidChange.", traceIndent);
#endif
		}
		self.currentTextStyle = nil;
		[[self selectionView] setNeedsLayout];
		flags.willSelectionChange = NO;
		flags.wordSelected = NO;

//		if (self.selectedTextRange)
			self.selectionAffinity = [self selectionAffinityForPosition:(PhiTextPosition *)self.selectedTextRange.end];
//		else
//			self.selectionAffinity = UITextStorageDirectionForward;
		
		if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
			[self.delegate textViewDidChangeSelection:self];
		}
	}
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
}

#pragma mark View Methods

- (BOOL)isEditable {
	return flags.editable;
}
- (void)setEditable:(BOOL)flag {
	flags.editable = flag;
}

- (BOOL)canBecomeFirstResponder {
#ifdef TRACE
	NSLog(@"%@Entering canBecomeFirstResponder...", traceIndent);
#endif
	if (flags.editable && [self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
		return [self.delegate textViewShouldBeginEditing:self];
	}
	return flags.editable;
}

- (BOOL)becomeFirstResponder {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if ([super becomeFirstResponder]) {
		[[self selectionView] setHidden:NO];
		[[self selectionView] setNeedsLayout];
		[self reshowMenu];
		if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
			[self.delegate textViewDidBeginEditing:self];
		}
		return YES;
	}
	return NO;
}

- (BOOL)canResignFirstResponder {
#ifdef TRACE
	NSLog(@"%@Entering canResignFirstResponder...", traceIndent);
#endif
	if ([self.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
		return [self.delegate textViewShouldEndEditing:self];
	}
	return YES;
}


- (BOOL)resignFirstResponder {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if ([super resignFirstResponder]) {
		[[self selectionView] setNeedsLayout];
		[self hideMenu];
		if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
			[self.delegate textViewDidEndEditing:self];
		}
		return YES;
	}
	return NO;
}

- (void)setNeedsDisplay {
#ifdef TRACE
	NSLog(@"%@Entering -[%@ %@]...", traceIndent, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
#if PHI_ACCESS_FRAME_BEFORE_DISPLAY
	CGRect documentBounds = CGRectOffset([self bounds], -[self.textDocument paddingLeft], -[self.textDocument paddingTop]);
	PhiAATreeRange *textFrameRange = [self.textDocument beginContentAccessInRect:documentBounds];
#endif
	[textViews makeObjectsPerformSelector:@selector(setNeedsDisplay)];
	[self setSelectionNeedsDisplay];
#if PHI_ACCESS_FRAME_BEFORE_DISPLAY
	for (PhiTextFrame *textFrame in textFrameRange)
		[textFrame autoEndContentAccess];
#endif
}
- (void)setSelectionNeedsDisplay {
	//[textViews makeObjectsPerformSelector:@selector(setSelectionNeedsDisplay)];
}

- (void)setNeedsDisplayInValueRect:(NSValue *)rect {
	[self setNeedsDisplayInRect:[rect CGRectValue]];
}

- (void)setNeedsDisplayInRect:(CGRect)rect {
#ifdef TRACE
	NSLog(@"%@Entering -[%@ %@:%@]...", traceIndent, NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromCGRect(rect));
#endif
#if PHI_ACCESS_FRAME_BEFORE_DISPLAY
	CGRect documentBounds = CGRectOffset([self bounds], -[self.textDocument paddingLeft], -[self.textDocument paddingTop]);
	PhiAATreeRange *textFrameRange = [self.textDocument beginContentAccessInRect:documentBounds];
#endif
	CGRect wideRect;
	for (UIView *tile in textViews) {
		wideRect = CGRectMake(tile.frame.origin.x,   rect.origin.y,
							  tile.frame.size.width, rect.size.height);
		if (CGRectIntersectsRect(wideRect, tile.frame))
			[tile setNeedsDisplayInRect:wideRect];
	}
#if PHI_ACCESS_FRAME_BEFORE_DISPLAY
	for (PhiTextFrame *textFrame in textFrameRange)
		[textFrame autoEndContentAccess];
#endif
}

- (void)addSubviewToBack:(UIView *)view {
	[self insertSubview:view atIndex:0];
	[view setNeedsDisplay];
}
- (void)insertTextViewTileWithFrame:(CGRect)tileFrame atIndex:(NSUInteger)index {
	PhiTextView *tile = [reusableTextViews anyObject];
	if (!tile) {
#ifdef DEVELOPER
		NSLog(@"Creating new text view with frame:(%.1f, %.1f) (%.1f, %.1f)", CGRectComp(tileFrame));
#endif
		tile = [[PhiTextView alloc] initWithFrame:CGRectZero];
	} else {
		[reusableTextViews removeObject:[[tile retain] autorelease]];
		[tile prepareForReuse];
	}
	tile.frame = tileFrame;
	tile.document = self.textDocument;
	if (CGRectIntersectsRect(tileFrame, self.bounds)) {
		[self addSubviewToBack:tile];
	} else {
		[self performSelectorOnMainThread:@selector(addSubviewToBack:) withObject:tile waitUntilDone:NO];
	}
	if (index < [textViews count]) {
		[textViews insertObject:tile atIndex:index];
	} else {
		[textViews addObject:tile];
	}
#if PHI_DIRTY_FRAMES_IN_VIEW
	//DONE: beginContentAccess to textFrames in the tile
	for (PhiTextFrame *textFrame in [self.textDocument beginContentAccessInRect:tileFrame]) {
		[tile.dirtyTextFrames addObject:textFrame];
	}
#endif
}
- (void)addTextViewTileWithFrame:(CGRect)tileFrame {
	[self insertTextViewTileWithFrame:tileFrame atIndex:NSUIntegerMax];
}
- (void)removeTextViewTile:(PhiTextView *)tile {
	[reusableTextViews addObject:tile];
	[tile removeFromSuperview];
#if PHI_DIRTY_FRAMES_IN_VIEW
	//DONE: endContentAccess to textFrames in tile
	for (PhiTextFrame *textFrame in tile.dirtyTextFrames)
		[textFrame endContentAccess];
	[tile.dirtyTextFrames removeAllObjects];
#endif
}
- (void)layoutSubviews {
#ifdef DEVELOPER
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	PhiTextView *tile = nil;
	BOOL aboveTop = YES;
	CGRect tileFrame = CGRectMake(0, 0, tileWidthHint, tileHeightHint);
	CGSize bufferSize = CGSizeMake(MAX(scrollBuffer, autoScrollGap * autoScrollSpeed), MAX(scrollBuffer, autoScrollGap * autoScrollSpeed));
	if (self.bounds.size.width >= self.contentSize.width) {
		bufferSize.width = 0;
		//if (self.textDocument.wrap && tileFrame.size.width > self.bounds.size.width / 2.0)
			// TODO factor in auto expansion
		//	tileFrame.size.width = self.bounds.size.width;
	}
	if (self.bounds.size.height >= self.contentSize.height)
		bufferSize.height = 0;
	CGRect bufferedBounds = CGRectNull;
	CGRect visibleBounds = [[self.layer presentationLayer] bounds];
	
#define SIZE_LIMIT 1500000.0
	CGFloat n = 0.0;
	if (bufferSize.width * bufferSize.height > 0.0) {
		if ((ceilf((self.bounds.size.width + bufferSize.width) / tileFrame.size.width) + ceilf(bufferSize.width / tileFrame.size.width))
			* (ceilf((self.bounds.size.height + bufferSize.height) / tileFrame.size.height) + ceilf(bufferSize.height / tileFrame.size.height))
			   > SIZE_LIMIT / (tileFrame.size.width * tileFrame.size.height))
		{
			CGFloat t = MAX(tileFrame.size.width, tileFrame.size.height);
			CGFloat sum = ceilf(self.bounds.size.width / t) + ceilf(self.bounds.size.height / t);
			CGFloat prd = ceilf(self.bounds.size.width / t) * ceilf(self.bounds.size.height / t);
			n = (sqrtf(sum * sum - 4 * prd + 4.0 * SIZE_LIMIT / (t * t)) - sum) / 4.0;
			bufferSize.width = bufferSize.height = MAX(autoScrollGap * autoScrollSpeed, t * floorf(n));
		}
	} else if (bufferSize.width > 0.0) {
		if (ceilf(self.bounds.size.width / tileFrame.size.width) + 2.0 * (bufferSize.width / tileFrame.size.width)
			> SIZE_LIMIT / (tileFrame.size.width * self.bounds.size.height))
		{
			CGFloat h = ceilf(self.bounds.size.height / tileFrame.size.height) * tileFrame.size.height;
			n = (SIZE_LIMIT / (tileFrame.size.width * h) - ceilf(self.bounds.size.width / tileFrame.size.width)) / 2.0;
			bufferSize.width = MAX(autoScrollGap * autoScrollSpeed, tileFrame.size.width * floorf(n));
		}
	} else if (bufferSize.height > 0.0) {
		if (ceilf(self.bounds.size.height / tileFrame.size.height) + 2.0 * (bufferSize.height / tileFrame.size.height)
			> SIZE_LIMIT / (tileFrame.size.height * self.bounds.size.width))
		{
			CGFloat w = ceilf(self.bounds.size.width / tileFrame.size.width) * tileFrame.size.width;
			n = (SIZE_LIMIT / (tileFrame.size.height * w) - ceilf(self.bounds.size.height / tileFrame.size.height)) / 2.0;
			bufferSize.height = MAX(autoScrollGap * autoScrollSpeed, tileFrame.size.height * floorf(n));
		}
	}

	bufferedBounds = CGRectInset(self.bounds, -bufferSize.width, -bufferSize.height);
	while (bufferedBounds.size.width * bufferedBounds.size.height > SIZE_LIMIT) {
		bufferSize.width /= 2.0;
		bufferSize.height /= 2.0;
		bufferedBounds = CGRectInset(self.bounds, -bufferSize.width, -bufferSize.height);
	}

	// Auto expand if wrap is on
	//if (self.textDocument.wrap)
	//	self.contentSize = self.bounds.size;
	
	//Recycle tiles that are not visible
	NSUInteger i, j, count = [textViews count];
	if (count) {
		for (i = 0; i < count; i++) {
			tile = [textViews objectAtIndex:i];
			if (!CGRectIntersectsRect(tile.frame, bufferedBounds)) {
				// Get tile out of the way
				[self performSelectorOnMainThread:@selector(removeTextViewTile:) withObject:tile waitUntilDone:NO];
				[textViews removeObject:tile];
				count--, i--;
			} else {
				if (aboveTop && CGRectGetMinY(tile.frame) > CGRectGetMinY(bufferedBounds)) {
					// Fill rows at top of editor with tiles
					tileFrame.origin.y = tile.frame.origin.y - tileHeightHint;
					do {
						tileFrame.origin.x = bufferedBounds.origin.x;
						j = 0;
						// Fill row
						do {
							[self insertTextViewTileWithFrame:tileFrame atIndex:j++];
							count++, i++;
							tileFrame.origin.x += tileWidthHint;
						} while (CGRectGetMinX(tileFrame) < CGRectGetMaxX(bufferedBounds));
						tileFrame.origin.y -= tileHeightHint;
					} while (CGRectGetMaxY(tileFrame) > CGRectGetMinY(bufferedBounds));
					tile = [textViews objectAtIndex:i];
				}
				tileFrame.origin.y = tile.frame.origin.y;
				if (CGRectGetMinX(tile.frame) > CGRectGetMinX(bufferedBounds)) {
					// Fill columns at front of current row
					tileFrame.origin.x = tile.frame.origin.x - tileWidthHint;
					j = i;
					do {
						[self insertTextViewTileWithFrame:tileFrame atIndex:j];
						count++, i++;
						tileFrame.origin.x -= tileWidthHint;
					} while (CGRectGetMaxX(tileFrame) > CGRectGetMinX(bufferedBounds));
				}
				// Skip all columns in current row
				while (i < count - 1 && tileFrame.origin.y == tile.frame.origin.y)
				{
					if (!CGRectIntersectsRect(tile.frame, visibleBounds))
						[tile setNeedsDisplay];
					tile = [textViews objectAtIndex:++i];
				}
				// Step back if we overshot
				if (tileFrame.origin.y != tile.frame.origin.y ) {
					tile = [textViews objectAtIndex:--i];
				}
				tileFrame.origin = tile.frame.origin;
				while (CGRectGetMaxX(tileFrame) < CGRectGetMaxX(bufferedBounds)) {
					tileFrame.origin.x += tileWidthHint;
					[self insertTextViewTileWithFrame:tileFrame atIndex:++i];
					count++;
				}
			}
			aboveTop = NO;
		}
		tileFrame.origin = tile.frame.origin;
		// Fill rows at bottom of editor
		while (CGRectGetMaxY(tileFrame) < CGRectGetMaxY(bufferedBounds)) {
			tileFrame.origin.x = bufferedBounds.origin.x;
			tileFrame.origin.y += tileHeightHint;
			// Fill row
			do {
				[self addTextViewTileWithFrame:tileFrame];
				tileFrame.origin.x += tileWidthHint;
			} while (CGRectGetMinX(tileFrame) < CGRectGetMaxX(bufferedBounds));
		}
	}
	if (!count) {
		tileFrame.origin.y = bufferedBounds.origin.y;
		do {
			tileFrame.origin.x = bufferedBounds.origin.x;
			do {
				[self addTextViewTileWithFrame:tileFrame];
				tileFrame.origin.x += tileWidthHint;
			} while (CGRectGetMinX(tileFrame) < CGRectGetMaxX(bufferedBounds));
			tileFrame.origin.y += tileHeightHint;
		} while (CGRectGetMinY(tileFrame) < CGRectGetMaxY(bufferedBounds));
	}

	/*/Invalidate textFrames not in textViews
	if ([textViews count]) { 
		[textDocument invalidateDocumentOutsideOfRect:CGRectUnion([[textViews objectAtIndex:0] frame], [[textViews lastObject] frame])];
	}
	/**/
	if (![[self selectedTextRange] isEmpty]) {
		[selectionView setNeedsLayout];
	}
	if (flags.menuShown)
		[self showMenu];

#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}

- (NSUndoManager *)undoManager {
	return [textDocument undoManager];
}

- (void)setBackgroundColor:(UIColor *)color {
	[super setBackgroundColor:color];
	[self setNeedsDisplay];
}

#pragma mark Text Storage Methods

/* Returns true if the underlining document storage contains any tokens that can be deleted.
 * This may include non printable tokens.
 */
- (BOOL)hasDeletableTokenInDirection:(UITextStorageDirection)direction {
	if ([self selectedTextRange] && [self hasText]) switch (direction) {
		case UITextStorageDirectionForward:
			return [self comparePosition:[[self selectedTextRange] start] toPosition:[self endOfDocument]] < NSOrderedSame;
			break;
		case UITextStorageDirectionBackward:
			return [self comparePosition:[[self selectedTextRange] end] toPosition:[self beginningOfDocument]] > NSOrderedSame;
			break;
		default:
			//This should never happen. Raise error?
			break;
	}
	return NO;
}

- (void)deleteRange:(PhiTextRange *)range {
	BOOL shouldReplace = range && ![range isEmpty];
	if (shouldReplace && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
		shouldReplace = [self.delegate textView:self shouldChangeTextInRange:range replacementText:@""];
	}
	if(shouldReplace) {
		[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerTypingGroupingType | PhiTextUndoManagerDeletingGroupingType | PhiTextUndoManagerCutingGroupingType];
		//[self.textDocument invalidateDocumentRange:range]; // the store does this...
		flags.shouldInvalidateTextDocument = NO;
		[self.textDocument.store deleteCharactersInRange:[range range]];
		flags.shouldInvalidateTextDocument = YES;
	}
}

- (UITextRange *)rangeOfNextDeletableTokenInDirection:(UITextStorageDirection)direction {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextEditorView rangeOfNextDeletableTokenInDirection:%d]...", traceIndent, direction);
#endif
	PhiTextRange *range = (PhiTextRange *)[self selectedTextRange];
	NSUInteger length = 0;
	NSUInteger location = 0;
	if (range && [range isEmpty]) {
		switch (direction) {
			case UITextStorageDirectionForward:
				location = PhiPositionOffset([range end]);
				if (location != PhiPositionOffset([self endOfDocument])) {
					length = 1;
				}
				break;
			case UITextStorageDirectionBackward:
				location = PhiPositionOffset([range start]);
				if (location != 0 && [self hasText]) {
					length = 1;
					location = location - length;
				}
#ifdef DEVELOPER
				NSLog(@"location: %d -> %d", location, location - 1);
#endif
				break;
			default:
				//This should never happen. Raise Error?
				break;
		}
		range = [PhiTextRange textRangeWithRange:NSMakeRange(location, length)];
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@", traceIndent, __FUNCTION__, range);
#endif
	return range;
}

#pragma mark Text Input Methods

- (UIView *)textInputView {
#ifdef TRACE
	NSLog(@"%@Getting textInputView:%@.", traceIndent, self);
#endif
	return self;
}

- (id<UITextInputTokenizer>)tokenizer {
	if (tokenizer) {
#ifdef TRACE
		NSLog(@"%@Getting tokenizer:%@.", traceIndent, tokenizer);
#endif
		return tokenizer;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	Class tokenizerClass = NSClassFromString([defaults stringForKey:@"tokenizerClassName"]);
	if (!tokenizerClass)
		tokenizerClass = [PhiTextInputTokenizer class];
	tokenizer = [[tokenizerClass alloc] initWithTextInput:self];
#ifdef TRACE
	NSLog(@"%@Getting (new) tokenizer:%@.", traceIndent, tokenizer);
#endif
	return tokenizer;
}

- (void)setSelectionAffinityValue:(NSNumber *)affinity {
	[self setSelectionAffinity:[affinity intValue]];
}
- (void)setSelectionAffinity:(UITextStorageDirection)affinity {
#ifdef TRACE
    if (affinity != selectionAffinity) {
        NSLog(@"Setting selectionAffinity:%s.", affinity==0?"UITextStorageDirectionForward":"UITextStorageDirectionBackward");
    }
#endif
	if (affinity == UITextStorageDirectionBackward) {
		selectionAffinity = (UITextStorageDirection)affinity;
	} else if (affinity == UITextStorageDirectionForward) {
		selectionAffinity = (UITextStorageDirection)affinity;
	}
}
- (UITextStorageDirection)selectionAffinity {
#ifdef TRACE
	NSLog(@"%@Getting selectionAffinity:%s.", traceIndent, selectionAffinity==0?"UITextStorageDirectionForward":"UITextStorageDirectionBackward");
#endif
	return selectionAffinity;
}
- (UITextStorageDirection)selectionAffinityForPosition:(PhiTextPosition *)position {
	UITextStorageDirection rv = selectionAffinity;
	PhiTextRange *range = nil;
	if (position.line)
		range = position.line.textRange;
	else
		range = (PhiTextRange *)self.selectedTextRange;
	
	if (range && ![range isEmpty]) {
		//TODO: What if the line happens to be empty?
		if ([position compare:(PhiTextPosition *)[range end]] == NSOrderedSame)
			rv = UITextStorageDirectionBackward;
		else
			rv = UITextStorageDirectionForward;
	} else
	if (//[[[self textDocument] store] isLineBreakAtIndex:PhiPositionOffset(position) - 1] &&
		[[[self textDocument] store] isLineBreakAtIndex:PhiPositionOffset(position)]) {
		rv = UITextStorageDirectionForward;
	}
#ifdef TRACE
	NSLog(@"Getting selectionAffinity:%s forPosition:%@.", rv==0?"UITextStorageDirectionForward":"UITextStorageDirectionBackward", position);
#endif
	return rv;
}

- (void)setInputDelegate:(id <UITextInputDelegate>)sysDelegate {
#ifdef TRACE
	NSLog(@"Setting inputDelegate:%@.", sysDelegate);
#endif
	inputDelegate = sysDelegate;
}
- (id <UITextInputDelegate>)inputDelegate {
#ifdef TRACE
	NSLog(@"%@Getting inputDelegate:%@.", traceIndent, inputDelegate);
#endif
	return inputDelegate;
}

- (UITextPosition *)beginningOfDocument {
	if (bod == nil)
		bod = [[PhiTextPosition textPositionWithPosition:0] retain];
#ifdef TRACE
	NSLog(@"%@Getting %s:%@.", traceIndent, __FUNCTION__, bod);
#endif
	return bod;
}
- (UITextPosition *)endOfDocument {
	NSUInteger length = [self.textDocument.store length];
	if (eod == nil || length != PhiPositionOffset(eod)) {
		if (eod) [eod release];
		eod = [[PhiTextPosition textPositionWithPosition:length] retain];
	}
#ifdef TRACE
	NSLog(@"%@Getting %s:%@.", traceIndent, __FUNCTION__, eod);
#endif
	return eod;
}

- (UITextRange *)selectedTextRange {
#ifdef TRACE
	NSLog(@"%@Getting %s:%@.", traceIndent, __FUNCTION__, selectedTextRange);
#endif
	UITextRange *rv;
	@synchronized(self) {
		rv = [[selectedTextRange copy] autorelease];
	}
	return rv;
}

/*! Important: for the Text Input System only, do not call this method. (Use changeSelectedRange:)
 */
- (void)setSelectedTextRange:(PhiTextRange *)textRange {
#ifdef TRACE
	NSLog(@"%@Entering setSelectedTextRange:%@...", traceIndent, textRange);
#endif
	@synchronized(self) {
		flags.shouldNotifyInputDelegate = NO;
		//Note: changeSelectedRange copies textRange
		[self changeSelectedRange:textRange scroll:YES];
		flags.shouldNotifyInputDelegate = YES;
	}
#ifdef TRACE
	NSLog(@"%@Exiting setSelectedTextRange.", traceIndent);
#endif
}
- (void)changeSelectedRange:(PhiTextRange *)textRange scroll:(BOOL)scrollToSelection {
	[self changeSelectedRange:textRange scroll:scrollToSelection endUndoGrouping:YES];
}
- (void)changeSelectedRange:(PhiTextRange *)textRange scroll:(BOOL)scrollToSelection endUndoGrouping:(BOOL)ensureUndoGroupingEnded {
#ifdef TRACE
	NSLog(@"%@Entering changeSelectedRange:%@ scroll:%s endUndoGrouping:%s...", traceIndent, textRange, scrollToSelection?"YES":"NO", ensureUndoGroupingEnded?"YES":"NO");
#endif
	if (textRange) {
		textRange = [self clampTextRange:textRange];
/*		NSUInteger endIndex = PhiPositionOffset([textRange end]);
		if ([textRange isEmpty] && endIndex) {
			//TODO: DOS Mode
			endIndex--;
			if ([self.textDocument.store isLineBreakAtIndex:endIndex]) {
				textRange = [PhiTextRange textRangeWithRange:NSMakeRange(endIndex, 0)];
			}
		}
*/
		// Check that selected text range really has changed
		if (!selectedTextRange || !NSEqualRanges([(PhiTextRange *)selectedTextRange range], [textRange range])) {
			[self selectionWillChange];
/*			BOOL willSelectionDisplayChange = YES;
			if (selectedTextRange) {
				willSelectionDisplayChange = !([selectedTextRange isEmpty] && [textRange isEmpty]);
				[selectedTextRange release];
			} else {
				willSelectionDisplayChange = ![textRange isEmpty];
			}
 */
#ifdef DEVELOPER
			NSLog(@"selectedTextRange set from %@ to %@...", selectedTextRange, textRange);
#endif
			if (selectedTextRange)
				[selectedTextRange release];
			selectedTextRange = [textRange copy];

			[self selectionDidChange];
			if (scrollToSelection)
				[self scrollSelectionToVisible];
		}
	} else if (selectedTextRange) {
		[self selectionWillChange];
		[selectedTextRange release];
		selectedTextRange = nil;
		[self selectionDidChange];
	}
	if (ensureUndoGroupingEnded)
		[self.textDocument.undoManager ensureUndoGroupingEnded];
#ifdef TRACE
	NSLog(@"%@Exiting changeSelectedRange.", traceIndent);
#endif
}
- (void)changeSelectedRange:(PhiTextRange *)textRange {
	[self changeSelectedRange:textRange scroll:NO endUndoGrouping:YES];
}

- (PhiTextStyle *)textStyleForSelectedRange {
	if (!self.selectedTextRange || (self.currentTextStyle && self.selectedTextRange.empty))
		return self.currentTextStyle;
	if (self.selectedTextRange.empty)
		return [self.textDocument styleAtPosition:(PhiTextPosition *)[self.selectedTextRange start]
									  inDirection:UITextStorageDirectionForward];
	return [self.textDocument styleFromPosition:(PhiTextPosition *)[self.selectedTextRange start]
					toFarthestEffectivePosition:nil notBeyondPosition:(PhiTextPosition *)[self.selectedTextRange end]];
}
- (void)setTextStyleForSelectedRange:(PhiTextStyle *)style {
	if (!self.selectedTextRange || self.selectedTextRange.empty) {
		self.currentTextStyle = style;
		if ([self.selectedTextRange.start isEqual:[self endOfDocument]]) {
			[self.textDocument setDefaultStyle:style];
			[[self selectionView] setNeedsLayout];
		}
		//TODO: redisplay caret and/or line with new line height (?)
	} else {
		[self.textDocument setStyle:style range:(PhiTextRange *)self.selectedTextRange];
		[[self selectionView] setNeedsLayout];
//		[self performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:NO];
	}
}
- (void)addTextStyleForSelectedRange:(PhiTextStyle *)style {
	if (!self.selectedTextRange || self.selectedTextRange.empty) {
		self.currentTextStyle = [[self textStyleForSelectedRange] styleWithAddedStyle:style];
		//TODO: redisplay caret and/or line with new line height
	} else {
		[self.textDocument addStyle:style range:(PhiTextRange *)self.selectedTextRange];
		[[self selectionView] setNeedsLayout];
//		[self performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:invalidRect] waitUntilDone:NO];
	}
}
- (NSDictionary *)textStylingAtPosition:(PhiTextPosition *)position inDirection:(UITextStorageDirection)direction {
#ifdef DEVELOPER
	NSLog(@"%@Entering [textStylingAtPosition:%d inDirection:%s]...", traceIndent, PhiPositionOffset(position), direction==UITextStorageDirectionForward?"UITextStorageDirectionForward":"UITextStorageDirectionBackward");
#endif
	PhiTextStyle *style = [self.textDocument styleAtPosition:position inDirection:direction];
	NSDictionary *styling = [NSDictionary dictionaryWithObjectsAndKeys:
							 [style.font UIFont], UITextInputTextFontKey,
							 nil];
	
	return styling;
}

- (NSString *)textInRange:(PhiTextRange *)range {
	NSString *string = nil;
	if (range) {
		string = [self.textDocument.store substringWithRange:[range range]];
	}
#ifdef TRACE
	NSLog(@"%@Getting textInRange:%@:%d", traceIndent, range, [string length]);
#endif
	return string;
}
- (void)changeTextInRange:(PhiTextRange *)range replacementText:(NSString *)text {
#ifdef TRACE
	NSLog(@"%@Entering changeTextInRange:%@ replacementText:'%@'...", traceIndent, range, text);
#endif
	PhiTextRange *selectedText = (PhiTextRange *)[self selectedTextRange];
	BOOL shouldReplace = text != nil;
	if (shouldReplace && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
		shouldReplace = [self.delegate textView:self shouldChangeTextInRange:selectedText replacementText:text];
	}
	if(shouldReplace && [text compare:[self textInRange:range]]) {
		//NSRange invalidRange = NSMakeRange(PhiRangeOffset(range), MAX(PhiRangeLength(range), [text length]));
		[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerReplaceGroupingType];
		//[self.textDocument invalidateDocumentNSRange:invalidRange]; // the store does this...
		flags.shouldInvalidateTextDocument = NO;
		[self.textDocument.store replaceCharactersInRange:[range range] withString:text];
		flags.shouldInvalidateTextDocument = YES;
		[self.textDocument.undoManager endUndoGrouping:PhiTextUndoManagerReplaceGroupingType];
		
		NSInteger diff = text.length - range.range.length;
		NSInteger location, length;
		if (selectedText && diff != 0 && NSMaxRange(selectedText.range) > range.range.location) {
			if (NSMaxRange(range.range) <= selectedText.range.location) {
				location = selectedText.range.location + diff;
				length = selectedText.range.length;
			} else {
				if (NSMaxRange(range.range) <= NSMaxRange(selectedText.range)) {
					location = selectedText.range.location + text.length;
					length = NSMaxRange(selectedText.range) + diff - selectedText.range.location;
				} else if (range.range.location >= selectedText.range.location) {
					location = selectedText.range.location;
					length = range.range.location - selectedText.range.location;
				} else {
					location = range.range.location;
					length = range.range.length + diff;
				}
			}
			[self changeSelectedRange:[PhiTextRange textRangeWithRange:
										[self clampRange:NSMakeRange(location, length)]]
							   scroll:NO endUndoGrouping:NO];
		}
	}
#ifdef TRACE
	NSLog(@"%@Exiting changeTextInRange:replacementText:.", traceIndent);
#endif
}
/*! Important: for the Text Input System only, do not call this method.
 (Use changeTextInRange:replacementText:)
 */
- (void)replaceRange:(PhiTextRange *)range withText:(NSString *)text {
#ifdef TRACE
	NSLog(@"%@Entering replaceRange:%@ withText:'%@'...", traceIndent, range, text);
#endif
	flags.shouldNotifyInputDelegate = NO;
	[self changeTextInRange:range replacementText:text];
	flags.shouldNotifyInputDelegate = YES;
	[self scrollSelectionToVisible];
#ifdef TRACE
	NSLog(@"%@Exiting replaceRange.", traceIndent);
#endif
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {
#ifdef DEVELOPER
	NSLog(@"%@Entering setMarkedText:'%@' selectedRange:%@...", traceIndent, markedText, NSStringFromRange(selectedRange));
#endif
	PhiTextRange *caret = (PhiTextRange *)[self selectedTextRange];
	if (markedTextRange) {
		caret = (PhiTextRange *)markedTextRange;
		[markedTextRange autorelease];
		markedTextRange = nil;
	}
	NSUInteger startIndex = PhiRangeOffset(caret);
	PhiTextRange *newSelection = [PhiTextRange textRangeWithRange:
										  NSMakeRange(startIndex + selectedRange.location,
													  selectedRange.length)];
	if (markedText) {
		markedTextRange = [[PhiTextRange alloc] initWithRange:NSMakeRange(startIndex, markedText.length)];
		flags.shouldNotifyInputDelegate = NO; {
			PhiTextStyle *style = self.currentTextStyle;
			flags.shouldInvalidateTextDocument = NO; {
				[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerTypingGroupingType | PhiTextUndoManagerPastingGroupingType];
				if (caret && ![caret.start isEqual:[self endOfDocument]]) {
					if (caret.empty && style) {
						[self.textDocument.store insertAttributedString:
						 [[[NSMutableAttributedString alloc] initWithString:markedText
																 attributes:(NSDictionary *)[style attributes]] autorelease]
																atIndex:PhiRangeOffset(caret)];
					} else {
						[self.textDocument.store replaceCharactersInRange:[caret range] withString:markedText];
					}
				} else {
					if (!style)
						style = [[self textDocument] styleAtEndOfDocument];
					[self.textDocument.store appendAttributedString:
					 [[[NSMutableAttributedString alloc] initWithString:markedText
															 attributes:(NSDictionary *)[style attributes]] autorelease]];
				}
			} flags.shouldInvalidateTextDocument = YES;
			[self changeSelectedRange:newSelection scroll:NO endUndoGrouping:NO];
		} flags.shouldNotifyInputDelegate = YES;
		[self.markedTextView setHidden:NO];
		[self.markedTextView setNeedsLayout];
		[self.markedTextView setNeedsDisplay];
	} else {
		markedTextRange = nil;
		[self.markedTextView setHidden:YES];
		if ([caret length]) {
			flags.shouldNotifyInputDelegate = NO; {
				[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerTypingGroupingType | PhiTextUndoManagerPastingGroupingType];
				[self.textDocument.store deleteCharactersInRange:[(PhiTextRange *)markedTextRange range]];
			} flags.shouldInvalidateTextDocument = YES;
			[self changeSelectedRange:newSelection scroll:NO endUndoGrouping:NO];
		}
	}

	[self scrollSelectionToVisible];
}
- (UITextRange *)markedTextRange {
#ifdef DEVELOPER
	NSLog(@"%@Getting markedTextRange:%@", traceIndent, markedTextRange);
#endif
	return markedTextRange;
}
- (void)unmarkText {
#ifdef DEVELOPER
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if (markedTextRange) {
		BOOL shouldReplace = YES;
		if (shouldReplace && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
			shouldReplace = [self.delegate textView:self shouldChangeTextInRange:(PhiTextRange *)markedTextRange replacementText:
							 [self.textDocument.store substringWithRange:[(PhiTextRange *)markedTextRange range]]];
		}
		if (!shouldReplace) {
			[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerTypingGroupingType | PhiTextUndoManagerPastingGroupingType];
			[self.textDocument.store deleteCharactersInRange:[(PhiTextRange *)markedTextRange range]];
			[self changeSelectedRange:[PhiTextRange textRangeWithPosition:(PhiTextPosition *)[markedTextRange start]]];
		}
		[markedTextRange release];
		[self.markedTextView setHidden:YES];
	}
	markedTextRange = nil;
}
- (NSDictionary *)markedTextStyle {
#ifdef DEVELOPER
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
    return [self textStylingAtPosition:[markedTextRange start] inDirection:UITextStorageDirectionForward];
}

- (UITextRange *)textRangeFromPosition:(PhiTextPosition *)p toPosition:(PhiTextPosition *)q {
	PhiTextRange *range = [PhiTextRange textRangeWithRange:[self clampRange:NSMakeRange(MIN(PhiPositionOffset(p), PhiPositionOffset(q)), ABS((int) PhiPositionOffset(q) - PhiPositionOffset(p)))]];
#ifdef TRACE
	NSLog(@"%@Getting [textRangeFromPosition:%@ toPosition:%@]:%@", traceIndent, p, q, range);
#endif
	return range;
}
- (UITextPosition *)positionFromPosition:(PhiTextPosition *)position offset:(NSInteger)offset {
#ifdef TRACE
	NSLog(@"%@Entering positionFromPosition:%@ offset:%d...", traceIndent, position, offset);
#endif
	PhiTextPosition *newPosition = [position textPositionWithOffset:offset];
	return newPosition;
}
- (UITextPosition *)positionFromPosition:(PhiTextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
#ifdef TRACE
	NSLog(@"%@Entering positionFromPosition:%@ inDirection:%d offset:%ld...", traceIndent, position, direction, offset);
#endif
	PhiTextPosition *newPosition = position;
	NSInteger offsetDirection = 1;
	UITextStorageDirection affinity;
	UITextWritingDirection bwd = [self baseWritingDirectionForPosition:position inDirection:UITextStorageDirectionForward]; //TODO: which UITextStorageDirection?
	if (bwd == UITextWritingDirectionRightToLeft) {
		offsetDirection = -1;
	}
	//TODO: if base writing direction == UITextWritingDirectionNatural ?
	
	switch (direction) {
		case UITextLayoutDirectionLeft:
			offset = -offset;
		case UITextLayoutDirectionRight:
			newPosition = [position textPositionWithOffset:offsetDirection * offset];
			break;
		case UITextLayoutDirectionUp:
			offset = -offset;
		case UITextLayoutDirectionDown:
            affinity = [self selectionAffinityForPosition:position];
			newPosition = [textDocument positionFromPosition:position withLineOffset:offset selectionAffinity:&affinity];
			[self performSelectorOnMainThread:@selector(setSelectionAffinityValue:) withObject:[NSNumber numberWithInt:self.selectionAffinity | affinity] waitUntilDone:NO];
			break;
		default:
			// This should never happen. Raise Exception?
			break;
	}
	return newPosition;
}

- (NSComparisonResult)comparePosition:(UITextPosition *)p toPosition:(UITextPosition *)q {
#ifdef TRACE
	NSLog(@"%@Entering comparePosition:%@ toPosition:%@...", traceIndent, p, q);
#endif
	if (p == q && q == eod) {
		//FIXME: hack for wierd hardware keyboard behaviour (up/down keys at EoD)
		return NSOrderedAscending;
	}
	return [(PhiTextPosition *)p compare:(PhiTextPosition *)q];
}
- (NSInteger)offsetFromPosition:(UITextPosition *)p toPosition:(UITextPosition *)q {
	NSInteger offset = PhiPositionOffset(q) - PhiPositionOffset(p);
#ifdef TRACE
	NSLog(@"%@Getting [offsetFromPosition:%@ toPosition:%@]:%d", traceIndent, p, q, offset);
#endif
	return offset;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
#ifdef TRACE
	NSLog(@"%@Entering positionWithinRange:%@ farthestInDirection:%d...", traceIndent, range, direction);
#endif
	//TODO: if range spans multiple lines should newPosition be at the end of the first line?
	UITextPosition *newPosition = nil;
	UITextWritingDirection bwd = [self baseWritingDirectionForPosition:[range start] inDirection:UITextStorageDirectionForward]; //TODO: or should it be end? or somewhere inbetween?? //TODO: which UITextStorageDirection?
	switch (direction) {
		case UITextLayoutDirectionRight:
			if (bwd == UITextWritingDirectionRightToLeft) {
				newPosition = [range start];
				break;
			}
		case UITextLayoutDirectionDown:
			newPosition = [range end];
			break;
		case UITextLayoutDirectionLeft:
			if (bwd == UITextWritingDirectionRightToLeft) {
				newPosition = [range end];
				break;
			}
		case UITextLayoutDirectionUp:
			newPosition = [range start];
			break;
		default:
			// This should never happen. Raise Error?
			break;
	}
	return newPosition;
}
- (UITextRange *)characterRangeByExtendingPosition:(PhiTextPosition *)position inDirection:(UITextLayoutDirection)direction {
#ifdef TRACE
	NSLog(@"%@Entering characterRangeByExtendingPosition:%@ inDirection:%d...", traceIndent, position, direction);
#endif
	NSInteger location = 0, length = 0;
	UITextWritingDirection bwd = [self baseWritingDirectionForPosition:position inDirection:UITextStorageDirectionForward]; //TODO: which UITextStorageDirection?
	switch (direction) {
		case UITextLayoutDirectionRight:
			if (bwd == UITextWritingDirectionRightToLeft) {
				location = 0;
				length = PhiPositionOffset(position);
				break;
			}
		case UITextLayoutDirectionDown:
			location = PhiPositionOffset(position);
			length = [self.textDocument.store length] - PhiPositionOffset(position);
			break;
		case UITextLayoutDirectionLeft:
			if (bwd == UITextWritingDirectionRightToLeft) {
				location = PhiPositionOffset(position);
				length = [self.textDocument.store length] - PhiPositionOffset(position);
				break;
			}
		case UITextLayoutDirectionUp:
			location = 0;
			length = PhiPositionOffset(position);
			break;
		default:
			//This should never happen. Raise Error?
			break;
	}
	return [PhiTextRange textRangeWithRange:[self clampRange:NSMakeRange(location, length)]];
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
#ifdef TRACE
	NSLog(@"%@Entering baseWritingDirectionForPosition:%@ inDirection:%d...", traceIndent, position, direction);
#endif
	//TODO: Do I really have to support UITextWritingDirectionRightToLeft??
	return UITextWritingDirectionLeftToRight;
}
- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {
#ifdef TRACE
	NSLog(@"%@Entering setBaseWritingDirection:%d forRange:%@...", traceIndent, writingDirection, range);
#endif
	//TODO: Do I really have to support baseWritingDirection for any direction? (Maybe later!)
}

#pragma mark Text View Methods

- (CGRect)firstRectForRange:(UITextRange *)range {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextEditorView firstRectForRange:%@]...", traceIndent, range);
#endif
	CGRect firstRect = [textDocument firstRectForRange:(PhiTextRange *)range];
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%.f, %.f), (%.f, %.f).", traceIndent, __FUNCTION__, CGRectComp(firstRect));
#endif
	return firstRect;
}
- (CGRect)lastRectForRange:(UITextRange *)range {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextEditorView lastRectForRange:%@]...", traceIndent, range);
#endif
	CGRect lastRect = [textDocument lastRectForRange:(PhiTextRange *)range];
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%.f, %.f), (%.f, %.f).", traceIndent, __FUNCTION__, CGRectComp(lastRect));
#endif
	return lastRect;
}
- (CGRect)visibleCaretRectForPosition:(UITextPosition *)position alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
	UITextStorageDirection affinity = [self selectionAffinityForPosition:(PhiTextPosition *)position];
	CGRect caretRect = [textDocument caretRectForPosition:(PhiTextPosition *)position
										selectionAffinity:affinity
											   autoExpand:![[self selectedTextRange] isEmpty]
												   inRect:self.bounds
											  alignPixels:pixelsAligned
												   toView:view];
#ifdef TRACE
	NSLog(@"%@Getting [PhiTextEditorView visibleCaretRectForPosition:%@]:(%.f, %.f), (%.f, %.f)", traceIndent, position, CGRectComp(caretRect));
#endif
	return caretRect;
}
- (CGRect)visibleCaretRectForPosition:(UITextPosition *)position {
	return [self visibleCaretRectForPosition:position alignPixels:NO toView:nil];
}
- (CGRect)caretRectForPosition:(UITextPosition *)position {
	CGRect caretRect = [textDocument caretRectForPosition:(PhiTextPosition *)position
										selectionAffinity:[self selectionAffinityForPosition:(PhiTextPosition *)position]];
#ifdef TRACE
	NSLog(@"%@Getting [PhiTextEditorView caretRectForPosition:%@]:(%.f, %.f), (%.f, %.f)", traceIndent, position, CGRectComp(caretRect));
#endif
	return caretRect;
}
- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
	return [textDocument closestPositionToPoint:point];
}
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(PhiTextRange *)range {
	return [textDocument closestPositionToPoint:point withinRange:range];
}
- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
	return [textDocument characterRangeAtPoint:point];
}

- (void)scrollRangeToVisible:(PhiTextRange *)range {
	CGMutablePathRef path = CGPathCreateMutable();
	[[self textDocument] buildPath:path forRange:[self clampTextRange:range]];
	[self scrollRectToVisible:CGPathGetBoundingBox(path) animated:YES];
	CGPathRelease(path);
}
- (void)scrollSelectionToVisible {
	PhiTextRange *selectedRange = (PhiTextRange *)[self selectedTextRange];
	if (selectedRange) {
		if ([selectedRange isEmpty]) {
			[self scrollRectToVisible:[self caretRectForPosition:[selectedRange end]] animated:YES];
		} else {
			[self scrollRectToVisible:CGPathGetBoundingBox(self.selectionView.selectionPath) animated:YES];
		}
	}
}

#pragma mark Key Input Methods

- (BOOL)hasText {
#ifdef TRACE
	NSLog(@"%@Entering hasText...", traceIndent);
#endif
    if ([self.textDocument.store length] > 0) {
        return YES;
    }
    return NO;
}
- (void)changeSelectedText:(NSString *)text {
#ifdef TRACE
	NSLog(@"%@Entering changeSelectedText:'%@'...", traceIndent, text);
#endif
	PhiTextRange *caret = [self clampTextRange:(PhiTextRange *)[self selectedTextRange]];
	BOOL shouldReplace = YES;
	if (shouldReplace && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
		shouldReplace = [self.delegate textView:self shouldChangeTextInRange:caret replacementText:text];
	}
	if (shouldReplace) {
		PhiTextRange *newSelection;
		PhiTextStyle *style = self.currentTextStyle;
		//[self.textDocument invalidateDocumentRange:caret]; // the store does this...
		flags.shouldInvalidateTextDocument = NO;
		[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerTypingGroupingType | PhiTextUndoManagerPastingGroupingType];
		if (caret && ![caret.start isEqual:[self endOfDocument]]) {
			if (text) {
				if (caret.empty && style) {
					[self.textDocument.store insertAttributedString:
					 [[[NSMutableAttributedString alloc] initWithString:text
															 attributes:(NSDictionary *)[style attributes]] autorelease]
															atIndex:PhiRangeOffset(caret)];
				} else {
					[self.textDocument.store replaceCharactersInRange:[caret range] withString:text];
				}
			} else if ([caret length]) {
				[self.textDocument.store deleteCharactersInRange:[caret range]];
			}
			newSelection = [PhiTextRange textRangeWithRange:[self clampRange:NSMakeRange(caret.range.location + [text length], 0)]];
		} else {
			if (text) {
				if (!style)
					style = [[self textDocument] styleAtEndOfDocument];
				[self.textDocument.store appendAttributedString:
				 [[[NSMutableAttributedString alloc] initWithString:text
														 attributes:(NSDictionary *)[style attributes]] autorelease]];
			}
			newSelection = [PhiTextRange textRangeWithPosition:(PhiTextPosition *)[self endOfDocument]];
		}
		flags.shouldInvalidateTextDocument = YES;
		[self changeSelectedRange:newSelection scroll:NO endUndoGrouping:NO];
	}
#ifdef TRACE
	NSLog(@"%@Exiting changeSelectedText", traceIndent);
#endif
}
/*! Important: for the Text Input System only, do not call this method.
 (Use changeSelectedText:)
 */
- (void)insertText:(NSString *)text {
#ifdef TRACE
	NSLog(@"%@Entering insertText:'%@'...", traceIndent, text);
#endif
	flags.shouldNotifyInputDelegate = NO;
	[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerTypingGroupingType];
	[self changeSelectedText:text];
	flags.shouldNotifyInputDelegate = YES;
	[self scrollSelectionToVisible];
#ifdef TRACE
	NSLog(@"%@Exiting insertText", traceIndent);
#endif
}
/*! Important: for the Text Input System only, do not call this method.
 (Use deleteAtSelectedTextRange)
 */
- (void)deleteBackward {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	flags.shouldNotifyInputDelegate = NO;
	[self deleteAtSelectedTextRange];
	flags.shouldNotifyInputDelegate = YES;
	[self scrollSelectionToVisible];
#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}

- (void)deleteAtSelectedTextRange {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if ([self hasDeletableTokenInDirection:UITextStorageDirectionBackward]) {
		PhiTextRange *range = (PhiTextRange *)[self rangeOfNextDeletableTokenInDirection:UITextStorageDirectionBackward];
		NSUInteger startPosition = PhiPositionOffset([range start]);
		PhiTextStyle *saveStyle = [self.textDocument styleAtPosition:(PhiTextPosition *)[range start] inDirection:UITextStorageDirectionForward];
		if (flags.wordSelected && startPosition > 0
			&& [self.textDocument.store characterAtIndex:startPosition - 1] == ' ') {
			range = [PhiTextRange textRangeWithRange:NSMakeRange(startPosition - 1, PhiRangeLength(range) + 1)];
		}
		if (!self.selectedTextRange.empty)
			[self.textDocument.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerDeletingGroupingType | PhiTextUndoManagerCutingGroupingType];
		[self deleteRange:range];
		[self changeSelectedRange:[PhiTextRange textRangeWithRange:NSMakeRange(PhiRangeOffset(range), 0)] scroll:NO endUndoGrouping:NO];
		self.currentTextStyle = saveStyle;
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
}

- (BOOL)enablesReturnKeyAutomatically {
	return flags.enablesReturnKeyAutomatically;
}
- (void)setEnablesReturnKeyAutomatically:(BOOL)flag {
	flags.enablesReturnKeyAutomatically = flag;
}

- (BOOL)isSecureTextEntry {
	return flags.secureTextEntry;
}
- (void)setSecureTextEntry:(BOOL)flag {
	flags.secureTextEntry = flag;
}

#pragma mark Scroll View Methods

- (void)didScroll {
	[self scrollViewDidScroll:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//	if (![self.selectedTextRange isEmpty]) [self showMenu];
	if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[self.delegate scrollViewDidScroll:scrollView];
	}
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
		[self.delegate scrollViewDidZoom:scrollView];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self hideMenu];
	if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
		[self.delegate scrollViewWillBeginDragging:scrollView];
	}
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (![self.selectedTextRange isEmpty] && !decelerate) [self showMenu];
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
		[self.delegate scrollViewDidEndDragging:scrollView willDecelerate:(BOOL)decelerate];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
		[self.delegate scrollViewWillBeginDecelerating:scrollView];
	}
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (![self.selectedTextRange isEmpty]) [self showMenu];
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[self.delegate scrollViewDidEndDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
		[self.delegate scrollViewDidEndScrollingAnimation:scrollView];
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
		return [self.delegate viewForZoomingInScrollView:scrollView];
	}
	return nil;
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
		[self.delegate scrollViewWillBeginZooming:scrollView withView:(UIView *)view];
	}
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
		[self.delegate scrollViewDidEndZooming:scrollView withView:(UIView *)view atScale:(float)scale];
	}
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
		return [self.delegate scrollViewShouldScrollToTop:scrollView];
	}
	return YES;
}
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	if (![self.selectedTextRange isEmpty]) [self showMenu];
	if ([self.delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
		[self.delegate scrollViewDidScrollToTop:scrollView];
	}
}

- (BOOL)canCancelContentTouches {
#ifdef TRACE
	NSLog(@"%@Executing [UIScrollView canCancelContentTouches]...", traceIndent);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	BOOL rv = [super canCancelContentTouches];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UIScrollView canCancelContentTouches]:%s.", traceIndent, rv?"YES":"NO");
#endif
	return rv;
}
- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
#ifdef TRACE
	NSLog(@"%@Executing [UIScrollView touchesShouldBegin:%@ withEvent:%@ inContentView:%@]...", traceIndent, touches, event, view);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	BOOL rv = [super touchesShouldBegin:touches withEvent:event inContentView:view];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UIScrollView touchesShouldBegin:withEvent:inContentView:]:%s.", traceIndent, rv?"YES":"NO");
#endif
	return rv;
}
- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
#ifdef TRACE
	NSLog(@"%@Executing [UIScrollView touchesShouldCancelInContentView:%@]...", traceIndent, view);
	traceIndent = [traceIndent stringByAppendingString:@"    "];
#endif
	BOOL rv = [super touchesShouldCancelInContentView:(UIView *)view];
#ifdef TRACE
	traceIndent = [traceIndent substringToIndex:[traceIndent length] - 4];
	NSLog(@"%@Executed [UIScrollView touchesShouldCancelInContentView:]:%s.", traceIndent, rv?"YES":"NO");
#endif
	return rv;
}
/*
- (void)setContentSize:(CGSize)size {
	[super setContentSize:size];
}
*/
- (void)calculateContentSize {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	BOOL concealScrollIndicator = self.showsVerticalScrollIndicator;
	if (concealScrollIndicator)
		[self setShowsVerticalScrollIndicator:NO];
	[self setContentSize:[[self textDocument] suggestTextSize]];
	if (concealScrollIndicator)
		[self setShowsVerticalScrollIndicator:YES];
	[pool release];
}

#pragma mark Selection View Delegate Methods

- (PhiTextRange *)textSelectionViewSelectedTextRange:(PhiTextSelectionView *)view {
	if (view == self.markedTextView)
		return (PhiTextRange *)[self markedTextRange];
	return (PhiTextRange *)[self selectedTextRange];
}

- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldShowSelectionHandle:(PhiTextSelectionHandle *)handle {
	return [self isFirstResponder];
}
//- (void)textSelectionView:(PhiTextSelectionView *)view didShowSelectionHandle:(PhiTextSelectionHandle *)handle;
- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldHideSelectionHandle:(PhiTextSelectionHandle *)handle {
	return ![self isFirstResponder];
}
//- (void)textSelectionView:(PhiTextSelectionView *)view didHideSelectionHandle:(PhiTextSelectionHandle *)handle;

- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldShowSelectionCaret:(PhiTextCaretView *)caret {
	return [self isFirstResponder];
}
//- (void)textSelectionView:(PhiTextSelectionView *)view didShowSelectionCaret:(PhiTextCaretView *)caret;
- (BOOL)textSelectionView:(PhiTextSelectionView *)view shouldHideSelectionCaret:(PhiTextCaretView *)caret {
	return ![self isFirstResponder];
}
//- (void)textSelectionView:(PhiTextSelectionView *)view didHideSelectionCaret:(PhiTextCaretView *)caret;


#pragma mark Gesture Methods

- (void)setupGestures {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	[self tearDownGestures];	
	
	Class selectionModifierClass = NSClassFromString([defaults stringForKey:@"selectionModifierClassName"]);
	if (!selectionModifierClass)
		selectionModifierClass = [PhiTextSelectionHandleRecognizer class];
	selectionModifier = [[selectionModifierClass alloc] initWithTarget:self action:@selector(changeSelection:)];
	selectionModifier.minimumNumberOfTouches = 1;
	selectionModifier.maximumNumberOfTouches = 1;
	selectionModifier.owner = self;
	[self addGestureRecognizer:selectionModifier];
}
- (void)tearDownGestures {
	if (selectionModifier) {
		[self removeGestureRecognizer:selectionModifier];
		[selectionModifier release];
	}
	selectionModifier = nil;
}

- (CGRect)visibleBounds {
	if (!CGRectEqualToRect(keyboardFrame, CGRectZero)) {
		CGRect intersection = CGRectIntersection(self.bounds, keyboardFrame);
		if (intersection.size.height != 0.0f) {
			intersection.size.height = MAX(0, self.bounds.size.height - intersection.size.height);
			intersection.size.width = self.bounds.size.width;
			intersection.origin = self.bounds.origin;
		} else {
			intersection = self.bounds;
		}
		return intersection;
	}
	return self.bounds;
}
- (void)setBounds:(CGRect)rect {
	[super setBounds:rect];
}
- (void)autoScrollFire:(NSTimer *)timer {
	BOOL stopTimer = NO;
	UIViewAnimationCurve autoScrollCurve = UIViewAnimationCurveLinear;
	UIGestureRecognizer *gestureRecognizer = [[timer userInfo] objectForKey:@"gestureRecognizer"];
	CGPoint point = [gestureRecognizer locationInView:self];
	CGPoint scrollOffset = [self contentOffset];
	CGFloat distance;
	CGRectEdge edge;
	[[[timer userInfo] objectForKey:@"edge"] getValue:&edge];
	
	switch (edge) {
		case CGRectMinYEdge:
			distance = autoScrollGap - MAX(point.y - CGRectGetMinY(self.bounds), 0);
			distance = distance * autoScrollSpeed;
			stopTimer = distance <= 0 || scrollOffset.y <= 0;
			if (!stopTimer) {
				scrollOffset.y -= distance;
				if (scrollOffset.y < 0) {
					autoScrollCurve = UIViewAnimationCurveEaseOut;
					scrollOffset.y = 0;
				}
			}
			break;
		case CGRectMaxYEdge:
			distance = autoScrollGap - MAX(CGRectGetMaxY(self.bounds) - point.y, 0);
			distance = distance * autoScrollSpeed;
			stopTimer = distance <= 0 || scrollOffset.y >= self.contentSize.height - self.bounds.size.height;
			if (!stopTimer) {
				scrollOffset.y += distance;
				if (scrollOffset.y > self.contentSize.height - self.bounds.size.height) {
					autoScrollCurve = UIViewAnimationCurveEaseOut;
					scrollOffset.y > self.contentSize.height - self.bounds.size.height;
				}
			}
			break;
		case CGRectMinXEdge:
			distance = autoScrollGap - MAX(point.x - CGRectGetMinX(self.bounds), 0);
			distance = distance * autoScrollSpeed;
			stopTimer = distance <= 0 || scrollOffset.x <= 0;
			if (!stopTimer) {
				scrollOffset.x -= distance;
				if (scrollOffset.x < 0) {
					autoScrollCurve = UIViewAnimationCurveEaseOut;
					scrollOffset.x = 0;
				}
			}
			break;
		case CGRectMaxXEdge:
			distance = autoScrollGap - MAX(CGRectGetMaxX(self.bounds) - point.x, 0);
			distance = distance * autoScrollSpeed;
			stopTimer = distance <= 0 || scrollOffset.x >= self.contentSize.width - self.bounds.size.width;
			if (!stopTimer) {
				scrollOffset.x += distance;
				if (scrollOffset.x > self.contentSize.width - self.bounds.size.width) {
					autoScrollCurve = UIViewAnimationCurveEaseOut;
					scrollOffset.x = self.contentSize.width - self.bounds.size.width;
				}
			}
			break;
		default:
			break;
	}
	if (!stopTimer) {
		self.magnifier.active = NO;
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:autoScrollDuration];
		[UIView setAnimationCurve:autoScrollCurve];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(didScroll)];
		[self setContentOffset:scrollOffset animated:NO];
		[UIView commitAnimations];
		stopTimer = (autoScrollCurve == UIViewAnimationCurveEaseOut);
	}
	if (stopTimer) {
		self.magnifier.active = YES;
		[autoScrollTimer invalidate];
		[autoScrollTimer release];
		autoScrollTimer = nil;
	}
	if ([gestureRecognizer isKindOfClass:[PhiTextSelectionHandleRecognizer class]])
		[[(PhiTextSelectionHandleRecognizer *)gestureRecognizer currentHandle] moveToClosestPositionToPoint:point inView:self];
}
- (IBAction)enterEditor:(UIGestureRecognizer *)tap {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	BOOL enter = [self isFirstResponder];
	if (!enter) {
		enter = [self becomeFirstResponder];
	}
	if (enter) {
		[self hideMenu];
		if (![self moveCaretToClosestSnapPositionAtPoint:[tap locationInView:self]]) {
			[self showMenu];
		}		
	}
}

- (UITextPosition *)closestWordPositionToPoint:(CGPoint)point inDirection:(PhiTextStorageDirection)direction {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextEditorView closestWordPositionToPoint:(%.f, %.f) inDirection:%s]", traceIndent, point.x, point.y, direction==PhiTextStorageDirectionAny?"PhiTextStorageDirectionAny":(direction==PhiTextStorageDirectionForward?"PhiTextStorageDirectionForward":(direction==PhiTextStorageDirectionBackward?"PhiTextStorageDirectionBackward":"(unknown)")));
#endif
	UITextPosition *position = [self closestPositionToPoint:point];
	UITextPosition *word = nil, *back = nil, *forward = nil;
	NSInteger backOffset = NSIntegerMax, forwardOffset = NSIntegerMax, wordOffset;
	
	switch (direction) {
		case PhiTextStorageDirectionAny:
		case PhiTextStorageDirectionForward:
			if ([[self tokenizer] isPosition:position atBoundary:UITextGranularityWord inDirection:UITextStorageDirectionBackward]
				) {
				forward = position;
				forwardOffset = 0;
			} else {
				word = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionForward];
				wordOffset = [self offsetFromPosition:word toPosition:position];
				forward = word;
				forwardOffset = wordOffset;
#ifdef DEVELOPER
				NSLog(@"Snap forward to word by offset: %d", forwardOffset);
#endif
			}
			if (direction == PhiTextStorageDirectionForward)
				break;
		case PhiTextStorageDirectionBackward:
			if ([[self tokenizer] isPosition:position atBoundary:UITextGranularityWord inDirection:UITextStorageDirectionForward]
				) {
				back = position;
				backOffset = 0;
			} else {
				word = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
				wordOffset = [self offsetFromPosition:word toPosition:position];
				back = word;
				backOffset = wordOffset;
#ifdef DEVELOPER
				NSLog(@"Snap backward to word by offset: %d", backOffset);
#endif
			}
		default:
			break;
	}
	
	position = forward;
	if (ABS(backOffset) < ABS(forwardOffset)) {
		position = back;
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@...", traceIndent, __FUNCTION__, position);
#endif
	return position;
}
- (UITextPosition *)closestWordPositionToPoint:(CGPoint)point {
	return [self closestWordPositionToPoint:point inDirection:PhiTextStorageDirectionAny];
}
- (UITextPosition *)closestSnapPositionToPoint:(CGPoint)point {
	return [self closestSnapPositionToPoint:point inDirection:PhiTextStorageDirectionAny];
}
- (UITextPosition *)closestSnapPositionToPoint:(CGPoint)point inDirection:(PhiTextStorageDirection)direction {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextEditorView closestSnapPositionToPoint:(%.f, %.f) inDirection:%s]", traceIndent, point.x, point.y, direction==PhiTextStorageDirectionAny?"PhiTextStorageDirectionAny":(direction==PhiTextStorageDirectionForward?"PhiTextStorageDirectionForward":(direction==PhiTextStorageDirectionBackward?"PhiTextStorageDirectionBackward":"(unknown)")));
#endif
	UITextPosition *position = [self closestPositionToPoint:point];
	UITextPosition *word = nil, *para = nil,// *line = nil,
		*back = nil, *forward = nil;
	NSInteger backOffset = NSIntegerMax, forwardOffset = NSIntegerMax,
	wordOffset, paraOffset;//, lineOffset;
	
	switch (direction) {
		case PhiTextStorageDirectionAny:
		case PhiTextStorageDirectionForward:
			if ([[self tokenizer] isPosition:position atBoundary:UITextGranularityWord inDirection:UITextStorageDirectionBackward] ||
				[[self tokenizer] isPosition:position atBoundary:UITextGranularitySentence inDirection:UITextStorageDirectionBackward]
//				|| ([[self tokenizer] isPosition:position atBoundary:UITextGranularityLine inDirection:UITextStorageDirectionBackward] && ![[self tokenizer] isPosition:position atBoundary:UITextGranularityParagraph inDirection:UITextStorageDirectionBackward])
				) {
				forward = position;
				forwardOffset = 0;
			} else {
				word = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionForward];
				para = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularitySentence inDirection:UITextStorageDirectionForward];
				//line = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularityLine inDirection:UITextStorageDirectionForward];
				wordOffset = [self offsetFromPosition:word toPosition:position];
				paraOffset = [self offsetFromPosition:para toPosition:position];
				//lineOffset = [self offsetFromPosition:line toPosition:position];
				if (ABS(wordOffset) <= ABS(paraOffset)) {
					forward = word;
					forwardOffset = wordOffset;
				} else {
					forward = para;
					forwardOffset = paraOffset;
				}
#ifdef DEVELOPER
				NSLog(@"Snap forward by offset: %d (word: %d; para: %d)", forwardOffset, wordOffset, paraOffset);
#endif
			}
			if (direction == PhiTextStorageDirectionForward)
				break;
		case PhiTextStorageDirectionBackward:
			if ([[self tokenizer] isPosition:position atBoundary:UITextGranularityWord inDirection:UITextStorageDirectionForward] ||
				[[self tokenizer] isPosition:position atBoundary:UITextGranularitySentence inDirection:UITextStorageDirectionForward]
//				|| ([[self tokenizer] isPosition:position atBoundary:UITextGranularityLine inDirection:UITextStorageDirectionForward] && ![[self tokenizer] isPosition:position atBoundary:UITextGranularityParagraph inDirection:UITextStorageDirectionForward])
				) {
				back = position;
				backOffset = 0;
			} else {
				word = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
				para = [[self tokenizer] positionFromPosition:position toBoundary:UITextGranularitySentence inDirection:UITextStorageDirectionBackward];
				para = [self positionFromPosition:para offset:-1];
				wordOffset = [self offsetFromPosition:word toPosition:position];
				paraOffset = [self offsetFromPosition:para toPosition:position];
				if (ABS(wordOffset) <= ABS(paraOffset)) {
					back = word;
					backOffset = wordOffset;
				} else {
					back = para;
					backOffset = paraOffset;
				}
#ifdef DEVELOPER
				NSLog(@"Snap backward by offset: %d (word: %d; para: %d)", backOffset, wordOffset, paraOffset);
#endif
			}
		default:
			break;
	}
	
	position = forward;
	if (ABS(backOffset) < ABS(forwardOffset)) {
		position = back;
	}

	PhiTextLine *line = [(PhiTextPosition *)position line];
	PhiTextRange *lineRange = [line textRange];
	if (line.frame != [self.textDocument lastEmptyFrame]
		&& ![lineRange isEmpty]
		&& PhiPositionOffset(position) == PhiPositionOffset(lineRange.end)
		&& [self.textDocument.store isLineBreakAtIndex:PhiPositionOffset(position) - 1]
		) {
#ifdef DEVELOPER
		NSLog(@"Adjust position");
		NSLog(@"stringIndex: %@; store length: %d", position, [self.textDocument.store length]);
#endif
			position = [PhiTextPosition textPositionWithTextPosition:(PhiTextPosition *)position offset:-1];
	}
	
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@...", traceIndent, __FUNCTION__, position);
#endif
	return position;
}
- (void)selectWordAtPoint:(CGPoint)point {
	[self moveCaretToClosestSnapPositionAtPoint:point];
	[self selectWord];
}
- (void)selectWordAtTap:(UIGestureRecognizer *)tap {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	BOOL enter = [self isFirstResponder];
	if (!enter) {
		enter = [self becomeFirstResponder];
	}
	if (enter) {
		[self hideMenu];
		[self selectWordAtPoint:[tap locationInView:self]];
		[self showMenu];
		flags.keepMenuVisible = YES;
	}
}
- (void)selectParagraphAtTap:(UIGestureRecognizer *)tap {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	BOOL enter = [self isFirstResponder];
	if (!enter) {
		enter = [self becomeFirstResponder];
	}
	if (enter) {
		[self hideMenu];
		[self moveCaretToClosestPositionAtPoint:[tap locationInView:self]];
		[self selectGranularity:UITextGranularityParagraph];
		[self showMenu];
		flags.keepMenuVisible = YES;
	}
}

- (BOOL)moveCaretToPosition:(PhiTextPosition *)position {
	PhiTextRange *newSelection = (PhiTextRange *)[self textRangeFromPosition:position toPosition:position];
	PhiTextRange *oldSelection = (PhiTextRange *)[self selectedTextRange];
	
	if (!oldSelection || !NSEqualRanges([oldSelection range], [newSelection range])) {
		if (position.line && [(PhiTextPosition *)position.line.textRange.end compare:position] == NSOrderedSame)
			self.selectionAffinity = UITextStorageDirectionBackward;
		else
			self.selectionAffinity = UITextStorageDirectionForward;
		[self changeSelectedRange:newSelection];
		return YES;
	}
	return NO;
}
- (BOOL)moveCaretToClosestPositionAtPoint:(CGPoint)point {
	return [self moveCaretToPosition:(PhiTextPosition *)[self closestPositionToPoint:point]];
}
- (BOOL)moveCaretToClosestSnapPositionAtPoint:(CGPoint)point {
	return [self moveCaretToPosition:(PhiTextPosition *)[self closestSnapPositionToPoint:point]];
}

- (void)selectWord {
	UITextRange *selectedRange = [self selectedTextRange];
	NSUInteger endIndex = PhiPositionOffset([selectedRange end]);
	
	if ((endIndex == 0 || [[[self textDocument] store] isLineBreakAtIndex:endIndex - 1]) && [[[self textDocument] store] isLineBreakAtIndex:endIndex]) {
		[self changeSelectedRange:[PhiTextRange textRangeWithRange:NSMakeRange(endIndex, 1)]];
	} else {
		[self selectGranularity:UITextGranularityWord];
	}
}
- (void)selectGranularity:(UITextGranularity)granularity {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	UITextRange *selectedRange = [self selectedTextRange];
	UITextPosition *start = [selectedRange start], *end = [selectedRange end];
	
	if (selectedRange) {
		if ([[self tokenizer] isPosition:start atBoundary:granularity inDirection:UITextStorageDirectionBackward]) {
			end = [[self tokenizer] positionFromPosition:end toBoundary:granularity inDirection:UITextStorageDirectionForward];
		} 
		else if ([[self tokenizer] isPosition:end atBoundary:granularity inDirection:UITextStorageDirectionForward]) {
			start = [[self tokenizer] positionFromPosition:start toBoundary:granularity inDirection:UITextStorageDirectionBackward];
		} else {
			end = [[self tokenizer] positionFromPosition:end toBoundary:granularity inDirection:UITextStorageDirectionForward];
			start = [[self tokenizer] positionFromPosition:start toBoundary:granularity inDirection:UITextStorageDirectionBackward];
		}
		if ([[[self textDocument] store] isLineBreakAtIndex:PhiPositionOffset(end) - 1]) {
			end = [PhiTextPosition textPositionWithTextPosition:(PhiTextPosition *)end offset:-1];
		}
		
		[self changeSelectedRange:(PhiTextRange *)[self textRangeFromPosition:start toPosition:end]];
		
		//NOTE: rangeEnclosingPosition:withGranularity:inDirection: doesn't select the word if the position is at the start boundry or admist punctuation
		//[self changeSelectedRange:[[self tokenizer] rangeEnclosingPosition:[[self selectedTextRange] start] withGranularity:granularity inDirection:UITextLayoutDirectionRight]];
		if (granularity == UITextGranularityWord) {
			flags.wordSelected = YES;
		}
	}
}

- (void)showMagnifier:(PhiTextMagnifier *)aMagnifier atPoint:(CGPoint)point {
#ifdef TRACE
	NSLog(@"%@Entering [showMagnifierAtPoint:(%.f, %.f)]", traceIndent, point.x, point.y);
#endif
	if (aMagnifier && !flags.magnifierShown) {
		//[aMagnifier setHidden:YES];
		[aMagnifier growFromPoint:point];
		flags.magnifierShown = YES;
	}
#ifdef TRACE
	NSLog(@"%@Exiting [showMagnifierAtPoint:]", traceIndent);
#endif
}
- (void)showCaretMagnifierAtPoint:(CGPoint)point {
	if (!magnifier) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"com.phitext"];
		
		Class magnifierClass = NSClassFromString([defaults stringForKey:@"magnifierClassName"]);
		if (!magnifierClass)
			magnifierClass = [PhiTextMagnifier class];
		magnifier = [[magnifierClass alloc] initWithOrigin:point];
		[magnifier setSubjectView:self];
	}
	[self showMagnifier:magnifier atPoint:(CGPoint)point];
}
- (void)showSelectionMagnifierAtPoint:(CGPoint)point {
	[self showCaretMagnifierAtPoint:point];
}
- (void)moveMagnifier:(PhiTextMagnifier *)aMagnifier toPoint:(CGPoint)point {
#ifdef TRACE
	NSLog(@"%@Entering [moveMagnifierToPoint:(%.f, %.f)]", traceIndent, point.x, point.y);
#endif
	if (aMagnifier) {
		//[aMagnifier.superview bringSubviewToFront:aMagnifier];
		[aMagnifier setCenter:[self convertPoint:point toView:aMagnifier.superview]];
	}
}
- (void)moveCaretMagnifierToPoint:(CGPoint)point {
	[self moveMagnifier:magnifier toPoint:point];
}
- (void)moveSelectionMagnifierToPoint:(CGPoint)point {
	[self moveCaretMagnifierToPoint:point];
}
- (void)hideMagnifier:(PhiTextMagnifier *)aMagnifier toPoint:(CGPoint)point {
#ifdef TRACE
	NSLog(@"%@Entering [hideMagnifierToPoint:(%.f, %.f)]", traceIndent, point.x, point.y);
#endif
	if (aMagnifier) {
		point = [self convertPoint:point toView:aMagnifier];
		
		[aMagnifier shrinkToPoint:point];
		//[aMagnifier setSubjectView:nil];
	}
	flags.magnifierShown = NO;
}
- (void)hideCaretMagnifierToPoint:(CGPoint)point {
	[self hideMagnifier:magnifier toPoint:point];
}
- (void)hideSelectionMagnifierToPoint:(CGPoint)point {
	[self hideCaretMagnifierToPoint:point];
}

- (void)changeSelection:(PhiTextSelectionHandleRecognizer *)pan {
#ifdef DEVELOPER
	NSLog(@"%@Entering [PhiTextEditorView changeSelection:%@]...", traceIndent, pan);
#endif
	CGPoint point;
	UIView *caret;
	BOOL enter, autoScroll = NO;
	CGRectEdge autoScrollEdge = -1;
	CGRect intersection;
	CGFloat dxEdge = 0.0;
	CGFloat dxClosestEdge = 0.0;
	
	switch (pan.state) {
		case UIGestureRecognizerStateBegan:
			[self hideMenu];
			if (pan.currentHandle) {
				[self showSelectionMagnifierAtPoint:[self convertPoint:pan.currentHandle.caret.center fromView:pan.currentHandle.caret.superview]];
			} else {
				enter = [self isFirstResponder];
				if (!enter) {
					enter = [self becomeFirstResponder];
				}
				if (!enter) {
					[pan fail];
					break;
				}
				point = [pan locationInView:self];
				if (pan.tapCount == 2) {
					[self selectWordAtPoint:point];
					[initialHandleRange release];
					initialHandleRange = [self.selectedTextRange copy];
					[self showSelectionMagnifierAtPoint:[self convertPoint:pan.currentHandle.caret.center fromView:pan.currentHandle.caret.superview]];
				} else {
					[self moveCaretToClosestPositionAtPoint:point];
					[self showCaretMagnifierAtPoint:point];
				}
				if (!flags.blinkingPaused) {
					[self.selectionView pauseBlinking];
					flags.blinkingPaused = YES;
				}
			}
		case UIGestureRecognizerStateChanged:
			point = [pan locationInView:self];
			intersection = CGRectInset([self visibleBounds], 2 * autoScrollGap, 2 * autoScrollGap);
			if (!CGRectContainsPoint(intersection, point)) {
				//Top edge
				dxClosestEdge = MAX(point.y - CGRectGetMinY(self.bounds), 0);
				autoScrollEdge = CGRectMinYEdge;
				//Bottom edge
				dxEdge = MAX(CGRectGetMaxY(self.bounds) - point.y, 0);
				dxClosestEdge = MIN(dxEdge, dxClosestEdge);
				if (dxClosestEdge == dxEdge)
					autoScrollEdge = CGRectMaxYEdge;
				//Left edge
				dxEdge = MAX(point.x - CGRectGetMinX(self.bounds), 0);
				dxClosestEdge = MIN(dxEdge, dxClosestEdge);
				if (dxClosestEdge == dxEdge)
					autoScrollEdge = CGRectMinXEdge;
				//Right edge
				dxEdge = MAX(CGRectGetMaxX(self.bounds) - point.x, 0);
				dxClosestEdge = MIN(dxEdge, dxClosestEdge);
				if (dxClosestEdge == dxEdge)
					autoScrollEdge = CGRectMaxXEdge;
				autoScroll = (dxClosestEdge < autoScrollGap);
				if (autoScroll && !autoScrollTimer) {
					autoScrollTimer = 
					[[NSTimer scheduledTimerWithTimeInterval:autoScrollDuration
													  target:self
													selector:@selector(autoScrollFire:)
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															  [NSValue value:&autoScrollEdge withObjCType:@encode(CGRectEdge)], @"edge",
															  pan, @"gestureRecognizer",
															  nil]
													 repeats:YES] retain];
				}
			}
			if (pan.currentHandle) {
				[pan.currentHandle moveToClosestPositionToPoint:point inView:self];
				[self moveSelectionMagnifierToPoint:[self convertPoint:pan.currentHandle.caret.center fromView:pan.currentHandle.caret.superview]];
			} else
				//Check for NaN
				if (point.x == point.x && point.y == point.y) {
					if (pan.tapCount > 1) {
						PhiTextPosition *position = (PhiTextPosition *)[self closestPositionToPoint:point];
						PhiTextRange *oldSelection = (PhiTextRange *)[self selectedTextRange];
						PhiTextRange *newSelection = (PhiTextRange *)initialHandleRange;
						if (PhiPositionOffset(position) > PhiPositionOffset([initialHandleRange end])) {
							newSelection = (PhiTextRange *)[self textRangeFromPosition:[initialHandleRange start] toPosition:position];
						} else if (PhiPositionOffset(position) < PhiPositionOffset([initialHandleRange start])) {
							newSelection = (PhiTextRange *)[self textRangeFromPosition:position toPosition:[initialHandleRange end]];
						}
						if (!oldSelection || !NSEqualRanges([oldSelection range], [newSelection range]))
							[self changeSelectedRange:newSelection];
						[self moveSelectionMagnifierToPoint:point];
					} else {
						[self moveCaretToClosestPositionAtPoint:point];
						[self moveCaretMagnifierToPoint:point];
					}
				}
			break;
		case UIGestureRecognizerStateEnded:
			[autoScrollTimer invalidate];
			[autoScrollTimer release];
			autoScrollTimer = nil;
			enter = [self isFirstResponder];
			if (!enter) {
				enter = [self becomeFirstResponder];
			}
			if (!enter) {
				[pan fail];
				break;
			}
			if (pan.hasMovementOccurred && pan.currentHandle) {
				if (![pan.currentHandle moveToClosestPositionToPoint:[pan lastLocationInView:pan.currentHandle] withVelocity:[pan velocityInView:pan.currentHandle]])
					[self showMenu];
				[self hideSelectionMagnifierToPoint:[self convertPoint:pan.currentHandle.caret.center fromView:pan.currentHandle.caret.superview]];
				flags.keepMenuVisible = YES;
				break;
			} else {
				if (pan.tapCount == 2) {
					BOOL setKeepMenuVisible = flags.menuShown;
					if (initialHandleRange) {
						if ([self comparePosition:[initialHandleRange end] toPosition:[self.selectedTextRange end]] == NSOrderedSame) {
							pan.currentHandle = self.selectionView.startHandle;
							if ([self comparePosition:[initialHandleRange start] toPosition:[self.selectedTextRange start]] != NSOrderedSame)
								[pan.currentHandle moveToClosestPositionToPoint:[pan lastLocationInView:pan.currentHandle] withVelocity:[pan velocityInView:pan.currentHandle]];
						} else {
							pan.currentHandle = self.selectionView.endHandle;
							if ([self comparePosition:[initialHandleRange end] toPosition:[self.selectedTextRange end]] != NSOrderedSame)
								[pan.currentHandle moveToClosestPositionToPoint:[pan lastLocationInView:pan.currentHandle] withVelocity:[pan velocityInView:pan.currentHandle]];
						}
					} else {
						[self selectWordAtPoint:[pan lastLocationInView:self]];
					}
					if (setKeepMenuVisible)
						flags.keepMenuVisible = YES;
					else
						[self showMenu];
				} else if (pan.tapCount == 4) {
					[self selectGranularity:UITextGranularityParagraph];
					[self showMenu];
				} else {
					point = [pan lastLocationInView:self];
					if (CGRectContainsPoint(CGRectInset([self convertRect:self.selectionView.endHandle.caret.frame fromView:self.selectionView], -25.0, -25.0), point)
						|| ![self moveCaretToClosestSnapPositionAtPoint:point]
						|| pan.hasLongPressOccurred)
						[self showMenu];
				}
			}
		case UIGestureRecognizerStateCancelled:
			[autoScrollTimer invalidate];
			[autoScrollTimer release];
			autoScrollTimer = nil;
			if (pan.currentHandle) {
				if (initialHandleRange) {
					[initialHandleRange release];
					initialHandleRange = nil;
				}
				[self hideSelectionMagnifierToPoint:[self convertPoint:pan.currentHandle.caret.center fromView:pan.currentHandle.caret.superview]];
				flags.keepMenuVisible = YES;
			} else {
				if (flags.blinkingPaused) {
					[[self selectionView] resumeBlinking];
					flags.blinkingPaused = NO;
				}
				if (flags.magnifierShown) {
					caret = self.selectionView.endHandle.caret;
					[self hideCaretMagnifierToPoint:[self convertPoint:caret.center fromView:caret.superview]];
				}
			}
			break;
		default:
			break;
	}
}

#pragma mark Edit Actions

- (BOOL)shouldEnableMenuPositionAdjustment {
	return flags.enableMenuPositionAdjustment;
}
- (void)setEnableMenuPositionAdjustment:(BOOL)flag {
	flags.enableMenuPositionAdjustment = flag;
}

- (void)adjustMenuPosition:(CGRect)menuFrame targetRect:(CGRect)targetRect {
	if (flags.enableMenuPositionAdjustment) {
		UIMenuController *menu = [UIMenuController sharedMenuController];
		PhiTextRange *selectedRange = (PhiTextRange *)[self selectedTextRange];
		
		if (![selectedRange isEmpty] && !CGRectEqualToRect(menuFrame, CGRectZero)) {
			if (CGRectGetMaxY(menuFrame) < CGRectGetMinY(targetRect)) {
				if (CGRectIntersectsRect([self convertRect:self.selectionView.startHandle.caret.frame fromView:self.selectionView], self.bounds)
					&& CGRectGetMidX(menuFrame) < CGRectGetMinX([self convertRect:self.selectionView.startHandle.caret.frame fromView:self.selectionView])) {
					if ([menu arrowDirection] == UIMenuControllerArrowDefault) {
						[menu setArrowDirection:UIMenuControllerArrowRight];
						flags.menuArrowDirectionOverride = YES;
					}
					menuTargetRect = [self convertRect:self.selectionView.startHandle.caret.frame fromView:self.selectionView];
					[menu setTargetRect:menuTargetRect inView:self];
				} else {
					if ([menu arrowDirection] == UIMenuControllerArrowDefault) {
						[menu setArrowDirection:UIMenuControllerArrowDown];
						flags.menuArrowDirectionOverride = YES;
					}
				}
			} else {
				if (CGRectIntersectsRect([self convertRect:self.selectionView.endHandle.caret.frame fromView:self.selectionView], self.bounds)
					&& CGRectGetMidX(menuFrame) > CGRectGetMaxX([self convertRect:self.selectionView.endHandle.caret.frame fromView:self.selectionView])
					) {
					if ([menu arrowDirection] == UIMenuControllerArrowDefault) {
						[menu setArrowDirection:UIMenuControllerArrowLeft];
						flags.menuArrowDirectionOverride = YES;
					}
					menuTargetRect = [self convertRect:selectionView.endHandle.caret.frame fromView:self.selectionView];
					[menu setTargetRect:menuTargetRect inView:self];
				} else {
					if ([menu arrowDirection] == UIMenuControllerArrowDefault) {
						[menu setArrowDirection:UIMenuControllerArrowUp];
						flags.menuArrowDirectionOverride = YES;
					}
				}
			}
		}
	}
}
- (void)adjustMenuPosition:(CGRect)menuFrame {
	CGRect targetRect;
	PhiTextRange *selectedRange = (PhiTextRange *)[self selectedTextRange];

	if (![selectedRange isEmpty] && !CGRectEqualToRect(menuFrame, CGRectZero)) {
		targetRect = CGRectIntersection(CGPathGetBoundingBox([selectionView selectionPath]), self.bounds);
		if (targetRect.size.height > 40.0 && self.bounds.size.height > 36.0
			&& targetRect.size.height >= self.bounds.size.height - 36.0) {
			targetRect.size.height -= 40.0; //targetRect is too big, make it a little smaller so that menu will show nicely at bottom
		}
		[self adjustMenuPosition:menuFrame targetRect:targetRect];
	}
}
- (void)adjustMenuPosition {
	[self adjustMenuPosition:[self convertRect:[[UIMenuController sharedMenuController] menuFrame] fromView:nil]];
}
- (void)setKeepMenuVisible {
	flags.keepMenuVisible = YES;
}
- (BOOL)isMenuShown {
	return flags.menuShown;
}
- (void)willShowMenu {
	
}
- (void)willHideMenu {
	menuPageNumber = 0;
}
- (CGRect)menuTargetRect {
	if (CGRectEqualToRect(menuTargetRect, CGRectNull)) {
		PhiTextRange *selectedRange = (PhiTextRange *)[self selectedTextRange];
		if ([selectedRange isEmpty]) {
			[self.selectionView update];
			menuTargetRect = [self convertRect:self.selectionView.endHandle.caret.bounds fromView:self.selectionView.endHandle.caret];
		} else {
			menuTargetRect = CGPathGetBoundingBox([selectionView selectionPath]);
		}
		if (CGRectIntersectsRect(menuTargetRect, self.bounds)) {
			menuTargetRect = CGRectIntersection(menuTargetRect, self.bounds);
			if (menuTargetRect.size.height > 40.0 && self.bounds.size.height > 36.0
				&& menuTargetRect.size.height >= self.bounds.size.height - 36.0) {
				//menuTargetRect is too big, make it a little smaller so that menu will show nicely at bottom
				menuTargetRect.size.height -= 40.0;
			}
		}
	}
	return menuTargetRect;
}
- (void)showMenu {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if ([self isFirstResponder]) {
		UIMenuController *menu = [UIMenuController sharedMenuController];
		PhiTextRange *selectedRange = (PhiTextRange *)[self selectedTextRange];
		
		if (selectedRange) {
			CGRect targetRect = self.menuTargetRect;
			if ([selectedRange isEmpty]) {
				//DONE: use selection view's end caret frame instead of recalculating the rect
				if (flags.menuArrowDirectionOverride) {
					[menu setArrowDirection:UIMenuControllerArrowDefault];
					flags.menuArrowDirectionOverride = NO;
				}
			}
			if (CGRectIntersectsRect(targetRect, self.bounds)) {
				if (flags.menuArrowDirectionOverride) {
					[menu setArrowDirection:UIMenuControllerArrowDefault];
					flags.menuArrowDirectionOverride = NO;
				}
				[menu setTargetRect:menuTargetRect inView:self];
				if (CGRectGetMinY([self convertRect:targetRect toView:nil]) > 60) {//[menu menuFrame] is not accurate!
					//menu will be above
					[self adjustMenuPosition:CGRectMake(CGRectGetMidX(targetRect), CGRectGetMinY(targetRect), 0, 0) targetRect:targetRect];
				} else {
					//menu will be below
					[self adjustMenuPosition:CGRectMake(CGRectGetMidX(targetRect), CGRectGetMaxY(targetRect), 0, 0) targetRect:targetRect];
				}
				if (![menu isMenuVisible]) {
					[self _addMoreItems];
					
					[self willShowMenu];
#ifdef DEVELOPER
					NSLog(@"Showing menu now...");
#endif
					[menu setMenuVisible:YES animated:YES];
				}
				flags.menuShown = YES;
			} else {
				if ([menu isMenuVisible]) {
					[self willHideMenu];
					[menu setMenuVisible:NO animated:YES];
				}
			}
		}
		flags.keepMenuVisible = NO;
	} else {
		flags.keepMenuVisible = YES;
	}
}

- (void)reshowMenu {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	if (flags.keepMenuVisible) {
//		[self performSelector:@selector(showMenuAfterHidden) withObject:nil afterDelay:0.1];
		[self performSelectorOnMainThread:@selector(showMenu) withObject:nil waitUntilDone:NO];
		
		flags.keepMenuVisible = NO;
	}
}

- (void)hideMenu {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	UIMenuController *menu = [UIMenuController sharedMenuController];
	flags.keepMenuVisible = NO;
	if ([menu isMenuVisible]) {
		if (flags.menuArrowDirectionOverride) {
			[menu setArrowDirection:UIMenuControllerArrowDefault];
			flags.menuArrowDirectionOverride = NO;
		}
		[self willHideMenu];
		[menu setMenuVisible:NO animated:YES];
	}
	menuTargetRect = CGRectNull;
	flags.menuShown = NO;
}
- (BOOL)enableMenuPaging {
	return flags.enableMenuPaging;
}
- (void)setEnableMenuPaging:(BOOL)flag {
	flags.enableMenuPaging = flag;
}
- (void)addCustomMenuItem:(UIMenuItem *)menuItem atPage:(NSUInteger)pageNumber {
	if (pageNumber == [menuPages count])
		[menuPages addObject:[NSMutableArray arrayWithObject:menuItem]];
	else
		[[menuPages objectAtIndex:pageNumber] addObject:menuItem];
}
- (void)addCustomMenuItem:(UIMenuItem *)menuItem {
	if (![menuPages count])
		[menuPages addObject:[NSMutableArray arrayWithObject:menuItem]];
	else
		[[menuPages objectAtIndex:[menuPages count] - 1] addObject:menuItem];
}
- (BOOL)hasMoreMenuItems {
	BOOL more = flags.enableMenuPaging && [menuPages count] > menuPageNumber + 1;
	NSUInteger savePageNumber = menuPageNumber;
	if (more) {
		more = NO;
		for (menuPageNumber++; menuPageNumber < [menuPages count] && !more; menuPageNumber++) {
			NSArray *items = [menuPages objectAtIndex:menuPageNumber];
			for (int j = 0; j < [items count] && !more; j++) {
				UIMenuItem *item = [items objectAtIndex:j];
				more |= [self canPerformAction:item.action withSender:self];
			}
		}
	}
	menuPageNumber = savePageNumber;
	return more;
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(showCustomItems:)) {
		return [self hasMoreMenuItems];
	}
	if (menuPageNumber == 0) {
		if (action == @selector(paste:)) {
			UIPasteboard *pb = [UIPasteboard generalPasteboard];
			if ([[pb strings] count]) {
				return YES;
			}
		}
		
		if ([self hasText]) {
			if (![self selectedTextRange]
				&& action == @selector(selectAll:)) {
				return YES;
			}
			else if ([[self selectedTextRange] isEmpty]
					 && (action == @selector(select:) || action == @selector(selectAll:))) {
				return YES;
			} else if ([(PhiTextRange *)[self selectedTextRange] length] &&
				(action == @selector(cut:)
				 || action == @selector(copy:))
				//|| action == @selector(delete:) //Not needed when keyboard is visible (TODO: will keyboard be visible)
				//TODO:|| action == @selector(promptForReplace:)
				) {
					return YES;
			}
		}
	}
	
	if (menuPageNumber < [menuPages count]) {
		for (UIMenuItem *item in [menuPages objectAtIndex:menuPageNumber]) {
			if (action == item.action) {
				return [self respondsToSelector:action];
			}
		}
	}
	return NO;
}
- (UIMenuItem *)moreMenuItem {
	if (!moreMenuItem)
		moreMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"More...", @"more menu item title") action:@selector(showCustomItems:)];
	return moreMenuItem;
}
- (void)_addMoreItems {
	UIMenuController *menu = [UIMenuController sharedMenuController];
	NSMutableArray *menuItems = [[menuPages objectAtIndex:menuPageNumber] mutableCopy];
	if ([self hasMoreMenuItems])
		[menuItems addObject:[self moreMenuItem]];
	[menu setMenuItems:menuItems];
	[menuItems release];
}
- (void)showCustomItems:(id)sender {
	if ([self hasMoreMenuItems]) {
		UIMenuController *menu = [UIMenuController sharedMenuController];
		
		BOOL more = NO;
		for (menuPageNumber++; menuPageNumber < [menuPages count] - 1 && !more; menuPageNumber++) {
			NSArray *items = [menuPages objectAtIndex:menuPageNumber];
			for (int j = 0; j < [items count] && !more; j++) {
				UIMenuItem *item = [items objectAtIndex:j];
				more |= [self canPerformAction:item.action withSender:self];
			}
		}
		[menu setMenuVisible:NO animated:YES];
		
		[self _addMoreItems];
		
		flags.keepMenuVisible = YES;
		//[self reshowMenu];
	}
}
- (void)copy:(id)sender {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	NSString *text = [self textInRange:self.selectedTextRange];
	
	if (text && [text length]) {
		pb.string = text;
		flags.wordCopied = flags.wordSelected;
		[self hideMenu];
	}
}
- (void)cut:(id)sender {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	NSString *text = [self textInRange:self.selectedTextRange];
	
	if (text && [text length]) {
		pb.string = text;
		flags.wordCopied = flags.wordSelected;
		[[textDocument undoManager] ensureUndoGroupingBegan:PhiTextUndoManagerCutingGroupingType];
		[self deleteAtSelectedTextRange];
		[[textDocument undoManager] ensureUndoGroupingEnded];
	}
}
- (void)delete:(id)sender {
	if (self.selectedTextRange && ![self.selectedTextRange isEmpty]) {
		[[textDocument undoManager] ensureUndoGroupingBegan:PhiTextUndoManagerDeletingGroupingType];
		[self deleteAtSelectedTextRange];
		[[textDocument undoManager] ensureUndoGroupingEnded];
	}
}
- (void)paste:(id)sender {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	NSMutableString *text = nil;
	
	if ([[pb strings] count]) {
		text = [NSMutableString stringWithString:[pb.strings objectAtIndex:0]];
	}
	
	if (text && [text length]) {
		if (flags.wordCopied) {
			NSUInteger startPosition = PhiPositionOffset([self.selectedTextRange start]);
			NSUInteger endPosition = PhiPositionOffset([self.selectedTextRange end]);
			if (startPosition > 0 && [self.textDocument.store characterAtIndex:startPosition - 1] != ' ') {
				[text insertString:@" " atIndex:0];
			}
			if (endPosition < [self.textDocument.store length] && [self.textDocument.store characterAtIndex:endPosition + 1] != ' ') {
				[text appendString:@" "];
			}
		}
		[[textDocument undoManager] ensureUndoGroupingBegan:PhiTextUndoManagerPastingGroupingType];
		[self changeSelectedText:text];
		[[textDocument undoManager] ensureUndoGroupingEnded];
		[self hideMenu];
		[self scrollSelectionToVisible];
	}
}
- (void)select:(id)sender {
	[self hideMenu];
	[self selectWord];
	[self showMenu];
}
- (void)selectAll:(id)sender {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	[self hideMenu];
	[self changeSelectedRange:(PhiTextRange *)[self textRangeFromPosition:[self beginningOfDocument]
												toPosition:[self endOfDocument]]];
	[self showMenu];
}

#ifdef DEVELOPER
- (void)setContentSize:(CGSize)size {
	[super setContentSize:size];
}
#endif

@end
