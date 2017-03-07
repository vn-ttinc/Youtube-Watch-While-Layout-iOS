//
//  WatchWhileLayout.m
//  WatchWhileLayout-ios
//
//  Created by Ngo Than Phong on 3/1/17.
//  Copyright © 2017 kthangtd. All rights reserved.
//

#import "WatchWhileLayout.h"
#import <QuartzCore/QuartzCore.h>

#define WWL_STATE_MAXIMIZING 3
#define WWL_BACKGROUD_ID 1000
#define WWL_PLAYER_VIEW_ID 1010
#define WWL_OVERLAY_VIEW_ID 1020
#define WWL_METADATA_ID 1030

#define WWL_VELOCITY_MIN 900
#define WWL_PLAYER_RATIO 1.777F
#define WWL_COLOR_EX 0.204F

#define IS_TABLET ( [[[UIDevice currentDevice] model] isEqualToString:@"iPad"] )
#define IS_LANDSCAPE ( UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
#define FORE_TO_LANDSCAPE ( [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"] )
#define FORE_TO_PORTRAIT ( [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationPortrait] forKey:@"orientation"] )

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface WatchWhileLayout ()

@property (nonatomic, strong) WWLPlayerViewWrapper * playerViewWrapper;

@property (nonatomic, strong) WWLView * metadataPanelViewWrapper;

@property (nonatomic, strong) WWLView * metadataViewWrapper;

@property (nonatomic, assign) NSInteger saveState;

@property (nonatomic, assign) DragOrientation dragDirection;

@property (nonatomic, assign) CGPoint savePoint;

@property (nonatomic, assign) BOOL isForceUpdate;

@property (nonatomic, assign) CGFloat miniPlayerHeight;

@property (nonatomic, assign) UIEdgeInsets miniPlayerInsets;

@property (nonatomic, assign) CGRect miniPlayerViewWrapperRect;

@property (nonatomic, assign, readonly) CGSize playerViewSizeMax;

@property (nonatomic, assign, readonly) CGRect screenBounds;

@property (nonatomic, assign, readonly) NSTimeInterval animationDuration;

@end

@implementation WatchWhileLayout

@synthesize overlayView = _overlayView;
@synthesize state = _state;
@synthesize isFullScreen = _isFullScreen;

#pragma mark ---- < Singleton Init >

static WatchWhileLayout * sIntance = nil;

+ (void)init {
    if (contentWindow == nil) {
        contentWindow = [[WWLWindow alloc] init];
        contentWindow.windowLevel = UIWindowLevelStatusBar+1;
        [contentWindow makeKeyAndVisible];
        contentWindow.frame = [UIScreen mainScreen].bounds;
        contentWindow.rootViewController = [self get];
    }
}

+ (WatchWhileLayout *)get {
    if (contentWindow == nil) {
        NSLog(@"ERROR::WWL do not init in delegate");
        return nil;
    }
    if (sIntance == nil) {
        sIntance = [[WatchWhileLayout alloc] init];
        sIntance.view.tag = WWL_BACKGROUD_ID;
    }
    return sIntance;
}

#pragma mark ---- < Init >

- (instancetype)init {
    if (self = [super init]) {
        self.miniPlayerPadding = 12.0f;
        _state = WWL_STATE_HIDED;
        self.dragDirection = DRAGGING_NONE;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLayout];
}

- (void)initLayout {
    [self.view addSubview:self.metadataViewWrapper];
    [self.view addSubview:self.metadataPanelViewWrapper];
    [self.view addSubview:self.playerViewWrapper];
    [self.view addSubview:self.overlayView];
    
    contentWindow.hidden = YES;
    [self minimize:NO];
    _state = WWL_STATE_HIDED;
}

- (CGFloat)miniPlayerWidth {
    if (_miniPlayerWidth > 0) {
        return _miniPlayerWidth;
    }
    return self.playerViewSizeMax.width/(IS_TABLET ? 3 : 2);
}

- (CGFloat)miniPlayerHeight {
    _miniPlayerHeight = self.miniPlayerWidth/WWL_PLAYER_RATIO;
    return _miniPlayerHeight;
}

