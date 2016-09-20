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
#import "doTextHelper.h"
#import "doIScriptEngine.h"

#define SDProgressViewItemMargin 10

@interface do_ProgressBar2_UIView()
@property (nonatomic,strong)NSString *fontColor;
@property (nonatomic,assign)NSInteger fontSize;
@property (nonatomic,assign)CGFloat  progressWidth;
@property (nonatomic,strong)NSString *style;
@property (nonatomic,strong)NSString *text;

@end
@implementation do_ProgressBar2_UIView
{
    CGFloat _currentProgress;
    //背景圆环
    CAShapeLayer *ringBgLayer;
    CAShapeLayer *indicatorLayer;
    CAShapeLayer *progressLayer;

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
    
    
    NSInteger fontSize = [[_model GetProperty:@"fontSize"].DefaultValue integerValue];
    self.fontSize = [doUIModuleHelper GetDeviceFontSize:(int)fontSize :_model.XZoom :_model.YZoom];
    
    self.fontColor = [_model GetProperty:@"fontColor"].DefaultValue;
    [self setupBackgroudLayer];
    
    [self change_style:self.style];
    _currentProgress = 0.0f;
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
    [self changePositon];
    NSString *width = [_model GetPropertyValue:@"progressWidth"];
    [self change_progressWidth:width];
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
    self.fontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[[_model GetProperty:@"fontSize"].DefaultValue intValue]] :_model.XZoom :_model.YZoom];
    [self setNeedsDisplay];
}
- (void)change_progress:(NSString *)newValue
{
    //自己的代码实现
    CGFloat temp = fabs([newValue floatValue]/100.0);
    CGFloat progress = MAX(MIN(temp, 1.0), 0.0);
    if ([self.style isEqualToString:@"normal"]) {
        if (progressLayer) {
            progressLayer.strokeEnd = progress;
        }
        else
        {
            _currentProgress = progress;
        }
    }
}
- (void)change_progressBgColor:(NSString *)newValue
{
    //自己的代码实现
    UIColor *probgc = [doUIModuleHelper GetColorFromString:newValue :[UIColor clearColor]];
    ringBgLayer.strokeColor = probgc.CGColor;
}
- (void)change_progressColor:(NSString *)newValue
{
    //自己的代码实现
    UIColor *probgc = [doUIModuleHelper GetColorFromString:newValue :[UIColor clearColor]];
    if ([[self.style lowercaseString] isEqualToString:@"normal"]) {
        progressLayer.strokeColor = probgc.CGColor;
    }
    else
    {
        indicatorLayer.strokeColor = probgc.CGColor;
    }
}
- (void)change_progressWidth:(NSString *)newValue
{
    if ([newValue isEqualToString:@""]) {
        return;
    }
    //自己的代码实现
    CGFloat w = MIN(_model.RealWidth, _model.RealHeight) / 2;
    
//    self.progressWidth = [newValue floatValue]* _model.XZoom;
    
    self.progressWidth = ([newValue floatValue] / 100.0f ) * w;
    if (w < self.progressWidth) {
        self.progressWidth = w;
    }
    ringBgLayer.lineWidth = self.progressWidth;
    ringBgLayer.path = [self layoutPathWithScale:1].CGPath;
    if ([[self.style lowercaseString]isEqualToString:@"normal"]) {
        progressLayer.lineWidth = self.progressWidth;
        progressLayer.path = [self layoutPath].CGPath;
    }
    else
    {
        indicatorLayer.lineWidth = self.progressWidth;
        indicatorLayer.path = [self layoutPathWithScale:1].CGPath;
    }
}
- (void)change_style:(NSString *)newValue
{
    //自己的代码实现
    self.style = newValue;
    if ([newValue isEqualToString:@"cycle"])
    {
        [progressLayer removeFromSuperlayer];
        [self setupAnimationLayer];
        [self startAnimation];
    }
    else
    {
        [indicatorLayer removeFromSuperlayer];
        [self setupRingAnimationLayer];
    }
}

- (void)change_text:(NSString *)newValue
{
    //自己的代码实现
    self.text = newValue;
    if ([[self.style lowercaseString] isEqualToString:@"normal"]) {
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if ([[self.style lowercaseString] isEqualToString:@"normal"]) {
        [self drawNormalStyle:ctx withRect:rect];
    }
}

//绘制带进度的进度条
- (void)drawNormalStyle:(CGContextRef)ctx withRect:(CGRect)rect
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont systemFontOfSize:self.fontSize];
    attributes[NSForegroundColorAttributeName] = [doUIModuleHelper GetColorFromString:self.fontColor :[UIColor clearColor]];
    CGSize fontSize = [self.text sizeWithAttributes:attributes];
    [self.text drawAtPoint:CGPointMake(rect.size.width / 2 - (fontSize.width)/2, rect.size.height / 2 - (fontSize.height / 2)) withAttributes:attributes];
}

