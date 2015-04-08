//
//  TCKit.h
//  FlipFlash
//
//  Created by Jon Kent on 4/7/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Image
@interface UIImage (TC)

- (UIImage *)scaleImageToSize:(CGSize)newSize;

@end

#pragma mark - Data
@interface NSData (TC)

+ (NSString *)md5hash;

@end

#pragma mark - NSDate
@interface NSDate (TC)

+ (uint64_t)ticks;

@end

#pragma mark - UINavigtionController
@interface UINavigationController (TC)

- (CGFloat)navigationHeight;

@end