- (UIEdgeInsets)miniPlayerInsets {
    if (_miniPlayerInsets.top == 0 || self.isForceUpdate) {
        self.isForceUpdate = NO;
        _miniPlayerInsets.bottom = self.screenBounds.size.height-self.miniPlayerPadding;
        _miniPlayerInsets.top = _miniPlayerInsets.bottom-self.miniPlayerHeight;
        _miniPlayerInsets.right = self.screenBounds.size.width-self.miniPlayerWidth;
        _miniPlayerInsets.left = _miniPlayerInsets.right-self.miniPlayerPadding;
    }
    return _miniPlayerInsets;
}

#pragma mark ---- < Update Layout Changed >

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.isForceUpdate = YES;
    if (self.dragDirection == DRAGGING_NONE) {
        [self updateLayoutWithAnimated:NO];
    }
}

#pragma mark ---- < WWL Action >

- (void)startPlay {
    [self maximize:YES];
}

#pragma mark ---- < Setup View >

- (void)setPlayerView:(UIView *)playerView {
    if (_playerView != nil) {
        [_playerView removeFromSuperview];
    }
    _playerView = playerView;
    _playerView.tag = WWL_PLAYER_VIEW_ID;
    _playerView.backgroundColor = [UIColor blackColor];
    _playerView.userInteractionEnabled = NO;
    [self.playerViewWrapper addSubview:_playerView];
    [self.playerViewWrapper bringSubviewToFront:_playerView];
    _playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playerViewWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[pv]-(0)-|"
                                                                                   options:0
                                                                                   metrics:nil
                                                                                     views:@{@"pv":_playerView}]];
    
    [self.playerViewWrapper addConstraint:[NSLayoutConstraint constraintWithItem:_playerView
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_playerView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1/WWL_PLAYER_RATIO
                                                                        constant:0]];
    
    [self.playerViewWrapper addConstraint:[NSLayoutConstraint constraintWithItem:_playerView
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.playerViewWrapper
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1
                                                                        constant:0]];
}

- (void)setMetadataView:(UIView *)metadataView {
    [self removeOldView:_metadataView];
    _metadataView = metadataView;
    _metadataView.frame = self.metadataViewWrapper.bounds;
    _metadataView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.metadataViewWrapper addSubview:_metadataView];
}

- (void)setMetadataPanelView:(UIView *)metadataPanelView {
    [self removeOldView:_metadataPanelView];
    _metadataPanelView = metadataPanelView;
    _metadataPanelView.frame = self.metadataPanelViewWrapper.bounds;
    _metadataPanelView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.metadataPanelViewWrapper addSubview:_metadataPanelView];
}

- (void)setOverlayView:(WWLOverlayView *)overlayView {
    if (![overlayView isKindOfClass:[WWLOverlayView class]]) {
        NSLog(@"ERROR::OverlayView must be inheritance from WWLOverlayView");
        return;
    }
    if (_overlayView != nil) {
        [_overlayView removeFromSuperview];
    }
    _overlayView = overlayView;
    _overlayView.tag = WWL_OVERLAY_VIEW_ID;
    _overlayView.frame = self.playerViewWrapper.frame;
}

- (WWLOverlayView *)overlayView {
    if (_overlayView == nil) {
        _overlayView = [[WWLOverlayView alloc] initWithFrame:self.playerViewWrapper.frame];
        _overlayView.tag = WWL_OVERLAY_VIEW_ID;
    }
    return _overlayView;
}

- (void)setMetadataViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    [self setMetadataView:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)setMetadataPanelViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    [self setMetadataPanelView:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)removeOldView:(UIView *)view {
    if (_metadataView != nil) {
        UIResponder * nextResponder = [view nextResponder];
        if (nextResponder != nil && [nextResponder isKindOfClass:[UIViewController class]]) {
            UIViewController * vc = (UIViewController *)nextResponder;
            [vc willMoveToParentViewController:nil];
            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
        } else {
            [view removeFromSuperview];
        }
    }
}

