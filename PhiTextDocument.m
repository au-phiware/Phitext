//
//  PhiTextDocument.m
//  Phitext
//
//  Created by Corin Lawson on 10/03/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <QuartzCore/CAShapeLayer.h>
#import "PhiTextEditorView.h"
#import "PhiTextDocument.h"
#import "PhiTextPosition.h"
#import "PhiTextRange.h"
#import "PhiTextFrame.h"
#import "PhiTextLine.h"
#import "PhiTextStorage.h"
#import "PhiTextStyle.h"
#import "PhiTextFont.h"
#import "PhiTextEmptyFrame.h"
#import "PhiAATree.h"
#import "PhiTextUndoManager.h"

#ifndef PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT
#ifdef DEVELOPER
#define PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT(_RECT_) NSLog(@"[%i] Updating editor rect: %@", __LINE__, NSStringFromCGRect(_RECT_)),[owner performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:(_RECT_)] waitUntilDone:NO]
#else
#define PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT(_RECT_) [owner performSelectorOnMainThread:@selector(setNeedsDisplayInValueRect:) withObject:[NSValue valueWithCGRect:(_RECT_)] waitUntilDone:NO]
#endif
#endif

#ifndef PHI_CARET_WIDTH
#define PHI_CARET_WIDTH (2.0)
#endif
#ifndef PHI_CARET_OFFSET
#define PHI_CARET_OFFSET (1.0)
#endif

#ifndef PHI_CARET_PIXEL_FLOOR_FUNC
#define PHI_CARET_PIXEL_FLOOR_FUNC PhiFloorPixelToCenter
#endif
#ifndef PHI_CARET_PIXEL_CEIL_FUNC
#define PHI_CARET_PIXEL_CEIL_FUNC PhiCeilPixelToCenter
#endif

@interface PhiTextFrame (PhiTextDocument)

@property (nonatomic, readwrite) CFIndex firstStringIndex;
@property (nonatomic, retain, readwrite) PhiTextRange *textRange;

- (CGSize)tileSize;
- (CFIndex)changeInTextRange;
- (void)setFirstLineNumber:(NSUInteger)number;

@end

CGRect PhiUnionRectFrame (CGRect rect, PhiTextFrame *textFrame) {
	CGRect frameRect = [textFrame CGRectValue];
	//if ([textFrame isKindOfClass:[PhiTextEmptyFrame class]])
	{
		CGSize tileSize = [textFrame tileSize];
		if (tileSize.width * tileSize.height > 0.0)
			frameRect.size = tileSize;
	}
	return CGRectUnion(rect, frameRect);
}

@interface PhiTextDocument ()

- (void)setDefaults;

@end

typedef CGFloat (*PhiConvertPixelToViewFunction)(CGFloat points, UIView *view);

static CGFloat PhiFloorPixelToEdge(CGFloat points, UIView *view) {
	CGFloat scale = 1.0;
	if ([view respondsToSelector:@selector(contentScaleFactor)])
		scale = [view contentScaleFactor];
	
	return floor(points * scale) / scale;
}
static CGFloat PhiFloorPixelToCenter(CGFloat points, UIView *view) {
	CGFloat scale = 1.0;
	if ([view respondsToSelector:@selector(contentScaleFactor)])
		scale = [view contentScaleFactor];
	
	return (floor(points * scale) + 0.5) / scale;
}
static CGFloat PhiCeilPixelToEdge(CGFloat points, UIView *view) {
	CGFloat scale = 1.0;
	if ([view respondsToSelector:@selector(contentScaleFactor)])
		scale = [view contentScaleFactor];
	
	return ceil(points * scale) / scale;
}
static CGFloat PhiCeilPixelToCenter(CGFloat points, UIView *view) {
	CGFloat scale = 1.0;
	if ([view respondsToSelector:@selector(contentScaleFactor)])
		scale = [view contentScaleFactor];
	
	return (ceil(points * scale) - 0.5) / scale;
}

@implementation PhiTextDocument

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	float aFloat;
	int anInt;
	CFNumberRef aNumberValue;
	
	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("storageClassName"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		aFloat = 8.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("paddingLeft"), aNumberValue, suiteName);
		CFPreferencesSetAppValue(CFSTR("paddingRight"), aNumberValue, suiteName);
		CFPreferencesSetAppValue(CFSTR("paddingTop"), aNumberValue, suiteName);
		CFRelease(aNumberValue);

		aFloat = 32.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("paddingBottom"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		anInt = 1;
		aNumberValue = CFNumberCreate(NULL, kCFNumberIntType, &anInt);
		CFPreferencesSetAppValue(CFSTR("textWrapping"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		aFloat = 120.0f;
		aNumberValue = CFNumberCreate(NULL, kCFNumberCGFloatType, &aFloat);
		CFPreferencesSetAppValue(CFSTR("frameTileHeightHint"), aNumberValue, suiteName);
		CFRelease(aNumberValue);
		
		CFPreferencesSetAppValue(CFSTR("storageClassName"), CFSTR("PhiTextStorage"), suiteName);
		
#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}

@synthesize owner, store, undoManager, tileHeightHint;
@synthesize wrap, currentColor, defaultStyle;
@synthesize paddingLeft, paddingTop, paddingRight, paddingBottom;

- (void)setStore:(PhiTextStorage *)aStore {
	if (store != aStore) {
		if (store) {
			[undoManager removeAllActionsWithTarget:store];
			[self.owner storageWillChange];
			[store release];
		}
		store = aStore;
		if (store) {
			[store retain];
			[self.owner storageDidChange];
			[self invalidateDocument];
		}
	}
}

- (void)setWrap:(BOOL)flag {
	if (wrap != flag) {
		wrap = flag;
		[self setSize:self.owner.bounds.size];
		[self invalidateDocument];
		if ([self.owner isKindOfClass:[UIScrollView class]]) {
			if ([self.owner respondsToSelector:@selector(scrollSelectionToVisible)]) {
				[self.owner scrollSelectionToVisible];
			}
			[self.owner flashScrollIndicators];
		}
	}
}

- (void)textWillChange {
	oldLength = [[self store] length];
	[[self owner] textWillChange];
}

- (void)textDidChange {
	[[self owner] textDidChange];
}

#pragma mark Internal Methods
- (PhiAATree *)textFrames {
	return textFrames;
}
- (CGRect)suggestTileBounds {
	CGRect rv = CGRectMake(0, 0, wrap?self.bounds.size.width:CGFLOAT_MAX, MIN(MAX([self tileHeightHint], 0.0), self.owner.bounds.size.height));
	
	if (rv.size.width * rv.size.height == 0.0) {
		rv.size = CGSizeMake([[UIScreen mainScreen] bounds].size.width, [self tileHeightHint]);
	}
	
	return rv;
}
- (PhiTextFrame *)lastEmptyFrame {
	if (!lastEmptyFrame) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"com.phitext"];
		
		CGRect tileBounds = [self suggestTileBounds];
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, CGRectMake(0, 0, tileBounds.size.width, tileBounds.size.height));
		lastEmptyFrame = [[PhiTextEmptyFrame alloc] initInPath:path forDocument:self attributes:NULL];
		[lastEmptyFrame autoEndContentAccess];
		CGPathRelease(path);
	}
	return lastEmptyFrame;
}

- (void)setDefaults {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];

	[self setCurrentColor:[UIColor blackColor]];
	
	paddingLeft = [defaults floatForKey:@"paddingLeft"];
	paddingRight = [defaults floatForKey:@"paddingRight"];
	paddingTop = [defaults floatForKey:@"paddingTop"];
	paddingBottom = [defaults floatForKey:@"paddingBottom"];
	frameAttributes = NULL;
	[textFrames removeAllObjects];
	[textFrames setObjectComparator:(CFComparatorFunction)PhiTextFrameCompareByRange];
	textFrames.delegate = self;
	invalidRange = NSMakeRange(0, 0);
	lastValidTextFrameNode = nil;
	oldLength = 0;
	diffLength = 0;
	selectionAffinity = 0;
	tileHeightHint = [defaults floatForKey:@"frameTileHeightHint"];
	wrap = [defaults boolForKey:@"textWrapping"];
	
	if (lastEmptyFrame)
		[lastEmptyFrame release];
	lastEmptyFrame = nil;
	
	self.undoManager = [[[PhiTextUndoManager alloc] init] autorelease];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDefaults) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)reloadDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	if (tileHeightHint != [defaults floatForKey:@"frameTileHeightHint"]) {
		tileHeightHint = [defaults floatForKey:@"frameTileHeightHint"];
		
		[textFrames removeAllObjects];
		
		[self invalidateDocument];
	}
}

