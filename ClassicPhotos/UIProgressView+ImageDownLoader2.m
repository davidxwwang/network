//
//  UIProgressView+ImageDownLoader2.m
//  ClassicPhotos
//
//  Created by xwwang_0102 on 16/9/5.
//  Copyright © 2016年 bitcar. All rights reserved.
//

#import "UIProgressView+ImageDownLoader2.h"

@implementation UIProgressView (ImageDownLoader2)

- (void)setProgressWithDownloadProgressOfOperation:(ImageDownLoader2 *)operation
                                          animated:(BOOL)animated
{
    [operation setDownloadProgress:^(NSUInteger bytes, long long totalBytes, long long totalBytesExpected){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (totalBytesExpected > 0) {
               // [self setProgress:(totalBytes / (totalBytesExpected * 1.0f)) animated:animated];
            }
        });
        
    }];

}



@end
