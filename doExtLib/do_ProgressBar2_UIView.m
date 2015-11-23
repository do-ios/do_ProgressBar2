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

@interface do_ProgressBar2_UIView()
@property (nonatomic,strong)NSString *fontColor;
@property (nonatomic,assign)NSInteger fontSize;
@property (nonatomic,assign)CGFloat progress;
@property (nonatomic,strong)NSString *progressColor;
@property (nonatomic,strong)NSString *progressBgColor;
@property (nonatomic,assign)CGFloat  progressWidth;
@property (nonatomic,strong)NSString *style;
@property (nonatomic,strong)NSString *text;
@property (nonatomic,strong) NSTimer *animationTimer;

@end
@implementation do_ProgressBar2_UIView
{
    CGFloat _angleInterval;
    CGFloat _currentProgress;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    self.progressWidth = 1.0;
    self.style = [_model GetProperty:@"style"].DefaultValue;
    self.fontSize = [[_model GetProperty:@"fontSize"].DefaultValue integerValue];
    self.fontColor = [_model GetProperty:@"fontColor"].DefaultValue;
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    [self.animationTimer invalidate];
    self.animationTimer = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    [self setNeedsDisplay];
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
    [self setNeedsDisplay];
}
- (void)change_fontSize:(NSString *)newValue
{
    //自己的代码实现
    self.fontSize = [newValue integerValue];
    [self setNeedsDisplay];
}
- (void)change_progress:(NSString *)newValue
{
    //自己的代码实现
    self.progress = [newValue floatValue];
    _currentProgress = 0.0;
    if ([self.style isEqualToString:@"normal"]) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.00001 target:self selector:@selector(changeProgress) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.animationTimer = timer;
    }
}
- (void)change_progressBgColor:(NSString *)newValue
{
    //自己的代码实现
    self.progressBgColor = newValue;
    if ([self.style isEqualToString:@"cycle"]) {
        return;
    }
    [self setNeedsDisplay];
}
- (void)change_progressColor:(NSString *)newValue
{
    //自己的代码实现
    self.progressColor = newValue;
    if ([self.style isEqualToString:@"cycle"]) {
        return;
    }
    [self setNeedsDisplay];
}
- (void)change_progressWidth:(NSString *)newValue
{
    //自己的代码实现
    CGFloat w = MIN(_model.RealWidth, _model.RealHeight) / 2;
    self.progressWidth = [newValue floatValue];
    if (w <= self.progressWidth) {
        self.progressWidth = w - 2;
    }
    if ([self.style isEqualToString:@"cycle"]) {
        return;
    }
    [self setNeedsDisplay];
}
- (void)change_style:(NSString *)newValue
{
    //自己的代码实现
    self.style = newValue;
    if ([newValue isEqualToString:@"cycle"]) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(changeAngle) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
    else
    {
        [self.animationTimer fire];
    }
}

- (void)change_text:(NSString *)newValue
{
    //自己的代码实现
    self.text = newValue;
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
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if ([self.style isEqualToString:@"normal"]) {
        [self drawNormalStyle:ctx withRect:rect];
    }
    else
    {
        [self drawCircleStyle:ctx withRect:rect];
    }
}
- (void)changeAngle
{
    _angleInterval += M_PI * 0.01;
    if (_angleInterval >= M_PI * 2) _angleInterval = 0;
    [self setNeedsDisplay];
}
- (void)changeProgress
{
        _currentProgress +=0.5;
    if (_currentProgress > self.progress) {
        [self.animationTimer invalidate];
        _currentProgress -=0.5;
        return;
    }

    [self setNeedsDisplay];
}
//绘制带进度的进度条
- (void)drawNormalStyle:(CGContextRef)ctx withRect:(CGRect)rect
{
    CGFloat radius = MIN(rect.size.width, rect.size.height) / 2;
    CGContextSaveGState(ctx);
    CGContextSetLineWidth(ctx, self.progressWidth);
    UIColor *probgc = [doUIModuleHelper GetColorFromString:self.progressBgColor :[UIColor clearColor]];
    [probgc setStroke];

    CGContextAddArc(ctx, rect.size.width / 2, rect.size.height / 2, radius - self.progressWidth, M_PI * 0, M_PI * 2, 1);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    
    probgc = [doUIModuleHelper GetColorFromString:self.progressColor :[UIColor clearColor]];
    [probgc setStroke];
    CGContextSetLineWidth(ctx, self.progressWidth);
    CGFloat to =_currentProgress / 100 * 2 *M_PI - 0.5 * M_PI; // 初始值
    CGContextAddArc(ctx, rect.size.width / 2, rect.size.height / 2, radius - self.progressWidth, -M_PI * 0.5, to, 0);
    CGContextStrokePath(ctx);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont systemFontOfSize:self.fontSize];
    attributes[NSForegroundColorAttributeName] = [doUIModuleHelper GetColorFromString:self.fontColor :[UIColor clearColor]];
    CGSize fontSize = [self.text sizeWithAttributes:attributes];
    [self.text drawAtPoint:CGPointMake(rect.size.width / 2 - (fontSize.width)/2, rect.size.height / 2 - (fontSize.height / 2)) withAttributes:attributes];
}
//绘制不带进度的样式
- (void)drawCircleStyle:(CGContextRef)ctx withRect:(CGRect)rect
{
    CGFloat radius = MIN(rect.size.width, rect.size.height) / 2;
    CGContextSaveGState(ctx);
    CGContextSetLineWidth(ctx, self.progressWidth);
    UIColor *probgc = [doUIModuleHelper GetColorFromString:self.progressBgColor :[UIColor clearColor]];
    [probgc setStroke];
    CGContextAddArc(ctx, rect.size.width / 2, rect.size.height / 2, radius - self.progressWidth, M_PI * 0, M_PI * 2, 1);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    
    probgc = [doUIModuleHelper GetColorFromString:self.progressColor :[UIColor clearColor]];
    [probgc setStroke];
    CGContextSetLineWidth(ctx, self.progressWidth);
    CGFloat to =  - M_PI * 0.15 + _angleInterval;
    
    CGContextAddArc(ctx, rect.size.width / 2, rect.size.height / 2, radius - self.progressWidth, to, _angleInterval, 1);
    CGContextStrokePath(ctx);

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
