//
//  NJKWebViewProgressView.m
//
//  Created by Satoshi Aasanoon 11/16/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import "NJKWebViewProgressView.h"
#import <QuartzCore/QuartzCore.h>
#include <time.h>

@implementation NJKWebViewProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self configureViews];
}

-(void)configureViews
{
    //self.userInteractionEnabled = NO;
    self.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    _progressBarView = [[NSView alloc] initWithFrame:self.bounds];
    _progressBarView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    NSColor *tintColor = [NSColor colorWithRed:22.f / 255.f green:126.f / 255.f blue:251.f / 255.f alpha:1.0];
    
    _progressBarView.wantsLayer = true;
    _progressBarView.layer.backgroundColor = tintColor.CGColor;
    [self addSubview:_progressBarView];
    
    _barAnimationDuration = 0.27f;
    _fadeAnimationDuration = 0.27f;
    _fadeOutDelay = 0.3f;
}

-(void)setProgress:(float)progress
{
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    BOOL isGrowing = progress > 0.0;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        CGFloat time = (isGrowing && animated) ? _barAnimationDuration : 0.0;
        [context setDuration:time];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        CGRect frame = _progressBarView.frame;
        frame.size.width = progress * self.bounds.size.width;
        [_progressBarView.animator setFrame:frame];
    } completionHandler:nil];
    
    if (progress >= 1.0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_fadeOutDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:animated ? _fadeAnimationDuration : 0.0];
                [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
                _progressBarView.animator.alphaValue = 0.0;
            } completionHandler:^{
                CGRect frame = _progressBarView.frame;
                frame.size.width = 0;
                _progressBarView.frame = frame;
            }];
        });
    }
    else {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:animated ? _fadeAnimationDuration : 0.0];
            [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            _progressBarView.animator.alphaValue = 1.0;
        } completionHandler:nil];
    }
}

@end
