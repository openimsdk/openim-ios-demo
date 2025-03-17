


#import "WPFPerson.h"

@implementation WPFPerson

+ (instancetype)personWithId:(NSString *)personId name:(NSString *)name hanyuPinyinOutputFormat:(HanyuPinyinOutputFormat *)pinyinFormat {
    return [self personWithId:personId name:name sub:nil hanyuPinyinOutputFormat:pinyinFormat];
}

+ (instancetype)personWithId:(NSString *)personId name:(NSString *)name sub:(nullable NSString *)sub hanyuPinyinOutputFormat:(HanyuPinyinOutputFormat *)pinyinFormat {
    WPFPerson *person = [[WPFPerson alloc] init];

    NSMutableString *completeSpelling = [[NSMutableString alloc] init];
    NSMutableString *polyPhoneCompleteSpelling;

    NSString *initialString = @"";
    NSString *polyPhoneInitialString;

    NSMutableArray *completeSpellingArray = [[NSMutableArray alloc] init];
    NSMutableArray *polyPhoneCompleteSpellingArray;

    NSMutableArray *pinyinFirstLetterLocationArray = [[NSMutableArray alloc] init];
   
    for (NSInteger i = 0; i < name.length; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *hanyuChar = [name substringWithRange:range];
        NSString *mainPinyinStrOfChar;
        NSString *polyPhonePinyinStrOfChar;
        BOOL isPolyPhoneChar = NO;
        
        /** 将单个汉字转化为拼音的类方法
         *  name : 需要转换的汉字
         *  pinyinFormat : 拼音的格式化器
         *  @"" :  seperator 分隔符
         */
        NSArray *pinyinStrArrayOfChar = [PinyinHelper getFormattedHanyuPinyinStringArrayWithChar:[name characterAtIndex:i] withHanyuPinyinOutputFormat:pinyinFormat];

        if ((nil != pinyinStrArrayOfChar) && ((int) [pinyinStrArrayOfChar count] > 0)) {
            mainPinyinStrOfChar = [pinyinStrArrayOfChar objectAtIndex:0];
            if (pinyinStrArrayOfChar.count > 1) {
                polyPhonePinyinStrOfChar = [pinyinStrArrayOfChar objectAtIndex:1];
                person.isContainPolyPhone = YES;
                isPolyPhoneChar = YES;
            }
        }
        
        if (nil != mainPinyinStrOfChar) {
            if (person.isContainPolyPhone) {
                NSString *appendString = isPolyPhoneChar ? polyPhonePinyinStrOfChar : mainPinyinStrOfChar;
                if (polyPhoneCompleteSpelling.length) {
                    [polyPhoneCompleteSpelling appendString:appendString];
                } else {
                    polyPhoneCompleteSpelling = [NSMutableString stringWithFormat:@"%@%@", completeSpelling, appendString];
                }
            }
            [completeSpelling appendString:mainPinyinStrOfChar];

            if ([WPFPinYinTools isChinese:hanyuChar]) {

                NSString *firstLetter = [mainPinyinStrOfChar substringToIndex:1];

                if (person.isContainPolyPhone) {

                    NSString *targetStringOfChar = isPolyPhoneChar ? polyPhonePinyinStrOfChar : mainPinyinStrOfChar;
                    NSString *targetFirstLetter = [targetStringOfChar substringToIndex:1];

                    /** 获取该 多音字 字符的拼音在整个字符串中的位置 */
                    
                    for (NSInteger j= 0 ;j < targetStringOfChar.length ; j++) {
                        if (!polyPhoneCompleteSpellingArray.count) {
                            polyPhoneCompleteSpellingArray = [completeSpellingArray mutableCopy];
                        }
                        [polyPhoneCompleteSpellingArray addObject:@(i)];
                    }

                    if (polyPhoneInitialString.length) {
                        polyPhoneInitialString = [polyPhoneInitialString stringByAppendingString:targetFirstLetter];
                    } else {
                        polyPhoneInitialString = [initialString stringByAppendingString:targetFirstLetter];
                    }

                }
                
                /** 获取该字符的拼音在整个字符串中的位置，如 "wang peng fei"
                 * "wang" 对应的四个拼音字母是 0,0,0,0,
                 * "peng" 对应的四个拼音字母是 1,1,1,1
                 * "fei"  对应的三个拼音字母是 2,2,2
                 */
                for (NSInteger j= 0 ;j < mainPinyinStrOfChar.length ; j++) {
                    [completeSpellingArray addObject:@(i)];
                }

                initialString = [initialString stringByAppendingString:firstLetter];

                [pinyinFirstLetterLocationArray addObject:@(i)];
            }
        } else {

            if (person.isContainPolyPhone) {
                [polyPhoneCompleteSpelling appendFormat:@"%C",[name characterAtIndex:i]];
                [polyPhoneCompleteSpellingArray addObject:@(i)];
                polyPhoneInitialString = [polyPhoneInitialString stringByAppendingString:hanyuChar];
            }
            [completeSpelling appendFormat:@"%C",[name characterAtIndex:i]];
            [completeSpellingArray addObject:@(i)];
            [pinyinFirstLetterLocationArray addObject:@(i)];
            initialString = [initialString stringByAppendingString:hanyuChar];
        }
    }
    
    person.name = name;
    person.sub = sub;
    person.personId = personId;
    person.completeSpelling = completeSpelling;
    person.initialString = initialString;
    person.pinyinLocationString = [completeSpellingArray componentsJoinedByString:@","];
    person.initialLocationString = [pinyinFirstLetterLocationArray componentsJoinedByString:@","];
    if (person.isContainPolyPhone) {
        person.polyPhoneCompleteSpelling = polyPhoneCompleteSpelling;
        person.polyPhoneInitialString = polyPhoneInitialString;
        person.polyPhonePinyinLocationString = [polyPhoneCompleteSpellingArray componentsJoinedByString:@","];
    }
    
    return person;
}

@end
