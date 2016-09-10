//
//  FTPManager.h
//  ClassicPhotos
//
//  Created by xwwang_0102 on 16/9/9.
//  Copyright © 2016年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CFNetwork/CFNetwork.h>

enum {
    kSendBufferSize = 32768
};

@protocol FTPManagerDelegate <NSObject>

-(void)ftpUploadFinishedWithSuccess:(BOOL)success;
-(void)ftpDownloadFinishedWithSuccess:(BOOL)success;
-(void)directoryListingFinishedWithSuccess:(NSArray *)arr;
-(void)ftpError:(NSString *)err;

@end

@interface FTPManager : NSObject<NSStreamDelegate>

- (id)initWithServer:(NSString *)server user:(NSString *)username
            password:(NSString *)pass;

- (void)downloadRemoteFile:(NSString *)filename localFileName:(NSString *)localname;
- (void)uploadFileWithFilePath:(NSString *)filePath;
- (void)createRemoteDirectory:(NSString *)dirname;
- (void)listRemoteDirectory;
@property (nonatomic, weak) id<FTPManagerDelegate>;
@property (nonatomic, retain) NSString *ftpServer;
@property (nonatomic, retain) NSString *ftpUsername;
@property (nonatomic, retain) NSString *ftpPassword;

@end