- (PhiTextRange *)textRangeOfDocument {
	return [PhiTextRange textRangeWithRange:NSMakeRange(PhiPositionOffset([owner beginningOfDocument]), PhiPositionOffset([owner endOfDocument]))];	
}

#pragma mark Line Searching

/* Search for the line containing the specified position */
- (PhiTextLine *)searchLineWithRange:(PhiTextRange *)range andPoint:(CGPoint)point {
#ifdef TRACE
	NSLog(@"%@Entering searchLineWithRange:%@ andPoint:(%.f, %.f)...", traceIndent, range, point.x, point.y);
#endif
	PhiTextLine *line = nil;
	PhiAATreeRange *textFrameRange = nil;
	
	point.x -= self.paddingLeft;
	point.y -= self.paddingTop;
	
	textFrameRange = [self beginContentAccessInRect:CGRectMake(point.x, point.y, 0, 0)];
	if ([textFrameRange.end.object rect].origin.y <= point.y) {
		line = [textFrameRange.end.object searchLineWithRange:range andPoint:point];
	} else {
		line = [textFrameRange.start.object searchLineWithRange:range andPoint:point];
	}
	
    for (PhiTextFrame *frame in textFrameRange)
        [frame performSelectorOnMainThread:@selector(endContentAccess) withObject:nil waitUntilDone:NO];
    
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@.", traceIndent, __FUNCTION__, line);
#endif
	return line;
}
- (PhiTextLine *)searchLineWithPoint:(CGPoint)point {
	return [self searchLineWithRange:nil andPoint:point];
}

/* Search for the line containing the specified position */
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity inRect:(CGRect)rect frameNode:(PhiAATreeNode **)frameNode {
#ifdef TRACE
	NSLog(@"%@Entering [searchLineWithPosition:%@ selectionAffinity:%s inRect:%@ frameNode:0x%x]...", traceIndent, position, affinity==UITextStorageDirectionForward?"UITextStorageDirectionForward":"UITextStorageDirectionBackward", NSStringFromCGRect(rect), frameNode);
#endif
	PhiTextLine *line = nil;
	if (position.line && !frameNode)
		return position.line;
	
	PhiAATreeRange *textFrameRange = nil;
	PhiTextFrame *frame = [self lastEmptyFrame];
	if (frameNode)
		*frameNode = [textFrames lastNode];
	
	if (!(frame == (PhiTextFrame *)[textFrames lastObject] && PhiPositionOffset(position) == [self.store length])) {
		textFrameRange = [self beginContentAccessInRange:[PhiTextRange textRangeWithPosition:position] andRect:rect];
		
		if (!textFrameRange.singleton && affinity == UITextStorageDirectionBackward && PhiPositionOffset(position) > 0
			// && ![self.store isLineBreakAtIndex:PhiPositionOffset(position) - 1]
			) {
			frame = (PhiTextFrame *)textFrameRange.start.object;
			if (frameNode)
				*frameNode = textFrameRange.start;
		} else {
			frame = (PhiTextFrame *)textFrameRange.end.object;
			if (frameNode)
				*frameNode = textFrameRange.end;
		}
	}

	line = [frame searchLineWithPosition:position selectionAffinity:affinity];
    
    for (PhiTextFrame *tf in textFrameRange)
        [tf endContentAccess];
	/***/
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@", traceIndent, __FUNCTION__, line);
#endif
	return line;
}
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity inRect:(CGRect)rect {
	return [self searchLineWithPosition:position selectionAffinity:affinity inRect:rect frameNode:NULL];
}
- (PhiTextLine *)searchLineWithPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity {
	return [self searchLineWithPosition:position selectionAffinity:affinity inRect:CGRectNull frameNode:NULL];
}

#pragma mark Geometry Methods
- (CGRect)rectForLine:(PhiTextLine *)line withOffset:(CGPoint)offset includeLeading:(BOOL)includeLeading {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextView rectForLine:%@ withOffset:(%.f, %.f) includeLeading:%s]...", traceIndent, line, offset.x, offset.y, includeLeading?"YES":"NO");
#endif
	CGRect rect;
	/*	//TODO: DOS Mode
	 CFRange lineRange = [self stringRangeForLine:line withFrameIndex:frameIndex];
	 if ([self.store isLineBreakAtIndex:lineRange.location + lineRange.length - 1]) {
	 width = self.bounds.size.width;
	 }
	 /**/
	CGPoint oid = line.originInDocument;
	CGPoint docOrigin = self.bounds.origin;
	rect = CGRectMake(docOrigin.x + oid.x + offset.x,
					  docOrigin.y + oid.y - line.ascent + offset.y,
					  line.width, line.ascent + line.descent + (includeLeading?line.leading:0.0));
	
#ifdef TRACE
	NSLog(@"%@Exiting [PhiTextView rectForLine:withOrigin:offset:]:(%.f, %.f), (%.f, %.f)...", traceIndent, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif
	return rect;
}
- (CGRect)rectForLine:(PhiTextLine *)line withOffset:(CGPoint)offset {
	return [self rectForLine:line withOffset:offset includeLeading:NO];
}
- (CGRect)rectForLine:(PhiTextLine *)line {
	return [self rectForLine:line withOffset:CGPointZero];
}

// TODO: Are correction rects the red rects in UITextView??
- (CGRect)lineRectForRange:(PhiTextRange *)range withPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity {
	return [self lineRectForRange:range withPosition:position selectionAffinity:affinity includeLeading:NO];
}
- (CGRect)lineRectForRange:(PhiTextRange *)range withPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity includeLeading:(BOOL)includeLeading {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextView lineRectForRange:%@ withPosition:%@ includeLeading:%s]...", traceIndent, range, position, includeLeading?"YES":"NO");
#endif
	CGRect lineRect = CGRectZero;
	@synchronized(store) {
		PhiTextLine *line;
		CGFloat startOffset;
		PhiTextPosition *start = (PhiTextPosition *)[range start];
		PhiTextPosition *end = (PhiTextPosition *)[range end];
		//range = [[self owner] trimNewLinesFromTextRange:range];
		
		// Clamp position
		if ([position compare:start] == NSOrderedAscending) {
			position = start;
		}
		if ([position compare:end] == NSOrderedDescending) {
			position = end;
		}
		
		line = [self searchLineWithPosition:position selectionAffinity:affinity];
		startOffset = [line offsetForPosition:start];
		lineRect = [self rectForLine:line withOffset:CGPointMake(startOffset, 0.0) includeLeading:includeLeading];
		
		PhiTextRange *lineRange = [line textRange];
		// If our text doesn't span to the next line then adjust width
		if ([end compare:(PhiTextPosition *)lineRange.end] == NSOrderedAscending) {
			lineRect.size.width = [line offsetForPosition:end];
		}
		// If it does span to (at least) the end of the line then check for new line and adjust width. TODO: DOS Mode
		else if (affinity == UITextStorageDirectionBackward
			 && [self.store isLineBreakAtIndex:PhiPositionOffset(lineRange.end) - 1]) {
#ifdef DEVELOPER
			NSLog(@"Adjust width");
			NSLog(@"store length: %d; stringRange: %@; startOffset: %d", [self.store length], lineRange, startOffset);
#endif
			lineRect.size.width = self.bounds.size.width;
		}
		lineRect.size.width -= startOffset;
	}//end synchronized
	
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%.f, %.f), (%.f, %.f).", traceIndent, __FUNCTION__, CGRectComp(lineRect));
#endif
	return lineRect;
}
- (CGRect)firstRectForRange:(PhiTextRange *)range {
	return [self lineRectForRange:range withPosition:(PhiTextPosition *)[range start] selectionAffinity:UITextStorageDirectionForward includeLeading:YES];
}
- (CGRect)lastRectForRange:(PhiTextRange *)range {
	return [self lineRectForRange:range withPosition:(PhiTextPosition *)[range end] selectionAffinity:UITextStorageDirectionBackward includeLeading:YES];
}

- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
					autoExpand:(BOOL)flag inRect:(CGRect)rect
				   alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
	PhiTextLine *line;

	line = [self searchLineWithPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
	if ([position compare:(PhiTextPosition *)[[[line frame] textRange] start]] == NSOrderedAscending) {
		rect = CGRectIntersection(CGRectUnion(rect, [[line frame] rect]), self.bounds);
		return CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), 0, 0);
	}
	line = [self searchLineWithPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
	if ([position compare:(PhiTextPosition *)[[[line frame] textRange] end]] == NSOrderedDescending) {
		rect = CGRectIntersection(CGRectUnion(rect, [[line frame] rect]), self.bounds);
		return CGRectMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect), 0, 0);
	}
	return [self caretRectForPosition:position selectionAffinity:affinity
						   autoExpand:flag alignPixels:pixelsAligned toView:view];
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
					autoExpand:(BOOL)flag inRect:(CGRect)rect {
	return [self caretRectForPosition:position selectionAffinity:affinity
						   autoExpand:flag inRect:rect alignPixels:NO toView:nil];
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
						inRect:(CGRect)rect {
	return [self caretRectForPosition:position selectionAffinity:affinity
						   autoExpand:NO inRect:rect alignPixels:NO toView:nil];
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
						inRect:(CGRect)rect alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
	return [self caretRectForPosition:position selectionAffinity:affinity
						   autoExpand:NO inRect:rect alignPixels:pixelsAligned toView:view];
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
					alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
	return [self caretRectForPosition:position selectionAffinity:affinity
						   autoExpand:NO alignPixels:pixelsAligned toView:view];
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
					autoExpand:(BOOL)flag {
	return [self caretRectForPosition:position selectionAffinity:affinity
						   autoExpand:flag alignPixels:NO toView:nil];
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity
					autoExpand:(BOOL)flag alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextView caretRectForPosition:%@ selectionAffinity:%s autoExpand:%s]...", traceIndent, position, affinity==UITextStorageDirectionForward?"UITextStorageDirectionForward":"UITextStorageDirectionBackward", flag?"YES":"NO");
#endif
	CGRect caret = CGRectZero;
	@synchronized(store)
	{
		PhiTextPosition *start = position;
		PhiTextLine *line;
		CGFloat startOffset;

		line = [self searchLineWithPosition:position selectionAffinity:affinity];
		if (line) {
			startOffset = [line offsetForPosition:start];
			caret = [self rectForLine:line withOffset:CGPointMake(startOffset, 0.0) includeLeading:YES];
			caret.size.width = (CGFloat)PHI_CARET_WIDTH;
			caret.origin.x -= (CGFloat)PHI_CARET_OFFSET;
			if (affinity == UITextStorageDirectionBackward) {
				PhiTextRange *lineRange = [line textRange];
				// If our text doesn't span to the next line then adjust width
				if ([position compare:(PhiTextPosition *)lineRange.end] == NSOrderedAscending) {
					caret.origin.x += [line offsetForPosition:position] - startOffset;
#ifdef DEVELOPER
					NSLog(@"Position adjusted to end of text");
#endif
				}
				// If it does span to (at least) the end of the line then check for new line and adjust width. TODO: DOS Mode
				else if (flag && [self.store isLineBreakAtIndex:PhiPositionOffset(lineRange.end) - 1]) {
					caret.origin.x += self.bounds.size.width - startOffset;
#ifdef DEVELOPER
					NSLog(@"Position adjusted to end of text bounds");
#endif
				}
			}
		} else {
			//TODO: Use CTFontGetBoundingBox??
			caret = CGRectMake(self.bounds.origin.x - 1.0,
							   self.bounds.origin.y,
							   PHI_CARET_WIDTH, self.defaultStyle.font.ascent + self.defaultStyle.font.descent + self.defaultStyle.font.leading);		
		}
	}
	if (caret.origin.x > CGRectGetMaxX(self.bounds)) {
		caret.origin.x = CGRectGetMaxX(self.bounds);
	}
	
	if (pixelsAligned) {
		CGRect alignedCaret;
		alignedCaret.origin = CGPointMake(PHI_CARET_PIXEL_FLOOR_FUNC(caret.origin.x, view),
										  PHI_CARET_PIXEL_FLOOR_FUNC(caret.origin.y, view));
		alignedCaret.size = CGSizeMake(PHI_CARET_WIDTH,
									   PHI_CARET_PIXEL_CEIL_FUNC(CGRectGetMaxY(caret), view) - alignedCaret.origin.y);
		caret = alignedCaret;
	}
	
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%.f, %.f), (%.f, %.f).", traceIndent, __FUNCTION__, CGRectComp(caret));
#endif
	return caret;
}
- (CGRect)caretRectForPosition:(PhiTextPosition *)position selectionAffinity:(UITextStorageDirection)affinity {
	return [self caretRectForPosition:position selectionAffinity:affinity autoExpand:NO];
}

- (PhiTextPosition *)positionFromPosition:(PhiTextPosition *)position withLineOffset:(NSInteger)offset selectionAffinity:(UITextStorageDirection *)affinity {
#ifdef TRACE
	NSLog(@"%@Entering [PhiTextView positionFromPosition:%@ withLineOffset:%d]...", traceIndent, position, offset);
#endif
	PhiTextPosition *newPosition;
	@synchronized(store) {
	PhiTextLine *line;
	PhiAATreeNode *frameNode;
	PhiTextFrame *frame;
	//PhiTextRange *lineRange;
	CFIndex i, count;
	
	line = [self searchLineWithPosition:position selectionAffinity:*affinity inRect:CGRectNull frameNode:&frameNode];
	i = line.index;
	
	i += offset;
	frame = line.frame;
	count = [frame lineCount];
	while (i < 0 && frameNode.previous) {
		//TODO: validate the frame before frameIndex
		frameNode = frameNode.previous;
		frame = frameNode.object;
		count = [frame lineCount];
		i += count;
	}
	//TODO: validate the frame after frameIndex
	while (i >= count && frameNode.next) {
		i -= count;
		frameNode = frameNode.next;
		frame = frameNode.object;
		//TODO: validate the frame after frameIndex
		count = [frame lineCount];
	}
	if (i < 0) {
		newPosition = (PhiTextPosition *)[owner beginningOfDocument];
	} else if (i >= count) {
		newPosition = (PhiTextPosition *)[owner endOfDocument];
	} else {
		CGFloat charOffset = [line offsetForPosition:position];
		line = [frame lineAtIndex:i];
		//lineRange = [line textRange];
		newPosition = [line positionForPoint:CGPointMake(line.originInDocument.x + charOffset, line.originInDocument.y)];
		if ([newPosition compare:(PhiTextPosition *)[[line textRange] end]])
			*affinity = UITextStorageDirectionForward;
		else
			*affinity = UITextStorageDirectionBackward;
		/*/ TODO: DOS Mode and selectionAffinity
#ifdef DEVELOPER
		NSLog(@"stringIndex: %@; lineRange: %@", newPosition, lineRange);
#endif
		if (//[self.store isLineBreakAtIndex:stringIndex - 1] ||
			frame != [self lastEmptyFrame] &&
			([newPosition compare:(PhiTextPosition *)lineRange.end] == NSOrderedSame
			 || [newPosition compare:(PhiTextPosition *)[[frame textRange] end]] == NSOrderedSame
			)
		) {
#ifdef DEVELOPER
			NSLog(@"Adjust position");
#endif
			newPosition = [PhiTextPosition textPositionWithTextPosition:newPosition offset:-1];
		}
		/**/
	}
	}
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@.", traceIndent, __FUNCTION__, newPosition);
#endif
	return newPosition;
}

