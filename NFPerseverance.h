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
#import "NFPerseverance.h"
#include <xpc/xpc.h>

@class GAEGizmoPowerMonitor;

@interface NFPerseverance : NSObject{
    dispatch_block_t _activityPreferWiFiHandler;
    dispatch_block_t _activityResetPreferWiFiHandler;
    NSString *_activityPreferWiFiName;
    NSString *_activityResetPreferWiFiName;
    BOOL _preferWiFiRequestScheduled;
    BOOL _resetPreferWiFiRequestScheduled;
    NSUInteger _desiredAttemptCount;
    NSUInteger _desiredResetCount;
    NSUInteger _attemptCount;
    NSUInteger _resetCount;
    BOOL _enabled;
    NFPreferWiFiState _latestRequest;
    NFPreferWiFiState _lastState;
}
+(xpc_object_t)criteriaWithInterval:(int64_t)interval;
+(instancetype)sharedInstance;
-(instancetype)init;
-(void)beginPreferWiFiRequestWithInterval:(int64_t)interval queue:(dispatch_queue_t)queue;
-(void)beginResetWiFiRequestWithInterval:(int64_t)interval queue:(dispatch_queue_t)queue;
-(void)attemptPreferWiFi;
-(void)resetPreferWiFi;
-(void)updatePrefs;
-(void)notify:(const char *)notificationName state:(uint64_t)state;
@end

