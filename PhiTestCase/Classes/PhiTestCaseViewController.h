//
//  PhiTestCaseViewController.h
//  PhiTestCase
//
//  Created by Philippe Hausler on 3/28/10.
//  Copyright Philippe Hausler 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Phitext/Phitext.h>
#import <Phitext/PhiColorPatchControl.h>
#import <Phitext/PhiTextStyle.h>

@class PhiTextStyle;

@interface PhiTestCaseViewController : UIViewController <PhiTextViewDelegate> {
    IBOutlet PhiTextEditorView *editor;
    IBOutlet UITextView *textView;
    IBOutlet UINavigationController *textStyleController;
    IBOutlet PhiTextStyle *textStyle;
	IBOutlet UILabel *postionLabel;
    IBOutlet UILabel *tileHeightLabel;
    IBOutlet UISlider *tileHeightSlider;
    IBOutlet UILabel *tileWidthLabel;
    IBOutlet UISlider *tileWidthSlider;
    IBOutlet UILabel *heightHintLabel;
    IBOutlet UISlider *heightHintSlider;
    IBOutlet UILabel *rrHeight;
    IBOutlet UITextField *rrLength;
    IBOutlet UITextField *rrOffset;
    IBOutlet UILabel *rrWidth;
    IBOutlet UILabel *vrcpLength;
    IBOutlet UILabel *vrcpOffset;
    IBOutlet UILabel *vrcrLength;
    IBOutlet UILabel *vrcrOffset;
    IBOutlet UILabel *rrX;
    IBOutlet UILabel *rrY;
    IBOutlet PhiColorPatchControl *backgroundColorPatch;
    IBOutlet PhiColorPatchControl *textViewBackgroundColorPatch;
    IBOutlet UISlider *alphaSlider;
    IBOutlet UISlider *textViewAlphaSlider;
    IBOutlet UISwitch *atBoundaryBackward;
    IBOutlet UISwitch *atBoundaryForward;
    IBOutlet UISwitch *withinTextUnitBackward;
    IBOutlet UISwitch *withinTextUnitForward;
    IBOutlet UILabel *toBoundaryBackward;
    IBOutlet UILabel *toBoundaryForward;
	IBOutlet UISegmentedControl *granularity;
}
- (IBAction)applyStyle:(id)sender;
- (IBAction)changeTileHeight:(id)sender;
- (IBAction)changeTileWidth:(id)sender;
- (IBAction)changeHeightHint:(id)sender;
- (IBAction)toggleWrap;
- (IBAction)toggleEditable;
- (IBAction)clearText;
- (IBAction)copyText;
- (IBAction)loadText;
- (IBAction)makeSkinny:(id)sender;
- (IBAction)makeWide:(id)sender;
- (IBAction)scrollToCaret;
- (IBAction)scrollPageUp;
- (IBAction)scrollPageDown;
- (IBAction)scrollToTop;
- (IBAction)updateTokenizer:(id)sender;
- (IBAction)updateRectForRange:(id)sender;
- (IBAction)toggleEditable;
- (IBAction)toggleTextViewOpacity:(id)sender;
- (IBAction)toggleOpacity:(id)sender;
- (IBAction)toggleWrap;
- (IBAction)editorColorDidChange;
- (IBAction)textViewColorDidChange;

@end

