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

@interface NRLink : NSObject
@property(readonly, nonatomic) unsigned long long identifier;
@property(nonatomic) BOOL isPrimary;
@property(readonly, nonatomic) unsigned char type;
@property(readonly, nonatomic) unsigned char state;
@end

@interface NRLinkWiFi : NRLink
- (void)setIsPrimary:(BOOL)arg1;
- (BOOL)resume;
- (BOOL)suspend;
@end


@interface NRLinkBluetooth : NRLink
- (BOOL)resume;
- (BOOL)suspend;
@end

@interface NRAnalytics : NSObject
@end

@interface NRAnalyticsPreferWiFi : NRAnalytics
@property(nonatomic) unsigned long long linkTransitionsWhileRequestActive;
@property(nonatomic) unsigned long long preferWiFiRequestSuccessful;
@property(nonatomic) unsigned long long preferWiFiRequestTimedOut;
@property(nonatomic) unsigned long long preferWiFiRequestEnd;
@property(nonatomic) unsigned long long preferWiFiRequestStart;
@end

@interface NRDDeviceConductor : NSObject
@property(retain, nonatomic) NSObject<OS_dispatch_queue> *queue;
@property(nonatomic) BOOL preferWiFiRequest;
@property(nonatomic) BOOL isEnabled;
@property(nonatomic) BOOL disablePreferWiFi;
@property(retain, nonatomic) NRLink *primaryLink;
@property(retain, nonatomic) NSMutableSet <NRLink *>*availableLinks;
@property(nonatomic) BOOL bringUpWiFiImmediately;
@property(retain, nonatomic) NRAnalyticsPreferWiFi *preferWiFiAnalytics;
@property(nonatomic) BOOL hasPhoneCallRelayRequest;
- (void)setPreferWiFiAllowedForTesting:(BOOL)arg1;
- (void)addSuspendBluetoothRequestWhenWiFiAvailable;
- (void)updatePrimaryLink;
- (void)setIPTunnelPolicyForLink:(id)arg1;
- (void)forceWoWMode;
- (void)suspendLinkOfType:(unsigned char)arg1;
- (void)resumeLinkOfType:(unsigned char)arg1;
- (void)setBringUpWiFiImmediatelyInner:(BOOL)arg1 timeout:(unsigned short)arg2 addSuspendBTRequest:(BOOL)arg3;
- (BOOL)sendPreferWiFiRequest:(BOOL)arg1 immediately:(BOOL)arg2 removeIfFailed:(BOOL)arg3 preferLinkType:(unsigned char)arg4 isAck:(BOOL)arg5 completion:(id /*block*/)arg6;
- (void)linkIsAvailable:(id)arg1;
- (void)sendHelloWithPreferredLink:(id)arg1 forced:(BOOL)arg2;
- (id)copyLinkOfType:(unsigned char)arg1;
- (id)copyPrimaryLink;
@end

@interface NRLinkManager : NSObject
@property(retain, nonatomic) NSObject<OS_dispatch_queue> *queue;
@end

@interface NRLinkManagerWiFi : NRLinkManager
@property(nonatomic) BOOL isWiFiAvailable;
- (void)enableWiFi;
- (void)disableWiFi;
- (BOOL)preferWiFiRequestAvailable;
- (BOOL)preferWiFiRequestUnavailable;
@end

@interface NRLinkDirector : NSObject
@property(retain, nonatomic) NSObject<OS_dispatch_queue> *queue;
@property(retain, nonatomic) NRLinkManagerWiFi *wifiManager;
@property(retain, nonatomic) NSMutableDictionary *conductors;
+ (id)copySharedLinkDirector;
- (void)setPreferWiFiAllowedForTesting:(BOOL)arg1;
- (BOOL)preferWiFiRequestUnavailable;
- (BOOL)preferWiFiRequestAvailable;
@end



//NetworkRelay
/*
@interface NRPreferWiFi : NSObject
+(id)sharedInstance;
-(void)submitRequest:(BOOL)arg1 ;
@end

extern "C" void NRPreferWiFiSet(BOOL isPrefer);
extern "C" void NRPreferWiFiReset();
extern "C" BOOL NRPreferWiFiHasRequest();
*/
