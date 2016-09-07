//
//  ListViewController.m
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//
#import "UIProgressView+ImageDownLoader2.h"
#import "ListViewController.h"

@interface ListViewController ()

@end

@implementation ListViewController
@synthesize photos = _photos;
@synthesize pendingOperations = _pendingOperations;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark -
#pragma mark - Lazy instantiation

- (PendingOperations *)pendingOperations
{
    if (!_pendingOperations) {
        _pendingOperations = [[PendingOperations alloc] init];
    }
    return _pendingOperations;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Classic Photos";
    self.tableView.rowHeight = 80.0f;
    
    ImageDownLoader2 *imageDownloader = [[ImageDownLoader2 alloc] init];

    [imageDownloader setDownloadProgress:^(NSUInteger bytes, long long totalBytes, long long totalBytesExpected){
        NSLog(@"下载到数据 比率 ＝ %f",(totalBytes *1.0f) /totalBytesExpected);
    }];

    //[self.pendingOperations.downloadsInProgress setObject:imageDownloader forKey:indexPath];
   [self.pendingOperations.downloadQueue addOperation:imageDownloader];
    //[self startImageDownloadingForRecord:nil atIndexPath:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (void)controll:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    btn.selected = !btn.isSelected;
    
    if (btn.isSelected == YES) {
        for (id downloader in self.pendingOperations.downloadQueue.operations) {
            [(ImageDownLoader2 *)downloader pause];
        }
    }
    else{
        for (id downloader in self.pendingOperations.downloadQueue.operations) {
            [(ImageDownLoader2 *)downloader resume];
        }
    
    }
    //[self.pendingOperations.downloadQueue addOperation:imageDownloader];

}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIProgressView *view = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        view.frame =  CGRectMake(200, 20, 80, 30);
        view.tag = 1000;
        [cell.contentView addSubview:view];
        view.trackTintColor = [UIColor lightGrayColor];
        view.progressTintColor = [UIColor redColor];
        [view setProgress:0.0];
       // cell.accessoryView = view;
        
        UIButton *controllButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 20, 80, 30)];
        [controllButton setTitle:@"开始" forState:UIControlStateNormal];
        [controllButton setTitle:@"暂停" forState:UIControlStateSelected];
        [controllButton addTarget:self action:@selector(controll:) forControlEvents:UIControlEventTouchUpInside];
        [controllButton setBackgroundColor:[UIColor lightGrayColor]];
        [cell.contentView addSubview:controllButton];
    }
    
    UIProgressView *progressView = (UIProgressView *)[cell.contentView viewWithTag:1000];
    [self startImageDownloadingForRecord:nil progressView:progressView];
    
//    PhotoRecord *aRecord = [self.photos objectAtIndex:indexPath.row];
//
//    if (aRecord.hasImage) {
//        [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
//        cell.imageView.image = aRecord.image;
//        cell.textLabel.text = aRecord.name;
//    }else if (aRecord.isFailed){
//        [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
//        cell.imageView.image = [UIImage imageNamed:@"Failed.png"];
//        cell.textLabel.text = @"Failed to load";
//    }else{
//        [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
//        cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
//        cell.textLabel.text = @"";
//
//        if (!tableView.dragging && !tableView.decelerating) {
//            [self startOperationsForPhotoRecord:aRecord atIndexPath:indexPath];
//        }
//    }
    
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0f;
}


#pragma mark -
#pragma mark - UIScrollView delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 1
    [self suspendAllOperations];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // 2
    if (!decelerate) {
        [self loadImagesForOnscreenCells];
        [self resumeAllOperations];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 3
    [self loadImagesForOnscreenCells];
    [self resumeAllOperations];
}

#pragma mark -
#pragma mark - Cancelling, suspending, resuming queues / operations

- (void)suspendAllOperations {
     NSLog(@"暂停前，下载Queue中operations：%@",self.pendingOperations.downloadQueue.operations);
    [self.pendingOperations.downloadQueue setSuspended:YES];
    [self.pendingOperations.filtrationQueue setSuspended:YES];
    
    NSLog(@"，暂停后，下载Queue中operations：%@",self.pendingOperations.downloadQueue.operations);
}


- (void)resumeAllOperations {
    [self.pendingOperations.downloadQueue setSuspended:NO];
    [self.pendingOperations.filtrationQueue setSuspended:NO];
}


