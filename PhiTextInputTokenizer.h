//
//  PhiTextInputTokenizer.h
//  FirstCoreText
//
//  Created by Corin Lawson on 7/02/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UITextInput.h>

@class PhiTextEditorView;

@interface PhiTextInputTokenizer : UITextInputStringTokenizer {
	PhiTextEditorView *owner;
}

@end
