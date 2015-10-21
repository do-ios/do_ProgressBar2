//
//  do_ProgressBar2_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_ProgressBar2_IView.h"
#import "do_ProgressBar2_UIModel.h"
#import "doIUIModuleView.h"

@interface do_ProgressBar2_UIView : UIView<do_ProgressBar2_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_ProgressBar2_UIModel *_model;
}

@end
