//
//  SMKenBurnsEffect.m
//  SMKenBurnsEffect
//
//  Created by Oxygen on 20.07.12.
//  Copyright (c) 2012 SM. All rights reserved.
//

#import "SMKenBurnsEffect.h"

static CGFloat const kNextPicAnimationDuration = 0.5;
static CGFloat const kDefaultZoom = 2.2;
static int const kNoImage = -1;

#define INITIAL_AFFINE_STATE CGAffineTransformMake(1, 0, 0, 1, 0, 0)


@interface ISKenBurnsEffect ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) CGRect prevFrame;
@property (nonatomic, assign) NSInteger currentImageIndex;

@end


@implementation ISKenBurnsEffect

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.currentImageIndex = kNoImage;
    
    if (!self.zoomSize) {
        self.zoomSize = kDefaultZoom;
    }
    
    self.imageView = [self createDefaultImageView];
    self.imageView.image = [self.images firstObject];
    [self addSubview:self.imageView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (CGRectEqualToRect(self.prevFrame, CGRectZero)) {
        self.prevFrame = self.frame;
    }
    
    if ([self orientationChanged]) {
        [self restartWithCurrentImage];
    }
    
    self.prevFrame = self.frame;
}


#pragma mark -
#pragma mark Setters

- (void)setImages:(NSArray *)images
{
    _images = images;
    self.imageView.image = [images firstObject];
}


#pragma mark -
#pragma mark Public Methods

- (void)start
{
    self.imageView = [self createDefaultImageView];
    [self addSubview:self.imageView];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:[self timerInterval] target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)stop
{
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (BOOL)isAnimating
{
    return [self.timer isValid];
}


#pragma mark -
#pragma mark Actions

- (void)tick
{
    if (self.currentImageIndex == kNoImage) {
        [self incCurrentImageIndex];
        [self.imageView setImage:[self currentImage]];
        [self startAnimate];
    } else {
        __weak ISKenBurnsEffect *weakSelf = self;
        [self showNextWithComplition:^{
            [weakSelf incCurrentImageIndex];
            [weakSelf startAnimate];
        }];
    }
}


#pragma mark -
#pragma mark Animations

- (void)startAnimate
{
    float resizeRatio = [self ratioForAspectFitImageInImageView:self.imageView];
    float realImageWidth  = self.imageView.image.size.width * resizeRatio;
    float realImageHeight = self.imageView.image.size.height * resizeRatio;
    float zoomedWidth  = realImageWidth * self.zoomSize;
    float zoomedHeight = realImageHeight * self.zoomSize;

    float maxXOffset = zoomedWidth/2 - self.frame.size.width/2;
    float maxYOffset = zoomedHeight/2 - self.frame.size.height/2;
    
    int xDelta = [self randFrom:(maxXOffset*(-1)) to:maxXOffset];
    int yDelta = [self randFrom:(maxYOffset*(-1)) to:maxYOffset];

    [self animateWithZoom:self.zoomSize atPoint:CGPointMake(xDelta, yDelta)];
}

- (void)animateWithZoom:(float)zoom atPoint:(CGPoint)pt
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:self.fadeDuration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(endAnimation)];
    
    CGAffineTransform rotate    = CGAffineTransformMakeRotation(1/100);
    CGAffineTransform move      = CGAffineTransformMakeTranslation(pt.x, pt.y);
    CGAffineTransform combo     = CGAffineTransformConcat(rotate, move);
    CGAffineTransform zoomIn    = CGAffineTransformMakeScale(zoom, zoom);
    CGAffineTransform transform = CGAffineTransformConcat(zoomIn, combo);
    self.imageView.transform = transform;
    [UIView commitAnimations];
}

- (void)endAnimation
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:self.fadeDuration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    self.imageView.transform = INITIAL_AFFINE_STATE;
    [UIView commitAnimations];
}

- (void)showNextWithComplition:(void (^)())complition
{
    UIImageView *nextImgView = [self createDefaultImageView];
    nextImgView.image = [self nextImage];
    nextImgView.alpha = 0;
    [self insertSubview:nextImgView aboveSubview:self.imageView];
    
    __weak ISKenBurnsEffect *weakSelf = self;
    [UIView animateWithDuration:kNextPicAnimationDuration animations:^{
        nextImgView.alpha = 1;
    } completion:^(BOOL finished) {
        UIImageView *oldImageView = weakSelf.imageView;
        weakSelf.imageView = nextImgView;
        [oldImageView removeFromSuperview];
        
        if (complition) {
            complition();
        }
    }];
}


#pragma mark -
#pragma mark Images Managment

- (UIImage *)currentImage
{
    return self.images[self.currentImageIndex];
}

- (UIImage *)nextImage
{
    NSInteger index = (self.currentImageIndex+1 < self.images.count) ? self.currentImageIndex+1 : 0;
    return self.images[index];
}

- (void)incCurrentImageIndex
{
    self.currentImageIndex++;
    if (self.currentImageIndex >= (int)self.images.count) {
        self.currentImageIndex = 0;
    }
}


#pragma mark -
#pragma mark Helpers

- (int)randFrom:(int)from to:(int)to
{
    return (arc4random()%(to-from)) + from;
}

- (float)ratioForAspectFitImageInImageView:(UIImageView *)imageView
{
    UIImage *image = imageView.image;
    float frameWidth  = imageView.frame.size.width;
    float frameHeight = imageView.frame.size.height;
    
    float resizeRatio = -1;
    float widthDiff   = fabs(imageView.image.size.width - frameWidth);
    float heightDiff  = fabs(imageView.image.size.height - frameHeight);
    
    if (image.size.width > frameWidth) {
        if (image.size.height > frameHeight) {
            resizeRatio = (heightDiff > widthDiff) ? frameWidth/image.size.width : frameHeight/image.size.height;
        } else {
            resizeRatio = frameHeight/image.size.height;
        }
    } else {
        if (image.size.height > frameHeight) {
            resizeRatio = frameWidth/image.size.width;
        } else {
            resizeRatio = (heightDiff > widthDiff) ? frameHeight/image.size.height : frameWidth/image.size.width;
        }
    }
    return resizeRatio;
}

- (BOOL)orientationChanged
{
    BOOL wasPortrait = (self.prevFrame.size.height > self.prevFrame.size.width);
    BOOL nowPortrait = (self.frame.size.height > self.frame.size.width);
    return (wasPortrait != nowPortrait);
}

- (void)restartWithCurrentImage
{
    [self stop];
    
    UIImageView *updImgView = [self createDefaultImageView];
    updImgView.image = self.imageView.image;
    updImgView.alpha = 0;
    [self insertSubview:updImgView aboveSubview:self.imageView]; 
    
    [UIView animateWithDuration:0.4 animations:^{
        updImgView.alpha = 1;
    } completion:^(BOOL finished) {
        self.imageView = updImgView;
        [self startAnimate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:[self timerInterval] target:self selector:@selector(tick) userInfo:nil repeats:YES];
    }];
}

- (NSTimeInterval)timerInterval
{
    return (self.fadeDuration*2)+kNextPicAnimationDuration; //2 - because 2 animations: fadeIn and fadeOut.
}

- (UIImageView *)createDefaultImageView
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    return imageView;
}

@end
