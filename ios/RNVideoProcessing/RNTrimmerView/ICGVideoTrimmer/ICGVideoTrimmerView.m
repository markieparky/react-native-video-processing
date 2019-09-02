//
//  ICGVideoTrimmerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ICGVideoTrimmerView.h"
#import "ICGThumbView.h"
#import "ICGRulerView.h"

@interface ICGVideoTrimmerView() <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *frameView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (strong, nonatomic) UIView *leftOverlayView;
@property (strong, nonatomic) UIView *leftOverlayShadeView;
@property (strong, nonatomic) UIView *rightOverlayView;
@property (strong, nonatomic) UIView *rightOverlayShadeView;
@property (strong, nonatomic) UILabel *leftTimeView;
@property (strong, nonatomic) UILabel *rightTimeView;
@property (strong, nonatomic) ICGThumbView *leftThumbView;
@property (strong, nonatomic) ICGThumbView *rightThumbView;

@property (strong, nonatomic) UIView *trackerView;
@property (strong, nonatomic) UIView *trackerMiddleView;
@property (strong, nonatomic) UIView *tracker;
@property (strong, nonatomic) UIView *trackerHandle;
@property (strong, nonatomic) UIView *topBorder;
@property (strong, nonatomic) UIView *bottomBorder;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat endTime;

@property (nonatomic) CGFloat widthPerSecond;
@property (nonatomic) int trackerHandleHeight;

@property (nonatomic) CGPoint leftStartPoint;
@property (nonatomic) CGPoint rightStartPoint;
@property (nonatomic) CGFloat overlayWidth;

@end

@implementation ICGVideoTrimmerView

#pragma mark - Initiation

- (instancetype)initWithFrame:(CGRect)frame
{
    NSAssert(NO, nil);
    @throw nil;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [super initWithCoder:aDecoder];
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
    return [self initWithFrame:CGRectZero asset:asset];
}

- (instancetype)initWithFrame:(CGRect)frame asset:(AVAsset *)asset
{
    self = [super initWithFrame:frame];
    if (self) {
        _asset = asset;
        [self resetSubviews];
    }
    return self;
}


#pragma mark - Private methods

- (UIColor *)themeColor
{
    return _themeColor ?: [UIColor lightGrayColor];
}

- (CGFloat)maxLength
{
    return _maxLength ?: 15;
}

- (CGFloat)minLength
{
    return _minLength ?: 3;
}

- (UIColor *)trackerColor
{
    return _trackerColor ?: [UIColor whiteColor];
}

- (UIColor *) trackerHandleColor
{
    return _trackerHandleColor ?: [UIColor whiteColor];
}

- (Boolean) showTrackerHandle
{
    return _showTrackerHandle ?: NO;
}

- (CGFloat)borderWidth
{
    return _borderWidth ?: 1;
}

- (CGFloat)thumbWidth
{
    return _thumbWidth ?: 10;
}

- (void)resetSubviews
{
    //    self.clipsToBounds = YES;
    
    self.trackerHandleHeight = 10;
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - self.trackerHandleHeight)];
    [self.scrollView setBounces:NO];
    [self.scrollView setScrollEnabled:NO];
    [self addSubview:self.scrollView];
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    
    CGFloat ratio = self.showsRulerView ? 0.7 : 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(self.thumbWidth, 0, CGRectGetWidth(self.contentView.frame)-2*self.thumbWidth, CGRectGetHeight(self.contentView.frame)*ratio)];
    //[self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];
    
    [self addFrames];
    
//    if (self.showsRulerView) {
        CGRect rulerFrame = CGRectMake(0, CGRectGetHeight(self.contentView.frame), CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame)*0.5);
        ICGRulerView *rulerView = [[ICGRulerView alloc] initWithFrame:rulerFrame widthPerSecond:self.widthPerSecond themeColor:self.themeColor];
  [rulerView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.0]];
        [self addSubview:rulerView];
  
