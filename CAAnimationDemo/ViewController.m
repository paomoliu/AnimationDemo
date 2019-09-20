//
//  ViewController.m
//  CAAnimationDemo
//
//  Created by Rachel on 2019/9/17.
//  Copyright © 2019 Rachel. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property (nonatomic, strong) CAShapeLayer *firstLayer;
@property (nonatomic, strong) CAShapeLayer *secondLayer;
@property (nonatomic, assign) CGFloat amplitude;        // 水波振幅 A
@property (nonatomic, assign) CGFloat cycle;            // 水波周期 ω
@property (nonatomic, assign) CGFloat initialPhase;     // 初相位 φ
@property (nonatomic, assign) CGFloat offsetY;          // 水位高度 k
@property (nonatomic, assign) CGFloat waterWaveWidth;   // 水波在屏幕上所占的宽度
@property (nonatomic, assign) CGFloat waterWaveSpead;   // 水波波速

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self drawOvalAnimation];
//    [self fireAnimation];
//    [self waterWaveAnimation];
    [self fireworksAnimation];
}

#pragma mark - Draw Oval

- (void)drawOvalAnimation {
    // 绘制一个椭圆
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(30, 100, 300, 500)];
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.strokeColor = [UIColor redColor].CGColor;        // 画笔颜色
    shapeLayer.fillColor = [UIColor clearColor].CGColor;        // 画笔所绘路径下图形的填充色
    shapeLayer.lineWidth = 2;
    shapeLayer.path = path.CGPath;
    [self.view.layer addSublayer:shapeLayer];
    
    // 增加 画椭圆 动画
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 3;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]; // 动画缓慢开始，在其持续时间的中间加速，然后在完成之前再次减速
    pathAnimation.fromValue = @0;
    pathAnimation.toValue = @1;
    pathAnimation.autoreverses = YES;               // 正向动画结束后，再逆向返回起始点
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.repeatCount = MAXFLOAT;
    [shapeLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
}

#pragma mark - Fire

- (void)fireAnimation {
    self.view.backgroundColor = [UIColor blackColor];
    // 创建发射器
    CAEmitterLayer *emitter = [CAEmitterLayer layer];       // 粒子发射器
    emitter.position = self.view.center;
    emitter.emitterShape = kCAEmitterLayerCircle;           // 发射器形状
    // 合并粒子重叠部分的亮度使得看上去更亮
    emitter.renderMode = kCAEmitterLayerAdditive;           // 发射器渲染模式（控制粒子图片在视觉上是如何混合的）
    
    // 发射单元 - 火焰
    CAEmitterCell *fire = [[CAEmitterCell alloc] init];
    fire.birthRate = 200;                                   // 粒子的创建速率，默认为1/s
    fire.lifetime = 0.2;                                    // 粒子存活时间
    fire.lifetimeRange = 0.5;                               // 粒子的生存时间范围
    fire.color = [UIColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:0.1].CGColor;
    fire.contents = (id)[UIImage imageNamed:@"fire"].CGImage;
    fire.velocity = 35;                                     // 粒子初速度
    fire.velocityRange = 10;                                // 粒子初速度范围
    
    // 粒子沿着Y轴向上成90度发散(发射范围计算方式：emissionLongitude + emissionRange ~ emissionLongitude - emissionRange)
    fire.emissionLongitude = -M_PI_2;                       // 粒子在x-y平面的发射角度（决定粒子飞行方向）
    fire.emissionRange = M_PI_4;                            // 粒子发射角度范围（决定粒子发散范围）
    
    emitter.emitterCells = @[fire];
    [self.view.layer addSublayer:emitter];
}

#pragma mark - Water Wave

/**
 *  正弦型函数解析式：y = Asin（ωx+φ）+ k
 *  各常数值对函数图像的影响：
 *  A：振幅，决定峰值（即纵向拉伸压缩的倍数），控制波浪高度
 *  ω：角速度，决定周期（最小正周期T=2π/|ω|），控制波浪宽度
 *  φ：初相位，决定波形与X轴位置关系或横向移动距离（左加右减），控制波浪的水平移动
 *  k：偏距，表示波形在Y轴的位置关系或纵向移动距离（上加下减），控制水位高度
 */
