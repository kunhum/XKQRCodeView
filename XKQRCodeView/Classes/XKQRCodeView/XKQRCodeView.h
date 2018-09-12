//
//  XKQRCodeView.h
//  TestDemo
//
//  Created by Nicholas on 2017/10/19.
//  Copyright © 2017年 nicholas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XKQRCodeView : UIView

///扫描区域
@property (nonatomic, assign) CGRect scanArea;
///扫描区域外的透明度
@property (nonatomic, assign) CGFloat scanExternalAlpha;
///扫描区域的背景图片
@property (nonatomic, strong) UIImage *scanAreBackgroundImage;
///扫描区域上下滚动图片
@property (nonatomic, strong) UIImage *scanImage;

///获取扫描信息
@property (nonatomic, copy) void(^xk_getScanData)(NSString *stringValue);

- (instancetype)initWithFrame:(CGRect)frame scanArea:(CGRect)scanArea;

///开始扫描
- (void)xk_startRunning;

@end
