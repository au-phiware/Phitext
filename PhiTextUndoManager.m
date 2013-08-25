//
//  PhiTextUndoManager.m
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

#import "PhiTextUndoManager.h"


@implementation PhiTextUndoManager

+ (void)initialize {
	CFStringRef suiteName = CFSTR("com.phitext");
	int anInt;
	CFNumberRef aNumberValue;

	CFPropertyListRef last = CFPreferencesCopyAppValue(CFSTR("ignoreUndoGroupings"), suiteName);
	if (last) {
		CFRelease(last);
	} else {
		anInt = PhiTextUndoManagerReplaceGroupingType;
		aNumberValue = CFNumberCreate(NULL, kCFNumberIntType, &anInt);
		CFPreferencesSetAppValue(CFSTR("ignoreUndoGroupings"), aNumberValue, suiteName);
		CFRelease(aNumberValue);

#ifdef PHI_SYNC_DEFAULTS
		CFPreferencesAppSynchronize(suiteName);
#endif
	}
}

@synthesize ignoreUndoGroupings=ignoreGroupings;

- (id)init {
	if (self == [super init]) {
		openGrouping = PhiTextUndoManagerNoneGroupingType;

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"com.phitext"];
		ignoreGroupings = [defaults integerForKey:@"ignoreUndoGroupings"];
	}
	return self;
}

- (void)setDefaultActionName {
	if (openGrouping & PhiTextUndoManagerTypingGroupingType) {
		return [self setActionName:NSLocalizedString(@"Typing", @"typing undo default action name")];
	} else if (openGrouping & PhiTextUndoManagerStylingGroupingType) {
		return [self setActionName:NSLocalizedString(@"Formatting", @"formatting undo default action name")];
	} else if (openGrouping & PhiTextUndoManagerDeletingGroupingType) {
		return [self setActionName:NSLocalizedString(@"Delete", @"delete undo default action name")];
	} else if (openGrouping & PhiTextUndoManagerPastingGroupingType) {
		return [self setActionName:NSLocalizedString(@"Paste", @"paste undo default action name")];
	} else if (openGrouping & PhiTextUndoManagerCutingGroupingType) {
		return [self setActionName:NSLocalizedString(@"Cut", @"cut undo default action name")];
	} else if (openGrouping & PhiTextUndoManagerReplaceGroupingType) {
		return [self setActionName:NSLocalizedString(@"Correction", @"replace undo default action name")];
	} else {
		[self setActionName:NSLocalizedString(@"Text Edit", @"none undo default action name")];
	}
}

- (void)ensureUndoGroupingEnded {
	if (openGrouping) {
		[self setDefaultActionName];
		[self endUndoGrouping];
		openGrouping = PhiTextUndoManagerNoneGroupingType;
	}
}

- (void)endUndoGrouping:(PhiTextUndoManagerGroupingType)type {
	if (openGrouping && ![self shouldIgnoreUndoAnyGroupings:type]) {
		[self setDefaultActionName];
		[self endUndoGrouping];
		openGrouping = PhiTextUndoManagerNoneGroupingType;
	}
}

- (void)ensureUndoGroupingBegan:(PhiTextUndoManagerGroupingType)type {
	if (![self shouldIgnoreUndoAllGroupings:type] && !(openGrouping & type)) {
		[self ensureUndoGroupingEnded];
		[self beginUndoGrouping];
		openGrouping = type & ~ignoreGroupings;
		[self setDefaultActionName];
	}
}

- (BOOL)shouldIgnoreUndoAllGroupings:(PhiTextUndoManagerGroupingType)type {
	return (ignoreGroupings & type) == type;
}
- (BOOL)shouldIgnoreUndoAnyGroupings:(PhiTextUndoManagerGroupingType)type {
	return (ignoreGroupings & type);
}
- (void)setIgnoreUndoGroupings:(PhiTextUndoManagerGroupingType)type {
	if (ignoreGroupings != type) {
		ignoreGroupings = type;
		if (openGrouping & ignoreGroupings) {
			[self ensureUndoGroupingEnded];
		}
	}
}
- (void)addIgnoreUndoGroupings:(PhiTextUndoManagerGroupingType)type {
	[self setIgnoreUndoGroupings:ignoreGroupings | type];
}

- (void)undo {
	[self ensureUndoGroupingEnded];
	[super undo];
}

- (void)redo {
	[self ensureUndoGroupingEnded];
	[super redo];
}

@end