#pragma mark ---- < Setup ViewWrapper >

- (WWLPlayerViewWrapper *)playerViewWrapper {
    if (_playerViewWrapper == nil) {
        _playerViewWrapper = [[WWLPlayerViewWrapper alloc] init];
        _playerViewWrapper.backgroundColor = [UIColor blackColor];
        _playerViewWrapper.tag = WWL_PLAYER_VIEW_ID;
        [_playerViewWrapper addGestureRecognizer:
         [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(playerViewPan:)]];
        [_playerViewWrapper addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playerViewTap:)]];
    }
    return _playerViewWrapper;
}

- (WWLView *)metadataViewWrapper {
    if (_metadataViewWrapper == nil) {
        _metadataViewWrapper = [[WWLView alloc] init];
        _metadataViewWrapper.tag = WWL_METADATA_ID;
        _metadataViewWrapper.backgroundColor = [UIColor whiteColor];
    }
    return _metadataViewWrapper;
}

- (WWLView *)metadataPanelViewWrapper {
    if (_metadataPanelViewWrapper == nil) {
        _metadataPanelViewWrapper = [[WWLView alloc] init];
        _metadataPanelViewWrapper.tag = WWL_METADATA_ID;
        _metadataPanelViewWrapper.backgroundColor = [UIColor whiteColor];
        CALayer * leftBorder = [CALayer layer];
        leftBorder.backgroundColor = [[UIColor lightGrayColor] CGColor];
        leftBorder.frame = CGRectMake(0, 0, 1.0f, [self screenBounds].size.height);
        [_metadataPanelViewWrapper.layer addSublayer:leftBorder];
    }
    return _metadataPanelViewWrapper;
}

#pragma mark ---- <Update Layout State>

- (void)updateLayoutWithAnimated:(BOOL)animated {
    if (animated) {
        if (self.state == WWL_STATE_MINIMIZED) {
            [self hideOverlayView:NO];
        }
        [UIView animateWithDuration:self.animationDuration animations:^{
            [self updateLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self animationComplete:animated];
        }];
    } else {
        [self updateLayout];
        [self animationComplete:animated];
    }
}

- (void)animationComplete:(BOOL)animated {
    if (self.state == WWL_STATE_HIDED) {
        contentWindow.hidden = YES;
        _state = WWL_STATE_MINIMIZED;
        [self updateLayout];
        _state = WWL_STATE_HIDED;
    } else if (self.state != WWL_STATE_MINIMIZED) {
        self.overlayView.frame = self.playerViewWrapper.frame;
        if (animated || self.isFullScreen) {
            [self showOverlayView:YES];
        }
    }
    if (self.listener != nil) {
        switch (self.state) {
            case WWL_STATE_HIDED:
                if ([self.listener respondsToSelector:@selector(WWL_onHided)]) {
                    [self.listener WWL_onHided];
                }
                break;
            case WWL_STATE_MAXIMIZED:
            case WWL_STATE_MAXIMIZING:
                if ([self.listener respondsToSelector:@selector(WWL_maximized)]) {
                    [self.listener WWL_maximized];
                }
                break;
            case WWL_STATE_MINIMIZED:
                if ([self.listener respondsToSelector:@selector(WWL_minimized)]) {
                    [self.listener WWL_minimized];
                }
                break;
            default:
                break;
        }
    }
}

