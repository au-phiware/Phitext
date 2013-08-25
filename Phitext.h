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
