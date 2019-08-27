//
//  XKQRCodeView.m
//  TestDemo
//
//  Created by Nicholas on 2017/10/19.
//  Copyright © 2017年 nicholas. All rights reserved.
//

#import "XKQRCodeView.h"
#import <AVFoundation/AVFoundation.h>

API_AVAILABLE(ios(10.0))
@interface XKQRCodeView () <AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureDeviceInput *devideInput;

@property (nonatomic, strong) AVCaptureMetadataOutput *metaDataOutput;

///输入输出的中间桥梁
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureDevice *device;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

///遮罩的view
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
///扫描区域的背景图片
@property (nonatomic, strong) UIImageView *scanAreBackgroundImageView;
///扫描区域上下滚动图片
@property (nonatomic, strong) UIImageView *scanImageView;

//--- 相机
@property (nonatomic, strong) AVCapturePhotoOutput *imageOutput;
@property (nonatomic, strong) AVCaptureSession *imageSession;

@property (nonatomic, copy) void(^takePhotoHandler)(UIImage *image);

@end;

@implementation XKQRCodeView

- (instancetype)initWithFrame:(CGRect)frame scanArea:(CGRect)scanArea {
    
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        //扫描区域
        self.scanArea = scanArea;
        //透明度
        self.scanExternalAlpha = 0.5;
        [self.layer addSublayer:_previewLayer];
        [self addSubview:_maskView];
    }
    return self;
}

#pragma mark - 配置UI
- (void)setupUI {
    
    //摄像设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //输入流
    _devideInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    //输出流
    _metaDataOutput = [AVCaptureMetadataOutput new];
    [_metaDataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //连接对象
    _session = [AVCaptureSession new];
    //高质量
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    if ([_session canAddInput:_devideInput]) [_session addInput:_devideInput];
    if ([_session canAddOutput:_metaDataOutput]) [_session addOutput:_metaDataOutput];
    
    //条码类型，二维码与条形码兼容
    _metaDataOutput.metadataObjectTypes = @[
                                            AVMetadataObjectTypeQRCode,
                                            AVMetadataObjectTypeEAN13Code,
                                            AVMetadataObjectTypeEAN8Code,
                                            AVMetadataObjectTypeCode128Code
                                            ];
    
    //扫描的视图
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = self.bounds;
    
    //遮罩的view
    _maskView = [[UIView alloc] initWithFrame:self.bounds];
    _maskView.backgroundColor = [UIColor clearColor];
    
    //扫描区域背景图片
    _scanAreBackgroundImageView = [UIImageView new];
    [_maskView addSubview:_scanAreBackgroundImageView];
    
    //扫描区域上下滚动图片
    _scanImageView = [UIImageView new];
    [_maskView addSubview:_scanImageView];
    
    //--- 拍照
    if (@available(iOS 10.0, *)) {
        
        self.imageOutput = [AVCapturePhotoOutput new];
        AVCapturePhotoSettings *outputSetting = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
        [self.imageOutput setPhotoSettingsForSceneMonitoring:outputSetting];
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
    } else {
        // Fallback on earlier versions
    }
    
}

#pragma mark 设置扫描区域
- (void)setScanArea:(CGRect)scanArea {
    _scanArea = scanArea;
    
    //设置扫描区域
    CGSize layerSize = self.previewLayer.frame.size;
    scanArea.origin.x = (layerSize.width-scanArea.size.width)-scanArea.origin.x;
    CGFloat x = scanArea.origin.y/layerSize.height;
    CGFloat y = scanArea.origin.x/layerSize.width;
    CGFloat width = scanArea.size.height/layerSize.height;
    CGFloat height = scanArea.size.width/layerSize.width;
    self.metaDataOutput.rectOfInterest = CGRectMake(x, y, width, height);
    
    //设置扫描区域背景图片
    _scanAreBackgroundImageView.frame = scanArea;
    
    //设置扫描区域上下滚动图片
    _scanImageView.frame = CGRectMake(scanArea.origin.x, scanArea.origin.y, scanArea.size.width, 4);
    
}

#pragma mark 设置透明度
- (void)setScanExternalAlpha:(CGFloat)scanExternalAlpha {
    _scanExternalAlpha = scanExternalAlpha;
    
    [_maskLayer removeFromSuperlayer];
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.maskView.bounds];
    UIBezierPath *clearPath = [UIBezierPath bezierPathWithRect:self.scanArea];
    [bezierPath appendPath:clearPath];
    _maskLayer = [CAShapeLayer layer];
    _maskLayer.path = bezierPath.CGPath;
    _maskLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:scanExternalAlpha].CGColor;
    _maskLayer.fillRule = kCAFillRuleEvenOdd;
    [self.maskView.layer addSublayer:_maskLayer];
    
}