- (void)updateLayout {
    if (self.isFullScreen && IS_TABLET) {
        self.playerViewWrapper.frame = self.screenBounds;
        return;
    }
    if (self.state == WWL_STATE_MAXIMIZING) {
        if (!IS_LANDSCAPE && !IS_TABLET) {
            FORE_TO_LANDSCAPE;
        } else {
            [self enterPlayerFullscreen];
            _state = WWL_STATE_MAXIMIZED;
        }
        return;
    }else if (self.state == WWL_STATE_MAXIMIZED && self.isFullScreen) {
        [self exitFullscreen];
        return;
    }
    CGRect bounds = self.screenBounds;
    CGRect playerViewRect = bounds;
    CGRect metadataViewRect = self.metadataViewWrapper.frame;
    UIColor * bgColor;
    switch (self.state) {
        case WWL_STATE_MAXIMIZED: {
            if (IS_LANDSCAPE) {
                if (IS_TABLET) {
                    playerViewRect.size.width = playerViewRect.size.height;
                    CGRect metadataPanelViewRect = bounds;
                    metadataPanelViewRect.size.width -= playerViewRect.size.width;
                    metadataPanelViewRect.origin.x = playerViewRect.size.width;
                    self.metadataPanelViewWrapper.frame = metadataPanelViewRect;
                    self.metadataPanelViewWrapper.alpha = 1;
                } else {
                    [self enterPlayerFullscreen];
                    return;
                }
            }
            metadataViewRect = playerViewRect;
            playerViewRect.size.height = playerViewRect.size.width/WWL_PLAYER_RATIO;
            metadataViewRect.origin.y = playerViewRect.size.height;
            metadataViewRect.size.height -= metadataViewRect.origin.y;
            self.metadataViewWrapper.alpha = 1;
            bgColor = [UIColor colorWithWhite:WWL_COLOR_EX alpha:1];
        }
            break;
        case WWL_STATE_MINIMIZED: {
            playerViewRect.size = CGSizeMake(self.miniPlayerWidth, self.miniPlayerHeight);
            playerViewRect.origin = CGPointMake(self.miniPlayerInsets.left, self.miniPlayerInsets.top);
            metadataViewRect.origin.y = bounds.size.height;
            [self.metadataPanelViewWrapper setX:self.screenBounds.size.width];
            self.metadataViewWrapper.alpha = self.metadataPanelViewWrapper.alpha = 0;
            bgColor = [UIColor clearColor];
        }
            break;
        case WWL_STATE_HIDED: {
            playerViewRect = self.playerViewWrapper.frame;
            playerViewRect.origin.x = self.playerViewWrapper.x < self.miniPlayerInsets.left ? 0 : bounds.size.width;
            self.playerViewWrapper.frame = playerViewRect;
            self.playerViewWrapper.alpha = 0;
        }
            return;
        default:
            break;
    }
    self.playerViewWrapper.frame = playerViewRect;
    self.playerViewWrapper.alpha = 1;
    self.metadataViewWrapper.frame = metadataViewRect;
    [self.playerViewWrapper setBorderAlpha:1-self.metadataViewWrapper.alpha];
    contentWindow.backgroundColor = bgColor;
}

#pragma mark ---- <Player State>

- (void)maximize:(BOOL)animated {
    _state = WWL_STATE_MAXIMIZED;
    contentWindow.hidden = NO;
    _isFullScreen = NO;
    [self updateLayoutWithAnimated:animated];
}

- (void)minimize:(BOOL)animated {
    _isFullScreen = NO;
    _state = WWL_STATE_MINIMIZED;
    [self updateLayoutWithAnimated:animated];
}

- (void)hided:(BOOL)animated {
    _state = WWL_STATE_HIDED;
    [self updateLayoutWithAnimated:animated];
}

- (void)enterFullscreen:(BOOL)animated {
    contentWindow.hidden = NO;
    _state = WWL_STATE_MAXIMIZING;
    [self updateLayoutWithAnimated:animated];
}

- (void)enterPlayerFullscreen {
    self.playerViewWrapper.frame = self.overlayView.frame = self.screenBounds;
    self.metadataViewWrapper.alpha = self.metadataPanelViewWrapper.alpha = 0;
    self.playerViewWrapper.alpha = 1;
    _isFullScreen = YES;
}

- (void)exitFullscreen {
    [self maximize:YES];
}

