//
//  ImageDownLoader2.m
//  ClassicPhotos
//
//  Created by xwwang_0102 on 16/8/21.
//  Copyright © 2016年 bitcar. All rights reserved.
//

#import "ImageDownLoader2.h"


typedef NS_ENUM(NSInteger, operationState) {
    operationPausedState      = -1,
    operationReadyState       = 1,
    operationExecutingState   = 2,
    operationFinishedState    = 3,
};

static inline NSString * keyPathFromOperationState(operationState state) {
    switch (state) {
        case operationReadyState:
            return @"isReady";
        case operationExecutingState:
            return @"isExecuting";
        case operationFinishedState:
            return @"isFinished";
        case operationPausedState:
            return @"isPaused";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return @"state";
#pragma clang diagnostic pop
        }
    }
}

static dispatch_group_t url_request_operation_completion_group() {
    static dispatch_group_t af_url_request_operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_request_operation_completion_group = dispatch_group_create();
    });
    
    return af_url_request_operation_completion_group;
}

@interface ImageDownLoader2 ()

@property (readwrite, nonatomic, assign) operationState state;

@property (readwrite, nonatomic, strong) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, strong) id responseObject;
@property (readwrite, nonatomic, strong) NSError *responseSerializationError;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSData *responseData;


@property (readwrite, nonatomic, assign) long long totalBytesRead;

@end

@implementation ImageDownLoader2

@synthesize delegate = _delegate;
@synthesize indexPathInTableView = _indexPathInTableView;
@synthesize photoRecord = _photoRecord;
@synthesize downloadProgress =_downloadProgress;


#pragma mark -
#pragma mark - Life Cycle

- (id)init
{
    if (self = [super init]) {
        self.state = operationReadyState;
    }
    return self;
}

- (id)initWithPhotoRecord:(PhotoRecord *)record AtIndexPath:(NSIndexPath *)indexPath delegate:(id)theDelegate
{
    if (self = [super init]) {
        self.delegate = theDelegate;
        self.indexPathInTableView = indexPath;
        self.photoRecord = record;
        [self registerForKVO];
        self.state = operationReadyState;
    }
    return self;
}

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"AFNetworking"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (void)start
{
    if (self.isCancelled) {
        return;
    }
    
    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
}

- (void)operationDidStart {
    //[self.lock lock];//self.photoRecord.URL
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://codeload.github.com/Ahmed-Ali/JSONExport/zip/master"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    //request.HTTPShouldHandleCookies = (options & EMSDWebImageDownloaderHandleCookies);
    request.HTTPShouldUsePipelining = YES;
    [request setValue:[NSString stringWithFormat:@"bytes=%d-", 20000] forHTTPHeaderField:@"Range"];
    
    
    if (![self isCancelled]) {
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [self.connection start];
        [self.outputStream open];
        self.state = operationExecutingState;
        
    }
    //[self.lock unlock];
}



#pragma mark NSUrlConnectionDelegate
- (void)connection:(NSURLConnection __unused *)connection
didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
   // NSDictionary *xx = [response a]
    NSLog(@"expectedContentLength is %lld",response.expectedContentLength);
}

- (void)connection:(NSURLConnection __unused *)connection
    didReceiveData:(NSData *)data
{
    NSUInteger length = [data length];
    while (YES) {
        NSInteger totalNumberOfBytesWritten = 0;
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *)[data bytes];
            
            NSInteger numberOfBytesWritten = 0;
            while (totalNumberOfBytesWritten < (NSInteger)length) {
                numberOfBytesWritten = [self.outputStream write:&dataBuffer[(NSUInteger)totalNumberOfBytesWritten] maxLength:(length - (NSUInteger)totalNumberOfBytesWritten)];
                if (numberOfBytesWritten == -1) {
                    break;
                }
                
                totalNumberOfBytesWritten += numberOfBytesWritten;
            }
            
            break;
        }
        
       
        if (self.outputStream.streamError) {
            [self.connection cancel];
            [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:self.outputStream.streamError];
            return;
        }
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalBytesRead += length;
        
        if (self.downloadProgress) {
            self.downloadProgress(length, self.totalBytesRead, self.response.expectedContentLength);
        }
    });
    NSLog(@"下载数据参数 ＝ %lld,%lld",self.totalBytesRead,self.response.expectedContentLength);
   // NSLog(@"下载到数据 比率 ＝ %f",(self.totalBytesRead *1.0f) /self.response.expectedContentLength);

}

