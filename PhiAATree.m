//
//  Implementation based on: http://www.eternallyconfuzzled.com/tuts/datastructures/jsw_tut_andersson.aspx
//

#import "PhiAATree.h"

@interface PhiAATreeNode() // private methods.

// AA tree properties.
@property(retain, readwrite) PhiAATreeNode *left;
@property(retain, readwrite) PhiAATreeNode *right;
@property(assign, readwrite) PhiAATreeNode *up;
@property(assign, readwrite) int level;
@property(retain, readwrite) id object;

/*!
 * @abstract				Initializes the node using the specified data
 *							and binds this node to the specified key.
 * @discussion				The node will have level 1, which is the default
 *							when adding a node to the AA tree.
 *
 * @param aDataObject		The data to include in the node.
 * @result					An initialized node.
 */ 
- (id) initWithObject:(id)anObject;


@end


@interface PhiAATree() // private methods.

@property(retain, readwrite) PhiAATreeNode *root;
@property(assign, readwrite) NSUInteger count;
@property(assign) NSUInteger _hash;
@property(assign) unsigned long version;

- (void)__changeVersion;
- (PhiAATreeNode *) __balanceNodeWithObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot;

/*!
 * @abstract				Deletes the node bound to the specified key.
 * @discussion				The node is deleted by looking up the node with the 
 *							specified key. The node is removed as in any binary
 *							search tree, with the added functionallity that the
 *							difference in levels between parent and child should
 *							be at most one. If it is more, this is fixed, which may
 *							lead to skew and split operations.
 */
- (PhiAATreeNode *) __deleteNodeWithObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot balance:(BOOL)balance;
- (PhiAATreeNode *) __deleteNodeWithObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot;
- (void) __pruneAtNode:(PhiAATreeNode *)cut onRight:(BOOL)right;

/*!
 * @abstract				Insert the specified data in the AA tree.
 * @discussion				The data is inserted by looking up the correct leaf
 *							node, setting the node as the left or right child of
 *							the leaf. The function is recursive, so the skew and
 *							split operations are performed on all parents of the
 *							added node automatically. If a node with the same key
 *							as the new node is found, the data of the node is 
 *							replaced with the new data.
 *
 * @param aRoot				The root node to add the new node.
 * @param aNode				The node to add.
 * @result					The possibly new root.
 */
- (PhiAATreeNode *) __insertNode:(PhiAATreeNode *)aNode atRoot:(PhiAATreeNode *)aRoot balance:(BOOL)balance;
- (PhiAATreeNode *) __insertNode:(PhiAATreeNode *)aNode atRoot:(PhiAATreeNode *)aRoot;


/*!
 * @abstract				Lock the tree for reading.
 * @discussion				See the header file for more information on the current 
 *							implementation of thread safety.
 */
- (void) __lockForReading;


/*!
 * @abstract				Lock the tree for writing.
 * @discussion				See the header file for more information on the current 
 *							implementation of thread safety.
 */
- (void) __lockForWriting;


/*!
 * @abstract				Retrieves the node bound to the specified key.
 * @discussion				This function uses the key comparator, as specified on
 *							initialization of the tree.
 *
 * @param aKey				The key to look for.
 * @result					An AATreeNode pointer.
 */
- (PhiAATreeNode *) __nodeWithObject:(id)anObject;
- (PhiAATreeNode *) nodeMatchingObject:(id)anObject;

/*!
 * @abstract				Retrieves the node which comes closest to the specified key.
 * @discussion				This function uses the key comparator, as specified on
 *							initialization of the tree. The returned node's key won't
 *							surpass the specified key. If no node with a key lower than
 *							the specified key can be found, nil is returned. This function
 *							performs its operation recursive.
 *
 * @param aKey				The key to look for.
 * @param aRoot				The root to search from.
 * @result					An AATreeNode pointer.
 */
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse;
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject inRange:(PhiAATreeRange *)range withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse;
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator atRoot:(PhiAATreeNode *)aRoot reverse:(BOOL)reverse;
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator inRange:(PhiAATreeRange *)aRange reverse:(BOOL)reverse;
	

- (PhiAATreeNode *) __firstNode;


- (PhiAATreeNode *) __lastNode;


/*!
 * @abstract				Performs a recursive skew operation.
 * @discussion				This function makes sure that every violation of the first 
 *							balance rule, which states that no left horizontal logical links 
 *							are allowed, are fixed. It does this by rotating right at the 
 *							parent of the left horizontal logical link.
 *
 * @param aRoot				The root node to check.
 * @result					The possibly new root after the skew, or the same if nothing
 *							has been skewed.
 */
- (PhiAATreeNode *) __skew:(PhiAATreeNode *)aRoot;


/*!
 * @abstract				Performs a recursive split operation.
 * @discussion				This function makes sure that every violation of the second
 *							balance rule, which states that no two consecutive right 
 *							horizontal logical links are allowed, are fixed. It does this
 *							by rotating left and increasing the level of the parent.
 *
 * @param aRoot				The root node to check.
 * @result					The possibly new root after the split, or the same if nothing
 *							has been split.
 */
- (PhiAATreeNode *) __split:(PhiAATreeNode *)aRoot;


/*!
 * @abstract				Unlock the lock securing thread safety.
 */
- (void) __unlock;

@end


@implementation PhiAATreeRange

@synthesize start, end;