- (void)showOverlayView:(BOOL)animated {
    self.overlayView.hidden = NO;
    [UIView animateWithDuration:animated ? [self animationDuration] : 0 animations:^{
        self.overlayView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideOverlayView:(BOOL)animated {
    [UIView animateWithDuration:animated ? [self animationDuration] : 0 animations:^{
        self.overlayView.alpha = 0;
    } completion:^(BOOL finished) {
        self.overlayView.hidden = YES;
    }];
}

#pragma mark ---- <PlayerView Action>

- (void)playerViewPan:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.saveState = self.state;
            self.savePoint = [sender locationInView:self.view];
            self.dragDirection = DRAGGING_NONE;
            self.miniPlayerViewWrapperRect = CGRectMake(self.miniPlayerInsets.left,
                                                    self.miniPlayerInsets.top,
                                                    self.miniPlayerWidth,
                                                    self.miniPlayerHeight);
            [self hideOverlayView:NO];
        }
            break;
        case UIGestureRecognizerStateChanged:
            switch (self.dragDirection) {
                case DRAGGING_NONE:
                    [self calcDirection:[sender locationInView:self.view].y];
                    break;
                case DRAGGING_VERTICAL:
                    [self dragVertical:sender];
                    break;
                case DRAGGING_HORIZONTAL:
                    [self dragHorizontal:sender];
                    break;
                default:
                    break;
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            switch (self.dragDirection) {
                case DRAGGING_VERTICAL: {
                    self.dragDirection = DRAGGING_NONE;
                    CGFloat velocity = [sender velocityInView:self.view].y;
                    if (ABS(velocity) > WWL_VELOCITY_MIN) {
                        [self calcState:(velocity > 0)];
                    } else {
                        [self calcState:(self.playerViewWrapper.y/self.miniPlayerInsets.top > 0.5)];
                    }
                }
                    break;
                case DRAGGING_HORIZONTAL: {
                    self.dragDirection = DRAGGING_NONE;
                    CGFloat velocity = ABS([sender velocityInView:self.view].x);
                    if (velocity > WWL_VELOCITY_MIN || self.playerViewWrapper.alpha < 0.4) {
                        [self hided:YES];
                    } else {
                        [self minimize:YES];
                    }
                }
                    break;
                default:
                    break;
            }
        }
        default:
            break;
    }
}

- (void)playerViewTap:(UITapGestureRecognizer *)sender {
    switch (self.state) {
        case WWL_STATE_MINIMIZED:{
            if (!IS_TABLET && IS_LANDSCAPE) {
                [self enterFullscreen:YES];
            } else {
                [self maximize:YES];
            }
        }
            break;
        case WWL_STATE_MAXIMIZED:{
            if (self.overlayView.hidden) {
                [self showOverlayView:YES];
            } else {
                [self hideOverlayView:YES];
            }
        }
            break;
        default:
            break;
    }
}

- (void)calcDirection:(CGFloat)newY {
    if ((self.saveState == WWL_STATE_MINIMIZED && (newY - self.savePoint.y < -2)) ||
        self.saveState == WWL_STATE_MAXIMIZED) {
        self.dragDirection = DRAGGING_VERTICAL;
    } else if (!self.isFullScreen) {
        self.dragDirection = DRAGGING_HORIZONTAL;
    } else {
        self.dragDirection = DRAGGING_NONE;
    }
}

- (void)calcState:(BOOL)isMinimize {
    if (isMinimize) {
        [self minimize:YES];
    } else {
        if (self.isFullScreen) {
            [self enterFullscreen:YES];
            _state = WWL_STATE_MAXIMIZED;
        } else {
            [self maximize:YES];
        }
    }
}

