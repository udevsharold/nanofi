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

#import "NFPerseverance.h"
#import "NFShared.h"
#import "Headers.h"
#include <objc/runtime.h>
#include <notify.h>

#define XPC_ACTIVITY_SHOULD_WAKE_DEVICE "ShouldWakeDevice"

static BOOL instanceCreated;

@implementation NFPerseverance

static void AttemptPreferWiFi(){
    if (instanceCreated){
        [[NFPerseverance sharedInstance] attemptPreferWiFi];
    }
}

static void ResetPreferWiFi(){
    if (instanceCreated){
        [[NFPerseverance sharedInstance] resetPreferWiFi];
    }
}

static void PrefsChanged(){
    if (instanceCreated){
        [[NFPerseverance sharedInstance] updatePrefs];
    }
}

static void SBReloaded(){
    if (instanceCreated){
        [[NFPerseverance sharedInstance] updateModule];
    }
}

+(xpc_object_t)bareCriteria{
    xpc_object_t criteria = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_bool(criteria, XPC_ACTIVITY_REPEATING, YES);
    xpc_dictionary_set_string(criteria, XPC_ACTIVITY_PRIORITY, XPC_ACTIVITY_PRIORITY_UTILITY);
    xpc_dictionary_set_bool(criteria, XPC_ACTIVITY_ALLOW_BATTERY, YES);
    xpc_dictionary_set_bool(criteria, XPC_ACTIVITY_SHOULD_WAKE_DEVICE, NO);
    return criteria;
}

+(xpc_object_t)criteriaWithInterval:(int64_t)interval{
    xpc_object_t criteria = [self bareCriteria];
    xpc_dictionary_set_int64(criteria, XPC_ACTIVITY_INTERVAL, interval);
    return criteria;
}

+(instancetype)sharedInstance{
    static dispatch_once_t once = 0;
    __strong static NFPerseverance *sharedInstance = nil;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
        instanceCreated = YES;
    });
    return sharedInstance;
}

-(instancetype)init{
    if (self = [super init]){
        _activityPreferWiFiName = @"com.udevs.nanofi.preferwifi-activity";
        _activityResetPreferWiFiName = @"com.udevs.nanofi.resetpreferwifi-activity";
        _desiredAttemptCount = 1;
        _desiredResetCount = 1;
        _lastState = NFPreferWiFiStateNone;
        
        _activityPreferWiFiHandler = dispatch_block_create(static_cast<dispatch_block_flags_t>(0), ^{
            
            if (_latestRequest != NFPreferWiFiStatePrefer) return;

            if (_resetPreferWiFiRequestScheduled) [self stopResetPreferWiFiRequestActivity];
            
            NRLinkDirector *director = [objc_getClass("NRLinkDirector") copySharedLinkDirector];
            
            if (!director.wifiManager.isWiFiAvailable){
                HBLogDebug(@"WiFi link not available, stop activity");
                [self stopPreferWiFiRequestActivity];
                return;
            }
            
            for (NRDDeviceConductor *conductor in director.conductors.allValues){
                if ([[conductor copyPrimaryLink] isKindOfClass:objc_getClass("NRLinkWiFi")]){
                    HBLogDebug(@"✅ We got it. Primary link is WiFi, stop activity");
                    [self stopPreferWiFiRequestActivity];
                    [self notify:kPreferWiFiState state:NFPreferWiFiStatePrefer];
                    [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityNone];
                    return;
                }
                
                if (conductor.hasPhoneCallRelayRequest){
                    HBLogDebug(@"We have phone relay request, stop activity");
                    [self stopPreferWiFiRequestActivity];
                    [self notify:kPreferWiFiState state:NFPreferWiFiStateNone];
                    [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityFailed];
                    return;
                }
                
                NRLink *wifiLink = [conductor copyLinkOfType:2];
                if (!wifiLink || wifiLink.state == 255){
                    HBLogDebug(@"No valid WiFi link, stop activity");
                    [director preferWiFiRequestAvailable];
                    [self stopPreferWiFiRequestActivity];
                    [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityNone];
                    return;
                }
            }
            
            BOOL success = [director preferWiFiRequestAvailable];
            _attemptCount++;
            
            if (!success){
                [self stopPreferWiFiRequestActivity];
                [self notify:kPreferWiFiState state:NFPreferWiFiStateNone];
                [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityFailed];
                HBLogDebug(@"Stop attempting since we're in the middle of something");
            }
            
            HBLogDebug(@"Attempting prefer WiFi link #%lu", _attemptCount);
            
            if (_attemptCount > _desiredAttemptCount){
                [self stopPreferWiFiRequestActivity];
                [self notify:kPreferWiFiState state:NFPreferWiFiStateNone];
                [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityFailed];
                HBLogDebug(@"Exceeded desired attempt counts, stop activity");
            }

        });
        
        _activityResetPreferWiFiHandler = dispatch_block_create(static_cast<dispatch_block_flags_t>(0), ^{
            
            if (_latestRequest != NFPreferWiFiStateReset) return;
            
            if (_preferWiFiRequestScheduled) [self stopPreferWiFiRequestActivity];
            
            NRLinkDirector *director = [objc_getClass("NRLinkDirector") copySharedLinkDirector];
            
            for (NRDDeviceConductor *conductor in director.conductors.allValues){
                if (![[conductor copyPrimaryLink] isKindOfClass:objc_getClass("NRLinkWiFi")]){
                    HBLogDebug(@"✅ We got it. Primary link is no longer WiFi, stop activity");
                    [self stopResetPreferWiFiRequestActivity];
                    [self notify:kPreferWiFiState state:NFPreferWiFiStateReset];
                    [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityNone];
                    return;
                }
            }
            
            BOOL success = [director preferWiFiRequestUnavailable];
            _resetCount++;
            
            if (!success){
                [self stopResetPreferWiFiRequestActivity];
                [self notify:kPreferWiFiState state:NFPreferWiFiStateNone];
                [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityFailed];
                HBLogDebug(@"Stop resetting since we're in the middle of something");
            }
            
            HBLogDebug(@"Resetting prefer WiFi link #%lu", _attemptCount);
            
            if (_resetCount > _desiredResetCount){
                [self stopResetPreferWiFiRequestActivity];
                [self notify:kPreferWiFiState state:NFPreferWiFiStateNone];
                [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityFailed];
                HBLogDebug(@"Exceeded desired reset counts, stop activity");
            }
            
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(primaryLinkChanged:) name:@"PrimaryLinkChangedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifiChanged:) name:@"WiFiLinkChangedNotification" object:nil];
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)AttemptPreferWiFi, (CFStringRef)kAttemptPreferWiFi, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ResetPreferWiFi, (CFStringRef)kResetPreferWiFi, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PrefsChanged, (CFStringRef)kPrefsChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)SBReloaded, (CFStringRef)kSBReloaded, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    }
    return self;
}