- (void)waterWaveAnimation {
    // 数据初始化
    self.amplitude = 10;
    self.cycle = (CGFloat)4 * M_PI / self.view.frame.size.width;
    self.initialPhase = 0;
    self.offsetY = self.view.frame.size.height - 300;
    self.waterWaveWidth = self.view.frame.size.width;
    self.waterWaveSpead = 0.2;
    
    CGColorRef fillColor = [UIColor colorWithRed:30/255.0
                                           green:144/255.0
                                            blue:255/255.0
                                           alpha:0.5].CGColor;
    
    self.firstLayer = [CAShapeLayer layer];
    self.firstLayer.fillColor = fillColor;
    [self.view.layer addSublayer:self.firstLayer];
    
    self.secondLayer = [CAShapeLayer layer];
    self.secondLayer.fillColor = fillColor;
    [self.view.layer addSublayer:self.secondLayer];
    
    // 让水波动起来
    CADisplayLink *waveDisplayLing = [CADisplayLink displayLinkWithTarget:self selector:@selector(currentWaterWave)];
    [waveDisplayLing addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    [self waterDropsAnimation];
}

- (void)currentWaterWave {
    // 水波平移速度
    self.initialPhase += self.waterWaveSpead;
    [self drawWaterWave];
}

/**
 *  创建水波路径
 */
- (void)drawWaterWave {
    // 第一条水波路径
    CGMutablePathRef firstPath = [self waterWavepath:self.initialPhase];
    self.firstLayer.path = firstPath;
    CGPathRelease(firstPath);
    
    // 第二条水波路径
    CGMutablePathRef secondPath = [self waterWavepath:(self.initialPhase - 20)];;
    self.secondLayer.path = secondPath;
    CGPathRelease(secondPath);
}

- (CGMutablePathRef)waterWavepath:(CGFloat)initialPhase {
    NSInteger width = (NSInteger)self.waterWaveWidth;
    CGMutablePathRef path = CGPathCreateMutable();
    // 绘制一条正弦曲线
    CGPathMoveToPoint(path, nil, 0, self.offsetY);         // 设置初始位置
    for (NSInteger x = 0; x <= width; x++) {
        CGFloat y = self.amplitude * sin((CGFloat)self.cycle * x + initialPhase) + self.offsetY;
        CGPathAddLineToPoint(path, nil, x, y);
    }
    CGPathAddLineToPoint(path, nil, self.waterWaveWidth, self.view.frame.size.height);
    CGPathAddLineToPoint(path, nil, 0, self.view.frame.size.height);
    CGPathCloseSubpath(path);
    
    return path;
}

/**
 *  水珠动画
 */
- (void)waterDropsAnimation {
    // 发射器
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.position = CGPointMake(self.view.bounds.size.width * 0.5, self.view.bounds.size.height);
    emitter.emitterShape = kCAEmitterLayerLine;
    emitter.emitterSize = CGSizeMake(self.view.bounds.size.width, self.offsetY);
    
    // 水珠
    CAEmitterCell *waterDrop = [CAEmitterCell emitterCell];
    waterDrop.contents = (id)[UIImage imageNamed:@"water"].CGImage;
    waterDrop.birthRate = 2;
    waterDrop.lifetime = 20;
    waterDrop.lifetimeRange = 5;                // 水珠的生命周期是 15～25
    waterDrop.velocity = 15;
    waterDrop.velocityRange = 5;                // 水珠速度范围 10～20
    waterDrop.yAcceleration = -100;             // y方向加速度
    waterDrop.scale = 0.2;
//    waterDrop.alphaSpeed = -0.01;               // 透明度变化，每过一秒减少0.1
    
    emitter.emitterCells = @[waterDrop];
    [self.view.layer addSublayer:emitter];
}

#pragma mark - Fireworks

- (void)fireworksAnimation {
    self.view.backgroundColor = [UIColor blackColor];
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = CGPointMake(self.view.bounds.size.width * 0.5, self.view.bounds.size.height);
    emitter.emitterShape = kCAEmitterLayerPoint;
    emitter.renderMode = kCAEmitterLayerAdditive;
    
    // 发射
    CAEmitterCell *shoot = [[CAEmitterCell alloc] init];
    shoot.contents = (id)[UIImage imageNamed:@"shoot"].CGImage;
    shoot.color = [UIColor redColor].CGColor;   // rgb: 255 0 0
    shoot.emissionLongitude = -M_PI_2;
    shoot.emissionRange = M_PI_4;
    shoot.birthRate = 1;
    shoot.lifetime = 1.02;
    shoot.velocity = 600;
    shoot.velocityRange = 100;
    shoot.yAcceleration = 75;
    shoot.scale = 0.1;
    shoot.spin = 2 * M_PI;                      // 自转360°
    
    // 爆炸效果，突然之间变大一下
    CAEmitterCell *spark = [[CAEmitterCell alloc] init];
    spark.birthRate = 1;                        // 爆破是在发射点将消失时才产生，所以该值需要根据发射点lifetime进行设置
    spark.lifetime = 0.35;
    spark.velocity = 0;
    spark.scale = 2.5;
    // 使爆炸的火花多色
    spark.redSpeed = -1.5;                      // red每秒变化率（粒子颜色是255，最大值，故此处需要使用负数）
    spark.greenSpeed = 2;                       // green每秒变化率
    spark.blueSpeed = 1;                        // blue每秒变化率
    
    // 火花
    CAEmitterCell *start = [[CAEmitterCell alloc] init];
    start.contents = (id)[UIImage imageNamed:@"start"].CGImage;
    start.birthRate = 200;
    start.lifetime = 3;
    start.velocity = 125;
    start.yAcceleration = 75;
    start.emissionRange = 2 * M_PI;
    start.redSpeed = -0.1;
    start.greenSpeed = 0.1;
    start.blueSpeed = 0.1;
    start.alphaSpeed = -0.15;
    start.spin = 2 * M_PI;
    
    emitter.emitterCells = @[shoot];
    shoot.emitterCells = @[spark];
    spark.emitterCells = @[start];
    [self.view.layer addSublayer:emitter];
}

@end