- (void)buildPath:(CGMutablePathRef)path withFirstRect:(CGRect)firstRect toLastRect:(CGRect)lastRect {
	[self buildPath:path withFirstRect:firstRect toLastRect:lastRect alignPixels:NO toView:nil];
}
- (void)buildPath:(CGMutablePathRef)path withFirstRect:(CGRect)firstRect toLastRect:(CGRect)lastRect alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
	CGFloat midHeight;
	BOOL rowspan = (firstRect.origin.y != lastRect.origin.y);
	BOOL rectifyPixels = rowspan && (lastRect.origin.y - CGRectGetMaxY(firstRect) < lastRect.size.height);

	if (rectifyPixels)
		midHeight = (lastRect.origin.y + CGRectGetMaxY(firstRect)) / 2.0;
	
	if (pixelsAligned) {
		PhiConvertPixelToViewFunction floorPixelToView;
		PhiConvertPixelToViewFunction ceilPixelToView;
		if ([[view layer] isKindOfClass:[CAShapeLayer class]] && [(CAShapeLayer *)[view layer] strokeColor]) {
			floorPixelToView = PhiFloorPixelToCenter;
			ceilPixelToView = PhiCeilPixelToCenter;
		} else {
			floorPixelToView = PhiFloorPixelToEdge;
			ceilPixelToView = PhiCeilPixelToEdge;
		}

		if (rectifyPixels)
			midHeight = floorPixelToView(midHeight, view);

		CGPathMoveToPoint(path, NULL,
						  floorPixelToView(firstRect.origin.x, view),
						  floorPixelToView(firstRect.origin.y, view));
		if (rowspan) {
			CGPathAddLineToPoint(path, NULL,
								 ceilPixelToView(CGRectGetMaxX(self.bounds), view),
								 floorPixelToView(firstRect.origin.y, view));
			CGPathAddLineToPoint(path, NULL,
								 ceilPixelToView(CGRectGetMaxX(self.bounds), view),
								 rectifyPixels?midHeight:ceilPixelToView(lastRect.origin.y, view));
			CGPathAddLineToPoint(path, NULL,
								 ceilPixelToView(CGRectGetMaxX(lastRect), view),
								 rectifyPixels?midHeight:ceilPixelToView(lastRect.origin.y, view));
		} else {
			CGPathAddLineToPoint(path, NULL,
								 ceilPixelToView(CGRectGetMaxX(lastRect), view),
								 rectifyPixels?midHeight:floorPixelToView(lastRect.origin.y, view));
		}
		CGPathAddLineToPoint(path, NULL,
							 ceilPixelToView(CGRectGetMaxX(lastRect), view),
							 ceilPixelToView(CGRectGetMaxY(lastRect), view));
		if (rowspan) {
			CGPathAddLineToPoint(path, NULL,
								 floorPixelToView(self.bounds.origin.x, view),
								 ceilPixelToView(CGRectGetMaxY(lastRect), view));
			CGPathAddLineToPoint(path, NULL,
								 floorPixelToView(self.bounds.origin.x, view),
								 rectifyPixels?midHeight:floorPixelToView(CGRectGetMaxY(firstRect), view));
			CGPathAddLineToPoint(path, NULL,
								 floorPixelToView(firstRect.origin.x, view),
								 rectifyPixels?midHeight:floorPixelToView(CGRectGetMaxY(firstRect), view));
		} else {
			CGPathAddLineToPoint(path, NULL,
								 floorPixelToView(firstRect.origin.x, view),
								 ceilPixelToView(CGRectGetMaxY(lastRect), view));
		}
	} else {
		CGPathMoveToPoint(path, NULL, firstRect.origin.x, firstRect.origin.y);
		if (rowspan) {
			CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.bounds), firstRect.origin.y);
			CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.bounds), rectifyPixels?midHeight:lastRect.origin.y);
		}
		CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(lastRect), rectifyPixels?midHeight:lastRect.origin.y);
		CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(lastRect), CGRectGetMaxY(lastRect));
		if (rowspan) {
			CGPathAddLineToPoint(path, NULL, self.bounds.origin.x, CGRectGetMaxY(lastRect));
			CGPathAddLineToPoint(path, NULL, self.bounds.origin.x, rectifyPixels?midHeight:CGRectGetMaxY(firstRect));
			CGPathAddLineToPoint(path, NULL, firstRect.origin.x, rectifyPixels?midHeight:CGRectGetMaxY(firstRect));
		} else {
			CGPathAddLineToPoint(path, NULL, firstRect.origin.x, CGRectGetMaxY(lastRect));
		}
	}

	CGPathCloseSubpath(path);
}
- (void)buildPath:(CGMutablePathRef)path forRange:(PhiTextRange *)range {
	[self buildPath:path forRange:range alignPixels:NO toView:nil];
}
- (void)buildPath:(CGMutablePathRef)path forRange:(PhiTextRange *)range alignPixels:(BOOL)pixelsAligned toView:(UIView *)view {
	CGRect firstRect = [self firstRectForRange:range];
	CGRect lastRect;
	if (PhiRangeLength(range)) {
		lastRect = [self lastRectForRange:range];
	} else {
		lastRect = firstRect;
	}
	
	[self buildPath:path withFirstRect:firstRect toLastRect:lastRect alignPixels:pixelsAligned toView:view];
}

#pragma mark Hit Testing Methods

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
	return [self closestPositionToPoint:point withinRange:nil];
}
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(PhiTextRange *)range {
#ifdef DEVELOPER
	NSLog(@"%@Entering closestPositionToPoint:(%.f, %.f) withinRange:%@...", traceIndent, point.x, point.y, range);
#endif
	PhiTextPosition *closestPosition = nil;
	@synchronized(store) {
		PhiTextLine *line;
		PhiTextRange *rod = [self textRangeOfDocument];
		
		line = [self searchLineWithRange:range andPoint:point];
		closestPosition = [line positionForPoint:CGPointMake(point.x - [self paddingLeft], point.y - [self paddingTop])];
		
		if (range && [closestPosition compare:(PhiTextPosition *)[range start]] == NSOrderedAscending)
			closestPosition = (PhiTextPosition *)[range start];
		else if (range && [closestPosition compare:(PhiTextPosition *)[range end]] == NSOrderedDescending)
			closestPosition = (PhiTextPosition *)[range end];
		if ([closestPosition compare:(PhiTextPosition *)[rod start]] == NSOrderedAscending)
			closestPosition = (PhiTextPosition *)[range start];
		else if ([closestPosition compare:(PhiTextPosition *)[rod end]] == NSOrderedDescending)
			closestPosition = (PhiTextPosition *)[range end];
		/*/TODO: DOS Mode and selectionAffinity
		PhiTextRange *lineRange = [line textRange];
		if (line.frame != [self lastEmptyFrame]
			&& ![lineRange isEmpty]
			&& PhiPositionOffset(closestPosition) == PhiPositionOffset(lineRange.end) - 1
			&& [self.store isLineBreakAtIndex:PhiPositionOffset(closestPosition)]
		) {
#ifdef DEVELOPER
			NSLog(@"Adjust position");
			NSLog(@"stringIndex: %@; store length: %d", closestPosition, [self.store length]);
#endif
			if ([lineRange isEmpty])
			closestPosition = [PhiTextPosition textPositionWithTextPosition:closestPosition offset:-1];
		}
		/**/
	}
	
#ifdef DEVELOPER
	NSLog(@"%@Exiting closestPositionToPoint:%@.", traceIndent, closestPosition);
#endif
	return closestPosition;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
#ifdef TRACE
	NSLog(@"%@Entering characterRangeAtPoint:%d, %d...", traceIndent, point.x, point.y);
#endif
	PhiTextRange *characterRange = nil;
	PhiTextLine *line;
	PhiTextRange *range;
	PhiTextPosition *position;
	NSUInteger length;

	@synchronized(store) {
		line = [self searchLineWithPoint:point];
		position = [line positionForPoint:CGPointMake(point.x - [self paddingLeft], point.y - [self paddingTop])];
		range = [line textRange];
		length = [self.store length];
	}
	
	//TODO: includeLeading??
	if (CGRectContainsPoint([self rectForLine:line withOffset:CGPointZero includeLeading:YES], point)) {
		if ([position compare:(PhiTextPosition *)range.end] == NSOrderedSame) {
			characterRange = [PhiTextRange textRangeWithPosition:position];
			//TODO: or: characterRange = [PhiTextRange textRangeWithRange:NSMakeRange(MAX(stringIndex - 1, 0), MIN(1, [self.store length]))];?
		} else {
			characterRange = [PhiTextRange textRangeWithRange:NSMakeRange(PhiPositionOffset(position), MIN(1, length))];
		}
	}
	
//	if (!characterRange)
//		characterRange = [PhiTextRange textRangeWithRange:NSMakeRange(0, 0)];
	
	return characterRange;
}

#pragma mark Object Methods

- (id)init {
	if (self = [super init]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"com.phitext"];
		
		Class storageClass = NSClassFromString([defaults stringForKey:@"storageClassName"]);
		if (!storageClass)
			storageClass = [PhiTextStorage class];
		store = [[storageClass alloc] init];
		store.owner = self;
		textFrames = [[PhiAATree alloc] init];
		[self setDefaults];
	}
	return self;
}

#pragma mark Type Setting

