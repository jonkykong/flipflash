//
//  TCKit.m
//  FlipFlash
//
//  Created by Jon Kent on 4/7/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCKit.h"
#import <CommonCrypto/CommonDigest.h>
#import <mach/mach.h>

#pragma mark - Image
@implementation UIImage (TC)

- (UIImage *)scaleImageToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

#pragma mark - Data
@implementation NSData (TC)

+ (NSString *)md5hash {
    uint64_t now = [NSDate ticks];
    if(now == -1) {
        return nil;
    }
    NSData *nowData = [NSData dataWithBytes: &now length: sizeof(now)];
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(nowData.bytes, (CC_LONG)nowData.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end


#pragma mark - NSDate
@implementation NSDate (TC)

+ (uint64_t)ticks {
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) {
        return -1.0;
    }
    return mach_absolute_time();
}

@end

#pragma mark - UINavigtionController
@implementation UINavigationController (TC)

- (CGFloat)navigationHeight {
    CGFloat statusBarHeight = fminf([[UIApplication sharedApplication] statusBarFrame].size.width, [[UIApplication sharedApplication] statusBarFrame].size.height);
    return self.navigationBar.frame.size.height + statusBarHeight;
}

@end