- (void)dragVertical:(UIPanGestureRecognizer *)sender {
    CGFloat rawY = [sender locationInView:self.view].y - self.savePoint.y;
    CGRect playerViewRect = self.miniPlayerViewWrapperRect;
    CGFloat yRatio = 0, alpha = 0;
    
    if (!self.isFullScreen && !(IS_LANDSCAPE && !IS_TABLET)) {
        if (self.saveState == WWL_STATE_MINIMIZED) {
            playerViewRect.origin.y = MIN(self.miniPlayerInsets.top,
                                          MAX(playerViewRect.origin.y - ABS(MIN(rawY, 0)), 0));
        } else if (self.saveState == WWL_STATE_MAXIMIZED) {
            playerViewRect.origin.y = MIN(MAX(rawY, 0), self.miniPlayerInsets.top);
        }
        yRatio = playerViewRect.origin.y/self.miniPlayerInsets.top;
        playerViewRect.origin.x = self.miniPlayerInsets.left * yRatio;
        CGFloat w;
        alpha = 1-yRatio;
        if (IS_TABLET && IS_LANDSCAPE) {
            w = (self.playerViewSizeMax.width - self.miniPlayerWidth)*alpha + self.miniPlayerWidth;
        } else {
            w = self.miniPlayerWidth + self.miniPlayerInsets.left - playerViewRect.origin.x;
        }
        playerViewRect.size.width = MIN(self.playerViewSizeMax.width,
                                        MAX(w + alpha*self.miniPlayerPadding, self.miniPlayerWidth));
        playerViewRect.size.height = playerViewRect.size.width/WWL_PLAYER_RATIO;
    } else {
        if (self.saveState == WWL_STATE_MINIMIZED) {
            rawY = playerViewRect.origin.y - ABS(MIN(rawY, 0));
        } else if (self.saveState == WWL_STATE_MAXIMIZED) {
            rawY = MAX(rawY, 0);
        }
        playerViewRect.origin.y = MAX(MIN(rawY, self.miniPlayerInsets.top), 0);
        yRatio = playerViewRect.origin.y/self.miniPlayerInsets.top;
        alpha = 1-yRatio;
        playerViewRect.size.height = self.screenBounds.size.height - playerViewRect.origin.y - yRatio*self.miniPlayerPadding;
        playerViewRect.size.width = MAX(self.miniPlayerWidth, MIN(playerViewRect.size.height*WWL_PLAYER_RATIO,
                                                                  self.screenBounds.size.width));
        playerViewRect.origin.x = self.screenBounds.size.width - playerViewRect.size.width - yRatio*self.miniPlayerPadding;
    }
    self.playerViewWrapper.frame = playerViewRect;
    self.metadataViewWrapper.frame = CGRectMake(0,
                                                playerViewRect.origin.y + MAX(self.playerViewWrapper.height, self.playerViewSizeMax.height),
                                                self.playerViewSizeMax.width,
                                                self.metadataViewWrapper.height);
    self.metadataPanelViewWrapper.frame = CGRectMake(MAX(self.playerViewWrapper.width,
                                                         self.playerViewSizeMax.width) + playerViewRect.origin.x/1.6,
                                                     0,
                                                     self.metadataPanelViewWrapper.width,
                                                     self.metadataPanelViewWrapper.height);
    self.metadataViewWrapper.alpha = self.metadataPanelViewWrapper.alpha = alpha;
    contentWindow.backgroundColor = [UIColor colorWithWhite:WWL_COLOR_EX alpha:alpha*0.9];
    [self.playerViewWrapper setBorderAlpha:yRatio];
    if (self.listener != nil && [self.listener respondsToSelector:@selector(WWL_onSliding:)]) {
        [self.listener WWL_onSliding:alpha];
    }
}

- (void)dragHorizontal:(UIPanGestureRecognizer *)sender {
    CGFloat rawX = self.savePoint.x - [sender locationInView:self.view].x;
    CGRect playerViewRect = self.miniPlayerViewWrapperRect;
    playerViewRect.origin.x -= rawX;
    self.playerViewWrapper.frame = playerViewRect;
    self.playerViewWrapper.alpha = 1-ABS(rawX)/self.miniPlayerInsets.left;
}

#pragma mark - Environment Device

- (CGSize)playerViewSizeMax {
    CGSize size = CGSizeZero;
    if (self.isFullScreen) {
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            size.width = MAX(self.screenBounds.size.width, self.screenBounds.size.height);
        } else {
            size.width = self.screenBounds.size.width;
        }
    }
    size.width = MIN(self.screenBounds.size.width, self.screenBounds.size.height);
    size.height = size.width/WWL_PLAYER_RATIO;
    return size;
}