- (PhiTextFrame *)makeTextFrameInRect:(CGRect)rect beginningAt:(CFIndex)startIndex {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[PhiTextDocument makeTextFrameInRect:(%.1f, %.1f) (%.1f, %.1f) beginningAt:%d]...", traceIndent, CGRectComp(rect), startIndex);
#endif
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, rect);
	//TODO: recycle textFrames
	PhiTextFrame *textFrame = [PhiTextFrame textFrameInPath:path beginningAt:startIndex forDocument:self];
	[textFrame changeInTextRange];
	CGPathRelease(path);
#ifdef TRACE
	NSLog(@"%@Exiting %s:%@.", traceIndent, __FUNCTION__, textFrame);
#endif
	return textFrame;
}

- (void)invalidateDocument {
	if ([textFrames count]) {
#ifdef TRACE
		NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
		@synchronized(store) {
			[textFrames removeAllObjects];
		}
#ifdef DEVELOPER
		NSLog(@"[%i] Updating editor.", __LINE__);
#endif
		[self.owner performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
		[self performSelectorInBackground:@selector(calculateContentSize) withObject:nil];
#ifdef TRACE
		NSLog(@"%@Exiting %s.", traceIndent, __FUNCTION__);
#endif
	}
}

- (CGRect)invalidateTextFrameRange:(PhiAATreeRange *)range {
#ifdef TRACE
	NSLog(@"%@Entering -[%@ %@:%@]...", traceIndent, NSStringFromClass([self class]), NSStringFromSelector(_cmd), range);
#endif
	CGRect invalidRect = CGRectNull;
	BOOL hasLastEmptyFrame = [self lastEmptyFrame] == self.textFrames.lastObject;
	if (![[self textFrames] isEmpty] && ![range isEmpty]) {
		for (PhiTextFrame *frame in range) {
			invalidRect = PhiUnionRectFrame(invalidRect, frame);
			[frame invalidateFrame];

			if (hasLastEmptyFrame) {
				if (frame == [self lastEmptyFrame]) {
					invalidRect = PhiUnionRectFrame(invalidRect, self.textFrames.lastNode.previous.object);
					[self.textFrames.lastNode.previous.object invalidateFrame];
					break; // We're at the end
				} else if(frame == self.textFrames.lastNode.previous.object) {
					invalidRect = PhiUnionRectFrame(invalidRect, [self lastEmptyFrame]);
					[[self lastEmptyFrame] invalidateFrame];
					break; // We're at the end
				}
			}
		}
	}
	return CGRectOffset(invalidRect, self.paddingLeft, self.paddingTop);
}
/*! Returns the range into the receiver's textFrames that overlap with the specified object, 
 according to the specified comparator. Object is expected to be a:
 1. PhiTextFrame;
 2. PhiTextRange; or
 3. NSValue of CGRect; or
 4. NSValue of NSRange.
 */
- (PhiAATreeRange *)rangeOfTextFramesInTextFrame:(id)object comparator:(PhiTextFrameComparatorFunction)comparator {
	PhiAATreeRange *range = nil;
	if (!textFrames.empty) {
		PhiAATreeNode *start = nil, *end = nil;
		
		start = [textFrames nodeClosestToObject:object withComparator:(CFComparatorFunction)comparator reverse:NO];
		if (start.next) {
			end = [textFrames nodeClosestToObject:object withComparator:(CFComparatorFunction)comparator reverse:YES];
		} else {
			end = start;
		}
		range = [PhiAATreeRange rangeWithStartNode:start andEndNode:end];
	}
	return range;
}

- (PhiAATreeNode *)lastValidTextFrameNode {
	if (lastValidTextFrameNode)
		return lastValidTextFrameNode;
	return [textFrames firstNode];
}

- (void)takeFromLastValidTextFrameNode:(PhiAATreeNode *)node {
	if ((lastValidTextFrameNode && [textFrames compareNode:lastValidTextFrameNode toNode:node] == NSOrderedDescending)
		 || !node
		)
		lastValidTextFrameNode = node;
}

- (void)addToLastValidTextFrameNode:(PhiAATreeNode *)node {
	if ((!lastValidTextFrameNode
		|| [textFrames compareNode:lastValidTextFrameNode toNode:node] == NSOrderedAscending)
		&& node
		)
		lastValidTextFrameNode = node;
}

- (void)invalidateDocumentOutsideOfRect:(CGRect)rect {
#ifdef TRACE
	NSLog(@"%@Entering -[%@ %@:%@]...", traceIndent, NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromCGRect(rect));
#endif
	if (!textFrames.empty && rect.size.width * rect.size.height) {
		CGRect invalidRectUpper = CGRectNull;
		CGRect invalidRectLower = CGRectNull;
		rect = CGRectOffset(rect, -self.paddingLeft, -self.paddingTop);
		@synchronized(store) {
			PhiAATreeRange *range;
			range = [self rangeOfTextFramesInTextFrame:[NSValue valueWithCGRect:rect] comparator:(PhiTextFrameComparatorFunction)PhiTextFrameCompareByRect];
			if (range.end.next) {
				invalidRectLower = [self invalidateTextFrameRange:[PhiAATreeRange rangeWithStartNode:range.end.next andEndNode:textFrames.lastNode]];
			}
			if (range.start.previous)
				invalidRectUpper = [self invalidateTextFrameRange:[PhiAATreeRange rangeWithStartNode:textFrames.firstNode andEndNode:range.start.previous]];
		}
		PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT(invalidRectUpper);
		PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT(invalidRectLower);
	}
}
- (void)invalidateDocumentRect:(CGRect)rect {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[%@ %@:%@]...", traceIndent, NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromCGRect(rect));
#endif
	if (!textFrames.empty
		&& rect.size.width * rect.size.height
	) {
		CGRect invalidRect = CGRectNull;
		rect = CGRectOffset(rect, -self.paddingLeft, -self.paddingTop);
		@synchronized(store) {
			PhiAATreeRange *range;// = NSMakeRange(0, 0);
			range = [self rangeOfTextFramesInTextFrame:[NSValue valueWithCGRect:rect] comparator:(PhiTextFrameComparatorFunction)PhiTextFrameCompareByRect];
			invalidRect = [self invalidateTextFrameRange:range];
		}
		PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT(invalidRect);
	}
}
- (CGRect)invalidateDocumentRange:(PhiTextRange *)textRange {
#ifdef DEVELOPER
	NSLog(@"%@Entering -[%@ %@:%@]...", traceIndent, NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRange([textRange range]));
#endif
	CGRect invalidRect = CGRectNull;
	NSInteger length = [[self store] length];
	NSInteger diff = length - oldLength;
	if (!textFrames.empty) {
		PhiAATreeRange *range;// = NSMakeRange(0, 0);
		range = [PhiAATreeRange rangeForAATree:textFrames withEnclosingObject:textRange withComparator:(CFComparatorFunction)PhiTextFrameCompareByRange];
		invalidRect = [self invalidateTextFrameRange:range];
		[self takeFromLastValidTextFrameNode:range.start.previous];
	}
	diffLength += diff;
	invalidRange = NSUnionRange(invalidRange, NSMakeRange(PhiRangeOffset(textRange) + (diff<0?diff:0), ABS(diff)));
	return invalidRect;
}
- (CGRect)invalidateDocumentNSRange:(NSRange)range {
	return [self invalidateDocumentRange:[PhiTextRange textRangeWithRange:range]];
}
- (void)setSize:(CGSize)size invalidate:(BOOL)invalidate {
	CGSize contentSize = [self size];
	if (!CGSizeEqualToSize(contentSize, size)) {
		[owner setContentSize:size];
		[(PhiTextEmptyFrame *)[self lastEmptyFrame] setWidth:size.width - [self paddingLeft] - [self paddingRight]];
		[self.owner.selectionView setNeedsLayout];
		if (invalidate) {
			[self invalidateDocument];
		}
	}
}
- (void)calculateContentSize {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[self setSize:[self suggestTextSize] invalidate:NO];
    [pool release];
}
- (void)setSize:(CGSize)size {
	[self setSize:size invalidate:YES];
}
//Adjust editor's contentSize
- (void)adjustHeightToTextFrame:(PhiTextFrame *)textFrame exansionOnly:(BOOL)exansionOnly {
	BOOL needsExpansion = NO;
	CGRect rect = [textFrame CGRectValue];
	CGSize newSize = [self size];
	CGFloat newHeight = CGRectGetMaxY(rect) + [self paddingTop] + [self paddingBottom];
	
	if (newSize.height < newHeight)
		needsExpansion = YES;
	newSize.height = newHeight;
	if (needsExpansion || !exansionOnly)
		[self setSize:newSize invalidate:NO];
}
- (void)adjustWidthToTextFrame:(PhiTextFrame *)textFrame exansionOnly:(BOOL)exansionOnly {
	BOOL needsExpansion = NO;
	CGSize newSize = [self size];
	if (!self.wrap || !exansionOnly) {
		CGFloat newWidth = [textFrame realWidth];
		newWidth += [self paddingLeft] + [self paddingRight];
		if (newWidth > newSize.width)
			needsExpansion = YES;
		newSize.width = newWidth;
	}
	if (needsExpansion || !exansionOnly)
		[self setSize:newSize invalidate:NO];
	if (needsExpansion)
		[[self owner] flashScrollIndicators];
}
- (void)adjustSizeToTextFrame:(PhiTextFrame *)textFrame exansionOnly:(BOOL)exansionOnly {
	[self adjustHeightToTextFrame:textFrame exansionOnly:exansionOnly];
	[self adjustWidthToTextFrame:textFrame exansionOnly:exansionOnly];
}
- (void)adjustSizeToTextFrame:(PhiTextFrame *)textFrame {
	[self adjustSizeToTextFrame:textFrame exansionOnly:NO];
}
- (CGSize)size {
	CGSize contentSize = [(UIScrollView *)self.owner contentSize];
	return contentSize;
}
- (CGRect)bounds {
	CGSize contentSize = [self size];
	CGRect bounds = CGRectMake([self paddingLeft], [self paddingTop], contentSize.width - [self paddingLeft] - [self paddingRight], contentSize.height - [self paddingTop] - [self paddingBottom]);
	return bounds;
}
- (void)setPaddingTop:(CGFloat)padding {
	if (paddingTop != padding) {
		paddingTop = padding;
		[owner setNeedsDisplay];
	}
}
- (void)setPaddingLeft:(CGFloat)padding {
	if (paddingLeft != padding) {
		paddingLeft = padding;
		[owner setNeedsDisplay];
	}
}
- (void)setPaddingBottom:(CGFloat)padding {
	if (paddingBottom != padding) {
		paddingBottom = padding;
		[owner setNeedsDisplay];
	}
}
- (void)setPaddingRight:(CGFloat)padding {
	if (paddingRight != padding) {
		paddingRight = padding;
		[owner setNeedsDisplay];
	}
}
- (void)setCurrentColor:(UIColor *)color {
	if (![currentColor isEqual:color]) {
		[currentColor release];
		currentColor = [color retain];
		[owner setNeedsDisplay];
	}
}

/*!
 */
- (PhiAATreeRange *)beginContentAccessInRect:(CGRect)rect updateDisplay:(BOOL)shouldUpdateDisplay {
	return [self beginContentAccessInRange:nil andRect:rect updateDisplay:shouldUpdateDisplay];
}
- (PhiAATreeRange *)beginContentAccessInRect:(CGRect)rect {
	return [self beginContentAccessInRange:nil andRect:rect updateDisplay:YES];
}
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range updateDisplay:(BOOL)shouldUpdateDisplay {
	return [self beginContentAccessInRange:range andRect:CGRectZero updateDisplay:shouldUpdateDisplay];
}
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range {
	return [self beginContentAccessInRange:range andRect:CGRectZero updateDisplay:YES];
}
- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range andRect:(CGRect)rect {
	return [self beginContentAccessInRange:range andRect:rect updateDisplay:YES];
}

#define PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(_RECT_) if (shouldUpdateDisplay) PHI_SET_OWNER_NEEDS_DISPLAY_IN_RECT(CGRectOffset(_RECT_, self.paddingLeft, self.paddingTop))

- (PhiAATreeRange *)beginContentAccessInRange:(PhiTextRange *)range andRect:(CGRect)rect updateDisplay:(BOOL)shouldUpdateDisplay {
	if (range)
		range = [self.owner clampTextRange:range];
#ifdef DEVELOPER
	NSLog(@"%@Entering -[PhiTextDocument beginContentAccessInRange:%@ andRect:%@]...", traceIndent, range, NSStringFromCGRect(rect));
#endif
	PhiAATreeNode *firstNode = nil, *lastNode = nil;
	PhiTextFrame *textFrame;
	CGRect tileBounds = [self suggestTileBounds];
	CGRect invalidRect = CGRectNull;
	CFIndex startIndex;
	NSUInteger startLineNumber;
	CGFloat yMax = NAN;
	
	if (!([textFrames isEmpty] || [[textFrames firstNode] object] == [self lastEmptyFrame]) && ![[self store] length])
		[self invalidateDocument];

	if (!(CGRectEqualToRect(CGRectZero, rect) || CGRectEqualToRect(CGRectNull, rect)))
		yMax = CGRectGetMaxY(rect);

	// Kick off if we dont have any frames
	if ([textFrames isEmpty] || [[textFrames firstNode] object] == [self lastEmptyFrame]) {
		if ([[self store] length]) {
			if (![textFrames isEmpty])
				[textFrames removeAllObjects];
			diffLength = 0;
			textFrame = [[self makeTextFrameInRect:tileBounds beginningAt:0] autoEndContentAccess];
			[textFrames addObject:textFrame];
			PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(tileBounds);
		} else if ([textFrames isEmpty]) {
			[textFrames addObject:[self lastEmptyFrame]];
			[self lastEmptyFrame].origin = tileBounds.origin;
		}
	}

	// Find first frame... (binary search with shortcut)
	if ([textFrames count] == 1) {
		// ...that was easy
		firstNode = [textFrames firstNode];
	} else {
		PhiAATreeRange *validFrameRange = [PhiAATreeRange rangeWithStartNode:[textFrames firstNode] andEndNode:[self lastValidTextFrameNode]];
		
		if (validFrameRange.singleton) {
			firstNode = validFrameRange.start;
		} else {
			// Use the appropriate nodeClosestToObject
			if (CGRectEqualToRect(CGRectZero, rect) || CGRectEqualToRect(CGRectNull, rect)) {
				if (!range)
					firstNode = [textFrames firstNode];
				else
					firstNode = [textFrames nodeClosestToObject:range
														inRange:validFrameRange
												 withComparator:(CFComparatorFunction)PhiTextFrameCompareByRange reverse:NO];
			} else {
				if (!range)
					firstNode = [textFrames nodeClosestToObject:[NSValue valueWithCGRect:rect]
														inRange:validFrameRange
												 withComparator:(CFComparatorFunction)PhiTextFrameCompareByRect reverse:NO];
				else
					firstNode = [textFrames nodeClosestToObject:range withComparator:(CFComparatorFunction)PhiTextFrameCompareByRangeIn
													  andObject:[NSValue valueWithCGRect:rect] withComparator:(CFComparatorFunction)PhiTextFrameCompareByRectIn
														inRange:validFrameRange
														reverse:NO];
			}
		}
#ifdef DEVELOPER		
		NSAssert(firstNode, @"Failed to obtain any node from the tree of frames.");
#endif
		// When searching with range, first frame must not be the special lastEmptyFrame
		//  also, when searching with rect lastEmptyFrame may not be contiguous hence it may be way off
		if (firstNode.object == [self lastEmptyFrame]
			 && ((range && PhiRangeOffset(range) != [[self store] length])
				 || (PhiPositionOffset([[firstNode.previous.object textRange] end]) != PhiFrameOffset(firstNode.object))
				 )
			)
			// Note firstNode.previous exists because we have more than one frame (assuming lastEmptyFrame is the last frame, which it should be)
			firstNode = firstNode.previous;
	}

	// Find last frame (sequential search (starting at first frame), create frames if needed)
	lastNode = firstNode;
	textFrame = (PhiTextFrame *)lastNode.object; //current frame
	invalidRect = [textFrame CGRectValue];
	// Setup first string index and frame rect of the next frame
	startIndex = PhiPositionOffset([[textFrame textRange] end]);
	startLineNumber = [textFrame firstLineNumber] + [textFrame lineCount];
	tileBounds.origin.y = CGRectGetMaxY([textFrame rect]);
	if (tileBounds.size.width && tileBounds.size.height) {
		//Advance lastNode forward through text frames (beginning content access OR advancing firstNode where appropriate)
		if (startIndex < [[self store] length]) do {
			// If no next frame then create one, autoEndContentAccess
			// If next frame is lastEmptyFrame then replace it, autoEndContentAccess
			if (lastNode.next && lastNode.next.object == [self lastEmptyFrame])
				[textFrames pruneAtNode:lastNode.next];
			if (!lastNode.next) {
				diffLength = 0;
				[textFrame changeInTextRange];
				PhiTextFrame *newTextFrame = [self makeTextFrameInRect:CGRectMake(0, 0, tileBounds.size.width, tileBounds.size.height)
														   beginningAt:startIndex];
				[newTextFrame setFirstLineNumber:startLineNumber];
				[textFrames addObject:newTextFrame];
				[newTextFrame autoEndContentAccess];
				//NSAssert(lastNode.next != nil, @"New created text frame not appended to tree.");
			}
			// If next frame is noncontiguous then create one, autoEndContentAccess
			// Otherwise, next frame is ok, continue
			else {
				CFIndex endIndex = PhiFrameOffset(lastNode.next.object);
				CFIndex diff = [textFrame changeInTextRange];
				diffLength -= diff;
				if (startIndex != endIndex) {
					if (diffLength) {
						BOOL flag = NO;
						//flag = [self.store isLineBreakAtIndex:endIndex - 1];
						// If there is a line break (before and after change) then it is easy: only the current frames needs to change it's text
						if (flag) {
							startIndex = endIndex + diff;
							endIndex = PhiFrameOffset(textFrame);
							[textFrame setTextRange:[PhiTextRange textRangeWithRange:NSMakeRange
													 (endIndex, startIndex - endIndex)]];
							endIndex = PhiPositionOffset([[textFrame textRange] end]);
							if (startIndex != endIndex) {
								invalidRect = [lastNode.next.object CGRectValue];
								[lastNode.next.object invalidateFrame];
								PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
								startIndex = endIndex;
							}
							diffLength -= [textFrame changeInTextRange];
							tileBounds.origin.y = CGRectGetMaxY([textFrame rect]);
						}
						// otherwise the next frame needs to change
						else {
							invalidRect = [lastNode.next.object CGRectValue];
							[lastNode.next.object invalidateFrame];
							PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
						}
					}
					[(PhiTextFrame *)lastNode.next.object setFirstStringIndex:startIndex];
					[(PhiTextFrame *)lastNode.next.object setFirstLineNumber:startLineNumber];
				}
			}
			
			if (!(startIndex < [self.store length] // startIndex is before the last charater ie next frame is possible
				&& (
					(isnan(yMax) || CGRectGetMaxY([textFrame rect]) < yMax)
					&&
					(!range || startIndex <= PhiPositionOffset([range end]))
					)
				))
				break;
			
			// Advance firstNode if necessary, otherwise we'll need to beginConentAccess on the frames after the first
			if (firstNode == lastNode && (range || !isnan(yMax)) &&
				(
				 (!isnan(yMax) && CGRectGetMaxY([(PhiTextFrame *)firstNode.object rect]) < rect.origin.y)
				 ||
				 (range && PhiPositionOffset([[(PhiTextFrame *)firstNode.object textRange] end]) < PhiRangeOffset(range))
				)
			)
				firstNode = firstNode.next;
			
			// Advance lastNode
			lastNode = lastNode.next;
			textFrame = (PhiTextFrame *)lastNode.object;
			
			invalidRect = [textFrame CGRectValue];
			if (CGRectEqualToRect(invalidRect, CGRectNull)
				|| !CGPointEqualToPoint(invalidRect.origin, tileBounds.origin)) {
				//TODO: setNeeds(Display|Layout) on owner
				if ([textFrame beginContentAccess])
					[textFrame autoEndContentAccess];
				textFrame.origin = tileBounds.origin;
				invalidRect = PhiUnionRectFrame(invalidRect, textFrame);
				PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
			} else if (diffLength // need to check diffLength since rect will not always change (consider one line per frame)
					   || !CGRectEqualToRect(invalidRect, [textFrame rect])) {
				invalidRect = PhiUnionRectFrame(invalidRect, textFrame);
				PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
			}
			
			if (firstNode != lastNode)
				if (![textFrame beginContentAccess])
					break;
			
			startIndex += PhiRangeLength(textFrame.textRange);
			startLineNumber += [textFrame lineCount];
			tileBounds.origin.y += textFrame.size.height;
		} while (startIndex < [[self store] length]);
		// Otherwise no need to advance lastNode, check if it's rect needs redisplay
		else if (CGRectEqualToRect(invalidRect, CGRectNull)
				 || !CGRectEqualToRect(invalidRect, [textFrame rect])) {
			invalidRect = PhiUnionRectFrame(invalidRect, textFrame);
			PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
		}
		if (startIndex >= [[self store] length] && lastNode.next && lastNode.next.object != [self lastEmptyFrame]) {
			[textFrames pruneAtNode:lastNode.next];
			//TODO: finer setNeedsDisplay...
#ifdef DEVELOPER
			NSLog(@"[%i] Updating editor.", __LINE__);
#endif
			[self.owner performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
			[self.owner performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
		}
		
		//Advance (backward) firstNode through text frames (beginning content access), just in case  
		textFrame = (PhiTextFrame *)firstNode.object;
		startIndex = PhiFrameOffset(textFrame);
		//startLineNumber = [textFrame firstLineNumber];
		tileBounds.origin.y = CGRectGetMinY([textFrame rect]) - tileBounds.size.height;
		while (startIndex > 0 // startIndex is after the first character ie previous frame is possible
			   && (
				   (isnan(yMax) || CGRectGetMinY([textFrame rect]) > rect.origin.y)
				   &&
				   (!range || startIndex > PhiRangeOffset(range))
				   )
			   ) {
			// If no previous frame then create one
			if (!firstNode.previous) {
				//TODO: Need to build frames backwards
				NSLog(@"TODO: Need to build frames backwards..."); break;
			} else {
				CFIndex endIndex = PhiPositionOffset([[firstNode.previous.object textRange] end]);
				// If previous frame is noncontiguous then fix it
				if (startIndex != endIndex) {
					//TODO: Need to fix frames backwards
					NSLog(@"TODO: Need to fix frames backwards..."); break;
				}
			}
			// Otherwise, previous frame is ok, continue
			
			if (![textFrame beginContentAccess])
				break;

			// Advance firstNode
			firstNode = firstNode.previous;
			textFrame = (PhiTextFrame *)firstNode.object;
			startIndex = PhiFrameOffset(textFrame);
			//startLineNumber = [textFrame firstLineNumber];
		}
		// Finally beginContentAccess on first frame
		[textFrame beginContentAccess];
		
		// But wait, check if lastEmptyFrame is needed...
		textFrame = (PhiTextFrame *)lastNode.object;
		if (textFrame == [self lastEmptyFrame]) {
			[self addToLastValidTextFrameNode:lastNode.previous];
			
			// Is it needed?
			if (![[self store] isLineBreakAtIndex:[[self store] length] - 1] && lastNode.previous) {
				// Not needed, lob it off
				PhiAATreeNode *cut = lastNode;
				lastNode = lastNode.previous;
				[textFrames pruneAtNode:cut];
			} else if (lastNode.previous) {
				tileBounds = [(PhiTextFrame *)lastNode.previous.object rect];
				tileBounds.origin.y += tileBounds.size.height;
				startLineNumber = [(PhiTextFrame *)lastNode.previous.object firstLineNumber] + [(PhiTextFrame *)lastNode.previous.object lineCount];
				if (!CGPointEqualToPoint(textFrame.origin, tileBounds.origin)) {
					//TODO: setNeeds(Display|Layout) on owner
					invalidRect = [textFrame CGRectValue];
					textFrame.origin = tileBounds.origin;
					invalidRect = PhiUnionRectFrame(invalidRect, textFrame);
					PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
				}
				[textFrame setFirstLineNumber:startLineNumber];
			}
		}
		else {
			[self addToLastValidTextFrameNode:lastNode];
			
			// Is it needed?
			if ([[self store] isLineBreakAtIndex:[[self store] length] - 1]) {
				// Is it needed right now?
				if (PhiPositionOffset(textFrame.textRange.end) == [[self store] length]) {
					tileBounds = [textFrame rect];
					tileBounds.origin.y += tileBounds.size.height;
					startLineNumber = [textFrame firstLineNumber] + [textFrame lineCount];
					textFrame = [self lastEmptyFrame];
					invalidRect = CGRectNull;
					if ([[textFrames lastNode] object] == textFrame)
						invalidRect = [textFrame CGRectValue];
					if (lastNode.next && lastNode.next.object != textFrame)
						[textFrames pruneAtNode:lastNode.next];
					// Does it need to be added?
					if ([[textFrames lastNode] object] != textFrame)
						[textFrames addObject:textFrame];
					if (!CGPointEqualToPoint(textFrame.origin, tileBounds.origin)) {
						textFrame.origin = tileBounds.origin;
						invalidRect = PhiUnionRectFrame(invalidRect, textFrame);
						PHI_WILL_OWNER_NEED_DISPLAY_IN_RECT_AND_RANGE(invalidRect);
					}
					[textFrame setFirstLineNumber:startLineNumber];
					// Should we include it in the search results?
					if ((!range || PhiFrameOffset(textFrame) == PhiPositionOffset([range end])) && (isnan(yMax) || yMax > tileBounds.origin.y)) {
						lastNode = lastNode.next;
						[(PhiTextFrame *)lastNode.object beginContentAccess];
					}
				}
			} else if ([[textFrames lastNode] object] == [self lastEmptyFrame]) {
				// Not needed, lob it off
				[textFrames pruneAtNode:[textFrames lastNode]];
			}
		}
	} else {
		[(PhiTextFrame *)lastNode.object beginContentAccess];
	}
#ifdef DEVELOPER
	NSLog(@"Validated frames from %@ to %@", firstNode, lastNode);
#endif
    //Originally returned lastNode
	return [PhiAATreeRange rangeWithStartNode:firstNode andEndNode:lastNode];
}

- (CGSize)approximateTextSize {
	//TODO: use the length of string or count new lines 
	return [self suggestTextSize];
}
- (CGSize)suggestTextSize {
	if (self.wrap)
		return [self suggestTextSizeWithConstraints:CGSizeMake([self size].width, CGFLOAT_MAX)];
	return [self suggestTextSizeWithConstraints:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}
- (CGSize)suggestTextSizeWithConstraints:(CGSize)constraints {
#ifdef TRACE
	NSLog(@"%@Entering %s...", traceIndent, __FUNCTION__);
#endif
	CTFramesetterRef framesetter;
	CGSize size;

	if (constraints.width != CGFLOAT_MAX)
		constraints.width -= self.paddingLeft + self.paddingRight;
	if (constraints.height != CGFLOAT_MAX)
		constraints.height -= self.paddingTop + self.paddingBottom;
	
	framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)[self.store attributedString]);
	size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, constraints, NULL);
	CFRelease(framesetter);
	
	if (0.0 >= size.width || size.width > constraints.width)
		size.width = constraints.width;

	size.width += self.paddingLeft + self.paddingRight;
	size.height += self.paddingTop + self.paddingBottom;
#ifdef TRACE
	NSLog(@"%@Exiting %s:(%.f, %.f).", traceIndent, __FUNCTION__, size.width, size.height);
#endif
	return size;
}

#pragma mark Styling Methods

- (PhiTextStyle *)defaultStyle {
	if (!defaultStyle) {
		defaultStyle = [[PhiTextStyle alloc] init];
		
		CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 17.4, NULL);
		defaultStyle.font = [PhiTextFont fontWithCTFont:font];
		CFRelease(font);
		
		defaultStyle.color = [[self currentColor] CGColor];
	}
	
	return defaultStyle;
}

