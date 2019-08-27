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

///识别图片中的二维码
+ (void)xk_getInfoFromPhoto:(UIImage *)photo completed:(void(^)(NSString *stringValue))completed;

///初始化
- (instancetype)initWithFrame:(CGRect)frame scanArea:(CGRect)scanArea;
///开始扫描
- (void)xk_startRunning;
///停止扫描
- (void)xk_stopRunning;

///拍照、 iOS10之后生效
- (void)xk_takePhoto:(void(^)(UIImage *image))completed;

@end
