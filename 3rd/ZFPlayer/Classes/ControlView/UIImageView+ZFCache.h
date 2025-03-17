























#import <UIKit/UIKit.h>

typedef void (^ZFDownLoadDataCallBack)(NSData *data, NSError *error);
typedef void (^ZFDownloadProgressBlock)(unsigned long long total, unsigned long long current);

@interface ZFImageDownloader : NSObject<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;

@property (nonatomic, assign) unsigned long long totalLength;
@property (nonatomic, assign) unsigned long long currentLength;

@property (nonatomic, copy) ZFDownloadProgressBlock progressBlock;
@property (nonatomic, copy) ZFDownLoadDataCallBack callbackOnFinished;

- (void)startDownloadImageWithUrl:(NSString *)url
                         progress:(ZFDownloadProgressBlock)progress
                         finished:(ZFDownLoadDataCallBack)finished;

@end

typedef void (^ZFImageBlock)(UIImage *image);

@interface UIImageView (ZFCache)

/**
 *  Get/Set the callback block when download the image finished.
 *
 *  The image object from network or from disk.
 */
@property (nonatomic, copy) ZFImageBlock completion;

/**
 *  Image downloader
 */
@property (nonatomic, strong) ZFImageDownloader *imageDownloader;

/**
 *	Specify the URL to download images fails, the number of retries, the default is 2
 */
@property (nonatomic, assign) NSUInteger attemptToReloadTimesForFailedURL;

/**
 *	Will automatically download to cutting for UIImageView size of image.The default value is NO.
 *  If set to YES, then the download after a successful store only after cutting the image
 */
@property (nonatomic, assign) BOOL shouldAutoClipImageToViewSize;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param placeholderImageName The image name to be set initially, until the image request finishes.
 */
- (void)setImageWithURLString:(NSString *)url placeholderImageName:(NSString *)placeholderImageName;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url              The url for the image.
 * @param placeholderImage The image to be set initially, until the image request finishes.
 */
- (void)setImageWithURLString:(NSString *)url placeholder:(UIImage *)placeholderImage;

/**
 * Set the imageView `image` with an `url`, placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url               The url for the image.
 * @param placeholderImage  The image to be set initially, until the image request finishes.
 * @param completion        A block called when operation has been completed. This block has no return value
 *                          and takes the requested UIImage as first parameter. In case of error the image parameter
 *                          is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                          indicating if the image was retrieved from the local cache or from the network.
 *                          The fourth parameter is the original image url.
 */
- (void)setImageWithURLString:(NSString *)url
                  placeholder:(UIImage *)placeholderImage
                   completion:(void (^)(UIImage *image))completion;

/**
 * Set the imageView `image` with an `url`, placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholderImageName    The image name to be set initially, until the image request finishes.
 * @param completion     A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrieved from the local cache or from the network.
 *                       The fourth parameter is the original image url.
 */
- (void)setImageWithURLString:(NSString *)url
         placeholderImageName:(NSString *)placeholderImageName
                   completion:(void (^)(UIImage *image))completion;
@end