- (void)addDefaultStyle:(PhiTextStyle *)style {
	[self setDefaultStyle:[[self defaultStyle] styleWithAddedStyle:style]];
}

- (PhiTextStyle *)styleAtEndOfDocument {
	PhiTextStyle *style;
	if (![self.store length]) {
		style = [self defaultStyle];
	} else {
		NSDictionary *attributes;
		attributes = [self.store attributesAtIndex:[self.store length] - 1 effectiveRange:NULL];
		style = [PhiTextStyle styleWithDictionary:attributes];
	}	
	return style;
}

- (PhiTextStyle *)styleFromPosition:(PhiTextPosition *)position toEffectivePosition:(PhiTextPosition **)endPtr {
	PhiTextStyle *style;
	PhiTextRange *rod = [self textRangeOfDocument];
	if ([position isEqual:[rod end]]) {
		style = [self defaultStyle];
		if (endPtr)
			*endPtr = [[[rod end] copy] autorelease];
	} else {
		NSDictionary *attributes;
		NSRange range;
		if (endPtr) {
			attributes = [self.store attributesAtIndex:PhiPositionOffset(position) effectiveRange:&range];
			*endPtr = [PhiTextPosition textPositionWithPosition:NSMaxRange(range)];
		} else {
			attributes = [self.store attributesAtIndex:PhiPositionOffset(position) effectiveRange:NULL];
		}
		
		style = [PhiTextStyle styleWithDictionary:attributes];
	}	
	
	return style;
}
- (PhiTextStyle *)styleFromPosition:(PhiTextPosition *)position toFarthestEffectivePosition:(PhiTextPosition **)endPtr notBeyondPosition:(PhiTextPosition *)limitingPosition {
	PhiTextStyle *style;
	PhiTextRange *rod = [self textRangeOfDocument];
	if ([position isEqual:[rod end]]) {
		style = [self defaultStyle];
		if (endPtr)
			*endPtr = [[[rod end] copy] autorelease];
	} else {
		NSDictionary *attributes;
		NSRange range;
		NSRange limitRange = NSMakeRange(PhiPositionOffset(position), PhiPositionOffset(limitingPosition) - PhiPositionOffset(position));
		if (endPtr) {
			attributes = [self.store attributesAtIndex:PhiPositionOffset(position) longestEffectiveRange:&range inRange:limitRange];
			*endPtr = [PhiTextPosition textPositionWithPosition:NSMaxRange(range)];
		} else {
			attributes = [self.store attributesAtIndex:PhiPositionOffset(position) effectiveRange:NULL];
		}
		
		style = [PhiTextStyle styleWithDictionary:attributes];
	}	
	
	return style;
}
- (PhiTextStyle *)styleAtPosition:(PhiTextPosition *)position inDirection:(UITextStorageDirection)direction {
	PhiTextStyle *style;
	PhiTextRange *rod = [self textRangeOfDocument];
	if (![self.store length]
		|| (direction == UITextStorageDirectionForward && [position isEqual:[rod end]])) {
		style = [self defaultStyle];
	} else {
		NSDictionary *attributes;
		if (direction == UITextStorageDirectionBackward) {
			attributes = [self.store attributesAtIndex:PhiPositionOffset(position) - 1 effectiveRange:NULL];
		} else {
			attributes = [self.store attributesAtIndex:PhiPositionOffset(position) effectiveRange:NULL];
		}
		style = [PhiTextStyle styleWithDictionary:attributes];
	}	
	
	return style;
}