//    }
  
    // add borders
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:self.themeColor];
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:self.themeColor];
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  CGRectGetWidth(self.frame) - (self.minLength * self.widthPerSecond);
    
    // add left overlay view
    self.leftOverlayView = [[UIView alloc] initWithFrame:CGRectMake(self.thumbWidth - self.overlayWidth, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    CGRect leftThumbFrame = CGRectMake(self.overlayWidth-self.thumbWidth, 0, self.thumbWidth, CGRectGetHeight(self.frameView.frame));
    if (self.leftThumbImage) {
        self.leftThumbView = [[ICGThumbView alloc] initWithFrame:leftThumbFrame thumbImage:self.leftThumbImage];
    } else {
        self.leftThumbView = [[ICGThumbView alloc] initWithFrame:leftThumbFrame color:self.themeColor right:NO];
    }
  
  
  
  self.leftTimeView = [[UILabel alloc] initWithFrame:CGRectMake(self.overlayWidth-self.thumbWidth, -CGRectGetHeight(self.frameView.frame) / 2, 40, CGRectGetHeight(self.frameView.frame) / 2)];
  
  [self.leftOverlayView addSubview:self.leftTimeView];
  
  [self.leftTimeView setTextColor:[UIColor blackColor]];
  [self.leftTimeView setBackgroundColor:[UIColor clearColor]];
  [self.leftTimeView setText:[NSString stringWithFormat:@"%ld", (long) 0]];
  
  [self.leftTimeView setFont:[UIFont fontWithName: @"Trebuchet MS" size: 10.0f]];
    
    self.trackerView = [[UIView alloc] initWithFrame:CGRectMake(self.thumbWidth - self.trackerHandleHeight / 2, 0, 70, CGRectGetHeight(self.frameView.frame) + self.trackerHandleHeight)];
  
  
  self.trackerMiddleView = [[UIView alloc] initWithFrame:CGRectMake(self.thumbWidth - self.trackerHandleHeight / 2, 0, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.frameView.frame) + self.trackerHandleHeight)];
  
    
    self.tracker = [[UIView alloc] initWithFrame:CGRectMake(self.thumbWidth, 0, 4, CGRectGetHeight(self.frameView.frame) + 2)];
    self.trackerHandle = [[UIView alloc] initWithFrame:CGRectMake(self.thumbWidth, CGRectGetHeight(self.frameView.frame), self.trackerHandleHeight, self.trackerHandleHeight)];
    
    [self.trackerHandle.layer setMasksToBounds:YES];
    [self.contentView setUserInteractionEnabled:YES];
    
    //    self.trackerHandle.clipsToBounds = YES;
    [self.trackerHandle.layer setCornerRadius:10];
    self.tracker.backgroundColor = self.trackerColor;
    self.trackerHandle.backgroundColor = self.trackerHandleColor;
    //    self.trackerView.layer.masksToBounds = true;
//    self.tracker.layer.cornerRadius = 2;
  
    
    [self.trackerView addSubview:self.tracker];
    if (self.showTrackerHandle) {
        [self.trackerView addSubview: self.trackerHandle];
    }
//    [self.tracker setUserInteractionEnabled:YES];
//    [self.trackerView setUserInteractionEnabled:YES];
  [self.trackerMiddleView setUserInteractionEnabled:YES];
//    [self.trackerHandle setUserInteractionEnabled:YES];
    [self addSubview:self.trackerView];
  [self addSubview:self.trackerMiddleView];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTrackerPan:)];
    
    [self.panGestureRecognizer locationInView: self.trackerMiddleView];
    
    [self.trackerMiddleView addGestureRecognizer:self.panGestureRecognizer];
    //    [self.trackerHandle addGestureRecognizer:self.panGestureRecognizer];
  
  
    CGRect leftOverlayShadeFrame = CGRectMake(0, 0, 0, CGRectGetHeight(self.frameView.frame));
  self.leftOverlayShadeView = [[UIView alloc] initWithFrame:leftOverlayShadeFrame];
  [self.leftOverlayShadeView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
  
    [self.leftThumbView.layer setMasksToBounds:YES];
  [self.leftOverlayShadeView.layer setMasksToBounds:YES];
  [self.contentView addSubview:self.leftOverlayShadeView];
    [self.leftOverlayView addSubview:self.leftThumbView];
    [self.leftOverlayView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftOverlayView:)];
    [self.leftOverlayView addGestureRecognizer:leftPanGestureRecognizer];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self addSubview:self.leftOverlayView];
  
  
    
    // add right overlay view
  
