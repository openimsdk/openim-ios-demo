
#ifndef _ChineseToPinyinResource_H_
#define _ChineseToPinyinResource_H_

@class NSArray;
@class NSMutableDictionary;

@interface ChineseToPinyinResource : NSObject {
    NSString* _directory;
    NSDictionary *_unicodeToHanyuPinyinTable;
}


- (id)init;
- (void)initializeResource;
- (NSArray *)getHanyuPinyinStringArrayWithChar:(unichar)ch;
- (BOOL)isValidRecordWithNSString:(NSString *)record;
- (NSString *)getHanyuPinyinRecordFromCharWithChar:(unichar)ch;
+ (ChineseToPinyinResource *)getInstance;

@end



#endif // _ChineseToPinyinResource_H_