- (CGRect)screenBounds {
    if (SYSTEM_VERSION_LESS_THAN(@"8.0") && IS_LANDSCAPE) {
        // for iOS 7
        return CGRectMake(0, 0,
                          [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    return [UIScreen mainScreen].bounds;
}

- (NSTimeInterval)animationDuration {
    if (IS_TABLET) {
        return 0.3f;
    }
    return 0.2f;
}

@end

#pragma mark ---- < WWL Window >

@implementation WWLWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    UIView * view;
    if (SYSTEM_VERSION_LESS_THAN(@"8.0") && IS_LANDSCAPE) {
        CGPoint np = CGPointMake([UIScreen mainScreen].bounds.size.height-point.y, point.x);
        view = [[WatchWhileLayout get].view hitTest:np withEvent:event];
    } else {
        view = [[WatchWhileLayout get].view hitTest:point withEvent:event];
    }
    if ((view != nil) && (view.tag == WWL_PLAYER_VIEW_ID || view.tag == WWL_METADATA_ID ||
                          view.tag == WWL_OVERLAY_VIEW_ID || [view isKindOfClass:[UIButton class]] ||
                          (view.userInteractionEnabled && view.tag != WWL_BACKGROUD_ID &&
                           [view.window.rootViewController isKindOfClass:[WatchWhileLayout class]]))) {
        return YES;
    }
    return NO;
}

@end

#pragma mark ---- < WWL PlayerViewWrapper >

@interface WWLPlayerViewWrapper ()

@property (nonatomic, strong) UIImageView * shadow;

@end

@implementation WWLPlayerViewWrapper

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self shadow];
}

- (UIImageView *)shadow {
    if (_shadow == nil) {
        _shadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"miniplayer_shadow"]];
        _shadow.userInteractionEnabled = NO;
        [self addSubview:_shadow];
        _shadow.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(-4)-[sh]-(-4)-|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{@"sh":_shadow}]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-4)-[sh]-(-4)-|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{@"sh":_shadow}]];
        UIView * bg = [[UIView alloc] init];
        bg.backgroundColor = [UIColor blackColor];
        bg.frame = self.bounds;
        bg.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        bg.userInteractionEnabled = NO;
        [self addSubview:bg];
    }
    return _shadow;
}

- (void)setBorderAlpha:(CGFloat)alpha {
    self.shadow.alpha = alpha;
}

@end

#pragma mark ---- < WWL View >

@implementation WWLView

#pragma mark ---- < Custom Touch Event >

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint newPoint = CGPointMake(self.frame.origin.x+point.x, self.frame.origin.y+point.y);
    if (!CGRectContainsPoint(self.frame, newPoint)) {
        return NO;
    }
    for (UIView * view in self.subviews) {
        if (view.userInteractionEnabled && CGRectContainsPoint(view.frame, point)) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark ---- < WWL OverlayView >

@interface WWLOverlayView ()

@property (nonatomic, strong) WatchWhileLayout * parent;

@property (nonatomic, strong) UIImageView * topBar;

@property (nonatomic, strong) UIImageView * bottomBar;

@property (nonatomic, strong) NSTimer * timer;

@end

@implementation WWLOverlayView

@synthesize playerCollapseButton = _playerCollapseButton;
@synthesize playerFullscreenButton = _playerFullscreenButton;

#pragma mark ---- < Init >

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self setupDefaultButton];
}

- (void)setupDefaultButton {
    [self layoutIfNeeded];
    [self topBar];
    [self bottomBar];
    [self playerCollapseButton];
    [self playerFullscreenButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self fullscreenButtonUp:self.playerFullscreenButton];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    [self destroyTimer];
    if (alpha == 1) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(doHide) userInfo:nil repeats:NO];
    }
}

#pragma mark ---- < Setup Property >

- (WatchWhileLayout *)parent {
    if (self.superview == nil) {
        return nil;
    }
    return (WatchWhileLayout *)self.window.rootViewController;
}