+ (id)rangeForAATree:(PhiAATree *)tree withStartObject:(id)startObject andEndObject:(id)endObject {
	PhiAATreeNode *startNode, *endNode;
	
	if (startObject)
		startNode = [tree nodeMatchingObject:startObject];
	else
		startNode = [tree firstNode];

	if (endObject)
		endNode = [tree nodeMatchingObject:endObject];
	else
		endNode = [tree lastNode];
	
	return [PhiAATreeRange rangeWithStartNode:startNode andEndNode:endNode];
}

+ (id)rangeForAATree:(PhiAATree *)tree withEnclosingObject:(id)anObject {
	return [PhiAATreeRange rangeForAATree:tree withEnclosingObject:anObject withComparator:tree.objectComparator];
}

+ (id)rangeForAATree:(PhiAATree *)tree withEnclosingObject:(id)anObject withComparator:(CFComparatorFunction)comparator {
	PhiAATreeNode *startNode, *endNode;
	
	startNode = [tree nodeClosestToObject:anObject withComparator:comparator reverse:NO];
	endNode = [tree nodeClosestToObject:anObject withComparator:comparator reverse:YES];
	
	return [PhiAATreeRange rangeWithStartNode:startNode andEndNode:endNode];
}

+ (id)rangeWithStartNode:(PhiAATreeNode *)startNode andEndNode:(PhiAATreeNode *)endNode {
	return [[[PhiAATreeRange alloc] initWithStartNode:startNode andEndNode:endNode] autorelease];
}

- (id)initWithStartNode:(PhiAATreeNode *)startNode andEndNode:(PhiAATreeNode *)endNode {
	if (self = [super init]) {
		start = startNode;
		end = endNode;
		if (!start && end) {
			start = end;
			while (start.up)
				start = start.up;
			while (start.left)
				start = start.left;
		} else if (start && !end) {
			end = start;
			while (end.up)
				end = end.up;
			while (end.right)
				end = end.right;
		}
		[start retain];
		[end retain];
		current = nil;
	}
	return self;
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	/*	typedef struct {
	 unsigned long state;
	 id *itemsPtr;
	 unsigned long *mutationsPtr;
	 unsigned long extra[5];
	 } NSFastEnumerationState;
	 */
	NSUInteger batchCount = 0;
	
	/**/
	if (self.start || self.end) {
		NSMutableArray *inStack = (NSMutableArray *)state->extra[0];
		NSMutableArray *outStack = (NSMutableArray *)state->extra[1];
		
		if (!outStack) {
			outStack = [[NSMutableArray alloc] init];
			state->extra[1] = (unsigned long)outStack;
			stackbuf[batchCount++] = self.start.object;
		}
		if (!inStack) {
			inStack = [[NSMutableArray alloc] init];
			if (self.start != self.end) {
				if (self.start.right)
					[inStack addObject:self.start.right];
				for (PhiAATreeNode *node = self.start; node.up; node = node.up) {
					if (node.up.left == node) {
						if ([inStack count]) {
							[outStack insertObject:node.up atIndex:0];
						} else {
							stackbuf[batchCount++] = node.up.object;
							if (node.up == self.end) break;
						}
						if (node.up.right)
							[inStack insertObject:node.up.right atIndex:0];
					}
				}
			}
			state->extra[0] = (unsigned long)inStack;
		}
		
		PhiAATreeNode *node = nil;
		while (batchCount < len - 1 && [inStack count]) {
			node = (PhiAATreeNode *)[[[inStack lastObject] retain] autorelease];
			[inStack removeLastObject];
			if (node.right) {
				[inStack addObject:node.right];
			}
			if (node.left) {
				[outStack addObject:node];
				[inStack addObject:node.left];
			} else {
				stackbuf[batchCount++] = node.object;
				if (node == self.end) break;
				node = (PhiAATreeNode *)[outStack lastObject];
				if (node) {
					stackbuf[batchCount++] = node.object;
					[outStack removeLastObject];
					if (node == self.end) break;
				}
			}
		}
		if (node == self.end)
			[inStack removeAllObjects];
		
		state->itemsPtr = stackbuf;
		state->mutationsPtr = (unsigned long *)self;
		
		if (!batchCount) {
			[(NSMutableArray *)state->extra[0] release];
			state->extra[0] = (unsigned long)nil;
			[(NSMutableArray *)state->extra[1] release];
			state->extra[1] = (unsigned long)nil;
		}
	}
		
	return batchCount;
}

- (BOOL)isEmpty {
	return start == nil;
}

- (BOOL)isSingleton {
	return start && start == end;
}

- (NSArray *)allObjects {
	NSMutableArray *contents = [NSMutableArray arrayWithCapacity:1 << start.level + 1 << end.level];
	for (id object in self) {
		[contents addObject:object];
	}
	return [[contents copy] autorelease];
}

- (id)firstObject {
	return start.object;
}

- (id)lastObject {
	return end.object;
}

- (id)nextObject {
	if (current == end)
		return nil;
	
	if (!current)
		current = start;
	else
		current = current.next;

	return current.object;
}

- (id)previousObject {
	if (!current)
		return nil;

	if (current == start)
		current = nil;
	else
		current = current.previous;

	return current.object;
}

- (id)currentObject {
	return current.object;
}

- (void) dealloc {
	if (start)
		[start release];
	if (end)
		[end release];
	[super dealloc];
}

@end


@implementation PhiAATree

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// -- public methods --
// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

@synthesize count;
@synthesize objectComparator;
@synthesize delegate;

- (id) initWithObjectComparator:(CFComparatorFunction)anObjectComparator rootNode:(PhiAATreeNode *)rootNode {
	if (self = [super init]) {
		_hash = 0;
		version = 0;
		objectComparator = anObjectComparator;
		pthread_rwlock_init(&rwLock, NULL);
		self.root = rootNode;
	}
	return self;
}

