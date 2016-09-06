//
//  UIProgressView+ImageDownLoader2.h
//  ClassicPhotos
//
//  Created by xwwang_0102 on 16/9/5.
//  Copyright © 2016年 bitcar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageDownLoader2.h"
@interface UIProgressView (ImageDownLoader2)

/**
 Binds the progress to the download progress of the specified request operation.
 
 @param operation The request operation.
 @param animated `YES` if the change should be animated, `NO` if the change should happen immediately.
 */
- (void)setProgressWithDownloadProgressOfOperation:(ImageDownLoader2 *)operation
                                          animated:(BOOL)animated;


@end