//      self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - self.thumbWidth) / self.widthPerSecond;
  
  NSLog(@"X time : %f", self.maxLength);
  
  CGFloat rightViewFrameX;
  if (self.endTime < 7) {
    rightViewFrameX = (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ) ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - self.thumbWidth;
  }else{
    
    rightViewFrameX = (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ) ? self.widthPerSecond * 7 + self.thumbWidth : self.widthPerSecond * 7  + self.thumbWidth;
    self.endTime = 7;
  }
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
  
  
  CGRect rightOverlayShadeFrame = CGRectMake(rightViewFrameX, 0, 0, CGRectGetHeight(self.frameView.frame));
  
  
  self.rightOverlayShadeView = [[UIView alloc] initWithFrame:rightOverlayShadeFrame];
  [self.rightOverlayShadeView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
  
  CGFloat widthPosition = CGRectGetMinX(self.rightOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
  CGFloat widthFrame = CGRectGetWidth(self.scrollView.frame);
  
  CGFloat widthShade = widthFrame - widthPosition;
  
  self.rightOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
  CGRect frm = self.rightOverlayShadeView.frame;
  frm.size.width = widthShade;
  frm.origin.x = self.rightOverlayView.frame.origin.x;
  self.rightOverlayShadeView.frame = frm;
  
    if (self.rightThumbImage) {
        self.rightThumbView = [[ICGThumbView alloc] initWithFrame:CGRectMake(0, 0, self.thumbWidth, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[ICGThumbView alloc] initWithFrame:CGRectMake(0, 0, self.thumbWidth, CGRectGetHeight(self.frameView.frame)) color:self.themeColor right:YES];
    }
    [self.rightThumbView.layer setMasksToBounds:YES];
  [self.contentView addSubview:self.rightOverlayShadeView];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightOverlayView:)];
    [self.rightOverlayView addGestureRecognizer:rightPanGestureRecognizer];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self addSubview:self.rightOverlayView];
  
  
  
  self.rightTimeView = [[UILabel alloc] initWithFrame:CGRectMake(4, -CGRectGetHeight(self.frameView.frame) / 2, 40, CGRectGetHeight(self.frameView.frame) / 2)];
  
  [self.rightOverlayView addSubview:self.rightTimeView];
  
  [self.rightTimeView setTextColor:[UIColor blackColor]];
  [self.rightTimeView setBackgroundColor:[UIColor clearColor]];
  [self.rightTimeView setText:[NSString stringWithFormat:@"%ld", (long) 0]];
  
  [self.rightTimeView setFont:[UIFont fontWithName: @"Trebuchet MS" size: 10.0f]];
  
  self.trackerView.hidden = true;
    
    [self updateBorderFrames];
    [self notifyDelegate];
}


- (void)updateBorderFrames
{
    CGFloat height = self.borderWidth;
    [self.topBorder setFrame:CGRectMake(CGRectGetMaxX(self.leftOverlayView.frame), 0, CGRectGetMinX(self.rightOverlayView.frame)-CGRectGetMaxX(self.leftOverlayView.frame), height)];
    [self.bottomBorder setFrame:CGRectMake(CGRectGetMaxX(self.leftOverlayView.frame), CGRectGetHeight(self.frameView.frame)-height, CGRectGetMinX(self.rightOverlayView.frame)-CGRectGetMaxX(self.leftOverlayView.frame), height)];
}

