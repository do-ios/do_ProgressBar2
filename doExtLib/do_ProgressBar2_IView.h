//
//  do_ProgressBar2_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_ProgressBar2_IView <NSObject>

@required
//属性方法
- (void)change_fontColor:(NSString *)newValue;
- (void)change_fontSize:(NSString *)newValue;
- (void)change_progress:(NSString *)newValue;
- (void)change_progressBgColor:(NSString *)newValue;
- (void)change_progressColor:(NSString *)newValue;
- (void)change_progressWidth:(NSString *)newValue;
- (void)change_style:(NSString *)newValue;
- (void)change_text:(NSString *)newValue;

//同步或异步方法


@end