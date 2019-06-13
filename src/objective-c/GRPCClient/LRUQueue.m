//
//  LRUQueue.m
//  InterceptorSample
//
//  Created by Tony Lu on 6/12/19.
//  Copyright © 2019 gRPC. All rights reserved.
//

#import "LRUQueue.h"

/**
 * ArrayQueue
 */
@implementation ArrayQueue {
  NSMutableArray<RequestCacheEntry*> *_array;
}

- (nullable instancetype)init {
  if ((self = [super init])) {
    _array = [[NSMutableArray alloc] init];
    if (!_array) {
      self = nil;
    }
  }
  return self;
}

- (NSUInteger)size {
  return _array.count;
}

- (void)enqueue:(RequestCacheEntry *)entry {
  [_array addObject:entry];
}

- (void)updateUse:(RequestCacheEntry *)entry {
  // if the entry is not in the queue, return (cuz behavior undefined)
  if (![_array containsObject:entry]) { return; }
  [_array removeObject:entry];
  [_array addObject:entry];
}

-(RequestCacheEntry *)evict {
  RequestCacheEntry *toEvict = [_array firstObject];
  [_array removeObjectAtIndex:0];
  return toEvict;
}

@end

/**
 * Node
 */
@implementation Node {
  RequestCacheEntry *_entry;
}

@synthesize entry = _entry;

- (nullable instancetype)initWithPrevNode:(Node *)prev
                                 nextNode:(Node *)next
                            forCacheEntry:(nonnull RequestCacheEntry *)entry{
  if ((self = [super init])) {
    self.prev = prev;
    self.next = next;
    _entry = entry;
  }
  return self;
}


@end

/**
 * LinkedListQueue
 */
@implementation LinkedListQueue {
  Node *_head;
  Node *_tail;
  NSUInteger _size;
  NSMutableDictionary<RequestCacheEntry *, Node*> *_map;
}

- (nullable instancetype)init {
  if ((self = [super init])) {
    _map = [[NSMutableDictionary alloc] init];
    if (!_map) {
      self = nil;
    } else {
      _head = _tail = nil;
      _size = 0;
    }
  }
  return self;
}

- (void)enqueue:(RequestCacheEntry *)entry {
  Node *node = [[Node alloc] initWithPrevNode:nil nextNode:_head forCacheEntry:entry];
  if (_head) {
    _head.prev = node;
  } else {
    _tail = node;
  }
  _head = node;
  [_map setObject:node forKey:entry];
  ++_size;
}

- (RequestCacheEntry *)evict {
  Node *evictNode = _tail;
  if (evictNode) {
    _tail = evictNode.prev;
    if (_tail) {
      _tail.next = nil;
    }
    RequestCacheEntry *toEvict = evictNode.entry;
    [_map removeObjectForKey:toEvict];
    --_size;
    if (_size == 0) { _head = nil; }
    return toEvict;
  } else {
    return nil;
  }
}

- (NSUInteger)size {
  return _size;
}

- (void)updateUse:(RequestCacheEntry *)entry {
  Node *updateNode = [_map objectForKey:entry];
  if (updateNode == _head) { return; }
  if (!updateNode) { return; }
  if (updateNode.next) { updateNode.next = updateNode.prev; }
  if (updateNode.prev) { updateNode.prev = updateNode.next; }
  if (updateNode == _tail) { _tail = updateNode.prev; }
  updateNode.next = _head;
  if (_head) { _head.prev = updateNode; }
  _head = updateNode;
}

@end