- (void)handleTrackerPan: (UIGestureRecognizer *) recognizer {
  
  CGPoint pointtest = [recognizer locationInView:self];
    CGPoint point = [self.panGestureRecognizer locationInView:self.trackerMiddleView];
  NSLog(@"tracker : %f", pointtest.x);
  NSLog(@"tracker : %f", point.x);
//
    CGRect trackerFrame = self.trackerMiddleView.frame;
  
    trackerFrame.origin.x += point.x - self.trackerHandleHeight / 2;
  
  CGFloat diffrence = self.trackerMiddleView.frame.origin.x - trackerFrame.origin.x;
  self.trackerMiddleView.frame = trackerFrame;
  NSLog(@"leftoverlay : %f", self.leftOverlayView.center.x);
  
  
  
  
  
  CGFloat newRightViewMidX = self.rightOverlayView.center.x - diffrence;
  CGFloat minX = CGRectGetMaxX(self.leftOverlayView.frame) + self.minLength * self.widthPerSecond;
  CGFloat maxX = CMTimeGetSeconds([self.asset duration]) <= self.maxLength + 0.5 ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - self.thumbWidth;
  if (newRightViewMidX - self.overlayWidth/2 < minX) {
    newRightViewMidX = minX + self.overlayWidth/2;
  } else if (newRightViewMidX - self.overlayWidth/2 > maxX) {
    newRightViewMidX = maxX + self.overlayWidth/2;
  }
  
    self.rightOverlayView.center = CGPointMake(newRightViewMidX, self.rightOverlayView.center.y);
    
    
    
    CGFloat widthPosition = CGRectGetMinX(self.rightOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
    CGFloat widthFrame = CGRectGetWidth(self.scrollView.frame);
    
    CGFloat widthShade = widthFrame - widthPosition;
    
    self.rightOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
    CGRect frm = self.rightOverlayShadeView.frame;
    frm.size.width = widthShade;
    frm.origin.x = self.rightOverlayView.frame.origin.x;
    self.rightOverlayShadeView.frame = frm;
  
  
  
  
    //left view
  
  CGFloat newLeftViewMidX = self.leftOverlayView.center.x - diffrence;
  CGFloat maxWidth = CGRectGetMinX(self.rightOverlayView.frame) - (self.minLength * self.widthPerSecond);
  
  
  
  CGFloat newLeftViewMinX = newLeftViewMidX - self.overlayWidth/2;
  if (newLeftViewMinX < self.thumbWidth - self.overlayWidth) {
    newLeftViewMidX = self.thumbWidth - self.overlayWidth + self.overlayWidth/2;
  } else if (newLeftViewMinX + self.overlayWidth > maxWidth) {
    newLeftViewMidX = maxWidth - self.overlayWidth / 2;
  }
  
  
    self.leftOverlayView.center = CGPointMake(newLeftViewMidX, self.leftOverlayView.center.y);
    
    self.leftOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
    CGFloat widthShadeLeft = CGRectGetMaxX(self.leftOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
    CGRect frmLeft = self.leftOverlayShadeView.frame;
    frmLeft.size.width = widthShadeLeft;
    
    self.leftOverlayShadeView.frame = frmLeft;
  
  
  
  [self updateBorderFrames];
  [self notifyDelegate];
//
//    CGFloat time = (trackerFrame.origin.x - self.thumbWidth + self.scrollView.contentOffset.x + self.trackerHandleHeight) / self.widthPerSecond;
//    [self.delegate trimmerView:self currentPosition:time ];
  
}

- (void)moveLeftOverlayView:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.leftStartPoint = [gesture locationInView:self];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];
            
            int deltaX = point.x - self.leftStartPoint.x;
            
            CGPoint center = self.leftOverlayView.center;
          
          
          NSLog(@"leftoverlay : %f", self.leftOverlayView.center.x);
          
          NSLog(@"startpointleft : %f", self.leftStartPoint.x);
            
            CGFloat newLeftViewMidX = center.x += deltaX;;
            CGFloat maxWidth = CGRectGetMinX(self.rightOverlayView.frame) - (self.minLength * self.widthPerSecond);
          
        
          
            CGFloat newLeftViewMinX = newLeftViewMidX - self.overlayWidth/2;
            if (newLeftViewMinX < self.thumbWidth - self.overlayWidth) {
                newLeftViewMidX = self.thumbWidth - self.overlayWidth + self.overlayWidth/2;
            } else if (newLeftViewMinX + self.overlayWidth > maxWidth) {
                newLeftViewMidX = maxWidth - self.overlayWidth / 2;
            }
          
          if((self.endTime - self.startTime) >= 7  ){
            CGFloat diffrence = self.leftOverlayView.center.x - newLeftViewMidX;
            
            NSLog(@"X diffrence : %f", diffrence);
            if (diffrence >= 0) {
              self.rightOverlayView.center = CGPointMake(self.rightOverlayView.center.x - diffrence, self.rightOverlayView.center.y);
              
              
              
              CGFloat widthPosition = CGRectGetMinX(self.rightOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
              CGFloat widthFrame = CGRectGetWidth(self.scrollView.frame);
              
              CGFloat widthShade = widthFrame - widthPosition;
              
              self.rightOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
              CGRect frm = self.rightOverlayShadeView.frame;
              frm.size.width = widthShade;
              frm.origin.x = self.rightOverlayView.frame.origin.x;
              self.rightOverlayShadeView.frame = frm;
            }
          }
            
            self.leftOverlayView.center = CGPointMake(newLeftViewMidX, self.leftOverlayView.center.y);
          
          
          self.leftOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
            self.leftStartPoint = point;
          CGFloat widthShade = CGRectGetMaxX(self.leftOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
          CGRect frm = self.leftOverlayShadeView.frame;
          frm.size.width = widthShade;
          
          self.leftOverlayShadeView.frame = frm;
          
            [self updateBorderFrames];
            [self notifyDelegate];
            
            break;
        }
            
        default:
            break;
    }
    
    
}