- (id) initWithObjectComparator:(CFComparatorFunction)anObjectComparator {
	return [self initWithObjectComparator:anObjectComparator rootNode:nil];
}

- (id) init {
	return [self initWithObjectComparator:NULL rootNode:nil];
}

- (id) copyWithZone:(NSZone *)zone {
	
	PhiAATree *copy = [[PhiAATree allocWithZone:zone] initWithObjectComparator:objectComparator];
	
	[self __lockForReading];
	copy.root = [[self.root copyWithZone:zone] autorelease];
	copy.count = count;
	if (_hash)
		copy._hash = _hash;
	else copy._hash = [super hash];
	copy.version = version;
	[self __unlock];
	
	return copy;
}


- (NSUInteger)hash {
	if (_hash)
		return (_hash ^ version);
	else return ([super hash] ^ version);
}

- (NSUInteger) count {
	return count;
}

- (BOOL) isEmpty {
	return root == nil;
}

- (id) firstObject {
	[self __lockForReading];
	id object = [self __firstNode].object;
	[self __unlock];
	
	return object;
}

- (PhiAATreeNode *) firstNode {
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __firstNode] retain] autorelease];
	[self __unlock];
	
	return node;
}

- (id) lastObject {
	[self __lockForReading];
	id object = [self __lastNode].object;
	[self __unlock];
	
	return object;
}

- (id) lastNode {
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __lastNode] retain] autorelease];
	[self __unlock];
	
	return node;
}

- (NSComparisonResult)compareNode:(PhiAATreeNode *)aNode toNode:(PhiAATreeNode *)otherNode {
	if (objectComparator)
		return [self compareObject:aNode.object toObject:otherNode.object];

	if (aNode == otherNode)
		return NSOrderedSame;
	
	for (;aNode.next; aNode = aNode.next)
		if (aNode.next == otherNode)
			return NSOrderedAscending;
	
	return NSOrderedDescending;
}
- (NSComparisonResult)compareObject:(id)anObject toObject:(id)anotherObject withComparator:(CFComparatorFunction)comparator backwards:(BOOL)flag {
	if (anObject == anotherObject)
		return NSOrderedSame;
	if (comparator)
		return comparator(anObject, anotherObject, (void *)(int)flag);
	if ([anObject respondsToSelector:@selector(isEqual:)] && [anObject isEqual:anotherObject])
		return NSOrderedSame;
	return NSOrderedDescending;
}
- (NSComparisonResult)compareObject:(id)anObject toObject:(id)anotherObject withComparator:(CFComparatorFunction)comparator {
	return [self compareObject:anObject toObject:anotherObject withComparator:comparator backwards:NO];
}
- (NSComparisonResult)compareObject:(id)anObject toObject:(id)anotherObject {
	return [self compareObject:anObject toObject:anotherObject withComparator:objectComparator];
}

- (id) objectClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse {
	id closest;
	[self __lockForReading];
	PhiAATreeNode *node = [self __nodeClosestToObject:anObject atRoot:self.root withComparator:comparator reverse:reverse];
	if (!node) {
		if (reverse) {
			node = [self __lastNode];
		} else {
			node = [self __firstNode];
		}
	}
	closest = node.object;
	[self __unlock];
	
	return closest;
}
- (id) objectClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator reverse:(BOOL)reverse {
	id closest;
	[self __lockForReading];
	PhiAATreeNode *node = [self __nodeClosestToObject:anObject withComparator:comparator andObject:otherObject withComparator:otherComparator atRoot:self.root reverse:reverse];
	if (!node) {
		if (reverse) {
			node = [self __lastNode];
		} else {
			node = [self __firstNode];
		}
	}
	closest = node.object;
	[self __unlock];
	
	return closest;
}
- (id) objectClosestToObject:(id)anObject {
	return [self objectClosestToObject:anObject withComparator:objectComparator reverse:NO];
}
- (id) objectClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator {
	return [self objectClosestToObject:anObject withComparator:comparator andObject:otherObject withComparator:otherComparator reverse:NO];
}

- (PhiAATreeNode *) nodeClosestToObject:(id)anObject {
	return [self nodeClosestToObject:anObject withComparator:objectComparator reverse:NO];
}
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse {
	
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __nodeClosestToObject:anObject atRoot:self.root withComparator:comparator reverse:reverse] retain] autorelease];
	if (!node) {
		if (reverse) {
			node = [[[self __lastNode] retain] autorelease];
		} else {
			node = [[[self __firstNode] retain] autorelease];
		}
	}
	[self __unlock];
	
	return node;
}
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator reverse:(BOOL)reverse {
	
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __nodeClosestToObject:anObject withComparator:comparator
											  andObject:otherObject withComparator:otherComparator
												 atRoot:self.root reverse:reverse] retain] autorelease];
	if (!node) {
		if (reverse) {
			node = [[[self __lastNode] retain] autorelease];
		} else {
			node = [[[self __firstNode] retain] autorelease];
		}
	}
	[self __unlock];
	
	return node;
}
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject inRange:(PhiAATreeRange *)aRange withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse {
	
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __nodeClosestToObject:anObject inRange:aRange withComparator:comparator reverse:reverse] retain] autorelease];
	if (!node) {
		if (reverse) {
			if (aRange.end) {
				node = [[aRange.end retain] autorelease];
			} else {
				node = [[[self __lastNode] retain] autorelease];
			}
		} else {
			if (aRange.start) {
				node = [[aRange.start retain] autorelease];
			} else {
				node = [[[self __firstNode] retain] autorelease];
			}
		}
	}
	[self __unlock];
	
	return node;
}
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator inRange:(PhiAATreeRange *)aRange reverse:(BOOL)reverse {
	
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __nodeClosestToObject:anObject withComparator:comparator
											  andObject:otherObject withComparator:otherComparator
												inRange:aRange reverse:reverse] retain] autorelease];
	if (!node) {
		if (reverse) {
			if (aRange.end) {
				node = [[aRange.end retain] autorelease];
			} else {
				node = [[[self __lastNode] retain] autorelease];
			}
		} else {
			if (aRange.start) {
				node = [[aRange.start retain] autorelease];
			} else {
				node = [[[self __firstNode] retain] autorelease];
			}
		}
	}
	[self __unlock];
	
	return node;
}

