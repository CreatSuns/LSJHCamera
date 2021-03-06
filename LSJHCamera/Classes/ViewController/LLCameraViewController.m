#import "LLCameraPreviewImageView.h"
#import "LLCameraViewController.h"

@interface LLCameraViewController ()

@property (nonatomic, strong) UIView * containerView;                                //内容父容器
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * captureVideoPreviewLayer; //相机拍摄预览图层
@property (nonatomic, strong) LLCameraTool * videoTool;

@property (nonatomic, strong) UIView * cameraBar;          //顶部放置以下控件的视图
@property (nonatomic, strong) UIButton * flashButton;      //闪光灯
@property (nonatomic, strong) UIButton * cameraButton;     //切换相机
@property (nonatomic, strong) UIButton * flashLightButton; //手电筒

@property (nonatomic, strong) UILabel * messageLabel;
@property (nonatomic, strong) UIButton * closeButton; //关闭按钮
@property (nonatomic, strong) LLProgressView * progressView;

@property (nonatomic, assign) CGFloat timeCount;
@property (nonatomic, assign) CGFloat timeMargin;

@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, strong) LLCameraPreviewImageView * placeholdImageView;
@property (nonatomic, strong) AVPlayer * player;
@property (nonatomic, assign) LLCameraType cameraType;
@property (nonatomic, assign) LLCameraOrientation cameraOrientation;
@end

@implementation LLCameraViewController {
    NSString * _imagePath;
    NSString * _videoPath;
}
#pragma mark ======= LifeCircle
- (instancetype)init
{
    return [self initWithType:LLCameraTypeAll cameraOrientation:LLCameraOrientationBack];
}

- (instancetype)initWithType:(LLCameraType)type
           cameraOrientation:(LLCameraOrientation)cameraOrientation
{
    self = [super init];
    if (self) {
        self.time              = 15.0;
        self.cameraType        = type;
        self.cameraOrientation = cameraOrientation;
        self.saveAblum         = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    [self setupCaptureSession];
    [self setupSubView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:2
    animations:^{ self.messageLabel.alpha = 0; }
    completion:^(BOOL finished) { [self.messageLabel removeFromSuperview]; }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.videoTool stopCapture];
    [self.videoTool stopRecordFunction];
    self.navigationController.navigationBar.hidden = NO;
}

#pragma mark - Public Method
- (void)clearCache
{
    NSFileManager * fileManage = [NSFileManager defaultManager];
    NSError * error;
    [fileManage removeItemAtPath:[self.videoTool getVideoPathCache] error:&error];
}

#pragma mark ======= UI
- (void)setupSubView
{
    [self.view addSubview:self.containerView];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.cameraBar];
    [self.cameraBar addSubview:self.cameraButton];
    [self.cameraBar addSubview:self.flashButton];
    [self.cameraBar addSubview:self.flashLightButton];

    [self.view addSubview:self.progressView];

    if (self.cameraType == LLCameraTypeAll) {
        [self.view addSubview:self.messageLabel];
    }

    CGFloat cameraBar_X      = 0;
    CGFloat cameraBar_Y      = 0;
    CGFloat cameraBar_Width  = ScreenWidth;
    CGFloat cameraBar_Height = LLTopHeight;
    self.cameraBar.frame     = CGRectMake(cameraBar_X, cameraBar_Y, cameraBar_Width, cameraBar_Height);

    CGFloat width               = self.cameraBar.cmam_width / 3;
    CGFloat flashButton_centerX = width / 2;
    CGFloat flashButton_centerY = LLStatusBarHeight + 22;
    self.flashButton.center     = CGPointMake(flashButton_centerX, flashButton_centerY);

    CGFloat cameraButton_centerX = width + width / 2;
    CGFloat cameraButton_centerY = LLStatusBarHeight + 22;
    self.cameraButton.center     = CGPointMake(cameraButton_centerX, cameraButton_centerY);

    CGFloat flashLightButton_centerX = width * 2 + width / 2;
    CGFloat flashLightButton_centerY = LLStatusBarHeight + 22;
    self.flashLightButton.center     = CGPointMake(flashLightButton_centerX, flashLightButton_centerY);

    CGFloat closeButton_centerX = ScreenWidth / 4 - 10 * SizeAdapter;
    CGFloat closeButton_centerY = self.progressView.center.y;
    self.closeButton.center     = CGPointMake(closeButton_centerX, closeButton_centerY);

    CGFloat messageLabel_centerX = ScreenWidth / 2;
    CGFloat messageLabel_centerY = self.progressView.center.y - 60;
    self.messageLabel.center     = CGPointMake(messageLabel_centerX, messageLabel_centerY);
}

