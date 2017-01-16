//
//  SMKenBurnsEffect.h
//  SMKenBurnsEffect
//
//  Created by Oxygen on 20.07.12.
//  Copyright (c) 2012 SM. All rights reserved.
//

@interface ISKenBurnsEffect : UIView

@property (nonatomic, assign) CGFloat zoomSize; //default is 2.2
@property (nonatomic, assign) NSTimeInterval fadeDuration;
@property (nonatomic, strong) NSArray *images;

- (void)start;
- (void)stop;

- (BOOL)isAnimating;

@end