-(void)updatePrefs{
    BOOL prevEnabledState = _enabled;
    _enabled = [valueForKey(@"enabled", @YES) boolValue];
    if (instanceCreated && prevEnabledState != _enabled && !_enabled){
        [self resetPreferWiFi];
    }
}

-(void)updateModule{
    if (!_preferWiFiRequestScheduled && !_resetPreferWiFiRequestScheduled){
        [self notify:kPreferWiFiState state:_lastState];
    }else if (_preferWiFiRequestScheduled){
        [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityRequesting];
    }else if (_resetPreferWiFiRequestScheduled){
        [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityNone];
    }
}

-(void)notify:(const char *)notificationName state:(uint64_t)state{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        int token = 0;
        notify_register_check(notificationName, &token);
        notify_set_state(token, state);
        notify_cancel(token);
        notify_post(notificationName);
    });
    if (strcmp(notificationName, kPreferWiFiState) == 0) _lastState = state;
}

-(void)wifiChanged:(NSNotification *)notification{
    NFPreferWiFiState lastAction = [valueForKey(@"lastPreferWiFiAction", @(NFPreferWiFiStateNone)) unsignedLongLongValue];

    NRLinkDirector *director = [objc_getClass("NRLinkDirector") copySharedLinkDirector];
    
    if (!director.wifiManager.isWiFiAvailable){
        [self stopPreferWiFiRequestActivity];
        [self stopResetPreferWiFiRequestActivity];
        [self notify:kPreferWiFiState state:NFPreferWiFiStateNone];
        return;
    }else if (lastAction == NFPreferWiFiStatePrefer){
        dispatch_async(director.queue, ^{
            for (NRDDeviceConductor *conductor in director.conductors.allValues){
                if (![[conductor copyPrimaryLink] isKindOfClass:objc_getClass("NRLinkWiFi")]){
                    if (_latestRequest == NFPreferWiFiStateReset) return;
                    if (_preferWiFiRequestScheduled) return;
                    HBLogDebug(@"WiFi link available, restarting activity");
                    [self beginPreferWiFiRequestWithInterval:XPC_ACTIVITY_INTERVAL_1_MIN queue:director.queue];
                    [self notify:kPreferWiFiState state:NFPreferWiFiStatePrefer];
                    [self notify:kPreferWiFiActivity state:NFPreferWiFiActivityRequesting];
                    break;
                }else{
                    [self notify:kPreferWiFiState state:NFPreferWiFiStatePrefer];
                }
            }
        });
    }
}