- (id) objectMatchingObject:(id)anObject {
	
	[self __lockForReading];
	id data = [self __nodeWithObject:anObject].object;
	[self __unlock];
	
	return data;
}

- (PhiAATreeNode *) nodeMatchingObject:(id)anObject {
	
	[self __lockForReading];
	PhiAATreeNode *node = [[[self __nodeWithObject:anObject] retain] autorelease];
	[self __unlock];
	
	return node;
}

- (BOOL) containsObject:(id)anObject {
	[self __lockForReading];
	PhiAATreeNode *node = [self __nodeWithObject:anObject];
	[self __unlock];
	return node != nil;
}


- (void) print {
	
	[self.root printWithIndent:0];
}

- (BOOL) __hasCacheDelegate {
	return (delegate && [delegate respondsToSelector:@selector(cache:willEvictObject:)]);
}
- (void) __notifyCacheDelegateWithObject:(id)object {
	if ([self __hasCacheDelegate])
		[delegate cache:self willEvictObject:object];
}
- (void) __notifyCacheDelegateWithNode:(PhiAATreeNode *)node {
	if (node && [self __hasCacheDelegate]) for (id object in node)
		[delegate cache:self willEvictObject:object];
}

- (void) removeObject:(id)matchingObject {
	NSParameterAssert(matchingObject);
	
	[self __lockForWriting];
	self.root = [self __deleteNodeWithObject:matchingObject atRoot:self.root];
	[self __unlock];
}

- (void) removeObjects:(id <NSFastEnumeration>)objects {
	NSParameterAssert(objects);

	[self __lockForWriting];
	for (id matchingObject in objects) {
		self.root = [self __deleteNodeWithObject:matchingObject atRoot:self.root];
	}
	[self __unlock];
}

- (void) removeAllObjects {
	[self __lockForWriting];
	
	[self __notifyCacheDelegateWithNode:self.root];
	
	self.root = nil;
	count = 0;
	[self __changeVersion];
	
	[self __unlock];
}

- (void) pruneAtNode:(PhiAATreeNode *)node {
	[self pruneAtNode:node right:YES];
}
- (void) pruneAtNode:(PhiAATreeNode *)node right:(BOOL)right {
	if (node) {
		[self __lockForWriting];
		[self __pruneAtNode:node onRight:right];
		[self __unlock];
	}
}
- (void) pruneAtObject:(id)matchingObject {
	[self pruneAtObject:matchingObject onRight:YES];
}
- (void) pruneAtObject:(id)matchingObject onRight:(BOOL)right {
	NSParameterAssert(matchingObject);

	[self __lockForWriting];
	[self __pruneAtNode:[self __nodeWithObject:matchingObject] onRight:right];
	[self __unlock];
}

- (void) __fastRightPruneAtNode:(PhiAATreeNode *)cut {
	if (!cut.up) {
		NSAssert(cut == self.root, @"We found a child with no parent that is not the root!");
		self.root = self.root.left;
		cut.left = nil;
	} else {
		// Remove right
		[self __notifyCacheDelegateWithNode:cut.right];
		cut.right = nil;
		// Remove cut
		BOOL removeCut = YES;
		PhiAATreeNode *parent, *needsBalancing = nil;
		while (parent = cut.up) {
			if (needsBalancing)
				needsBalancing = cut.left;
			
			if (parent.left == cut) {
				if (removeCut) {
					[self __notifyCacheDelegateWithObject:cut.object];
					[self __notifyCacheDelegateWithNode:cut.right];
					parent.left = cut.left;
				}
				removeCut = YES;
			} else /*if (parent.right == cut)*/ {
				if (removeCut) {
					[self __notifyCacheDelegateWithObject:cut.object];
					[self __notifyCacheDelegateWithNode:cut.right];
					parent.right = cut.left;
				}
				removeCut = NO;
			}
			cut = parent;
		}
		self.root = [self __balanceNodeWithObject:needsBalancing.object atRoot:self.root];
	}
	[self __changeVersion];
}

- (void) __fastLeftPruneAtNode:(PhiAATreeNode *)cut {
	if (!cut.up) {
		NSAssert(cut == self.root, @"We found a child with no parent that is not the root!");
		self.root = self.root.right;
		cut.right = nil;
	} else {
		// Remove left
		[self __notifyCacheDelegateWithNode:cut.left];
		cut.left = nil;
		// Remove cut
		BOOL removeCut = YES;
		PhiAATreeNode *parent, *needsBalancing = nil;
		while (parent = cut.up) {
			if (needsBalancing)
				needsBalancing = cut.left;
			
			if (parent.right == cut) {
				if (removeCut) {
					[self __notifyCacheDelegateWithObject:cut.object];
					[self __notifyCacheDelegateWithNode:cut.left];
					parent.right = cut.right;
				}
				removeCut = YES;
			} else /*if (parent.left == cut)*/ {
				if (removeCut) {
					[self __notifyCacheDelegateWithObject:cut.object];
					[self __notifyCacheDelegateWithNode:cut.left];
					parent.left = cut.right;
				}
				removeCut = NO;
			}
			cut = parent;
		}
		self.root = [self __balanceNodeWithObject:needsBalancing.object atRoot:self.root];
	}
	[self __changeVersion];
}