#pragma mark - 背景圆环layer
- (void)setupBackgroudLayer
{
    ringBgLayer = [[CAShapeLayer alloc] initWithLayer:self.layer];
    ringBgLayer.bounds        = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
    ringBgLayer.position      = CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2);
    ringBgLayer.fillColor     = [UIColor clearColor].CGColor;
    ringBgLayer.lineWidth     = self.progressWidth;
    ringBgLayer.strokeColor   = [UIColor whiteColor].CGColor;
    ringBgLayer.path          = [self layoutPathWithScale:1.0].CGPath;
    
    [self.layer addSublayer:ringBgLayer];
    
}

- (UIBezierPath *)layoutPathWithScale: (CGFloat)scale {
    const double TWO_M_PI   = 2.0 * M_PI;
    const double startAngle = 0.75 * TWO_M_PI;
    const double endAngle   = startAngle +scale * TWO_M_PI;
    CGFloat width           = MIN(_model.RealWidth,_model.RealHeight);
    CGFloat radius = width /2 - self.progressWidth / 2;
    NSLog(@"layoutPathWithScale = %f",radius);
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2)
                                          radius:radius
                                      startAngle:startAngle
                                        endAngle:endAngle
                                       clockwise:YES];
}
#pragma mark - 进度圆环layer
- (void)setupRingAnimationLayer{
    UIBezierPath *path = [self layoutPath];
    progressLayer = [[CAShapeLayer alloc] initWithLayer:self.layer];
    progressLayer.bounds        = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
    progressLayer.position      = CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2);
    progressLayer.fillColor     = [UIColor clearColor].CGColor;
    progressLayer.lineWidth     = self.progressWidth;
    progressLayer.strokeColor   = [UIColor blackColor].CGColor;
    progressLayer.path          = path.CGPath;
    progressLayer.strokeStart = 0.0f;
    progressLayer.strokeEnd = _currentProgress;
    [self.layer addSublayer: progressLayer];
}

- (UIBezierPath *)layoutPath{
    const double TWO_M_PI   = 2.0 * M_PI;
    const double startAngle = 0.75 * TWO_M_PI;
    const double endAngle   = startAngle + TWO_M_PI;
    CGFloat width           = MIN(_model.RealWidth,_model.RealHeight);
    
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2)
                                          radius:width / 2 - self.progressWidth / 2
                                      startAngle:startAngle
                                        endAngle:endAngle
                                       clockwise:YES];
}
#pragma mark 指示器圆弧layer
- (void)setupAnimationLayer{
    indicatorLayer         = [[CAShapeLayer alloc] initWithLayer:self.layer];
    indicatorLayer.bounds                = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
    indicatorLayer.position              =CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2);
    indicatorLayer.fillColor             = [UIColor clearColor].CGColor;
    indicatorLayer.lineWidth             = self.progressWidth;
    indicatorLayer.lineCap               = @"round";
    indicatorLayer.strokeColor           = [UIColor blackColor].CGColor;
    indicatorLayer.path                  = [self layoutPathWithScale:0.25].CGPath;
    
    indicatorLayer.strokeStart = 0.f;//路径开始位置
    indicatorLayer.strokeEnd = 0.18f;//路径结束位置
    
    [self.layer addSublayer:indicatorLayer];
}
- (void)changePositon
{
    ringBgLayer.bounds        = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
    ringBgLayer.position      = CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2);
    ringBgLayer.path          = [self layoutPathWithScale:1.0].CGPath;
    
    if ([[self.style lowercaseString]isEqualToString:@"cycle"]) {
        indicatorLayer.bounds                = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
        indicatorLayer.position              =CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2);
        indicatorLayer.path                  = [self layoutPathWithScale:0.25].CGPath;
    }
    else
    {
        progressLayer.bounds        = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
        progressLayer.position      = CGPointMake(_model.RealWidth / 2, _model.RealHeight / 2);
        progressLayer.path          = [self layoutPath].CGPath;
    }
}
- (void)startAnimation
{
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
    anim.keyPath = @"transform";
    NSValue *val1 = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0 * M_PI, 0, 0, 1)];
    NSValue *val2 = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.5 * M_PI, 0, 0, 1)];
    NSValue *val3 = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(1.0 * M_PI, 0, 0, 1)];
    NSValue *val4 = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(1.5 * M_PI, 0, 0, 1)];
    NSValue *val5 = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(2.0 * M_PI, 0, 0, 1)];
    anim.values = @[val1, val2, val3, val4, val5];
    anim.duration = 2.0;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.repeatCount = MAXFLOAT;
    anim.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [indicatorLayer addAnimation:anim forKey:@"ringLayerAnimation"];
}

- (void)stopAnimation{
    [indicatorLayer removeAnimationForKey:@"ringLayerAnimation"];
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
