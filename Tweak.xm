#import <UIKit/UIKit.h>

static BOOL ViewContainsClass(UIView *view, Class targetClass, int depth) {
    if (!view || depth > 20) return NO;
    if ([view isKindOfClass:targetClass]) return YES;
    for (UIView *sub in view.subviews) {
        if (ViewContainsClass(sub, targetClass, depth + 1)) return YES;
    }
    return NO;
}

%hook UIWindow
- (UIEdgeInsets)safeAreaInsets {
    UIEdgeInsets orig = %orig;
    if (orig.bottom <= 0.0) {
        Class qaCls = NSClassFromString(@"CSQuickActionsButton");
        if (qaCls && ViewContainsClass(self, qaCls, 0)) {
            orig.bottom = 20;
        }
    }
    return orig;
}
%end

@interface CSQuickActionsView : UIView
- (UIEdgeInsets)_buttonOutsets;
@property (nonatomic, retain) UIControl *flashlightButton;
@property (nonatomic, retain) UIControl *cameraButton;
@end

%hook CSQuickActionsView

- (BOOL)wantsQuickActions {
    return YES;
}

- (BOOL)_prototypingAllowsButtons {
    return YES;
}

- (void)_layoutQuickActionButtons {
    CGRect const screenBounds = [UIScreen mainScreen].bounds;
    CGFloat const y = screenBounds.size.height - 90 - [self _buttonOutsets].top;
    [self flashlightButton].frame = CGRectMake(46, y, 50, 50);
    [self cameraButton].frame = CGRectMake(screenBounds.size.width - 96, y, 50, 50);
}

%end

#define MAX_DOCK_ICONS 4
#define MAX_RECENTS 3

@interface SBIconListGridLayoutConfiguration : NSObject
@property (nonatomic) unsigned long long numberOfPortraitRows;
@property (nonatomic) unsigned long long numberOfPortraitColumns;
@end

@interface SBIconListView : UIView
@property (nonatomic, retain) NSString *iconLocation;
@end

@interface SBBestAppSuggestion : NSObject
- (BOOL)isHandoff;
@end

@interface SBFloatingDockSuggestionsModel : NSObject
@property (nonatomic,readonly) SBBestAppSuggestion * currentAppSuggestion;
@end

%hook SBFloatingDockController
+ (BOOL)isFloatingDockSupported {
    return YES;
}
- (void)_configureFloatingDockBehaviorAssertionForOpenFolder:(id)arg1 atLevel:(NSUInteger)arg2 {
}
%end

%hook SBFloatingDockDefaults
- (void)setRecentsEnabled:(BOOL)arg1 {
    %orig(YES);
}
- (BOOL)recentsEnabled {
    return YES;
}
- (void)setAppLibraryEnabled:(BOOL)arg1 {
    %orig(NO);
}
- (BOOL)appLibraryEnabled {
    return NO;
}
%end

%hook SBIconListGridLayoutConfiguration
- (unsigned long long)numberOfPortraitColumns {
    unsigned long long o = %orig;
    if ([self numberOfPortraitRows] == 1 && o == 4) {
        return MAX_DOCK_ICONS;
    }
    return o;
}
%end

%hook SBIconListView
- (unsigned long long)maximumIconCount {
    if ([self.iconLocation isEqual:@"SBIconLocationDock"]) {
        return MAX_DOCK_ICONS;
    }
    return %orig;
}
%end

%hook SBFloatingDockSuggestionsModel
-(BOOL)recentDisplayItemsController:(id)arg1 shouldAddItem:(id)arg2 {
    if ([self.currentAppSuggestion isHandoff]) return NO;
    return %orig;
}

- (id)initWithMaximumNumberOfSuggestions:(NSUInteger)arg1 iconController:(id)arg2 recentsController:(id)arg3 recentsDataStore:(id)arg4 recentsDefaults:(id)arg5 floatingDockDefaults:(id)arg6 appSuggestionManager:(id)arg7 applicationController:(id)arg8 {
    return %orig(MAX_RECENTS,arg2,arg3,arg4,arg5,arg6,arg7,arg8);
}
-(unsigned long long)maxSuggestions {
    return MAX_RECENTS;
}
%end

%hook SBFloatingDockSuggestionsViewController
-(id)initWithNumberOfRecents:(unsigned long long)arg1 iconController:(id)arg2 applicationController:(id)arg3 layoutStateTransitionCoordinator:(id)arg4 suggestionsModel:(id)arg5 iconViewProvider:(id)arg6 {
    return %orig(MAX_RECENTS,arg2,arg3,arg4,arg5,arg6);
}
%end

%hook SBHomeGestureSettings
- (bool)isHomeGestureEnabled {
    return 1;
}
%end

%hook CCSControlCenterDefaults
- (unsigned long long)_defaultPresentationGesture {
    return 1;
}
%end

%hook SBControlCenterController
- (unsigned long long)presentingEdge {
    return 1;
}
%end

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    return %c(_UIStatusBarVisualProvider_Pad_ForcedCellular);
}
%end

%hook SBFHomeGrabberSettings 
-(BOOL)isEnabled {
	return NO;
}

-(void)setEnabled:(BOOL)arg1 {
	%orig(NO);
}
%end

%hook CSQuickActionsViewController
+ (BOOL)deviceSupportsButtons {
    return YES;
}
- (BOOL)hasCamera { return YES; }
- (BOOL)hasFlashlight { return YES; }
%end

@interface NCNotificationListView : UIView
@end

%hook NCNotificationListView
- (void)setFrame:(CGRect)frame {
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){16, 0, 0}]) {
        frame = CGRectMake(0, -100, frame.size.width, frame.size.height);
    }
    %orig(frame);
}
%end

@interface CSFullscreenNotificationView : UIView
@end

%hook CSFullscreenNotificationView
- (void)setFrame:(CGRect)frame {
    frame = CGRectMake(0, -50, frame.size.width, frame.size.height);
    %orig(frame);
}
%end