- (void)setDownloadProgress:( void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block{
    _downloadProgress = block;
}

<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
- (void)connectionDidFinishLoading:(NSURLConnection __unused *)connection {
   // self.responseData = [self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey];
    
    [self.outputStream close];
    if (self.responseData) {
        self.outputStream = nil;
    }
    
    self.connection = nil;
    
    if (self.responseData) {
        UIImage *downloadImage = [UIImage imageWithData:self.responseData];
        self.photoRecord.image = downloadImage;
    }else {
        self.photoRecord.failed = YES;
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection __unused *)connection
  didFailWithError:(NSError *)error
{
//    self.error = error;
//    
    [self.outputStream close];
    if (self.responseData) {
        self.outputStream = nil;
    }
    
    self.connection = nil;
    
    [self finish];
}

- (NSOutputStream *)outputStream {
    if (!_outputStream) {
        NSArray *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [docs[0] stringByAppendingPathComponent:@"downloadFile"];
        NSLog(@"下载的地址:%@",path);
        
        NSString *pathMD5 = [MD5 md5:path];
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    }
    return _outputStream;
}

- (void)setResponseData:(NSData *)responseData {
    [self.lock lock];
    if (!responseData) {
        _responseData = nil;
    } else {
        _responseData = [NSData dataWithBytes:responseData.bytes length:responseData.length];
    }
    [self.lock unlock];
}


-(void)finish   //一些收尾工作
{
    
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(imageDownloaderDidFinish:) withObject:self waitUntilDone:NO];
    self.state = operationFinishedState;
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:self];
//    });
    
}

- (void)registerForKVO {
    for (NSString *keyPath in [self observableKeypaths]) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (NSArray *)observableKeypaths {
    return [NSArray arrayWithObjects:@"isFinished", @"isExecuting",@"isReady", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    NSLog(@"第%ld行下载状态:%@",(long)((ImageDownLoader2*)object).indexPathInTableView.row,keyPath);
}

- (void)setState:(operationState)state {
    NSString *oldStateKey = keyPathFromOperationState(self.state);
    NSString *newStateKey = keyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
}

#pragma mark --NSOperation
- (void)setCompletionBlock:(void (^)(void))block {

    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __weak __typeof(self)weakSelf = self;
        [super setCompletionBlock:^ {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_group_t group =  url_request_operation_completion_group();
            dispatch_queue_t queue =  dispatch_get_main_queue();
#pragma clang diagnostic pop
            
            dispatch_group_async(group, queue, ^{
                block();
            });
            
            dispatch_group_notify(group, queue, ^{
                [strongSelf setCompletionBlock:nil];
            });
        }];
    }

}

- (BOOL)isReady {
    return self.state == operationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == operationExecutingState;
}

- (BOOL)isFinished {
    return self.state == operationFinishedState;
}

#pragma mark --
- (void)resume {
    if (![self isPaused]) {
        return;
    }
    
    self.state = operationReadyState;
    
    [self start];
}
- (void)pause {
    if ([self isPaused] || [self isFinished] || [self isCancelled]) {
        return;
    }
    
   
    if ([self isExecuting]) {
        [self performSelector:@selector(operationDidPause) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
    }
    
    self.state = operationPausedState;
}

- (void)operationDidPause {
    unsigned long long offset = 0;
    if ([self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey]) {
        offset = [[self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedLongLongValue];
    } else {
        offset = [[self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey] length];
    }
    
    NSMutableURLRequest *mutableURLRequest = [self.request mutableCopy];
    if ([self.response respondsToSelector:@selector(allHeaderFields)] && [[self.response allHeaderFields] valueForKey:@"ETag"]) {
        [mutableURLRequest setValue:[[self.response allHeaderFields] valueForKey:@"ETag"] forHTTPHeaderField:@"If-Range"];
    }
    [mutableURLRequest setValue:[NSString stringWithFormat:@"bytes=%llu-", offset] forHTTPHeaderField:@"Range"];
    self.request = mutableURLRequest;
    
    [self.lock lock];
    [self.connection cancel];
    [self.lock unlock];
}

- (BOOL)isPaused {
    return self.state == operationPausedState;
}

@end