- (void)cancelAllOperations {
    [self.pendingOperations.downloadQueue cancelAllOperations];
    [self.pendingOperations.filtrationQueue cancelAllOperations];
}


- (void)loadImagesForOnscreenCells {
    
    // 1 获取所有可见行
    NSSet *visibleRows = [NSSet setWithArray:[self.tableView indexPathsForVisibleRows]];
    
    // 2 获取所有等待的操作（下载和滤镜的处理）
    NSMutableSet *pendingOperations = [NSMutableSet setWithArray:[self.pendingOperations.downloadsInProgress allKeys]];
    [pendingOperations addObjectsFromArray:[self.pendingOperations.filtrationsInProgress allKeys]];
    
    NSMutableSet *toBeCancelled = [pendingOperations mutableCopy];
    NSMutableSet *toBeStarted = [visibleRows mutableCopy];
    
    // 3 所有开始的操作-pendings的数量
    [toBeStarted minusSet:pendingOperations];
    // 4 所有取消的操作-visible rows的数量
    [toBeCancelled minusSet:visibleRows];
    
    // 5 取消所有等待的操作
    for (NSIndexPath *anIndexPath in toBeCancelled) {
        
        ImageDownLoader2 *pendingDownload = [self.pendingOperations.downloadsInProgress objectForKey:anIndexPath];
        // ImageDownloader *pendingDownload = [self.pendingOperations.downloadsInProgress objectForKey:anIndexPath];
        [pendingDownload cancel];
        [self.pendingOperations.downloadsInProgress removeObjectForKey:anIndexPath];
        
    }
    toBeCancelled = nil;
    
    // 6 循环执行需要开始的操作
    for (NSIndexPath *anIndexPath in toBeStarted) {
        
        PhotoRecord *recordToProcess = [self.photos objectAtIndex:anIndexPath.row];
        [self startOperationsForPhotoRecord:recordToProcess atIndexPath:anIndexPath];
    }
    toBeStarted = nil;
    
}


- (void)startOperationsForPhotoRecord:(PhotoRecord *)record atIndexPath:(NSIndexPath *)indexPath
{
    if (!record.hasImage) {
        [self startImageDownloadingForRecord:record atIndexPath:indexPath];
    }
    
    if (!record.isFiltered) {
      //  [self startImageFiltrationForRecord:record atIndexPath:indexPath];
    }
}

- (void)startImageDownloadingForRecord:(PhotoRecord *)record progressView:(UIProgressView *)progressView
{
    ImageDownLoader2 *imageDownloader = [[ImageDownLoader2 alloc] init];
    if (progressView ) {
        [progressView setProgressWithDownloadProgressOfOperation:imageDownloader animated:NO];
    }
    [self.pendingOperations.downloadQueue addOperation:imageDownloader];
    
}


- (void)startImageDownloadingForRecord:(PhotoRecord *)record atIndexPath:(NSIndexPath *)indexPath
{
    ImageDownLoader2 *imageDownloader = [[ImageDownLoader2 alloc] init];
//    [imageDownloader setDownloadProgress:^(NSUInteger bytes, long long totalBytes, long long totalBytesExpected){
//        NSLog(@"下载到数据 比率 ＝ %lld",totalBytes/totalBytesExpected);
//    }];
    //[self.pendingOperations.downloadsInProgress setObject:imageDownloader forKey:indexPath];
    [self.pendingOperations.downloadQueue addOperation:imageDownloader];

    return;
    
    if (![self.pendingOperations.downloadsInProgress.allKeys containsObject:indexPath]) {
        
        ImageDownLoader2 *imageDownloader = [[ImageDownLoader2 alloc] initWithPhotoRecord:record AtIndexPath:indexPath delegate:self];
        [imageDownloader setCompletionBlock:^{
            NSLog(@" download finished");
        }];
        [self.pendingOperations.downloadsInProgress setObject:imageDownloader forKey:indexPath];
        [self.pendingOperations.downloadQueue addOperation:imageDownloader];
    }
}



- (void)imageDownloaderDidFinish:(ImageDownLoader2 *)downloader
{
    // 1
    NSIndexPath *indexPath = downloader.indexPathInTableView;
    // 2
//    PhotoRecord *theRecord = downloader.photoRecord;
    // 3
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    // 4
    [self.pendingOperations.downloadsInProgress removeObjectForKey:indexPath];
    NSLog(@"下载Queue中operations：%@",self.pendingOperations.downloadQueue.operations);
}


@end
