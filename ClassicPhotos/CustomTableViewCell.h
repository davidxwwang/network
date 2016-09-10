//
//  CustomTableViewCell.h
//  ClassicPhotos
//
//  Created by david on 16/9/7.
//  Copyright © 2016年 bitcar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *controllButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end