- (void)moveRightOverlayView:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.rightStartPoint = [gesture locationInView:self];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];
            
            int deltaX = point.x - self.rightStartPoint.x;
            
            CGPoint center = self.rightOverlayView.center;
            
            CGFloat newRightViewMidX = center.x += deltaX;
            CGFloat minX = CGRectGetMaxX(self.leftOverlayView.frame) + self.minLength * self.widthPerSecond;
            CGFloat maxX = CMTimeGetSeconds([self.asset duration]) <= self.maxLength + 0.5 ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - self.thumbWidth;
            if (newRightViewMidX - self.overlayWidth/2 < minX) {
                newRightViewMidX = minX + self.overlayWidth/2;
            } else if (newRightViewMidX - self.overlayWidth/2 > maxX) {
                newRightViewMidX = maxX + self.overlayWidth/2;
            }
          
          if((self.endTime - self.startTime) >= 7  ){
            
            CGFloat diffrence = self.rightOverlayView.center.x - newRightViewMidX;
            if (diffrence <= 0) {
              self.leftOverlayView.center = CGPointMake(self.leftOverlayView.center.x - diffrence, self.leftOverlayView.center.y);
              
              self.leftOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
              CGFloat widthShade = CGRectGetMaxX(self.leftOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
              CGRect frm = self.leftOverlayShadeView.frame;
              frm.size.width = widthShade;
              
              self.leftOverlayShadeView.frame = frm;
            }
            

          }
          
            self.rightOverlayView.center = CGPointMake(newRightViewMidX, self.rightOverlayView.center.y);
            self.rightStartPoint = point;
          
          
          CGFloat widthPosition = CGRectGetMinX(self.rightOverlayView.frame) + (self.scrollView.contentOffset.x -self.thumbWidth);
          CGFloat widthFrame = CGRectGetWidth(self.scrollView.frame);
          
          CGFloat widthShade = widthFrame - widthPosition;
          
          self.rightOverlayShadeView.layer.anchorPoint = CGPointMake(0.0 , 0.5);
          CGRect frm = self.rightOverlayShadeView.frame;
          frm.size.width = widthShade;
          frm.origin.x = self.rightOverlayView.frame.origin.x;
          self.rightOverlayShadeView.frame = frm;
            [self updateBorderFrames];
            [self notifyDelegate];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)seekToTime:(CGFloat) time
{
    CGFloat posToMove = time * self.widthPerSecond + self.thumbWidth - self.scrollView.contentOffset.x - self.trackerHandleHeight;
    
    CGRect trackerFrame = self.trackerView.frame;
    trackerFrame.origin.x = posToMove;
    self.trackerView.frame = trackerFrame;
  CGRect trackerMiddleFrame = self.trackerMiddleView.frame;
  trackerMiddleFrame.origin.x = posToMove;
  self.trackerMiddleView.frame = trackerMiddleFrame;
    
}

- (void)hideTracker:(BOOL)flag
{
    self.trackerView.hidden = flag;
}