-(void)primaryLinkChanged:(NSNotification *)notification{
    
    NFPreferWiFiState lastAction = [valueForKey(@"lastPreferWiFiAction", @(NFPreferWiFiStateNone)) unsignedLongLongValue];
    
    NRLinkDirector *director = [objc_getClass("NRLinkDirector") copySharedLinkDirector];
    
    if (lastAction == NFPreferWiFiStatePrefer && director.wifiManager.isWiFiAvailable){
        dispatch_async(director.queue, ^{
            for (NRDDeviceConductor *conductor in director.conductors.allValues){
                if (![[conductor copyPrimaryLink] isKindOfClass:objc_getClass("NRLinkWiFi")]){
                    if (_latestRequest == NFPreferWiFiStateReset) return;
                    if (_preferWiFiRequestScheduled) return;
                    HBLogDebug(@"Primary link changed, restarting activity");
                    [self beginPreferWiFiRequestWithInterval:XPC_ACTIVITY_INTERVAL_1_MIN queue:director.queue];
                    break;
                }
            }
        });
    }
}

-(void)resetPreferWiFi{
    _latestRequest = NFPreferWiFiStateReset;
    NRLinkDirector *director = [objc_getClass("NRLinkDirector") copySharedLinkDirector];
    dispatch_async(director.queue, ^{
        [self beginResetWiFiRequestWithInterval:XPC_ACTIVITY_INTERVAL_1_MIN queue:director.queue];
    });
}

-(void)attemptPreferWiFi{
    _latestRequest = NFPreferWiFiStatePrefer;
    NRLinkDirector *director = [objc_getClass("NRLinkDirector") copySharedLinkDirector];
    dispatch_async(director.queue, ^{
        [self beginPreferWiFiRequestWithInterval:XPC_ACTIVITY_INTERVAL_1_MIN queue:director.queue];
    });
}

-(void)scheduleActivity:(xpc_object_t)criteria name:(NSString*)activityName activityHandler:(dispatch_block_t)handler queue:(dispatch_queue_t)queue{
    if (!queue) return;
    xpc_activity_register(activityName.UTF8String, criteria, ^(xpc_activity_t activity){
        HBLogDebug(@"Handling activity: %@", activityName);
        dispatch_async(queue, handler);
    });
    HBLogDebug(@"🟢🕑 Activity scheduled: %@", activityName);
}

-(void)beginPreferWiFiRequestWithCriteria:(xpc_object_t)criteria queue:(dispatch_queue_t)queue{
    if (!queue) return;
    [self scheduleActivity:criteria name:_activityPreferWiFiName activityHandler:_activityPreferWiFiHandler queue:queue];
    _preferWiFiRequestScheduled = YES;
}

-(void)beginPreferWiFiRequestWithInterval:(int64_t)interval queue:(dispatch_queue_t)queue{
    [self beginPreferWiFiRequestWithCriteria:[NFPerseverance criteriaWithInterval:interval] queue:queue];
}

-(void)beginResetWiFiRequestWithCriteria:(xpc_object_t)criteria queue:(dispatch_queue_t)queue{
    if (!queue) return;
    [self scheduleActivity:criteria name:_activityResetPreferWiFiName activityHandler:_activityResetPreferWiFiHandler queue:queue];
    _resetPreferWiFiRequestScheduled = YES;
}

-(void)beginResetWiFiRequestWithInterval:(int64_t)interval queue:(dispatch_queue_t)queue{
    [self beginResetWiFiRequestWithCriteria:[NFPerseverance criteriaWithInterval:interval] queue:queue];
}

-(void)stopActivity:(NSString *)activityName{
    xpc_activity_unregister(activityName.UTF8String);
    HBLogDebug(@"🟠🕑 Activity unscheduled: %@", activityName);
}

-(void)stopPreferWiFiRequestActivity{
    [self stopActivity:_activityPreferWiFiName];
    _preferWiFiRequestScheduled = NO;
    _attemptCount = 0;
}

-(void)stopResetPreferWiFiRequestActivity{
    [self stopActivity:_activityResetPreferWiFiName];
    _resetPreferWiFiRequestScheduled = NO;
    _resetCount = 0;
}
@end
