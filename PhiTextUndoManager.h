//
//  PhiTextUndoManager.h
//  Phitext
//
//  Created by Corin Lawson on 17/08/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
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
