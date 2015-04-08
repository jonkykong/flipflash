//
//  TCCardData.m
//  testing swiping
//
//  Created by Jon Kent on 3/19/15.
//  Copyright (c) 2015 Jon Kent. All rights reserved.
//

#import "TCCard.h"

@interface TCCard ()
@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, assign) BOOL sending;
@end

@implementation TCCard

@synthesize data;
@synthesize sending;

static const NSString *kTCCardDataFrontText = @"frontText";
static const NSString *kTCCardDataFrontImage = @"frontImage";
static const NSString *kTCCardDataFrontImagePath = @"frontImagePath";
static const NSString *kTCCardDataBackText = @"backText";
static const NSString *kTCCardDataBackImage = @"backImage";
static const NSString *kTCCardDataBackImagePath = @"backImagePath";
static const NSString *kTCCardDataScoreRight = @"scoredRight";
static const NSString *kTCCardDataScoreWrong = @"scoredWrong";
static const NSString *kTCCardDataScoreLatest = @"scoredLatest";
static const NSString *kTCCardData = @"data";

- (instancetype)init {
    self = [super init];
    if (self) {
        data = [NSMutableDictionary dictionaryWithCapacity:4];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [[[self class] alloc] init];
    if (self) {
        data = [coder decodeObjectForKey:(NSString *)kTCCardData];
        UIImage *frontImage = data[kTCCardDataFrontImage];
        UIImage *backImage = data[kTCCardDataBackImage];
        // create files for images
        if(frontImage) self.frontImage = frontImage;
        if(backImage) self.backImage = backImage;
        // clear images from data
        [data setValue:nil forKey:(NSString *)kTCCardDataFrontImage];
        [data setValue:nil forKey:(NSString *)kTCCardDataBackImage];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSString *frontImagePath;
    NSString *backImagePath;
    if(sending) {
        frontImagePath = data[kTCCardDataFrontImagePath];
        backImagePath = data[kTCCardDataBackImagePath];
        [data setValue:self.frontImage forKey:(NSString *)kTCCardDataFrontImage];
        [data setValue:self.backImage forKey:(NSString *)kTCCardDataBackImage];
        [data setValue:nil forKey:(NSString *)kTCCardDataFrontImagePath];
        [data setValue:nil forKey:(NSString *)kTCCardDataBackImagePath];
    }
    
    [coder encodeObject:data forKey:(NSString *)kTCCardData];
    
    if(sending) {
        [data setValue:nil forKey:(NSString *)kTCCardDataFrontImage];
        [data setValue:nil forKey:(NSString *)kTCCardDataBackImage];
        [data setValue:frontImagePath forKey:(NSString *)kTCCardDataFrontImagePath];
        [data setValue:backImagePath forKey:(NSString *)kTCCardDataBackImagePath];
    }
}

- (void)encodeForSending:(BOOL)isSending {
    self.sending = isSending;
}

- (void)dealloc {
    // delete image files associated with the removed card
    self.frontImage = nil;
    self.backImage = nil;
}

#pragma mark - Setters

- (void)setFrontText:(NSString *)frontText {
    [data setValue:frontText forKey:(NSString *)kTCCardDataFrontText];
}

- (void)setBackText:(NSString *)backText {
    [data setValue:backText forKey:(NSString *)kTCCardDataBackText];
}

- (void)setFrontImage:(UIImage *)frontImage {
    [self setImage:frontImage forKey:(NSString *)kTCCardDataFrontImagePath];
}

- (void)setBackImage:(UIImage *)backImage {
    [self setImage:backImage forKey:(NSString *)kTCCardDataBackImagePath];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    NSString *filePath = data[key];
    
    // delete file if it exists from previous
    if(filePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    if(image) {
        filePath = [TCCard filePathForImageToSave:image];
    } else {
        filePath = nil;
    }
    
    [data setValue:filePath forKey:(NSString *)key];
}

- (void)incrementScoreRight {
    NSNumber *number = [NSNumber numberWithInteger:[self scoredRight] + 1];
    [data setValue:number forKey:(NSString *)kTCCardDataScoreRight];
    [data setValue:@1 forKey:(NSString *)kTCCardDataScoreLatest];
}

- (void)incrementScoreWrong {
    NSNumber *number = [NSNumber numberWithInteger:([self scoredWrong]) + 1];
    [data setValue:number forKey:(NSString *)kTCCardDataScoreWrong];
    [data setValue:@-1 forKey:(NSString *)kTCCardDataScoreLatest];
}

- (void)resetScores {
    NSNumber *number = @0;
    [data setValue:number forKey:(NSString *)kTCCardDataScoreRight];
    [data setValue:number forKey:(NSString *)kTCCardDataScoreWrong];
    [data setValue:@0 forKey:(NSString *)kTCCardDataScoreLatest];
}

- (void)resetLatestScore {
    [data setValue:@0 forKey:(NSString *)kTCCardDataScoreLatest];
}

#pragma mark - Getters

- (NSString *)frontText {
    return data[kTCCardDataFrontText];
}

- (NSString *)backText {
    return data[kTCCardDataBackText];
}

- (UIImage *)frontImage {
    NSString *uniquePath = data[kTCCardDataFrontImagePath];
    if(!uniquePath) {
        return nil;
    }
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:uniquePath];
    return [UIImage imageWithContentsOfFile:filePath];
}

- (void)frontImageWithCompletion:(void (^)(UIImage* image))completion {
    if(!completion) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = self.frontImage;
        if(!image) dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
        dispatch_async(dispatch_get_main_queue(), ^{ completion(image); });
    });
}

- (UIImage *)backImage {
    NSString *uniquePath = data[kTCCardDataBackImagePath];
    if(!uniquePath) {
        return nil;
    }
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:uniquePath];
    return [UIImage imageWithContentsOfFile:filePath];
}

- (void)backImageWithCompletion:(void (^)(UIImage* image))completion {
    if(!completion) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = self.backImage;
        if(!image) dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
        dispatch_async(dispatch_get_main_queue(), ^{ completion(image); });
    });
}

- (NSUInteger)scoredRight {
    NSNumber *number = data[kTCCardDataScoreRight];
    return number.integerValue;
}

- (NSUInteger)scoredWrong {
    NSNumber *number = data[kTCCardDataScoreWrong];
    return number.integerValue;
}

- (NSInteger)scoredNet {
    return [self scoredRight] - [self scoredWrong];
}

- (NSUInteger)scoredTotal {
    return [self scoredRight] + [self scoredWrong];
}

- (NSInteger)scoredLatest {
    NSNumber *number = data[kTCCardDataScoreLatest];
    return number.integerValue;
}

#pragma mark - image saving/retrieval

+ (NSString *)filePathForImageToSave:(UIImage *)image {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat scale = image.size.width / fminf(screenSize.width, screenSize.height);
    CGSize size = CGSizeMake(image.size.width / scale, image.size.height / scale);
    image = [image scaleImageToSize:size];
    NSString *filePath = [TCCard uniqueFilePath];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
    if(!imageData) {
        return nil;
    }
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    if(![imageData writeToFile:[docPath stringByAppendingPathComponent:filePath] atomically:YES]) {
        return nil;
    }
    return filePath;
}

+ (NSString *)uniqueFilePath {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"Photos"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil];
    if (!exists) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:nil]) {
            return nil;
        }
    }
    NSString *md5hash = [NSData md5hash];
    if(!md5hash) {
        return nil;
    }
    NSString *file = [md5hash stringByAppendingString:@".jpg"];
    filePath = [@"Photos" stringByAppendingPathComponent:file];
    return filePath;
}

@end
