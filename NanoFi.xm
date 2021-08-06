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

#import "common.h"
#import "NFShared.h"
#import "NFPerseverance.h"
#import "Headers.h"

static void ExitMain(){
    exit(0);
}

%hook NRLinkWiFi
- (void)setIsPrimary:(BOOL)primary{
    %orig;
    if (!primary){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PrimaryLinkChangedNotification" object:self];
    }
}
%end

%hook NRLinkManagerWiFi
- (void)setIsWiFiAvailable:(BOOL)available{
    %orig;
    if (available){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WiFiLinkChangedNotification" object:self];
    }
}
%end

%hook NRLinkDirector
- (id)initDirector{
    self = %orig;
    //we need to run this in the correct queue
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL enabled = [valueForKey(@"enabled", @YES) boolValue];
        uint64_t lastAction = [valueForKey(@"lastPreferWiFiAction", @(NFPreferWiFiStateNone)) unsignedLongLongValue];
        if (enabled && (lastAction == NFPreferWiFiStatePrefer)){
            [[NFPerseverance sharedInstance] setValue:@(NFPreferWiFiStatePrefer) forKey:@"_latestRequest"];
            [[NFPerseverance sharedInstance] beginPreferWiFiRequestWithInterval:XPC_ACTIVITY_INTERVAL_1_MIN queue:self.queue];
        }
    });
    return self;
}
%end

%ctor{
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ExitMain, (CFStringRef)kExitMain, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
