//
//  PhiTestCaseViewController.m
//  PhiTestCase
//
//  Created by Philippe Hausler on 3/28/10.
//  Copyright Philippe Hausler 2010. All rights reserved.
//

#import "PhiTestCaseViewController.h"

@implementation PhiTestCaseViewController

- (IBAction)applyStyle:(id)sender {
	[editor setTextStyleForSelectedRange:textStyle];
}

- (PhiTextRange *)rangeOfVisibleCharactersUsingCharacterRangeAtPoint {
	CGRect visibleRect = CGRectIntersection(editor.bounds, [[editor textDocument] bounds]);
	CGPoint top = visibleRect.origin;
	CGPoint bot = CGPointMake(CGRectGetMaxX(visibleRect), CGRectGetMaxY(visibleRect));
	PhiTextRange *first = (PhiTextRange *)[editor.textDocument characterRangeAtPoint:top];
	PhiTextRange *last  = (PhiTextRange *)[editor.textDocument characterRangeAtPoint:bot];
	PhiTextRange *visibleRange = (PhiTextRange *)[editor textRangeFromPosition:first.start toPosition:last.end];
	return visibleRange;
}
- (PhiTextRange *)rangeOfVisibleCharactersUsingClosestPositionToPoint {
	CGPoint top = CGPointMake(CGRectGetMinX(editor.bounds), CGRectGetMinY(editor.bounds));
	CGPoint bot = CGPointMake(CGRectGetMaxX(editor.bounds), CGRectGetMaxY(editor.bounds));
	PhiTextPosition *first = (PhiTextPosition *)[editor.textDocument closestPositionToPoint:top];
	PhiTextPosition *last  = (PhiTextPosition *)[editor.textDocument closestPositionToPoint:bot];
	PhiTextRange *visibleRange = (PhiTextRange *)[editor textRangeFromPosition:first toPosition:last];
	return visibleRange;
}
- (CGRect)rectForRange:(PhiTextRange *)range {
	CGRect rv = CGRectNull;

	CGMutablePathRef path = CGPathCreateMutable();
	[[editor textDocument] buildPath:path forRange:range];
	rv = CGPathGetBoundingBox(path);
	CGPathRelease(path);

	return rv;
}
- (void)textViewDidChangeSelection:(PhiTextEditorView *)theTextView {
	[self updateTokenizer:nil];
}
- (void)scrollViewDidScroll:(PhiTextEditorView *)theTextView {
	PhiTextRange *vrcr = [self rangeOfVisibleCharactersUsingCharacterRangeAtPoint];
	PhiTextRange *vrcp = [self rangeOfVisibleCharactersUsingClosestPositionToPoint];
	
	vrcrOffset.text = [NSString stringWithFormat:@"%d", PhiRangeOffset(vrcr)];
	vrcrLength.text = [NSString stringWithFormat:@"%d", PhiRangeLength(vrcr)];

	vrcpOffset.text = [NSString stringWithFormat:@"%d", PhiRangeOffset(vrcp)];
	vrcpLength.text = [NSString stringWithFormat:@"%d", PhiRangeLength(vrcp)];
}
- (void)textViewDidChange:(PhiTextEditorView *)theTextView {
	[self updateRectForRange:nil];
	[self scrollViewDidScroll:theTextView];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIScrollView *infoPanel = (UIScrollView *)[self.view viewWithTag:1];
	[infoPanel setContentSize:CGSizeMake(infoPanel.bounds.size.width, 1000.0)];
	
	[textStyleController.view setFrame:CGRectMake(428, 488, 320, 255)];
	[self.view addSubview:textStyleController.view];
	
//	[editor setEnableMenuPaging:YES];
//	[editor addCustomMenuItem:[[[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteAtSelectedTextRange)] autorelease] atPage:1];

	//[[self.editor textDocument] setStore:[[PhiTextStorage alloc] initWithString:@"Test "]];
	//[[self.editor textDocument] setWrap:NO];
//	editor.contentSize = editor.bounds.size;
//	editor.editable = YES;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	CGFloat tileWidthHint = [defaults floatForKey:@"tileWidthHint"];
	CGFloat tileHeightHint = [defaults floatForKey:@"tileHeightHint"];
	CGFloat frameHeightHint = [defaults floatForKey:@"frameTileHeightHint"];
	
	tileWidthSlider.value = tileWidthHint;
	tileHeightSlider.value = tileHeightHint;
	heightHintSlider.value = frameHeightHint;
	[self changeTileWidth:nil];
	[self changeTileHeight:nil];
	[self changeHeightHint:nil];
	[self textViewDidChange:nil];
	
	editor.delegate = self;
}