#pragma mark - Private Method
- (void)setupCaptureSession
{
    self.captureVideoPreviewLayer       = [self.videoTool previewLayer];
    CALayer * layer                     = self.containerView.layer;
    layer.masksToBounds                 = YES;
    self.captureVideoPreviewLayer.frame = layer.bounds;
    [layer addSublayer:self.captureVideoPreviewLayer];
    //开启录制功能
    [self.videoTool startRecordFunction];
}

- (void)openSystemPermissionsWithText:(NSString *)text
{
    LLAlertController * alert =
    [LLAlertController ll_alertWithTitle:text
                                   Message:nil
                          AlertLayoutStyle:LLAlertLayoutStyleHorizontal];
    alert.backgroundButton.enabled = NO;
    alert.presentStyle             = LLPopupPresentStyleBounce;
    alert.dismissStyle             = LLPopupDismissStyleShrink;
    // 创建 action
    LLAlertAction * defaultAction = [LLAlertAction ll_actionWithTitle:@"确定"
                                                               textColor:nil
                                                                textFont:nil
                                                                 handler:^{
                                                                     [[UIApplication sharedApplication]
                                                                     openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                                 }];

    LLAlertAction * cancelAction = [LLAlertAction ll_actionWithTitle:@"取消"
                                                              textColor:nil
                                                               textFont:nil
                                                                handler:^{
                                                                    if (self.navigationController) {
                                                                        [self.navigationController popViewControllerAnimated:YES];
                                                                    } else {
                                                                        [self dismissViewControllerAnimated:YES completion:nil];
                                                                    }
                                                                }];
    [alert ll_addAction:cancelAction];
    [alert ll_addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)endRecordingVideo
{
    [self stopTimer];
    [self.videoTool stopCapture];
}

- (void)cancelClick
{
    [self.placeholdImageView removeFromSuperview];
    self.placeholdImageView = nil;

    [self.videoTool startRecordFunction];

    if (self.videoTool.videoPath) {
        [self.player pause];
        NSFileManager * fileManage = [NSFileManager defaultManager];
        NSError * error;
        BOOL delet = [fileManage removeItemAtPath:self.videoTool.videoPath error:&error];
        NSLog(@"dele==%d", delet);
    } else if (self.placeholdImageView.image) {
        self.placeholdImageView.image = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
}

- (void)sureClick
{
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if (self.placeholdImageView.image) {
                                     if (self.takePhoto) {
                                         self.takePhoto(self.placeholdImageView.image, _imagePath);
                                     }
                                 } else {
                                     [self.player pause];
                                     [self.captureVideoPreviewLayer removeFromSuperlayer];

                                     if (self.takeVideo) {
                                         if (self.saveAblum) {
                                             self.takeVideo(_videoPath);
                                         } else {
                                             self.takeVideo(self.videoTool.videoPath);
                                         }
                                     }
                                 }
                             }];
}

- (void)startTimer
{
    CGFloat signleTime = self.time / 360;
    self.timeCount     = 0;
    self.timeMargin    = signleTime;
    self.timer         = [NSTimer scheduledTimerWithTimeInterval:signleTime
                                                  target:self
                                                selector:@selector(updateProgress)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer
{
    self.progressView.progress = 0.f;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateProgress
{
    if (self.timeCount >= self.time) {
        [self stopTimer];
        [self endRecordingVideo];
        return;
    }

    self.timeCount             = self.timeCount + self.timeMargin;
    CGFloat progress           = self.timeCount / self.time;
    self.progressView.progress = progress;
}

#pragma mark ======= Event
- (void)closeButtonClick
{
    [self endRecordingVideo];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)flashButtonClick:(UIButton *)flashButton
{
    flashButton.selected = !flashButton.selected;
    if (flashButton.selected) {
        [self.videoTool openFlash];
    } else {
        [self.videoTool closeFlash];
    }
}

- (void)flashLightButtonClick:(UIButton *)button
{
    button.selected = !button.selected;
    if (button.selected) {
        [self.videoTool openFlashLight];
    } else {
        [self.videoTool closeFlashLight];
    }
}

- (void)cameraButtonClick:(UIButton *)cameraButton
{
    cameraButton.selected = !cameraButton.selected;
    if (cameraButton.selected) {
        [self.videoTool changeCameraInputDeviceisFront:YES];
    } else {
        [self.videoTool changeCameraInputDeviceisFront:NO];
    }
}

#pragma mark ======= GestureRecognizer Event
- (void)startRecordingVideo:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self startTimer];
        [self.videoTool startCapture];
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.progressView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                         }];

    } else if (longPress.state == UIGestureRecognizerStateEnded) {
        [self endRecordingVideo];
        [self.videoTool stopRecordFunction];

        [UIView animateWithDuration:0.2
        animations:^{ self.progressView.transform = CGAffineTransformIdentity; }
        completion:^(BOOL finished) {

            if (self.videoTool.videoPath) {
                self.placeholdImageView.hidden = NO;
                NSURL * url                    = [NSURL fileURLWithPath:self.videoTool.videoPath];
                self.player                    = [AVPlayer playerWithURL:url];
                AVPlayerLayer * layer          = [AVPlayerLayer playerLayerWithPlayer:self.player];
                layer.videoGravity             = AVLayerVideoGravityResizeAspectFill;
                layer.frame                    = self.placeholdImageView.frame;
                layer.backgroundColor          = [UIColor blackColor].CGColor;
                [self.placeholdImageView.layer insertSublayer:layer atIndex:0];
                [self.player play];
                //注册通知
                [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(runLoopTheMovie:)
                       name:AVPlayerItemDidPlayToEndTimeNotification
                     object:nil];
            }
        }];
    }
}

