#import "../PS.h"
#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <UIKit/UIView+Private.h>

%hook PLCameraView

- (BOOL)_shouldHideHDRBadgeForMode: (NSInteger)mode {
    if (mode == 0 || mode == 4) {
        if ([self HDRIsOn]) {
            if (![((PLCameraController *)[%c(PLCameraController) sharedInstance]).effectsRenderer isShowingGrid]) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)_setFlashMode:(NSInteger)mode {
    %orig;
    [self _updateHDRBadge];
}

- (void)setCameraMode:(NSInteger)mode {
    %orig;
    if (!MSHookIvar<BOOL>(self, "_capturingPhoto") && ![(PLCameraController *)[%c(PLCameraController) sharedInstance] isCapturingVideo])
        [self _updateHDRBadge];
}

- (void)setVideoFlashMode:(NSInteger)mode {
    %orig;
    [self _updateHDRBadge];
}

- (void)_createHDRBadgeIfNecessary {
    %orig;
    MSHookIvar<CAMHDRBadge *>(self, "__HDRBadge").enabled = YES;
    MSHookIvar<CAMHDRBadge *>(self, "__HDRBadge").userInteractionEnabled = NO;
}

- (void)_createStillImageControlsIfNecessary {
    %orig;
    [self _createHDRBadgeIfNecessary];
}

- (void)cameraControllerTorchAvailabilityChanged:(id)change {
    %orig;
    [self _updateHDRBadge];
}

%new
- (void)_updateHDRBadge {
    BOOL hidden = [self _shouldHideHDRBadgeForMode:self.cameraMode];
    [[self _HDRBadge] pl_setHidden:hidden animated:YES];
}

- (id)initWithFrame:(CGRect)frame spec:(id)spec {
    self = %orig;
    [self _updateHDRBadge];
    return self;
}

%end

extern "C" NSBundle *PLPhotoLibraryFrameworkBundle();

%hook CAMHDRBadge

- (void)_commonInit {
    %orig;
    UIImage *image = [[UIImage imageNamed:@"CAMHDRButton" inBundle:PLPhotoLibraryFrameworkBundle()] _flatImageWithColor:[UIColor systemYellowColor]];
    [self setImage:image forState:UIControlStateNormal];
}

%end

%hook PLCameraController

- (void)setDelegate: (PLCameraView *)delegate {
    %orig;
    if (delegate != nil)
        [delegate _updateHDRBadge];
}

- (void)_flashStateChanged {
    %orig;
    [[self delegate] _updateHDRBadge];
}

%end
