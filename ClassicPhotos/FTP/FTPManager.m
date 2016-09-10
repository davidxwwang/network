//
//  FTPManager.m
//  ClassicPhotos
//
//  Created by xwwang_0102 on 16/9/9.
//  Copyright © 2016年 bitcar. All rights reserved.
//

#import "FTPManager.h"

@implementation FTPManager
-(id)initWithServer:(NSString *)server user:(NSString *)username password:(NSString *)pass
{
    if ((self = [super init])){
    
        self.ftpServer = server;
        self.ftpUsername = username;
        self.ftpPassword = pass;
    }
    return self;  
}

-(void)scheduleInCurrentThread:(NSStream*)aStream
{
    [aStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
}

-(NSURL *)smartURLForString:(NSString *)str
{
    NSURL * result;
    NSString * trimmedStr;
    NSRange schemeMarkerRange;
    NSString * scheme;
    result = nil;
    trimmedStr = [str stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceCharacterSet]];
    
    if ( (trimmedStr != nil) && ([trimmedStr length] != 0) ) {
        schemeMarkerRange = [trimmedStr rangeOfString:@"://"];
        if (schemeMarkerRange.location == NSNotFound) {
            
            result = [NSURL URLWithString:[NSString stringWithFormat: @"ftp://%@", trimmedStr]];
        } else {
            
            scheme = [trimmedStr substringWithRange:
                      NSMakeRange(0, schemeMarkerRange.location)];
            if ( ([scheme compare:@"http" options:
                   NSCaseInsensitiveSearch] == NSOrderedSame) ) {
                result = [NSURL URLWithString:trimmedStr];  
            } else {  
                //unsupported url schema  
            }   
        }  
    }  
    return result;   
}

-(BOOL)isReceiving {
    return (_dataStream != nil);
}
- (BOOL)isSending {
    return (_commandStream != nil);
}


-(void)closeAll {
    if (_commandStream != nil) {
        [_commandStream removeFromRunLoop:
         [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _commandStream.delegate = nil;
        [_commandStream close];
        _commandStream = nil;
    }
    if (_uploadStream != nil) {
        [_uploadStream close];
        _uploadStream = nil; }
    if (_downloadfileStream != nil) {
        [_downloadfileStream close];
        _downloadfileStream = nil;
    }
    if (_dataStream != nil) {
        [_dataStream removeFromRunLoop:
         [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _dataStream.delegate = nil;
        [_dataStream close];   
        _dataStream = nil;  
    }  
    _currentOperation = @"";   
}



-(void)downloadRemoteFile:(NSString *)filename localFileName:(NSString *)localname
{
    BOOL success;
    
    NSURL * url;
    
    url = [self smartURLForString:[NSString stringWithFormat:
                                   @"%@/%@",_ftpServer,filename]];
    success = (url != nil);
    if ( ! success) {
        [self.delegate ftpError:@"invalid url for downloadRemoteFile method"];
    } else {
        if (self.isReceiving){
            
            [self.delegate ftpError:@"receiving in progress"];
            return ;
        }
        
        NSString *path = [NSTemporaryDirectory()
                          stringByAppendingPathComponent:localname];
        _downloadfileStream = [NSOutputStream outputStreamToFileAtPath:
                               path append:NO];
        [_downloadfileStream open];
        _currentOperation = @"GET";
        _dataStream=CFBridgingRelease( CFReadStreamCreateWithFTPURL(NULL,(__bridge CFURLRef) url));
        [_dataStream  setProperty:_ftpUsername
                           forKey:(id)kCFStreamPropertyFTPUserName];
        [_dataStream  setProperty:_ftpPassword
                           forKey:(id)kCFStreamPropertyFTPPassword];
        _dataStream.delegate = self;
        
        [self performSelector:@selector(scheduleInCurrentThread:)
                     onThread:[[self class] networkThread]  
                   withObject:_dataStream waitUntilDone:YES];  
        [_dataStream open];  
    }  
}


- (void)createRemoteDirectory:(NSString *)dirname
{}
- (void)listRemoteDirectory
{}


@end