#pragma mark 设置扫描区域背景图片
- (void)setScanAreBackgroundImage:(UIImage *)scanAreBackgroundImage {
    _scanAreBackgroundImage = [scanAreBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.5, 0.5, 0.5, 0.5) resizingMode:UIImageResizingModeStretch];
    self.scanAreBackgroundImageView.image = _scanAreBackgroundImage;
}

#pragma mark 设置扫描区域上下滚动图片
- (void)setScanImage:(UIImage *)scanImage {
    _scanImage = [scanImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.5, 0.5, 0.5, 0.5) resizingMode:UIImageResizingModeStretch];
    CGSize originSize = scanImage.size;
    CGFloat height = self.scanArea.size.width*originSize.height/originSize.width;
    self.scanImageView.image = _scanImage;
//    [self.scanImageView sizeToFit];
    CGRect rect = self.scanImageView.frame;
    rect.size.height = height;
    self.scanImageView.frame = rect;
}
#pragma mark 处理扫描信息 AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    [self.session stopRunning];
    
    [self.scanImageView.layer removeAnimationForKey:@"animation"];
    NSString *stringValue = nil;
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *dataObject = [metadataObjects firstObject];
        stringValue = dataObject.stringValue;
    }
    if (self.xk_getScanData) self.xk_getScanData(stringValue);
}

#pragma mark 开始扫描
- (void)xk_startRunning {
    
    [self.session startRunning];
    
    [self.scanImageView.layer removeAnimationForKey:@"animation"];
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"position.y";
    animation.fromValue = @(self.scanArea.origin.y+CGRectGetHeight(self.scanImageView.frame)/2.0);
    animation.toValue = @(self.scanArea.size.height+self.scanArea.origin.y-CGRectGetHeight(self.scanImageView.frame)/2.0);
//    animation.autoreverses = YES;
    animation.repeatCount = CGFLOAT_MAX;
    animation.duration = 1.5;
    [self.scanImageView.layer addAnimation:animation forKey:@"animation"];
    
}
#pragma mark 停止扫描
- (void)xk_stopRunning {
    
    if (self.session.isRunning == NO) {
        return;
    }
    [self.session stopRunning];
}

#pragma mark 拍照
- (void)xk_takePhoto:(void (^)(UIImage *))completed {
    
    if (@available(iOS 10.0, *)) {
        
        if (self.session.isRunning == NO) {
            [self.session startRunning];
        }
        self.takePhotoHandler = completed;
        AVCapturePhotoSettings *outputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
        [self.imageOutput capturePhotoWithSettings:outputSettings delegate:self];
    } else {
        // Fallback on earlier versions
    }
    
    
}

#pragma mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error  API_AVAILABLE(ios(10.0)){
    
    [self.session stopRunning];
    
    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    UIImage *image = [UIImage imageWithData:data];
    
    !self.takePhotoHandler ?: self.takePhotoHandler(image);
}

#pragma mark - 类方法
#pragma mark 识别图片二维码
+ (void)xk_getInfoFromPhoto:(UIImage *)photo completed:(void (^)(NSString *))completed {
    
    //CIDetector(CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    //声明一个 CIDetector，并设定识别类型 CIDetectorTypeQRCode
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    
    //取得识别结果
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:photo.CGImage]];
    
    NSString *detectorString = nil;
    
    if (features.count > 0) {
        for (int index = 0; index < [features count]; index ++) {
            CIQRCodeFeature *feature = [features objectAtIndex:index];
            NSString *resultStr = feature.messageString;
            detectorString = resultStr;
            
        }
    }
    !completed ?: completed(detectorString);
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
