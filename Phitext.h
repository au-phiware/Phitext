//
//

//#import <Foundation/Foundation.h>
#import <Phitext/PhiTextView.h>
#import <Phitext/PhiTextRange.h>
#import <Phitext/PhiTextPosition.h>
#import <Phitext/PhiTextDocument.h>
#import <Phitext/PhiTextStorage.h>
#import <Phitext/PhiTextInputTokenizer.h>
#import <Phitext/PhiTextSelectionView.h>
#import <Phitext/PhiTextSelectionHandle.h>
#import <Phitext/PhiTextCaretView.h>
#import <Phitext/PhiTextMagnifier.h>
#import <Phitext/PhiTextEditorView.h>

inline NSString *PhiTextVersionString() {
	return [PhiTextEditorView versionString];
}
