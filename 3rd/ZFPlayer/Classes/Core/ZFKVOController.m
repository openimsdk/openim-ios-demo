























#import "ZFKVOController.h"

@interface ZFKVOEntry : NSObject
@property (nonatomic, weak)   NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;

@end

@implementation ZFKVOEntry

@end

@interface ZFKVOController ()
@property (nonatomic, weak) NSObject *target;
@property (nonatomic, strong) NSMutableArray *observerArray;

@end

@implementation ZFKVOController

- (instancetype)initWithTarget:(NSObject *)target {
    self = [super init];
    if (self) {
        _target = target;
        _observerArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)safelyAddObserver:(NSObject *)observer
               forKeyPath:(NSString *)keyPath
                  options:(NSKeyValueObservingOptions)options
                  context:(void *)context {
    if (_target == nil) return;
    
    NSInteger indexEntry = [self indexEntryOfObserver:observer forKeyPath:keyPath];
    if (indexEntry != NSNotFound) {

        NSLog(@"duplicated observer");
    } else {
        @try {
            [_target addObserver:observer
                     forKeyPath:keyPath
                        options:options
                        context:context];
            
            ZFKVOEntry *entry = [[ZFKVOEntry alloc] init];
            entry.observer = observer;
            entry.keyPath  = keyPath;
            [_observerArray addObject:entry];
        } @catch (NSException *e) {
            NSLog(@"ZFKVO: failed to add observer for %@\n", keyPath);
        }
    }
}

- (void)safelyRemoveObserver:(NSObject *)observer
                  forKeyPath:(NSString *)keyPath {
    if (_target == nil) return;
    
    NSInteger indexEntry = [self indexEntryOfObserver:observer forKeyPath:keyPath];
    if (indexEntry == NSNotFound) {

        NSLog(@"duplicated observer");
    } else {
        [_observerArray removeObjectAtIndex:indexEntry];
        @try {
            [_target removeObserver:observer
                            forKeyPath:keyPath];
        } @catch (NSException *e) {
            NSLog(@"ZFKVO: failed to remove observer for %@\n", keyPath);
        }
    }
}

- (void)safelyRemoveAllObservers {
    if (_target == nil) return;
    [_observerArray enumerateObjectsUsingBlock:^(ZFKVOEntry *entry, NSUInteger idx, BOOL *stop) {
        if (entry == nil) return;
        NSObject *observer = entry.observer;
        if (observer == nil) return;
        @try {
            [_target removeObserver:observer
                        forKeyPath:entry.keyPath];
        } @catch (NSException *e) {
            NSLog(@"ZFKVO: failed to remove observer for %@\n", entry.keyPath);
        }
    }];
    
    [_observerArray removeAllObjects];
}

- (NSInteger)indexEntryOfObserver:(NSObject *)observer
                   forKeyPath:(NSString *)keyPath {
    __block NSInteger foundIndex = NSNotFound;
    [_observerArray enumerateObjectsUsingBlock:^(ZFKVOEntry *entry, NSUInteger idx, BOOL *stop) {
        if (entry.observer == observer &&
            [entry.keyPath isEqualToString:keyPath]) {
            foundIndex = idx;
            *stop = YES;
        }
    }];
    return foundIndex;
}

@end
