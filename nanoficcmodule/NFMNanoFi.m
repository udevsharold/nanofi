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

static int prefer_wifi_state_token = 0;
static BOOL shouldSetValue = YES;

@implementation NFMNanoFi

- (instancetype)init{
    if (self = [super init]){
        _enabled = [valueForKey(@"enabled", @YES) boolValue];
        uint64_t lastState = [valueForKey(@"lastPreferWiFiState", @(NFPreferWiFiStateNone)) unsignedLongLongValue];
                
        shouldSetValue = NO;
        _selected = _enabled && (lastState == NFPreferWiFiStatePrefer);
        [self setSelected:_selected];
        shouldSetValue = YES;
        
        notify_register_dispatch(kPreferWiFiState, &prefer_wifi_state_token, dispatch_get_main_queue(), ^(int token) {
            
            uint64_t state = UINT64_MAX;
            notify_get_state(token, &state);
            
            shouldSetValue = NO;
            _selected = state == NFPreferWiFiStatePrefer;
            [self setSelected:_selected];
            shouldSetValue = YES;
            
            setValueForKey(@"lastPreferWiFiState", @(state));
            _requesting = NO;
        });
    }
    return self;
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
    _requesting = YES;
}

@end
