#import "ReactNativeImageCropping.h"
#import <UIKit/UIKit.h>
#import "TOCropViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ReactNativeImageCropping () <TOCropViewControllerDelegate>

@property (nonatomic, strong) RCTPromiseRejectBlock _reject;
@property (nonatomic, strong) RCTPromiseResolveBlock _resolve;
@property TOCropViewControllerAspectRatio aspectRatio;


@end

@implementation RCTConvert (AspectRatio)
RCT_ENUM_CONVERTER(TOCropViewControllerAspectRatio, (@{
            @"AspectRatioOriginal" : @(TOCropViewControllerAspectRatioOriginal),
              @"AspectRatioSquare" : @(TOCropViewControllerAspectRatioSquare),
                 @"AspectRatio3x2" : @(TOCropViewControllerAspectRatio3x2),
                 @"AspectRatio5x3" : @(TOCropViewControllerAspectRatio5x3),
                 @"AspectRatio4x3" : @(TOCropViewControllerAspectRatio4x3),
                 @"AspectRatio5x4" : @(TOCropViewControllerAspectRatio5x4),
                 @"AspectRatio7x5" : @(TOCropViewControllerAspectRatio7x5),
                @"AspectRatio16x9" : @(TOCropViewControllerAspectRatio16x9)
                }), UIStatusBarAnimationNone, integerValue)
@end

@implementation ReactNativeImageCropping

RCT_EXPORT_MODULE()


@synthesize bridge = _bridge;

- (NSDictionary *)constantsToExport
{
    return @{
   @"AspectRatioOriginal" : @(TOCropViewControllerAspectRatioOriginal),
     @"AspectRatioSquare" : @(TOCropViewControllerAspectRatioSquare),
        @"AspectRatio3x2" : @(TOCropViewControllerAspectRatio3x2),
        @"AspectRatio5x3" : @(TOCropViewControllerAspectRatio5x3),
        @"AspectRatio4x3" : @(TOCropViewControllerAspectRatio4x3),
        @"AspectRatio5x4" : @(TOCropViewControllerAspectRatio5x4),
        @"AspectRatio7x5" : @(TOCropViewControllerAspectRatio7x5),
       @"AspectRatio16x9" : @(TOCropViewControllerAspectRatio16x9),
    };
}

RCT_EXPORT_METHOD(  cropImageWithUrl:(NSString *)imageUrl deftype:(NSString *)type
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject

)
{
    self._reject = reject;
    self._resolve = resolve;
    self.aspectRatio = NULL;
    
    
    
    
    if ([type isEqualToString:@"PATH"]){
        NSLog(@"This is it: %@", @"This is path!");
        UIImage *image = [UIImage imageWithContentsOfFile:imageUrl];
        UIImage *resizeImg = [self resizeImage:image];
        
        if(resizeImg){
            [self handleImageLoad:resizeImg];
        }
//        if(image) {
//            [self handleImageLoad:image];
//        }
        
    }
    else if([type isEqualToString:@"URL"]) {
        NSLog(@"This is it: %@", @"This is URL!");
        NSURLRequest *imageUrlrequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]];
        
        [self.bridge.imageLoader loadImageWithURLRequest:imageUrlrequest callback:^(NSError *error, UIImage *image) {
            if(error) reject(@"100", @"Failed to load image", error);
//            if(image) {
//                [self handleImageLoad:image];
//            }
            
            UIImage *resizeImg = [self resizeImage:image];

            if(resizeImg){
                [self handleImageLoad:resizeImg];
            }
            
        }];
    }
    else if([type isEqualToString:@"ASSET"]) {
        // assets path
        NSLog(@"This is it: %@", @"assets path!");
        
        NSURL *url = [NSURL URLWithString:imageUrl];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:url resultBlock:^(ALAsset *asset) {
            
            ALAssetRepresentation *representation = [asset defaultRepresentation];
            
            UIImage *img = [UIImage imageWithCGImage:[representation fullResolutionImage]];
            
            UIImage *resizeImg = [self resizeImage:img];
            
//            if(img) {
//                [self handleImageLoad:img];
//            }
            if(resizeImg){
                [self handleImageLoad:resizeImg];
            }
            
        } failureBlock:^(NSError *error) {
            NSLog(@"that didn't work %@", error);
        }];
        
        
        
    }
    
    
    
    
}

RCT_EXPORT_METHOD(cropImageWithUrlAndAspect:(NSString *)imageUrl deftype:(NSString *)type
                                aspectRatio:(TOCropViewControllerAspectRatio)aspectRatio
                                   resolver:(RCTPromiseResolveBlock)resolve
                                   rejecter:(RCTPromiseRejectBlock)reject
        )
{
    self._reject = reject;
    self._resolve = resolve;
    self.aspectRatio = aspectRatio;
    
    NSURLRequest *imageUrlrequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    
    [self.bridge.imageLoader loadImageWithURLRequest:imageUrlrequest callback:^(NSError *error, UIImage *image) {
        if(error) reject(@"100", @"Failed to load image", error);
        
        UIImage *resizeImg = [self resizeImage:image];
        
        if(resizeImg){
            [self handleImageLoad:resizeImg];
        }
        
//        if(image) {
//            [self handleImageLoad:image];
//        }
    }];

}

//resize the image because we can send only 10mb so we set it to 4 mb max
-(UIImage *)resizeImage:(UIImage *)image
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 1024.0;
    float maxWidth = 1024.0;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth)
    {
        if(imgRatio < maxRatio)
        {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio)
        {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else
        {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, compressionQuality);
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
    
}

- (void)handleImageLoad:(UIImage *)image {
    
    UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:image];
    cropViewController.delegate = self;
    
    if(self.aspectRatio) {
        cropViewController.lockedAspectRatio = YES;
        cropViewController.defaultAspectRatio = self.aspectRatio;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [root presentViewController:cropViewController animated:YES completion:nil];
    });
}

/**
 Called when the user has committed the crop action, and provides both the original image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [cropViewController dismissViewControllerAnimated:YES completion:nil];
    });
    
    NSData *pngData = UIImagePNGRepresentation(image);
    NSString *fileName = [NSString stringWithFormat:@"memegenerator-crop-%lf.png", [NSDate timeIntervalSinceReferenceDate]];
    
    //commented out because temp dir will clean up after three days lifetime
    //NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName]; //Add the file name)
    //[pngData writeToFile:filePath atomically:YES];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    
    NSString *filePath = [documentPath stringByAppendingPathComponent:fileName]; //Add the file name)
    
    [pngData writeToFile:filePath atomically:YES];
    
    NSNumber *width  = [NSNumber numberWithFloat:image.size.width];
    NSNumber *height = [NSNumber numberWithFloat:image.size.height];
    
    NSDictionary * imageData = @{
                             @"uri":filePath,
                             @"width":width,
                             @"height":height
                             };
    self._resolve(imageData);
}
/**
 If implemented, when the user hits cancel, or completes a UIActivityViewController operation, this delegate will be called,
 giving you a chance to manually dismiss the view controller
 
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didFinishCancelled:(BOOL)cancelled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [cropViewController dismissViewControllerAnimated:YES completion:nil];
    });
    self._reject(@"400", @"Cancelled", [NSError errorWithDomain:@"Cancelled" code:400 userInfo:NULL]);
}
@end
