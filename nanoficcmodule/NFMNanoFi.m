//    Copyright (c) 2021 udevs
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, version 3.
//
//    This program is distributed in the hope that it will be useful, but
//    WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//    General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.

#import "../common.h"
#import "NFMNanoFi.h"
#import "../NFShared.h"
#include <notify.h>
#include <objc/runtime.h>

static int prefer_wifi_state_token = 0;
static int prefer_wifi_activity_token = 0;
static BOOL shouldSetValue = YES;

@implementation NFMNanoFi

- (instancetype)init{
    if (self = [super init]){
        _enabled = [valueForKey(@"enabled", @YES) boolValue];
        NFPreferWiFiState lastAction = [valueForKey(@"lastPreferWiFiAction", @(NFPreferWiFiStateNone)) unsignedLongLongValue];

        shouldSetValue = NO;
        _selected = _enabled && (lastAction == NFPreferWiFiStatePrefer);
        [self setSelected:_selected];
        shouldSetValue = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_enabled){
                NSArray *controllers = [[self valueForKey:@"_contentViewControllers"] allObjects];
                if (controllers.count > 0){
                    CCUIToggleViewController *toggleController = controllers.firstObject;
                    toggleController.glyphImage = [UIImage imageNamed:@"NanoFi-Requesting" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
                    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)kSBReloaded, NULL, NULL, YES);
                }
            }
        });

        notify_register_dispatch(kPreferWiFiState, &prefer_wifi_state_token, dispatch_get_main_queue(), ^(int token) {
            
            NFPreferWiFiState state = UINT64_MAX;
            notify_get_state(token, &state);
                        
            shouldSetValue = NO;
            _selected = state == NFPreferWiFiStatePrefer;
            [self setSelected:_selected];
            shouldSetValue = YES;
            
            setValueForKey(@"lastPreferWiFiState", @(state));
            _requesting = NO;
            
            [self updateGlyphNamed:@"NanoFi"];
        });
        
        notify_register_dispatch(kPreferWiFiActivity, &prefer_wifi_activity_token, dispatch_get_main_queue(), ^(int token) {
            
            NFPreferWiFiActivity activity = UINT64_MAX;
            notify_get_state(token, &activity);
            
            if (activity == NFPreferWiFiActivityRequesting){
                [self updateGlyphNamed:@"NanoFi-Requesting"];
                _requesting = YES;
            }else{
                [self updateGlyphNamed:@"NanoFi"];
                _requesting = NO;
            }
            
        });
    }
    return self;
}

-(void)updateGlyphNamed:(NSString *)name{
    NSArray *controllers = [[self valueForKey:@"_contentViewControllers"] allObjects];
    if (controllers.count > 0){
        if ([controllers.firstObject isKindOfClass:objc_getClass("CCUIToggleViewController")]){
            CCUIToggleViewController *toggleController = controllers.firstObject;
            toggleController.glyphImage = [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        }
    }
}

- (UIImage *)iconGlyph{
    return [UIImage imageNamed:@"NanoFi" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

- (UIColor *)selectedColor{
    return [UIColor blueColor];
}

- (BOOL)isSelected{
    return _selected;
}

- (void)setSelected:(BOOL)selected{
    if (!_enabled) return;
    _selected = selected;
    
    [super refreshState];
    if (!shouldSetValue) return;
    
    if(_selected){
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)kAttemptPreferWiFi, NULL, NULL, YES);
        setValueForKey(@"lastPreferWiFiAction", @(NFPreferWiFiStatePrefer));
    }
    else{
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)kResetPreferWiFi, NULL, NULL, YES);
        setValueForKey(@"lastPreferWiFiAction", @(NFPreferWiFiStateReset));
    }
    [self updateGlyphNamed:@"NanoFi-Requesting"];
    _requesting = YES;
}

@end