- (IBAction)editorColorDidChange {
	if (editor) {
		editor.backgroundColor = [backgroundColorPatch.color colorWithAlphaComponent:alphaSlider.value];
	}
}

- (IBAction)textViewColorDidChange {
	if (textView) {
		textView.backgroundColor = [textViewBackgroundColorPatch.color colorWithAlphaComponent:textViewAlphaSlider.value];
	}
}
- (IBAction)updateTokenizer:(id)sender {
	UITextGranularity g = UITextGranularityWord + granularity.selectedSegmentIndex;
	UITextPosition *p = editor.selectedTextRange.end;
	postionLabel.text = [NSString stringWithFormat:@"%i", PhiPositionOffset(p)];
	atBoundaryBackward.on = [editor.tokenizer isPosition:p atBoundary:g inDirection:UITextStorageDirectionBackward];
	atBoundaryForward.on  = [editor.tokenizer isPosition:p atBoundary:g inDirection:UITextStorageDirectionForward];
	withinTextUnitBackward.on = [editor.tokenizer isPosition:p withinTextUnit:g inDirection:UITextStorageDirectionBackward];
	withinTextUnitForward.on  = [editor.tokenizer isPosition:p withinTextUnit:g inDirection:UITextStorageDirectionForward];
	toBoundaryBackward.text = [NSString stringWithFormat:@"%i", PhiPositionOffset([editor.tokenizer positionFromPosition:p toBoundary:g inDirection:UITextStorageDirectionBackward])];
	toBoundaryForward.text  = [NSString stringWithFormat:@"%i", PhiPositionOffset([editor.tokenizer positionFromPosition:p toBoundary:g inDirection:UITextStorageDirectionForward])];
}
- (IBAction)updateRectForRange:(id)sender {
	NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
	CGRect rr = [self rectForRange:[PhiTextRange textRangeWithRange:NSMakeRange
									([[format numberFromString:rrOffset.text] intValue],
									 [[format numberFromString:rrLength.text] intValue])]];
	rrX.text = [NSString stringWithFormat:@"%.0f", rr.origin.x];
	rrY.text = [NSString stringWithFormat:@"%.0f", rr.origin.y];
	rrWidth.text = [NSString stringWithFormat:@"%.0f", rr.size.width];
	rrHeight.text = [NSString stringWithFormat:@"%.0f", rr.size.height];
}

- (IBAction)toggleWrap {
	if (editor) {
		editor.textDocument.wrap = !editor.textDocument.wrap;
	}
}

- (IBAction)toggleEditable {
	if (editor) {
		editor.editable = !editor.editable;
	}
}

- (IBAction)toggleOpacity:(id)sender {
	if (editor) {
		editor.opaque = !editor.opaque;
	}
}

- (IBAction)changeTileHeight:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];

	CGFloat tileHeightHint = ceilf(tileHeightSlider.value);
	
	[defaults setFloat:tileHeightHint forKey:@"tileHeightHint"];
	
	tileHeightLabel.text = [NSString stringWithFormat:@"%.0f", tileHeightHint];
}

- (IBAction)changeTileWidth:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	CGFloat tileWidthHint = ceilf(tileWidthSlider.value);
	if (1024 - 4 <= tileWidthHint && tileWidthHint <= 1024 + 4) {
		tileWidthHint = 1024;
		tileWidthLabel.textColor = [UIColor blackColor];
	} else
	if (768 - 4 <= tileWidthHint && tileWidthHint <= 768 + 4) {
		tileWidthHint = 768;
		tileWidthLabel.textColor = [UIColor blackColor];
	} else
	if (640 - 4 <= tileWidthHint && tileWidthHint <= 640 + 4) {
		tileWidthHint = 640;
		tileWidthLabel.textColor = [UIColor blackColor];
	} else
	if (320 - 4 <= tileWidthHint && tileWidthHint <= 320 + 4) {
		tileWidthHint = 320;
		tileWidthLabel.textColor = [UIColor blackColor];
	} else {
		tileWidthLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1.0];
	}
	
	[defaults setFloat:tileWidthHint forKey:@"tileWidthHint"];
	tileWidthLabel.text = [NSString stringWithFormat:@"%.0f", tileWidthHint];
}