- (UIButton *)playerCollapseButton {
    if (_playerCollapseButton == nil) {
        _playerCollapseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playerCollapseButton.frame = CGRectMake(4, 4, 40, 40);
        [self addSubview:_playerCollapseButton];
        [_playerCollapseButton setImage:[UIImage imageNamed:@"player_collapse"] forState:UIControlStateNormal];
        [_playerCollapseButton addTarget:self action:@selector(collapseButtonDown:) forControlEvents:UIControlEventTouchDown];
        [_playerCollapseButton addTarget:self action:@selector(collapseButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [_playerCollapseButton addTarget:self action:@selector(collapseButtonUp:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _playerCollapseButton;
}

- (UIButton *)playerFullscreenButton {
    if (_playerFullscreenButton == nil) {
        _playerFullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playerFullscreenButton.frame = CGRectMake(self.frame.size.width-40, self.frame.size.height-40, 40, 40);
        [self addSubview:_playerFullscreenButton];
        _playerFullscreenButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
        [_playerFullscreenButton setImage:[UIImage imageNamed:@"player_fullscreen_off"] forState:UIControlStateNormal];
        [_playerFullscreenButton addTarget:self action:@selector(fullscreenButtonDown:) forControlEvents:UIControlEventTouchDown];
        [_playerFullscreenButton addTarget:self action:@selector(fullscreenButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [_playerFullscreenButton addTarget:self action:@selector(fullscreenButtonUp:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _playerFullscreenButton;
}

- (UIImageView *)topBar {
    if (_topBar == nil) {
        _topBar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"player_bar_gradient"]];
        _topBar.frame = CGRectMake(0, 0, self.frame.size.width, 80);
        _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _topBar.userInteractionEnabled = NO;
        [self addSubview:_topBar];
        [self sendSubviewToBack:_topBar];
    }
    return _topBar;
}

- (UIImageView *)bottomBar {
    if (_bottomBar == nil) {
        _bottomBar = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithCGImage:self.topBar.image.CGImage scale:1.0 orientation:UIImageOrientationDown]];
        _bottomBar.frame = CGRectMake(0, self.frame.size.height-80, self.frame.size.width, 80);
        _bottomBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin;
        _bottomBar.userInteractionEnabled = NO;
        [self addSubview:_bottomBar];
        [self sendSubviewToBack:_bottomBar];
    }
    return _bottomBar;
}

#pragma mark ---- < Button Action >

- (void)setImageButton:(UIButton *)button name:(NSString *)name {
    [button setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
}

- (void)setImageButtonPressed:(UIButton *)button name:(NSString *)name {
    [self setImageButton:button name:[name stringByAppendingString:@"_pressed"]];
}

- (void)collapseButtonDown:(UIButton *)sender {
    [self setImageButtonPressed:sender name:@"player_collapse"];
}

- (void)collapseButtonTap:(UIButton *)sender {
    [self collapseButtonUp:sender];
    [self doCollapse];
}

- (void)collapseButtonUp:(UIButton *)sender {
    [self setImageButton:sender name:@"player_collapse"];
}

- (void)fullscreenButtonDown:(UIButton *)sender {
    NSString * name = @"player_fullscreen";
    name = [name stringByAppendingString:self.parent.isFullScreen ? @"_on" : @"_off"];
    [self setImageButtonPressed:sender name:name];
}

- (void)fullscreenButtonTap:(UIButton *)sender {
    [self doFullscreen];
    [self fullscreenButtonUp:sender];
}

- (void)fullscreenButtonUp:(UIButton *)sender {
    NSString * name = @"player_fullscreen";
    name = [name stringByAppendingString:self.parent.isFullScreen ? @"_on" : @"_off"];
    [self setImageButton:sender name:name];
}

#pragma mark ---- < Do Action >

- (void)doCollapse {
    [self.parent minimize:YES];
}

- (void)doFullscreen {
    if (self.parent.isFullScreen) {
        if (IS_LANDSCAPE && !IS_TABLET) {
            FORE_TO_PORTRAIT;
        }
        [self.parent exitFullscreen];
    } else {
        [self.parent enterFullscreen:YES];
    }
}

- (void)destroyTimer {
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)doHide {
    [self destroyTimer];
    [self.parent hideOverlayView:YES];
}

@end

#pragma mark ---- < UIView Extension >

@implementation UIView (Extension)

- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

@end