- (void)notifyDelegate
{
    CGFloat start = CGRectGetMaxX(self.leftOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x -self.thumbWidth) / self.widthPerSecond;
  
    if (!self.trackerView.hidden && start != self.startTime) {
//        [self seekToTime:start];
    }
    self.startTime = start;
  
//  [self.leftTimeView setText:[NSString stringWithFormat:@"%ld", (long) start]];
    self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - self.thumbWidth) / self.widthPerSecond;
  
  
  [self.rightTimeView setText:[NSString stringWithFormat:@"%.0f", (long) self.endTime - start]];
  
  
  NSLog(@"start time : %f", start);
//  [self.leftTimeView setText:[NSString stringWithFormat:@"%ld:%02ld", (long) start, (long) 00]];
//  self.endTime = 7;
    [self.delegate trimmerView:self didChangeLeftPosition:self.startTime rightPosition:self.endTime];
}

- (void)addFrames
{
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    if ([self isRetina]){
        self.imageGenerator.maximumSize = CGSizeMake(CGRectGetWidth(self.frameView.frame)*2, CGRectGetHeight(self.frameView.frame)*2);
    } else {
        self.imageGenerator.maximumSize = CGSizeMake(CGRectGetWidth(self.frameView.frame), CGRectGetHeight(self.frameView.frame));
    }
    
    CGFloat picWidth = 0;
    
    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
    UIImage *videoScreen;
    if ([self isRetina]){
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
    } else {
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
    }
    if (halfWayImage != NULL) {
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        CGRect rect = tmp.frame;
        rect.size.width = videoScreen.size.width;
        tmp.frame = rect;
        [self.frameView addSubview:tmp];
        picWidth = tmp.frame.size.width / 1;
        CGImageRelease(halfWayImage);
    }
    
    Float64 duration = CMTimeGetSeconds([self.asset duration]);
    CGFloat screenWidth = CGRectGetWidth(self.frame) - 2*self.thumbWidth; // quick fix to make up for the width of thumb views
    NSInteger actualFramesNeeded;
    
    CGFloat frameViewFrameWidth = (duration / self.maxLength) * screenWidth;
    [self.frameView setFrame:CGRectMake(self.thumbWidth, 0, frameViewFrameWidth, CGRectGetHeight(self.frameView.frame))];
    CGFloat contentViewFrameWidth = CMTimeGetSeconds([self.asset duration]) <= self.maxLength + 0.5 ? screenWidth + 30 : frameViewFrameWidth;
    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth, CGRectGetHeight(self.contentView.frame))];
    [self.scrollView setContentSize:self.contentView.frame.size];
    NSInteger minFramesNeeded = screenWidth / picWidth + 1;
    actualFramesNeeded =  (duration / self.maxLength) * minFramesNeeded + 1;
    
    Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
    self.widthPerSecond = frameViewFrameWidth / duration;
    
    int preferredWidth = 0;
    NSMutableArray *times = [[NSMutableArray alloc] init];
    for (int i=1; i<actualFramesNeeded; i++){
        
        CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame, 600);
        [times addObject:[NSValue valueWithCMTime:time]];
        
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        tmp.tag = i;
        
        CGRect currentFrame = tmp.frame;
        currentFrame.origin.x = i*picWidth;
        
        currentFrame.size.width = picWidth;
        preferredWidth += currentFrame.size.width;
        
        if( i == actualFramesNeeded-1){
            currentFrame.size.width-=6;
        }
        tmp.frame = currentFrame;
        
        [self.frameView addSubview:tmp];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=1; i<=[times count]; i++) {
            CMTime time = [((NSValue *)[times objectAtIndex:i-1]) CMTimeValue];
            
            CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
            
            UIImage *videoScreen;
            if ([self isRetina]){
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
            } else {
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
            }
            
            CGImageRelease(halfWayImage);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:i];
                [imageView setContentMode:UIViewContentModeScaleAspectFill];
                [imageView setImage:videoScreen];
                
            });
        }
    });
}

- (BOOL)isRetina
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale > 1.0));
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (CMTimeGetSeconds([self.asset duration]) <= self.maxLength + 0.5) {
        [UIView animateWithDuration:0.3 animations:^{
            [scrollView setContentOffset:CGPointZero];
        }];
    }
    [self notifyDelegate];
}

@end
