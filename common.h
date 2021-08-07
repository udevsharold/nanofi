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

#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <HBLog.h>

#define kIdentifier @"com.udevs.nanofi"
#define kPrefsPath @"/var/mobile/Library/Preferences/com.udevs.nanofi.plist"

#define kPrefsChanged @"com.udevs.nanofi.prefschanged"
#define kExitMain @"com.udevs.nanofi.exitmain"
#define kSBReloaded @"com.udevs.nanofi.sbreloaded"

#define kAttemptPreferWiFi @"com.udevs.nanofi.attempt-prefer-wifi"
#define kResetPreferWiFi @"com.udevs.nanofi.reset-prefer-wifi"

#define kPreferWiFiState "com.udevs.nanofi.state"
#define kPreferWiFiActivity "com.udevs.nanofi.activity"

typedef NS_ENUM(uint64_t, NFPreferWiFiState){
    NFPreferWiFiStateNone,
    NFPreferWiFiStateReset,
    NFPreferWiFiStatePrefer
};

typedef NS_ENUM(uint64_t, NFPreferWiFiActivity){
    NFPreferWiFiActivityNone,
    NFPreferWiFiActivityRequesting,
    NFPreferWiFiActivityFailed
};
