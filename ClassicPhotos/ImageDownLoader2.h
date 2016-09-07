//
//  ImageDownLoader2.h
//  ClassicPhotos
//
//  Created by xwwang_0102 on 16/8/21.
//  Copyright © 2016年 bitcar. All rights reserved.
//
//#import "ImageDownloader.h"
#import "PhotoRecord.h"
#import <Foundation/Foundation.h>

#import "MD5.h"

typedef void (^connectionOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@interface ImageDownLoader2 : NSOperation

@property (nonatomic, assign) id delegate;

@property (nonatomic, readwrite, strong) NSIndexPath *indexPathInTableView;
@property (nonatomic, readwrite, strong) PhotoRecord *photoRecord;

- (id)initWithPhotoRecord:(PhotoRecord *)record AtIndexPath:(NSIndexPath *)indexPath delegate:(id)theDelegate;
@property (readwrite, nonatomic, strong) NSURLConnection *connection;
@property (readonly,  nonatomic, strong) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, strong) NSURLRequest *request;

@property (readwrite, nonatomic, copy) connectionOperationProgressBlock downloadProgress;


- (void)pause;
- (void)resume;

@end