- (void)takingPictures
{
    [self.videoTool startTakingPhoto:^(UIImage * image) {
        self.placeholdImageView.hidden = NO;
        self.placeholdImageView.image  = image;
        [self endRecordingVideo];

    }];
}

#pragma mark ======= Notifation
- (void)runLoopTheMovie:(NSNotification *)n
{
    AVPlayerItem * p = [n object];
    [p seekToTime:kCMTimeZero];

    [self.player play];
}

#pragma mark - Setter -
- (void)setTime:(CGFloat)time
{
    NSAssert(time > 0, @"录制时间不能小于1s");
    _time = time;
}

- (void)setPreset:(AVCaptureSessionPreset)preset
{
    self.videoTool.videoPreset = preset;
}

- (void)setSaveAblum:(BOOL)saveAblum
{
    self.videoTool.saveAblum = saveAblum;
}

- (void)setAlbumName:(NSString *)albumName
{
    self.videoTool.albumName = albumName;
}

#pragma mark - Getter -
- (UILabel *)messageLabel
{
    if (!_messageLabel) {
        _messageLabel               = [[UILabel alloc] init];
        _messageLabel.text          = @"轻触拍照，按住摄像";
        _messageLabel.bounds        = CGRectMake(0, 0, 200, 30);
        _messageLabel.textColor     = [UIColor whiteColor];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _messageLabel;
}

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView                 = [[UIView alloc] initWithFrame:self.view.bounds];
        _containerView.backgroundColor = [UIColor whiteColor];
    }
    return _containerView;
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage ll_loadBundleImage:@"icon_cancel_camera"
                                                    ClassName:NSStringFromClass([self class]) bundleName:@"LSJHCamera"]
                      forState:UIControlStateNormal];
        _closeButton.bounds              = CGRectMake(0, 0, 50, 50);
        _closeButton.layer.cornerRadius  = _closeButton.bounds.size.width * 0.5;
        _closeButton.layer.masksToBounds = YES;
        [_closeButton addTarget:self
                         action:@selector(closeButtonClick)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIView *)cameraBar
{
    if (!_cameraBar) {
        _cameraBar = ({
            UIView * object        = [[UIView alloc] init];
            object.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
            object;
        });
    }
    return _cameraBar;
}

- (UIButton *)flashButton
{
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashButton setImage:[UIImage ll_loadBundleImage:@"icon_camera_flash_close"
                                                    ClassName:NSStringFromClass([self class]) bundleName:@"LSJHCamera"]
                      forState:UIControlStateNormal];
        [_flashButton setImage:[UIImage ll_loadBundleImage:@"icon_camera_flash_open"
                                                    ClassName:NSStringFromClass([self class]) bundleName:@"LSJHCamera"]
                      forState:UIControlStateSelected];
        _flashButton.bounds = CGRectMake(0, 0, 40, 40);
        [_flashButton addTarget:self
                         action:@selector(flashButtonClick:)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

- (UIButton *)flashLightButton
{
    if (!_flashLightButton) {
        _flashLightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashLightButton setImage:[UIImage ll_loadBundleImage:@"icon_scan_flashlight"
                                                      ClassName:NSStringFromClass([self class])
                                                     bundleName:@"LSJHCamera"] forState:UIControlStateNormal];
        _flashLightButton.bounds = CGRectMake(0, 0, 40, 40);
        [_flashLightButton addTarget:self
                              action:@selector(flashLightButtonClick:)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashLightButton;
}

- (UIButton *)cameraButton
{
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraButton setImage:[UIImage ll_loadBundleImage:@"icon_camera_switch"
                                                  ClassName:NSStringFromClass([self class]) bundleName:@"LSJHCamera"] forState:UIControlStateNormal];
        _cameraButton.bounds                = CGRectMake(0, 0, 40, 40);
        _cameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_cameraButton addTarget:self
                          action:@selector(cameraButtonClick:)
                forControlEvents:UIControlEventTouchUpInside];
        if (self.cameraOrientation == LLCameraOrientationFront) {
            _cameraButton.selected = YES;
        }
    }
    return _cameraButton;
}

