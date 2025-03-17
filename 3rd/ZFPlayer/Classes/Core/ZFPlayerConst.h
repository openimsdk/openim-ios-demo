























typedef NS_ENUM(NSUInteger, ZFPlayerPlaybackState) {
    ZFPlayerPlayStateUnknown,
    ZFPlayerPlayStatePlaying,
    ZFPlayerPlayStatePaused,
    ZFPlayerPlayStatePlayFailed,
    ZFPlayerPlayStatePlayStopped
};

typedef NS_OPTIONS(NSUInteger, ZFPlayerLoadState) {
    ZFPlayerLoadStateUnknown        = 0,
    ZFPlayerLoadStatePrepare        = 1 << 0,
    ZFPlayerLoadStatePlayable       = 1 << 1,
    ZFPlayerLoadStatePlaythroughOK  = 1 << 2, // Playback will be automatically started.
    ZFPlayerLoadStateStalled        = 1 << 3, // Playback will be automatically paused in this state, if started.
};

typedef NS_ENUM(NSInteger, ZFPlayerScalingMode) {
    ZFPlayerScalingModeNone,       // No scaling.
    ZFPlayerScalingModeAspectFit,  // Uniform scale until one dimension fits.
    ZFPlayerScalingModeAspectFill, // Uniform scale until the movie fills the visible bounds. One dimension may have clipped contents.
    ZFPlayerScalingModeFill        // Non-uniform scale. Both render dimensions will exactly match the visible bounds.
};

/**
 Synthsize a weak or strong reference.
 
 Example:
 @zf_weakify(self)
 [self doSomething^{
 @zf_strongify(self)
 if (!self) return;
 ...
 }];
 
 */
#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define zf_weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define zf_weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define zf_weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define zf_weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define zf_strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define zf_strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define zf_strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define zf_strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

#define ZFPlayerScreenWidth     [[UIScreen mainScreen] bounds].size.width

#define ZFPlayerScreenHeight    [[UIScreen mainScreen] bounds].size.height

#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