- (IBAction)changeHeightHint:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.phitext"];
	
	CGFloat tileHeightHint = ceilf(heightHintSlider.value);
	
	[defaults setFloat:tileHeightHint forKey:@"frameTileHeightHint"];
	
	heightHintLabel.text = [NSString stringWithFormat:@"%.0f", tileHeightHint];
}

- (IBAction)clearText {
	CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 17.4, NULL);
	CFStringRef keys[] = {
		kCTFontAttributeName,
		kCTForegroundColorAttributeName
	};
	CFTypeRef values[] = {
		font,
		[[UIColor blackColor] CGColor]
	};
	CFDictionaryRef attr = CFDictionaryCreate(NULL, (void *)keys, (void *)values, 2,
											  &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
/**/

	NSMutableAttributedString *textStore = [[NSMutableAttributedString alloc] initWithString:@""
																				   attributes:(NSDictionary *)attr];
	CFRelease(attr);
	CFRelease(font);
	
	// Replace the document's store and the document is notified
	[editor.textDocument.store setAttributedString:textStore];
	[textStore release];
	// ...but the editor view is not, hence we need to consider what is selected
	// Easiest option is to set it to nil (or beginningOfDocument is good)
	[editor changeSelectedRange:nil];
	// Same as:
	//[editor changeSelectedRange:nil scroll:NO];
}

- (IBAction)copyText {
	[textView selectAll:nil];
	[textView copy:nil];
	[editor selectAll:nil];
	[editor paste:nil];
}

- (IBAction)loadText {
	CTParagraphStyleSetting setting;
	CGFloat paraSpacing = 25;
	CTFontRef font = CTFontCreateWithName(CFSTR("Trebuchet MS"), 17.0, NULL);
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"txt"];
	
	setting.spec = kCTParagraphStyleSpecifierParagraphSpacing;
	setting.spec = kCTParagraphStyleSpecifierMinimumLineHeight;
	setting.valueSize = sizeof(CGFloat);
	setting.value = &paraSpacing;
	
	CFStringRef keys[] = {
		kCTParagraphStyleAttributeName,
		kCTFontAttributeName,
		kCTForegroundColorAttributeName
	};
	CFTypeRef values[] = {
		CTParagraphStyleCreate(&setting, 1),
		font,
		[[UIColor blackColor] CGColor]
	};
	CFDictionaryRef attr = CFDictionaryCreate(NULL, (void *)keys, (void *)values, 2,
											  &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	NSMutableAttributedString *textStore = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfFile:filePath encoding:NSMacOSRomanStringEncoding error:NULL]
																				   attributes:(NSDictionary *)attr];
	CFRelease(attr);
	CFRelease(font);
	
	// Replace the store's string and the document is notified
	editor.textDocument.store.attributedString = textStore;
	[textStore release];
	// ...but the editor view is not, hence we need to consider what is selected
	// Easiest option is to set it to nil (or endOfDocument/beginningOfDocument is good)
	[editor changeSelectedRange:[PhiTextRange textRangeWithPosition:(PhiTextPosition *)[editor beginningOfDocument]] scroll:YES];
}

- (IBAction)makeSkinny:(id)sender {
	CGRect frame = editor.frame;
	frame.size.width = 320;
	editor.frame = frame;
	editor.textDocument.size = frame.size;
}

- (IBAction)makeWide:(id)sender {
	CGRect frame = editor.frame;
	frame.size.width = 520;
	editor.frame = frame;
	editor.textDocument.size = frame.size;
}

- (IBAction)scrollToCaret {
	[editor scrollSelectionToVisible];
}
- (IBAction)scrollPageUp {
	[editor scrollRectToVisible:CGRectMake(editor.bounds.origin.x, MAX(0, editor.bounds.origin.y - editor.bounds.size.height), editor.bounds.size.width, editor.bounds.size.height) animated:YES];
}
- (IBAction)scrollPageDown {
	[editor scrollRectToVisible:CGRectMake(editor.bounds.origin.x, MAX(0, editor.bounds.origin.y + editor.bounds.size.height), editor.bounds.size.width, editor.bounds.size.height) animated:YES];
}
- (IBAction)scrollToTop {
	[editor scrollRectToVisible:CGRectMake(0, 0, editor.bounds.size.width, editor.bounds.size.height) animated:YES];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (IBAction)toggleTextViewOpacity:(id)sender {
	if (textView) {
		textView.opaque = !textView.opaque;
	}
}

- (void)dealloc {
    [super dealloc];
}

@end
