
#import "WPFPinYinDataManager.h"
#import "WPFPerson.h"
#import "WPFPinYinTools.h"


@interface WPFPinYinDataManager ()

@property (nonatomic, strong) HanyuPinyinOutputFormat *outputFormat;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation WPFPinYinDataManager

#pragma mark - Public Method

+ (void)addInitializeString:(NSString *)string identifer:(NSString *)identifier {
    [self addInitializeString:string sub:nil identifer:identifier];
}

+ (void)addInitializeString:(NSString *)string sub:(NSString *)sub identifer:(NSString *)identifier {
    WPFPinYinDataManager *manager = [WPFPinYinDataManager shareInstance];
    WPFPerson *person = [WPFPerson personWithId:identifier name:string sub:sub hanyuPinyinOutputFormat:manager.outputFormat];
    [manager.dataSource addObject:person];
}

+ (NSArray *)getInitializedDataSource {
    return [WPFPinYinDataManager shareInstance].dataSource;
}

- (void)clearDataSource {
    [_dataSource removeAllObjects];
}

#pragma mark Private Method
+ (WPFPinYinDataManager *)shareInstance {
    static dispatch_once_t onceToken;
    static WPFPinYinDataManager *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [[WPFPinYinDataManager alloc] init];
    });
    return _instance;
}

#pragma Setters && Getters
- (HanyuPinyinOutputFormat *)outputFormat {
    if (!_outputFormat) {
        _outputFormat = [WPFPinYinTools getOutputFormat];
    }
    return _outputFormat;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
