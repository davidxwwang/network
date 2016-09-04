//
//  ListViewController.h
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "PhotoRecord.h"
#import "PendingOperations.h"
//#import "ImageDownloader.h"
#import "ImageDownLoader2.h"

#import "AFNetworking.h"

#define kDataSourceURLString @"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist"

@protocol ImageDownloaderDelegate <NSObject>

- (void)imageDownloaderDidFinish:(ImageDownLoader2 *)downloader;

@end


@interface ListViewController : UITableViewController <ImageDownloaderDelegate>

@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, strong) PendingOperations *pendingOperations;

@end
