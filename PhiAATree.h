/*
 * --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
 *
 * This is an implementation of the Arne Andersson Tree, which is a balanced binary search
 * tree. For more information on how the balancing, inserting and deletion algorithms 
 * work, see http://en.wikipedia.org/wiki/Andersson_tree
 *
 * This class is set-up as an extension of the NSMutableDictionary class cluster, so all 
 * of the methods in the NSMutableDictionary public abstract interface can be called on this 
 * class also, with the exception of the initialize methods. The class supports the 
 * NSCopying and NSFastEnumeration protocols, among others.
 *
 * The class has been suitable for any type of data, and more importantly, for any type
 * of key. When initializing the tree, one must supply a NSComparator block which contains
 * the logic to compare two keys. Do note that a copy of the key is created when inserted
 * into the tree, so it must implement the NSCopying protocol.
 *
 * One of the advantages of using a tree as data model, is it is easy to determine an
 * object closest to a key. This is why the method objectClosestToKey is included in the
 * interface.
 *
 * The tree is completely thread safe. It uses a readers/write lock pattern, so multiple
 * readers (threads) don't lock each other out. The only time the readers do get locked is
 * when a writer (thread) wants or has access to the tree for mutations. In short, the
 * accessors can be used in parallel, but will have to wait for possible mutations to finish. 
 * This thread safety pattern is very suitable for a tree like this and, compared to 
 * the other locking mechanisms in Objective-C, the fastest when the tree is accessed
 * more often that mutated.
 * 
 * This class may be used, modified and distributed freely. Of course I would like to hear
 * about any updates, requests or bugs. I can be contacted at a.roemers@gmail.com
 *
 * --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
 *
 * Author		A. Roemers
 * Version		1.0
 * Date			2010-06-18
 *
 * --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
 *
 * AATree has been modified to behave as an NSArray (as opposed to NSDictionary), hence
 * the data is removed and only the key remains, renamed to object.
 * A mutator for keyComparator, rename to objectComparator has been added.
 * A bulk insert method has been added.
 *
 * Flatten files (node interface hidden in tree implementation).
 *
 *
 *
 *
 *
 *
 * --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
 *
 * Author		A. Roemers
 * Version		1.0
 * Date			2010-06-18
 *
 * --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
 *
 */

#import <Foundation/Foundation.h>
#import <pthread.h>

@interface PhiAATreeNode : NSObject <NSCopying, NSFastEnumeration> {
	PhiAATreeNode *left;
	PhiAATreeNode *right;
	PhiAATreeNode *up;
	int level;
	id object;
}

// AA tree properties.
@property(retain, readonly) PhiAATreeNode *previous;
@property(retain, readonly) PhiAATreeNode *next;
@property(retain, readonly) PhiAATreeNode *left;
@property(retain, readonly) PhiAATreeNode *right;
@property(assign, readonly) PhiAATreeNode *up;
@property(assign, readonly) int level;

// Data properties.
@property(retain, readonly) id object;


/*!
 * @abstract				Print the node using NSlog().
 * @discussion				First display the right child, using a bigger indent,
 *							then display the node itself, using the specified indent,
 *							and lastly display the left node, using a bigger indent.
 *
 * @param ident				The indent to use.
 */
- (void) printWithIndent:(int)indent;


@end

@class PhiAATree;
@interface PhiAATreeRange : NSEnumerator <NSFastEnumeration>
{
	PhiAATreeNode *start;
	PhiAATreeNode *end;
	PhiAATreeNode *current;
}

@property (retain, readonly) PhiAATreeNode *start;
@property (retain, readonly) PhiAATreeNode *end;
@property (assign, readonly, getter=isEmpty) BOOL empty;
@property (assign, readonly, getter=isSingleton) BOOL singleton;

+ (id)rangeForAATree:(PhiAATree *)tree withStartObject:(id)startObject andEndObject:(id)endObject;

+ (id)rangeForAATree:(PhiAATree *)tree withEnclosingObject:(id)anObject;

+ (id)rangeForAATree:(PhiAATree *)tree withEnclosingObject:(id)anObject withComparator:(CFComparatorFunction)comparator;

+ (id)rangeWithStartNode:(PhiAATreeNode *)startNode andEndNode:(PhiAATreeNode *)endNode;

- (id)initWithStartNode:(PhiAATreeNode *)startNode andEndNode:(PhiAATreeNode *)endNode;

- (NSArray *)allObjects;

- (id)firstObject;

- (id)lastObject;

- (id)nextObject;

- (id)previousObject;

- (id)currentObject;

@end


@interface PhiAATree : /*NSCache*/NSObject <NSCopying, NSFastEnumeration> {
	
	// The root node of the tree.
	PhiAATreeNode *root;

	PhiAATreeNode *firstNode;
	PhiAATreeNode *lastNode;

	// The NSComparator used to compare the keys of the nodes.
	CFComparatorFunction objectComparator;
	id /*<NSCacheDelegate>*/ delegate;
	