- (void)setStyle:(PhiTextStyle *)style range:(PhiTextRange *)range {
	PhiTextRange *rod = [self textRangeOfDocument];
	if ([[range end] isEqual:[rod end]])
		[self setDefaultStyle:style];
	if ([range length]) {
		[self.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerStylingGroupingType];
		[self.store setAttributes:(NSDictionary *)style.attributes range:PhiRangeRange(range)];
	} //else TODO: redisplay caret and/or line with new line height
}

- (void)addStyle:(PhiTextStyle *)style range:(PhiTextRange *)range {
	PhiTextRange *rod = [self textRangeOfDocument];
	if ([[range end] isEqual:[rod end]])
		[self addDefaultStyle:style];
	if ([range length]) {
		[self.undoManager ensureUndoGroupingBegan:PhiTextUndoManagerStylingGroupingType];
		[self.store addAttributes:(NSDictionary *)style.attributes range:PhiRangeRange(range)];
	} //else TODO: redisplay caret and/or line with new line height
}

#pragma mark Memory Management

- (void)cache:(/*NSCache */id)cache willEvictObject:(id)textFrame {
	if ([lastValidTextFrameNode object] == textFrame)
		lastValidTextFrameNode = nil;
	
	//TODO: recycle textFrame
}

- (void)dealloc {
	if (textFrames) {
		[textFrames release];
		textFrames = nil;
	}
	if (store) {
		[store release];
		store = nil;
	}
	if (lastEmptyFrame) {
		[lastEmptyFrame release];
		lastEmptyFrame = nil;
	}
	[self setDefaultStyle:nil];
	[self setCurrentColor:nil];
    [super dealloc];
}

@end