- (PhiAATreeNode *) addObject:(id)anObject {
	NSParameterAssert(anObject);
	
	[self __lockForWriting];
	PhiAATreeNode *newNode = [[PhiAATreeNode alloc] initWithObject:anObject];
	self.root = [self __insertNode:newNode atRoot:self.root];
	[newNode release];
	[self __unlock];
	
	return newNode;
}

- (void) addObjects:(id <NSFastEnumeration>)objects {
	NSParameterAssert(objects);
	
	[self __lockForWriting];
	for (id anObject in objects) {
		PhiAATreeNode *newNode = [[PhiAATreeNode alloc] initWithObject:anObject];
		self.root = [self __insertNode:newNode atRoot:self.root];
		[newNode release];
	}
	[self __unlock];
}

- (void) dealloc
{
	self.root = nil;
	[super dealloc];
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	NSUInteger batchCount = 0;
	
	if (![self isEmpty]) {
		[self __lockForReading]; {
			batchCount = [root countByEnumeratingWithState:state objects:stackbuf count:len];
			state->mutationsPtr = &version;
		} [self __unlock];
	}
	
	return batchCount;
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// -- private methods --
// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

@synthesize root;
@synthesize _hash;
@synthesize version;

- (PhiAATreeNode *) __balanceNodeWithObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot {
	
	if (aRoot) {
		
		// If we found the correct node, balance it.
		NSComparisonResult compareResult = [self compareObject:anObject toObject:aRoot.object];

		if (compareResult == NSOrderedSame) {
			
			// Check whether we are at an easy to balance node (zero to one children) or
			// a more difficult node.
			if (aRoot.left && aRoot.right) {
				
				// Delete the in-order predecessor (heir).
				aRoot.left = [self __balanceNodeWithObject:aRoot.object atRoot:aRoot.left];
				
			}

		// Otherwise, travel left or right.
		} else if (compareResult == NSOrderedAscending) {
			aRoot.left = [self __balanceNodeWithObject:anObject atRoot:aRoot.left];
		} else {
			aRoot.right = [self __balanceNodeWithObject:anObject atRoot:aRoot.right];
		}
		
		// Check whether the levels or the children are not more than one
		// lower than the current.
		if (aRoot.left.level < aRoot.level - 1 || aRoot.right.level < aRoot.level - 1) {
			
			// Decrease the level by one.
			aRoot.level--;
			
			// Decrease the right child's level also, when it is higher than its parent.
			if (aRoot.right.level > aRoot.level) aRoot.right.level = aRoot.level;
			
		}

		aRoot = [self __skew:aRoot];
		aRoot = [self __split:aRoot];
	}
	
	return aRoot;
}


- (PhiAATreeNode *) __deleteNodeWithObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot {
	return [self __deleteNodeWithObject:anObject atRoot:aRoot balance:YES];
}
- (PhiAATreeNode *) __deleteNodeWithObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot balance:(BOOL)balance {

	if (aRoot) {
		
		// If we found the correct node, remove it.
		NSComparisonResult compareResult = [self compareObject:anObject toObject:aRoot.object];

		if (compareResult == NSOrderedSame) {
			
			[self __notifyCacheDelegateWithObject:aRoot.object];
			
			// Check whether we are at an easy to remove node (zero to one children) or
			// a more difficult node.
			if (aRoot.left && aRoot.right) {
				
				// Get the in-order predecessor (heir).
				PhiAATreeNode *heir = aRoot.left;
				PhiAATreeNode *replacement;
				while (heir.right) heir = heir.right;

				// Replace the data.
				replacement = [[PhiAATreeNode alloc] initWithObject:heir.object];
				replacement.left = aRoot.left;
				replacement.right = aRoot.right;
				if (!aRoot.up) {
					self.root = replacement;
				} else if (aRoot.up.left == aRoot) {
					aRoot.up.left = replacement;
				} else {
					aRoot.up.right = replacement;
				}
				aRoot = replacement;
				[replacement release];
				
				// Delete the in-order predecessor (heir).
				aRoot.left = [self __deleteNodeWithObject:aRoot.object atRoot:aRoot.left balance:balance];
				
			} else if (aRoot.left) {
				aRoot = aRoot.left;
			} else {
				aRoot = aRoot.right; // which could be nil.
			}
			
			count--;
			[self __changeVersion];

		// Otherwise, travel left or right.
		} else if (compareResult == NSOrderedAscending) {
			aRoot.left = [self __deleteNodeWithObject:anObject atRoot:aRoot.left balance:balance];
		} else {
			aRoot.right = [self __deleteNodeWithObject:anObject atRoot:aRoot.right balance:balance];
		}
		
		// Check whether the levels or the children are not more than one
		// lower than the current.
		if (aRoot.left.level < aRoot.level - 1 || aRoot.right.level < aRoot.level - 1) {
			
			// Decrease the level by one.
			aRoot.level--;
			
			// Decrease the right child's level also, when it is higher than its parent.
			if (aRoot.right.level > aRoot.level) aRoot.right.level = aRoot.level;
			
			if (balance) {
				aRoot = [self __skew:aRoot];
				aRoot = [self __split:aRoot];
			}
		}
	}
	
	return aRoot;
}
- (void) __pruneAtNode:(PhiAATreeNode *)cut onRight:(BOOL)right {
	if (right)
		[self __fastRightPruneAtNode:cut];
	else
		[self __fastLeftPruneAtNode:cut];
/*	if (cut == root) {
		if (right) {
			lastNode = nil;
			self.root = self.root.left;
		} else {
			firstNode = nil;
			self.root = self.root.right;
		}
		self.root.up = nil;
	} else {
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
		
		if (cut) do {
			[array addObject:cut.object];
		} while (cut = (right?cut.next:cut.previous));
		
		for (id object in array)
			self.root = [self __deleteNodeWithObject:object atRoot:self.root];
	}
 */
}


- (PhiAATreeNode *) __insertNode:(PhiAATreeNode *)aNode atRoot:(PhiAATreeNode *)aRoot {
	return [self __insertNode:aNode atRoot:aRoot balance:YES];
}
- (PhiAATreeNode *) __insertNode:(PhiAATreeNode *)aNode atRoot:(PhiAATreeNode *)aRoot balance:(BOOL)balance {
	
	// If the root is not nil, we have not reached an empty child of a leaf node.
	if (aRoot) {
		
		// Decide which way to travel through the tree.
		NSComparisonResult compareResult = [self compareObject:aNode.object toObject:aRoot.object];
		
		// If the key of the new node is equal to the current root, just replace the data.
		if (compareResult == NSOrderedSame)	{
			aRoot.object = aNode.object;
			
		// Otherwise, travel left or right through the tree.
		} else {
			if (compareResult == NSOrderedAscending)
				aRoot.left = [self __insertNode:aNode atRoot:aRoot.left balance:balance];
			else
				aRoot.right = [self __insertNode:aNode atRoot:aRoot.right balance:balance];
			
			// After the node has been added, skew and split the (possibly new) root.
			// Because of the recursive nature of this function, all parents of the
			// new node will get skewed and split, all the way up to the root of the tree.
			if (balance) {
				aRoot = [self __skew:aRoot];
				aRoot = [self __split:aRoot];
			}
		}
		
	// Otherwise, insert the node.
	} else {
		aRoot = aNode;
		count++;
		[self __changeVersion];
	}
	
	return aRoot;
}

- (void)__changeVersion {
	version++;
	_hash = 0;
	lastNode = nil;
	firstNode = nil;
}

- (void) __lockForReading {
	
	pthread_rwlock_rdlock(&rwLock);
}


- (void) __lockForWriting {
	
	pthread_rwlock_wrlock(&rwLock);
}


- (PhiAATreeNode *) __nodeWithObject:(id)anObject {
	
	// Begin at the root of the tree.
	PhiAATreeNode *current = self.root;
	
	// While still at a node, check whether we have found the correct node or
	// travel left or right.
	while (current) {
		NSComparisonResult compareResult = [self compareObject:anObject toObject:current.object];
		
		if (compareResult == NSOrderedSame)	return current;
		else if (compareResult == NSOrderedAscending) current = current.left;
		else current = current.right;
	}
	
	// Nothing found, return nil.
	return nil;
}

- (PhiAATreeNode *) __commonAncestorForLeftNode:(PhiAATreeNode *)leftNode andRightNode:(PhiAATreeNode *)rightNode {
	if (!leftNode || !rightNode) 
		return self.root;

	int ancestorLevel = MAX(leftNode.level, rightNode.level);
	
	while (leftNode != rightNode) {
		if (leftNode.level < ancestorLevel) {
			leftNode = leftNode.up;
		} else {
			rightNode = rightNode.up;
			ancestorLevel = rightNode.level;
		}
	}
	
	return leftNode;
}
- (PhiAATreeNode *) __rootForRange:(PhiAATreeRange *)range {
	return [self __commonAncestorForLeftNode:range.start andRightNode:range.end];
}
/*
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse {

	// Start with no result.
	PhiAATreeNode *result = nil;
	
	// If we are still at a node, compare it to the specified key.
	if (aRoot) {
		NSComparisonResult compareResult;
		if (reverse)
			compareResult = [self compareObject:aRoot.object toObject:anObject withComparator:comparator];
		else
			compareResult = [self compareObject:anObject toObject:aRoot.object withComparator:comparator];
		
		
		// If the keys are equal, we have found an exact match and we are done.
		if (compareResult == NSOrderedSame)	result = aRoot;
		
		// Otherwise, travel left or right until a leaf node is surpassed.
		else if ((compareResult == NSOrderedAscending) ^ reverse)
			result = [self __nodeClosestToObject:anObject atRoot:aRoot.left withComparator:comparator reverse:reverse];
		else result = [self __nodeClosestToObject:anObject atRoot:aRoot.right withComparator:comparator reverse:reverse];

		// If no result has been found lower in the tree, test whether this node
		// is the closest.
		if (!result && (compareResult == NSOrderedDescending)) result = aRoot;
	}
	
	return result;
}
/**/
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject    withComparator:(CFComparatorFunction)comparator
								andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator
								   atRoot:(PhiAATreeNode *)aRoot reverse:(BOOL)reverse
							 leftSentinal:(PhiAATreeNode *)leftSentinal rightSentinal:(PhiAATreeNode *)rightSentinal {
	// Start with no result.
	PhiAATreeNode *result = nil;
	
	// If we are still at a node, compare it to the specified keys.
	while (aRoot) {
		NSComparisonResult compareResult;
		NSComparisonResult otherCompareResult;
		if (reverse) {
			compareResult = [self compareObject:aRoot.object toObject:anObject withComparator:comparator backwards:reverse];
			otherCompareResult = [self compareObject:aRoot.object toObject:otherObject withComparator:otherComparator backwards:reverse];
		}
		else {
			compareResult = [self compareObject:anObject toObject:aRoot.object withComparator:comparator backwards:reverse];
			otherCompareResult = [self compareObject:otherObject toObject:aRoot.object withComparator:otherComparator backwards:reverse];
		}
		
		
		// If the keys are equal or opposing, we have found an exact match or an inbetween value and we are done.
		if ((compareResult <= NSOrderedSame && otherCompareResult >= NSOrderedSame)) {
			result = aRoot;
			aRoot = nil;
			break; //not strictly needed
		}
		// Otherwise, travel left or right until a leaf node is surpassed.
		else {
			// If no result has been found lower in the tree, test whether this node
			// is the closest (ie. rightmost if reverse, leftmost otherwise).
			if (compareResult == NSOrderedDescending) result = aRoot;
			
			if ((compareResult == NSOrderedAscending) ^ reverse) {
				if (aRoot != leftSentinal) {
					aRoot = aRoot.left;
				} else {
					aRoot = nil;
				}
			} else {
				if (aRoot != rightSentinal) {
					aRoot = aRoot.right;
				} else {
					aRoot = nil;
				}
			}
		}
	}
	
	return result;
}
/**/
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject
								   atRoot:(PhiAATreeNode *)aRoot
						   withComparator:(CFComparatorFunction)comparator
								  reverse:(BOOL)reverse
							 leftSentinal:(PhiAATreeNode *)leftSentinal
							rightSentinal:(PhiAATreeNode *)rightSentinal {
	
	// Start with no result.
	PhiAATreeNode *result = nil;
	
	// If we are still at a node, compare it to the specified key.
	while (aRoot) {
		NSComparisonResult compareResult;
		if (reverse)
			compareResult = [self compareObject:aRoot.object toObject:anObject withComparator:comparator backwards:reverse];
		else
			compareResult = [self compareObject:anObject toObject:aRoot.object withComparator:comparator backwards:reverse];
		
		
		// If the keys are equal, we have found an exact match and we are done.
		if (compareResult == NSOrderedSame) {
			result = aRoot;
			aRoot = nil;
			break; //not strictly needed
		}
		// Otherwise, travel left or right until a leaf node is surpassed.
		else {
			// If no result has been found lower in the tree, test whether this node
			// is the closest (ie. rightmost if reverse, leftmost otherwise).
			if (compareResult == NSOrderedDescending) result = aRoot;
			
			if ((compareResult == NSOrderedAscending) ^ reverse) {
				if (aRoot != leftSentinal) {
					if (aRoot.left)
						aRoot = aRoot.left;
					else
						aRoot = nil;
				} else {
					aRoot = nil;
				}
			} else {
				if (aRoot != rightSentinal) {
					if (aRoot.right)
						aRoot = aRoot.right;
					else
						aRoot = nil;
				} else {
					aRoot = nil;
				}
			}
		}
	}
	
	return result;
}
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject atRoot:(PhiAATreeNode *)aRoot
						   withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse {
	return [self __nodeClosestToObject:anObject atRoot:aRoot
						withComparator:comparator reverse:reverse
						  leftSentinal:nil rightSentinal:nil];
}
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject inRange:(PhiAATreeRange *)aRange
						   withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse {
	return [self __nodeClosestToObject:anObject atRoot:[self __rootForRange:aRange]
						withComparator:comparator reverse:reverse
						  leftSentinal:aRange.start rightSentinal:aRange.end];
}
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator
								andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator
								   atRoot:(PhiAATreeNode *)aRoot reverse:(BOOL)reverse {
	return [self __nodeClosestToObject:anObject withComparator:comparator
							 andObject:otherObject withComparator:otherComparator
								atRoot:aRoot reverse:reverse
						  leftSentinal:nil rightSentinal:nil];
}
- (PhiAATreeNode *) __nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator
								andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator
								  inRange:(PhiAATreeRange *)aRange reverse:(BOOL)reverse {
	return [self __nodeClosestToObject:anObject withComparator:comparator
							 andObject:otherObject withComparator:otherComparator
								atRoot:[self __rootForRange:aRange] reverse:reverse
						  leftSentinal:aRange.start rightSentinal:aRange.end];
}

- (PhiAATreeNode *) __firstNode {
	if (!firstNode) {
		firstNode = self.root;
		while (firstNode.left)
			firstNode = firstNode.left;
	}
	
	return firstNode;
}


- (PhiAATreeNode *) __lastNode {
	if (!lastNode) {
		lastNode = self.root;
		while (lastNode.right)
			lastNode = lastNode.right;
	}
	
	return lastNode;
}


- (PhiAATreeNode *) __skew:(PhiAATreeNode *)aRoot {

	if (aRoot) {
		
		// Check for a logical horizontal left link.
		if (aRoot.left.level == aRoot.level) {
			
			// Perform a right rotation.
			PhiAATreeNode *save = aRoot;
			aRoot = [[save.left retain] autorelease];
			save.left = aRoot.right;
			aRoot.right = save;
		}
		
		// Skew the right side of the (new) root.
		aRoot.right = [self __skew:aRoot.right];
	}
	
	return aRoot;
}


- (PhiAATreeNode *) __split:(PhiAATreeNode *)aRoot {
	
	// Check for a consecutive logical horizontal right link.
	if (aRoot && aRoot.right.right.level == aRoot.level) {
		
		// Perform a left rotation.
		PhiAATreeNode *save = aRoot;
		aRoot = [[save.right retain] autorelease];
		save.right = aRoot.left;
		aRoot.left = save;
		
		// Increase the level of the new root.
		aRoot.level++;
		
		// Split the right side of the new root.
		aRoot.right = [self __split:aRoot.right];
	}
	
	return aRoot;
}


- (void) __unlock {
	
	pthread_rwlock_unlock(&rwLock);
}

@end

@implementation PhiAATreeNode

@synthesize left;
@synthesize right;
@synthesize up;
@synthesize level;
@synthesize object;

- (PhiAATreeNode *)previous {
	PhiAATreeNode *previous = nil;
	
	if (self.left) {
		previous = self.left;
		while (previous.right)
			previous = previous.right;
	} else {
		previous = self;
		while (previous && previous.up.left == previous)
			previous = previous.up;
		previous = previous.up;
	}
	
	return previous;
}

- (PhiAATreeNode *)next {
	PhiAATreeNode *next = nil;
	
	if (self.right) {
		next = self.right;
		while (next.left)
			next = next.left;
	} else {
		next = self;
		while (next && next.up.right == next)
			next = next.up;
		next = next.up;
	}
	
	return next;
}

- (void)setLeft:(PhiAATreeNode *)aNode {
	if (left != aNode) {
		if (left) {
			if (left.up == self)
				left.up = nil;
			[left release];
		}
		
		left = aNode;
		
		if (left) {
			[left retain];
			left.up = self;
		}
	}
}

- (void)setRight:(PhiAATreeNode *)aNode {
	if (right != aNode) {
		if (right) {
			if (right.up == self)
				right.up = nil;
			[right release];
		}
		
		right = aNode;
		
		if (right) {
			[right retain];
			right.up = self;
		}
	}
}

- (id) initWithObject:(id)anObject {
	
	if (self = [super init]) {
		self.object = anObject;
		self.level = 1;
	}
	
	return self;
}


- (id) copyWithZone:(NSZone *)zone {
	
	PhiAATreeNode *copy = [[PhiAATreeNode allocWithZone:zone] initWithObject:object];
	copy.left = [[left copyWithZone:zone] autorelease];
	copy.left.up = copy;
	copy.right = [[right copyWithZone:zone] autorelease];
	copy.right.up = copy;
	copy.level = level;
	return copy;
}


- (void) printWithIndent:(int)indent {
	
	if (left) [left printWithIndent:(indent+1)];
	
	NSMutableString *pre = [[NSMutableString alloc] init];
	for (int i=0; i<indent; i++) [pre appendString:@"   "];
	NSLog(@"%@%@%i [0x%x]%@", pre, (up?((up.left==self)?@"/":@"\\"):@"<"), level, self, object);
	[pre release];
	
	if (right) [right printWithIndent:(indent+1)];
}


- (void) dealloc
{
	[left release];
	[right release];
	[object release];
	[super dealloc];
}

- (id *) __objectPtr {
	return &object;
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	/*	typedef struct {
	 unsigned long state;
	 id *itemsPtr;
	 unsigned long *mutationsPtr;
	 unsigned long extra[5];
	 } NSFastEnumerationState;
	 */
	NSUInteger batchCount = 0;

	/**/
	NSMutableArray *inStack = (NSMutableArray *)state->extra[0];
	NSMutableArray *outStack = (NSMutableArray *)state->extra[1];
	
	if (!inStack) {
		inStack = [[NSMutableArray alloc] initWithCapacity:level + 1];
		[inStack addObject:self];
		state->extra[0] = (unsigned long)inStack;
	}
	if (!outStack) {
		outStack = [[NSMutableArray alloc] initWithCapacity:level + 1];
		state->extra[1] = (unsigned long)outStack;
	}

	while (batchCount < len - 1 && [inStack count]) {
		PhiAATreeNode *node = [[[inStack lastObject] retain] autorelease];
		[inStack removeLastObject];
		if (node.right) {
			[inStack addObject:node.right];
		}
		if (node.left) {
			[outStack addObject:node];
			[inStack addObject:node.left];
		} else {
			stackbuf[batchCount++] = node.object;
			node = [outStack lastObject];
			if (node) {
				stackbuf[batchCount++] = node.object;
				[outStack removeLastObject];
			}
		}
	}
	
	state->itemsPtr = stackbuf;
	state->mutationsPtr = (unsigned long *)self;
	
	if (!batchCount) {
		[(NSMutableArray *)state->extra[0] release];
		state->extra[0] = (unsigned long)nil;
		[(NSMutableArray *)state->extra[1] release];
		state->extra[1] = (unsigned long)nil;
	}
	/*/
	PhiAATreeNode *recentNode = nil;
	
	if (state->extra[0]) {
		recentNode = (PhiAATreeNode *)state->extra[0];
	} else {
		recentNode = self;
		while (recentNode.left)
			recentNode = recentNode.left;
		stackbuf[batchCount++] = recentNode.object;
	}
	
	while (batchCount < len && recentNode != [self up] && [recentNode next]) {
		recentNode = [recentNode next];
		stackbuf[batchCount++] = recentNode.object;
	}
	
	state->itemsPtr = stackbuf;
	state->mutationsPtr = (unsigned long *)self;
	
	if (state->extra[0])
		[(PhiAATreeNode *)state->extra[0] release];
	if (recentNode != (PhiAATreeNode *)state->extra[0])
		state->extra[0] = (unsigned long)[recentNode retain];
	else state->extra[0] = (unsigned long)nil;
	/**/
	
	return batchCount;
}

@end
