//
//  do_ProgressBar2_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_ProgressBar2_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#define SDProgressViewItemMargin 10

@implementation do_ProgressBar2_UIView
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
//    self.progressBgColor = [_model GetProperty:@"progressBgColor"].DefaultValue;
//    self.progress = [[_model GetProperty:@"progress"].DefaultValue floatValue];
//    self.progressColor = [_model GetProperty:@"progressColor"].DefaultValue;
//    self.progressWidth = [_model GetProperty:@"progressWidth"].DefaultValue;
    self.style = [_model GetProperty:@"style"].DefaultValue;
    self.fontSize = [[_model GetProperty:@"fontSize"].DefaultValue integerValue];
//    self.fontColor = [_model GetProperty:@"fontColor"].DefaultValue;
//    [self drawProgress:CGRectMake(_model.RealX, _model.RealY, _model.RealWidth, _model.RealHeight)];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_fontColor:(NSString *)newValue
{
    //自己的代码实现
    self.fontColor = newValue;
}
- (void)change_fontSize:(NSString *)newValue
{
    //自己的代码实现
    self.fontSize = [newValue integerValue];
}
- (void)change_progress:(NSString *)newValue
{
    //自己的代码实现
    self.progress = [newValue floatValue];
    [self setNeedsDisplay];
}
- (void)change_progressBgColor:(NSString *)newValue
{
    //自己的代码实现
    self.progressBgColor = newValue;
    [self setNeedsDisplay];
}
- (void)change_progressColor:(NSString *)newValue
{
    //自己的代码实现
    self.progressColor = newValue;
    [self setNeedsDisplay];
}
- (void)change_progressWidth:(NSString *)newValue
{
    //自己的代码实现
    self.progressWidth = newValue;
    [self setNeedsDisplay];
}
- (void)change_style:(NSString *)newValue
{
    //自己的代码实现
    self.style = newValue;
}
- (void)change_text:(NSString *)newValue
{
    //自己的代码实现
    self.text = newValue;
//    [self drawText];
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    CGFloat xCenter = (rect.size.width * 0.5) + rect.origin.x;
    CGFloat yCenter = (rect.size.height * 0.5) + rect.origin.y;
    CGFloat radius = MIN(rect.size.width * 0.5, rect.size.height * 0.5) - SDProgressViewItemMargin * 0.2;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // 进度环边框
    UIColor *probgc = [doUIModuleHelper GetColorFromString:self.progressBgColor :[UIColor clearColor]];
    [probgc set];
    CGFloat w = radius * 2 + 1;
    CGFloat h = w;
    CGFloat x = (rect.size.width - w) * 0.5 + rect.origin.x;
    CGFloat y = (rect.size.height - h) * 0.5 + rect.origin.y;
    CGContextAddEllipseInRect(ctx, CGRectMake(x, y, w, h));
    CGContextFillPath(ctx);
    
    // 进度环
    probgc = [doUIModuleHelper GetColorFromString:self.progressColor :[UIColor clearColor]];
    [probgc set];
    CGContextMoveToPoint(ctx, xCenter, yCenter);
    CGContextAddLineToPoint(ctx, xCenter, 0);
    CGFloat to;
    if ([self.style isEqualToString:@"normal"]) {
        to = - M_PI * 0.5 + self.progress / 100 * M_PI * 2 + 0.001; // 初始值
    }
    else
    {
        to = M_PI_4 * 0.125;
    }
    CGContextAddArc(ctx, xCenter, yCenter, radius, - M_PI * 0.5, to, 0);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    
    // 遮罩
    [[UIColor lightGrayColor] set];
    CGFloat maskW = (radius - [self.progressWidth floatValue]) * 2;
    CGFloat maskH = maskW;
    CGFloat maskX = (rect.size.width - maskW) * 0.5;
    CGFloat maskY = (rect.size.height - maskH) * 0.5;
    CGContextAddEllipseInRect(ctx, CGRectMake(maskX, maskY, maskW, maskH));
    CGContextFillPath(ctx);
    
    // 遮罩边框
    [[UIColor grayColor] set];
    CGFloat borderW = maskW + 1;
    CGFloat borderH = borderW;
    CGFloat borderX = (rect.size.width - borderW) * 0.5;
    CGFloat borderY = (rect.size.height - borderH) * 0.5;
    CGContextAddEllipseInRect(ctx, CGRectMake(borderX, borderY, borderW, borderH));
    CGContextStrokePath(ctx);
    if (!self.text || [self.style isEqualToString:@"cycle"]) {
        return;
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:self.fontSize];
    attributes[NSStrokeColorAttributeName] = [doUIModuleHelper GetColorFromString:self.fontColor :[UIColor clearColor]];
    [self.text drawAtPoint:CGPointMake(xCenter, yCenter) withAttributes:attributes];
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