- (LLProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[LLProgressView alloc]
            initWithFrame:CGRectMake((ScreenWidth - 80 * SizeAdapter) / 2,
                                     ScreenHeight - LLBottomHeight - 80 * SizeAdapter - 30,
                                     80 * SizeAdapter, 80 * SizeAdapter)
        progressViewStyle:LLProgressViewStyleCircle];
        _progressView.borderWidth         = 10 * SizeAdapter;
        _progressView.layer.cornerRadius  = 40 * SizeAdapter;
        _progressView.layer.masksToBounds = YES;
        _progressView.backgroundImage     = [UIImage ll_loadBundleImage:@"yuan" ClassName:NSStringFromClass(self.class) bundleName:@"LSJHCamera"];
        if (self.cameraType == LLCameraTypeAll) {
            UITapGestureRecognizer * tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(takingPictures)];
            [_progressView addGestureRecognizer:tap];

            UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(startRecordingVideo:)];
            [_progressView addGestureRecognizer:longPress];
            [longPress requireGestureRecognizerToFail:tap];
        } else if (self.cameraType == LLCameraTypeImage) {
            UITapGestureRecognizer * tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(takingPictures)];
            [_progressView addGestureRecognizer:tap];
        } else {
            UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(startRecordingVideo:)];
            [_progressView addGestureRecognizer:longPress];
        }
    }
    return _progressView;
}

- (LLCameraTool *)videoTool
{
    if (!_videoTool) {
        _videoTool                = [[LLCameraTool alloc] initWithCameraOrientation:self.cameraOrientation];
        _videoTool.saveMediaBlock = ^(BOOL isSuccess, NSString * result, NSString * imagePath, NSString * videoPath) {
            if (isSuccess) {
                _imagePath = imagePath;
                _videoPath = videoPath;
            }
        };
    }
    return _videoTool;
}

- (LLCameraPreviewImageView *)placeholdImageView
{
    if (!_placeholdImageView) {
        _placeholdImageView = ({
            LLCameraPreviewImageView * object =
            [[LLCameraPreviewImageView alloc] initWithFrame:self.view.bounds];
            object.userInteractionEnabled = YES;
            object.hidden                 = YES;
            WeakSelf(weakSelf);
            object.cancelHandle = ^{ [weakSelf cancelClick]; };
            object.finishHandle = ^(UIImage * _Nonnull previewImage) { [weakSelf sureClick]; };
            object.editHandle   = ^(UIImage * _Nonnull previewImage) {
                StrongSelf(strongSelf);
                if (self.videoTool.videoPath) {
                    [UIView ll_showCenterToastWithMessage:@"视频编辑暂未规划"];
                    if ([UIVideoEditorController
                        canEditVideoAtPath:self.videoTool.videoPath]) {
                        UIVideoEditorController * vc =
                        [[UIVideoEditorController alloc] init];
                        if (self.saveAblum) {
                            vc.videoPath = _videoPath;
                        } else {
                            vc.videoPath = strongSelf.videoTool.videoPath;
                        }
                        vc.delegate = self;
                        [strongSelf presentViewController:vc
                                                 animated:YES
                                               completion:nil];
                        NSLog(@"yes");
                    }

                    return;
                }

                LLImageCropViewController * vc =
                [[LLImageCropViewController alloc] initWithImage:previewImage];
                vc.onDidCropToRect = ^(UIImage * _Nonnull image, CGRect cropRect, NSInteger angle) {
                    [vc dismissViewControllerAnimated:NO
                                           completion:^{
                                               [strongSelf dismissViewControllerAnimated:YES
                                                                              completion:^{
                                                                                  if (strongSelf.takePhoto) {
                                                                                      strongSelf.takePhoto(image, _imagePath);
                                                                                  }
                                                                              }];
                                           }];
                };
                [strongSelf presentViewController:vc animated:YES completion:nil];
            };
            [self.view addSubview:object];
            object;
        });
    }
    return _placeholdImageView;
}

@end
