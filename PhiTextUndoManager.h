//
//  PhiTextUndoManager.h
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

#import <Foundation/Foundation.h>

typedef enum PhiTextUndoManagerGroupingTypes {
	PhiTextUndoManagerReplaceGroupingType		= 1 << 5,
	PhiTextUndoManagerCutingGroupingType		= 1 << 4,
	PhiTextUndoManagerPastingGroupingType   	= 1 << 3,
	PhiTextUndoManagerDeletingGroupingType   	= 1 << 2,
	PhiTextUndoManagerStylingGroupingType   	= 1 << 1,
	PhiTextUndoManagerTypingGroupingType    	= 1 << 0,
	PhiTextUndoManagerNoneGroupingType			= 0
} PhiTextUndoManagerGroupingType;

@interface PhiTextUndoManager : NSUndoManager {
	PhiTextUndoManagerGroupingType openGrouping;
	PhiTextUndoManagerGroupingType ignoreGroupings;
}

/*! Begin/end grouping for specific situations if not began/ended. !*/
- (void)ensureUndoGroupingBegan:(PhiTextUndoManagerGroupingType)type;
- (void)ensureUndoGroupingEnded;
- (void)endUndoGrouping:(PhiTextUndoManagerGroupingType)type;

@property (nonatomic, assign) PhiTextUndoManagerGroupingType ignoreUndoGroupings;
- (BOOL)shouldIgnoreUndoAnyGroupings:(PhiTextUndoManagerGroupingType)type;
- (BOOL)shouldIgnoreUndoAllGroupings:(PhiTextUndoManagerGroupingType)type;
- (void)addIgnoreUndoGroupings:(PhiTextUndoManagerGroupingType)type;

@end