	// The number of nodes in the tree.
	NSUInteger count;
	
	// The readers/writer lock for thread safety.
	pthread_rwlock_t rwLock;

	NSUInteger _hash;
	unsigned long version;
}

@property (assign, readonly, getter=isEmpty) BOOL empty;
@property (retain, readonly) PhiAATreeNode *root;
@property (retain, readonly) PhiAATreeNode *firstNode;
@property (retain, readonly) PhiAATreeNode *lastNode;
@property (retain, readonly) id firstObject;
@property (retain, readonly) id lastObject;
@property (assign, readonly) NSUInteger count;
@property (assign) CFComparatorFunction objectComparator;
@property (assign) id delegate;
//@property (assign) id <NSCacheDelegate> delegate;

/*!
 * @abstract				Initializes the tree with the specified key comparator.
 * @discussion				The key comparator is used for comparing the keys with
 *							each other, for every concerning operation that is performed
 *							on the tree. 
 *
 *							The supplied key comparator Block is copied, so it stored in
 *							the heap. This way, the actual declaration of the key comparator 
 *							can	safely go out of scope.
 *
 *							Use only this initializer, otherwise no key comparator exists.
 *
 * @param anObjectComparator	A NSComparator block which compares the keys with each other.
 * @result					An initialized AA tree object.
 */
- (id) initWithObjectComparator:(CFComparatorFunction)anObjectComparator;


/*!
 * @abstract				Creates a copy of the tree. 
 * @discussion				Note that modifications on the returned copy do not
 *							influence the original tree. On the other hand, the
 *							actual data and keys in the tree are not copied, so
 *							the data and keys in the copy point to exactly the 
 *							same objects as in the original.
 *
 * @param zone				The zone identifies an area of memory from which to 
 *							allocate for the new instance.
 * @result					A new instance of the tree.
 */
- (id) copyWithZone:(NSZone *)zone;


/*!
 * @abstract				Returns the number of objects currently in the receiver.
 *
 * @result					The number of objects currently in the receiver.
 */
- (NSUInteger) count;

- (NSComparisonResult)compareNode:(PhiAATreeNode *)aNode toNode:(PhiAATreeNode *)otherNode;
- (NSComparisonResult)compareObject:(id)anObject toObject:(id)anotherObject;

/*!
 * @abstract				This function returns the data object which is closest to the 
 *							specified key.
 * @discussion				The returned data's key is always lower than (or equal to) the 
 *							specified key. This also means that if the specified key is higher
 *							than the highest key in the tree, nil is returned. The key comparator, 
 *							as specified at the initialization of this tree, is used for comparing 
 *							the keys.
 *
 * @param anObject				The key to look for.
 * @result					The closest data object to the key.
 */
- (id) objectClosestToObject:(id)anObject;
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse;
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject inRange:(PhiAATreeRange *)aRange withComparator:(CFComparatorFunction)comparator reverse:(BOOL)reverse;
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator reverse:(BOOL)reverse;
- (PhiAATreeNode *) nodeClosestToObject:(id)anObject withComparator:(CFComparatorFunction)comparator andObject:(id)otherObject withComparator:(CFComparatorFunction)otherComparator inRange:(PhiAATreeRange *)aRange reverse:(BOOL)reverse;
- (id) objectMatchingObject:(id)anObject;
- (BOOL) containsObject:(id)anObject;
- (id) firstObject;
- (PhiAATreeNode *) firstNode;
- (id) lastObject;
- (PhiAATreeNode *) lastNode;

/*!
 * @abstract				Display the tree using NSLog().
 */
- (void) print;


/*!
 * @abstract				Delete the data object bound to the specified key.
 * @discussion				The key comparator, as specified at the initialization 
 *							of this tree, is used for comparing the keys. If no data is found
 *							for the specified key, the tree remains unaltered.
 *
 * @param aKey				The key to look for.
 */
- (void) removeObject:(id)matchingObject;
- (void) removeObjects:(id <NSFastEnumeration>)objects;
- (void) removeAllObjects;
- (void) pruneAtObject:(id)matchingObject;
- (void) pruneAtNode:(PhiAATreeNode *)node;
- (void) pruneAtObject:(id)matchingObject onRight:(BOOL)right;
- (void) pruneAtNode:(PhiAATreeNode *)node right:(BOOL)right;

/*!
 * @abstract				Insert the specified data into the tree, bound to the specified key.
 * @discussion				If the specified key is already in the tree, the old data is replaced
 *							with the new data. Note that the key must not be nil and must implement
 *							the NSCopying protocol.
 *
 * @param anObject			The data object to insert, which must not be nil.
 * @param aKey				The key to bind the data object to, which must not be nil.
 */
- (PhiAATreeNode *) addObject:(id)anObject;
- (void) addObjects:(id <NSFastEnumeration>)objects;

@end
