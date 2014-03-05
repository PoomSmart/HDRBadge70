#import <Foundation/Foundation.h>

@interface CAMHDRBadge : UIButton
@end

@interface PLCameraView : UIView
- (CAMHDRBadge *)_HDRBadge;
- (int)cameraMode;
- (BOOL)HDRIsOn;
- (BOOL)_shouldHideHDRBadgeForMode:(int)mode;
- (void)_createHDRBadgeIfNecessary;
@end

@interface PLCameraView (HDR70Addition)
- (void)_updateHDRBadge;
@end

@interface PLCameraEffectsRenderer : NSObject
@property(assign, nonatomic, getter=isShowingGrid) BOOL showGrid;
@end

@interface PLCameraController : NSObject
@property(retain) PLCameraEffectsRenderer *effectsRenderer;
+ (PLCameraController *)sharedInstance;
- (PLCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface UIColor (HDR70Addition)
+ (UIColor *)systemYellowColor;
@end

@interface UIImage (HDR70Addition)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
- (UIImage *)_flatImageWithColor:(UIColor *)color;
@end

@interface UIView (HDR70Addition)
- (void)pl_setHidden:(BOOL)hidden animated:(BOOL)animated;
@end

%hook PLCameraView

- (BOOL)_shouldHideHDRBadgeForMode:(int)mode
{
	if (mode == 0 || mode == 4) {
		if ([self HDRIsOn]) {
			if (![[%c(PLCameraController) sharedInstance].effectsRenderer isShowingGrid]) {
				return NO;
			}
		}
	}
	return YES;
}

- (void)_setFlashMode:(int)mode
{
	%orig;
	[self _updateHDRBadge];
}

- (void)setCameraMode:(int)mode
{
	%orig;
	if (!MSHookIvar<BOOL>(self, "_capturingPhoto") && ![[%c(PLCameraController) sharedInstance] isCapturingVideo])
		[self _updateHDRBadge];
}

- (void)setVideoFlashMode:(int)mode
{
	%orig;
	[self _updateHDRBadge];
}

- (void)_createHDRBadgeIfNecessary
{
	%orig;
	[MSHookIvar<CAMHDRBadge *>(self, "__HDRBadge") setEnabled:YES];
}

- (void)_createStillImageControlsIfNecessary
{
	%orig;
	[self _createHDRBadgeIfNecessary];
}

- (void)cameraControllerTorchAvailabilityChanged:(id)change
{
	%orig;
	[self _updateHDRBadge];
}

%new
- (void)_updateHDRBadge
{
	BOOL hidden = [self _shouldHideHDRBadgeForMode:[self cameraMode]];
	[[self _HDRBadge] pl_setHidden:hidden animated:YES];
}

- (id)initWithFrame:(CGRect)frame spec:(id)spec
{
	self = %orig;
	[self _updateHDRBadge];
	return self;
}

%end

extern "C" NSBundle *PLPhotoLibraryFrameworkBundle();

%hook CAMHDRBadge

- (void)_commonInit
{
	%orig;
	UIImage *image = [[UIImage imageNamed:@"CAMHDRButton" inBundle:PLPhotoLibraryFrameworkBundle()] _flatImageWithColor:[UIColor systemYellowColor]];
	[self setImage:image forState:UIControlStateNormal];
}

%end

%hook PLCameraController

- (void)setDelegate:(PLCameraView *)delegate
{
	%orig;
	if (delegate != nil)
		[delegate _updateHDRBadge];
}

- (void)_flashStateChanged
{
	%orig;
	[[self delegate] _updateHDRBadge];
}

%end